use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }

######################################################################
#
# eg/quickstart.pl - the smallest useful TUI::Handy form
#
# Run it from the top of the distribution:
#
#     perl -Ilib eg/quickstart.pl
#
# The point of this example is how little there is to it.  The text below
# is drawn exactly as written, and the labels in it ("Name", "Team",
# "Active") are the keys of the hash that run() gives back.  There is no
# widget construction, no layout code and no binding step; editing the
# screen and editing the data structure are the same edit.
#
######################################################################

use lib 'lib';
use TUI::Handy;

my $dsl = <<'FORM';
Quick start
Name:   [____________________]
Team:   [____________________]
[X] Active

[OK]
[Cancel]
FORM

my $tui = TUI::Handy->new(dsl => $dsl);

# A button handler receives the live value hash and returns true to close
# the form.  Returning false leaves the form open, which is how a handler
# that finds a problem keeps the user on the screen.
$tui->set('OK', sub {
    my $form = shift;
    if ($form->{'Name'} =~ /^\s*$/) {
        return 0;
    }
    return 1;
});
$tui->set('Cancel', sub { 1 });

my $form = $tui->run;

my $pressed = defined($tui->pressed) ? $tui->pressed : '(aborted)';
print "pressed: $pressed\n";
if ($pressed eq 'OK') {
    print "name:   $form->{'Name'}\n";
    print "team:   $form->{'Team'}\n";
    print "active: $form->{'Active'}\n";
}

__END__
