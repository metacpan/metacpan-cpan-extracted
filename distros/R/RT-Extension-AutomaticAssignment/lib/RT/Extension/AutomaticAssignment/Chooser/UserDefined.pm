package RT::Extension::AutomaticAssignment::Chooser::UserDefined;
use strict;
use warnings;
use base 'RT::Extension::AutomaticAssignment::Chooser';

sub ChooseOwnerForTicket {
    my $class  = shift;
    my $Ticket = shift;
    my @Users  = @{ shift(@_) };
    my $Config = shift;

    my $user = eval $Config->{code};
    if ($@) {
        RT::Logger->error("AutomaticAssignment chooser ChooseOwnerForTicket for ticket #" . $Ticket->Id . " failed: ".$@);
        return (undef);
    }

    return $user;
}

sub Description { "User Defined" }

sub CanonicalizeConfig {
    my $class = shift;
    my $input = shift;

    my $code = $input->{code};

    return { code => $code };
}

1;

