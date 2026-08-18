use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }

######################################################################
#
# eg/master_entry.pl - repeated record entry appended to a TSV file
#
#     perl -Ilib eg/master_entry.pl [TSVFILE]
#
# The form is re-opened after every saved record, which is what data
# entry against a master file actually looks like.  Two things are worth
# noticing:
#
#   * The field types in the DSL do the first layer of validation.  [###]
#     accepts digits only and [YYYYMMDD] accepts a date, so the handler
#     below is left with the checks that need to see more than one field.
#
#   * A handler that returns false keeps the form open with everything the
#     user typed still in place, so refusing a bad record costs nothing.
#     Both drivers honour this, so the guard is written once, in the
#     handler, and pressed() is only ever set by a press that closed the
#     form -- an abort can never look like a successful Save.
#
# The form definition may hold Japanese (or any other language): widths
# are computed at the byte level for UTF-8, Shift_JIS and EUC-JP.  Set
# TUI_HANDY_ENCODING to pick one; this file stays US-ASCII so that it can
# be read on any terminal.
#
######################################################################

use lib 'lib';
use TUI::Handy;

my $file = defined($ARGV[0]) ? $ARGV[0] : 'tui_handy_demo.tsv';

my @COLUMN = ('Code', 'Company', 'Contact', 'Qty', 'Unit price', 'Due date',
              'Category', 'Taxable');

my $dsl = <<'FORM';
Customer master entry
Code:       [#####]
Company:    [____________________________]
Contact:    [____________________]
Qty:        [#####]
Unit price: [$$$$$$$$]
Due date:   [YYYYMMDD]
--------------------------------------------
Category:
(*) Regular
( ) Wholesale
( ) Trial
[X] Taxable
--------------------------------------------
[Save]
[Quit]
FORM

my $saved = 0;

while (1) {
    my $tui = TUI::Handy->new(dsl => $dsl);
    my @problem = ();

    $tui->set('Save', sub {
        my $form = shift;
        @problem = validate($form);
        return @problem ? 0 : 1;
    });
    $tui->set('Quit', sub { 1 });

    my $form = $tui->run;
    my $pressed = $tui->pressed;

    unless (defined($pressed) && ($pressed eq 'Save')) {
        last;
    }

    append_record($file, $form);
    $saved++;
}

print "saved $saved record(s) to $file\n";

######################################################################

# Cross-field checks only; the DSL field types have already rejected
# anything of the wrong shape as it was typed.
sub validate {
    my ($form) = @_;
    my @bad = ();
    for my $key ('Code', 'Company', 'Qty') {
        my $value = defined($form->{$key}) ? $form->{$key} : '';
        $value =~ s/^\s+//;
        $value =~ s/\s+\z//;
        push @bad, $key if $value eq '';
    }
    my $qty = defined($form->{'Qty'}) ? $form->{'Qty'} : '';
    if (($qty ne '') && ($qty + 0 <= 0)) {
        push @bad, 'Qty must be positive';
    }
    return @bad;
}

sub append_record {
    my ($path, $form) = @_;
    my $new = (-e $path) ? 0 : 1;
    local *OUT;
    open(OUT, ">>$path") or die "Can't append to $path: $!\n";
    if ($new) {
        print OUT join("\t", @COLUMN), "\n";
    }
    my @field = ();
    for my $key (@COLUMN) {
        my $value = defined($form->{$key}) ? $form->{$key} : '';
        $value =~ s/[\t\r\n]/ /g;
        push @field, $value;
    }
    print OUT join("\t", @field), "\n";
    close(OUT);
    return;
}

__END__
