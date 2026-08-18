use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/0004-edit.t - value editing shared by both drivers: set(), insert,
# backspace, checkbox toggle, radio selection, and field-type validation.

use lib 'lib', 't/lib';
use INA_CPAN_Check;

require TUI::Handy;
$TUI::Handy::ENCODING = 'utf8';
$TUI::Handy::ENCODING = $TUI::Handy::ENCODING;  # silence 'used only once' under -w

my $dsl = <<'FORM';
Company: [______]
Qty:     [###]

Payment:
(*) Cash
( ) Card
[X] Ship
[Register]
FORM

my @tests = (
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->set('Company', 'ACME');
        ok($t->form->{'Company'} eq 'ACME', 'set() presets a text field');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->set('Company', 'abcdefghij');   # size is 6
        ok(length($t->form->{'Company'}) == 6, 'text is clipped to field size');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->set('Qty', '12ab3');            # numeric accepts digits only
        ok($t->form->{'Qty'} eq '123', 'numeric field rejects non-digits');
    },
    sub {
        # A radio preset naming no member of the group is ignored, rather
        # than clearing every button and storing a label that is not on the
        # screen.
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->set('Payment', 'Bitcoin');
        ok($t->form->{'Payment'} eq 'Cash',
           'a radio preset naming no member leaves the value alone');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->set('Payment', 'Bitcoin');
        my $on = 0;
        for my $w (@{$t->{widgets}}) {
            $on++ if $w->{kind} eq 'radio' && $w->{selected};
        }
        ok($on == 1, 'a radio preset naming no member leaves the buttons alone');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        my ($w) = grep { $_->{kind} eq 'text' && $_->{key} eq 'Company' } @{$t->{widgets}};
        $t->_insert($w, 'X');
        $t->_insert($w, 'Y');
        ok($t->form->{'Company'} eq 'XY', 'insert appends characters');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        my ($w) = grep { $_->{kind} eq 'text' && $_->{key} eq 'Company' } @{$t->{widgets}};
        $t->_set_text($w, 'AB');
        $t->_backspace($w);
        ok($t->form->{'Company'} eq 'A', 'backspace removes the last character');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        my ($w) = grep { $_->{kind} eq 'check' } @{$t->{widgets}};
        my $before = $t->form->{'Ship'};
        $t->_toggle($w);
        ok($t->form->{'Ship'} != $before, 'toggle flips a checkbox');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->set('Ship', 0);
        ok($t->form->{'Ship'} == 0, 'set() presets a checkbox to 0');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        my ($card) = grep { $_->{kind} eq 'radio' && $_->{label} eq 'Card' } @{$t->{widgets}};
        $t->_select_radio($card);
        ok($t->form->{'Payment'} eq 'Card', '_select_radio updates the group value');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->set('Payment', 'Card');
        my ($card) = grep { $_->{kind} eq 'radio' && $_->{label} eq 'Card' } @{$t->{widgets}};
        ok($card->{selected} == 1, 'set() selects the named radio member');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        my $fired = 0;
        $t->set('Register', sub { $fired = 1; 1 });
        my ($b) = grep { $_->{kind} eq 'button' } @{$t->{widgets}};
        my $closed = $t->_press($b);
        ok($fired == 1 && $closed == 1 && $t->pressed eq 'Register',
           'a handler returning true closes the form and records pressed');
    },
    sub {
        # A handler returning false is asking for the form to stay open, so
        # the press must not be recorded: otherwise a form abandoned after a
        # rejected press would still report the rejected button.
        my $t = TUI::Handy->new(dsl => $dsl);
        my $fired = 0;
        $t->set('Register', sub { $fired = 1; 0 });
        my ($b) = grep { $_->{kind} eq 'button' } @{$t->{widgets}};
        my $closed = $t->_press($b);
        ok($fired == 1 && $closed == 0 && !defined($t->pressed),
           'a handler returning false leaves the form open and pressed unset');
    },
);

plan_tests(scalar(@tests));
for my $x (@tests) {
    $x->();
}
