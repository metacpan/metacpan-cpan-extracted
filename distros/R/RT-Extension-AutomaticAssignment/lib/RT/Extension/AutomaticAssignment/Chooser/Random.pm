package RT::Extension::AutomaticAssignment::Chooser::Random;
use strict;
use warnings;
use base 'RT::Extension::AutomaticAssignment::Chooser';

sub ChooseOwnerForTicket {
    my $class  = shift;
    my $ticket = shift;
    my @users  = @{ shift(@_) };
    my $config = shift;

    return $users[rand @users];
}

sub Description { "Random" }

1;

