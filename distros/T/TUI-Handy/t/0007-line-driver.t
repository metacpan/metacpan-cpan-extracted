use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/0007-line-driver.t - the portable line-oriented driver, which is what a
# bare Windows cmd.exe gets, honours the same button-handler contract as the
# full-screen ANSI driver:
#
#   * a handler returning false keeps the form open, and the fields are
#     walked again with the values already entered as the defaults;
#   * a handler returning true closes the form and pressed() names it;
#   * a press that did NOT close the form leaves pressed() undefined, so an
#     abort can never be mistaken for a successful Save;
#   * end of input aborts, the way ESC does in the full-screen driver;
#   * a button choice outside the range only re-prompts for the button, and
#     does not cost another walk through the fields.
#
# STDIN is fed from a temporary file and STDOUT is diverted to another one,
# so the driver's prompts stay out of the TAP stream.  Both are done with
# two-argument open() and bareword handles, which is what Perl 5.005_03
# understands.

use lib 'lib', 't/lib';
use INA_CPAN_Check;

require TUI::Handy;

my $STDIN_FILE  = "tui_handy_in_$$.tmp";
my $STDOUT_FILE = "tui_handy_out_$$.tmp";

my $DSL = <<'FORM';
Line driver
Name: [__________]
Team: [__________]
[X] Active

Plan:
(*) Basic
( ) Extra
[Save]
[Quit]
FORM

# Run a form in line mode against the given keystroke lines and return the
# object, so a test can look at both the collected values and pressed().
sub run_line {
    my ($input, $handler) = @_;

    local *IN_TMP;
    open(IN_TMP, ">$STDIN_FILE") or die "Can't write $STDIN_FILE: $!";
    print IN_TMP $input;
    close(IN_TMP);

    my $tui = TUI::Handy->new(dsl => $DSL);
    $tui->set('Save', $handler);
    $tui->set('Quit', sub { 1 });

    local $ENV{'TUI_HANDY_MODE'} = 'line';

    open(SAVED_OUT, ">&STDOUT") or die "Can't dup STDOUT: $!";
    open(SAVED_IN,  "<&STDIN")  or die "Can't dup STDIN: $!";
    open(STDOUT, ">$STDOUT_FILE") or die "Can't write $STDOUT_FILE: $!";
    open(STDIN,  "<$STDIN_FILE")  or die "Can't read $STDIN_FILE: $!";

    eval { $tui->run };
    my $err = $@;

    # Restored without an explicit close first: closing both would free file
    # descriptors 0 and 1, and the next dup would then land on the wrong one.
    open(STDOUT, ">&SAVED_OUT") or die "Can't restore STDOUT: $!";
    open(STDIN,  "<&SAVED_IN")  or die "Can't restore STDIN: $!";
    close(SAVED_OUT);
    close(SAVED_IN);

    die $err if $err;
    return $tui;
}

# How many times the driver walked the fields, counted from the prompts it
# printed into the diverted STDOUT.
sub passes {
    local *OUT_TMP;
    open(OUT_TMP, "<$STDOUT_FILE") or return 0;
    my $n = 0;
    while (<OUT_TMP>) {
        $n++ if /^Name \[/;
    }
    close(OUT_TMP);
    return $n;
}

# Each entry is [ how many assertions it makes, the code that makes them ],
# and the plan is their sum, so an assertion added inside a block cannot
# drift away from the plan unnoticed.
my @tests = (

    # A plain run: one pass, Save accepted.
    [3, sub {
        my $tui = run_line("Alice\nSales\ny\n1\n1\n", sub { 1 });
        my $form = $tui->form;
        ok(defined($tui->pressed) && $tui->pressed eq 'Save',
           'an accepted press sets pressed()');
        ok($form->{'Name'} eq 'Alice' && $form->{'Team'} eq 'Sales',
           'values are collected in one pass');
        ok(passes() == 1, 'an accepted press walks the fields once');
    }],

    # A handler that refuses the first press: the fields are walked again,
    # and what was typed the first time survives as the default.
    [4, sub {
        my $seen = 0;
        my $tui = run_line("Alice\nSales\ny\n1\n1\n\n\n\n\n1\n", sub {
            $seen++;
            return ($seen >= 2) ? 1 : 0;
        });
        ok($seen == 2, 'the handler was called on both presses');
        ok(defined($tui->pressed) && $tui->pressed eq 'Save',
           'the accepted press sets pressed()');
        ok($tui->form->{'Name'} eq 'Alice',
           'an empty answer on the second pass keeps the first value');
        ok(passes() == 2, 'a refused press walks the fields a second time');
    }],

    # The second pass really can change a value.
    [2, sub {
        my $seen = 0;
        my $tui = run_line("Alice\nSales\ny\n1\n1\nBob\n\n\n\n1\n", sub {
            $seen++;
            return ($seen >= 2) ? 1 : 0;
        });
        ok($tui->form->{'Name'} eq 'Bob', 'the second pass overwrites a value');
        ok($tui->form->{'Team'} eq 'Sales', 'and leaves the others alone');
    }],

    # A refused press followed by end of input: the form was never closed by
    # a button, so pressed() must not name one.
    [2, sub {
        my $tui = run_line("Alice\nSales\ny\n1\n1\n", sub { 0 });
        ok(!defined($tui->pressed),
           'a refused press leaves pressed() undefined');
        ok($tui->{'aborted'} == 1, 'end of input aborts the form');
    }],

    # An out-of-range choice re-prompts for the button only.
    [2, sub {
        my $tui = run_line("Alice\nSales\ny\n1\n9\n0\n1\n", sub { 1 });
        ok(defined($tui->pressed) && $tui->pressed eq 'Save',
           'an out-of-range choice is ignored and the next one is used');
        ok(passes() == 1,
           'an out-of-range choice does not re-walk the fields');
    }],

    # A button with no handler closes the form and is reported.
    [1, sub {
        my $tui = TUI::Handy->new(dsl => $DSL);
        my $w;
        for my $x (@{$tui->{'widgets'}}) {
            $w = $x if $x->{'kind'} eq 'button' && $x->{'label'} eq 'Save';
        }
        my $closed = $tui->_press($w);
        ok($closed == 1 && defined($tui->pressed) && $tui->pressed eq 'Save',
           'a button with no handler submits and closes');
    }],

    # close_form() from inside a handler closes it even when the handler
    # returns false.
    [1, sub {
        my $tui = run_line("Alice\nSales\ny\n1\n1\n", sub {
            my ($form, $self) = @_;
            $self->close_form;
            return 0;
        });
        ok(defined($tui->pressed) && $tui->pressed eq 'Save',
           'close_form() from a handler closes the form');
    }],
);

my $plan = 0;
for my $t (@tests) {
    $plan += $t->[0];
}
plan_tests($plan);
for my $t (@tests) {
    $t->[1]->();
}

unlink($STDIN_FILE);
unlink($STDOUT_FILE);
