package RT::Extension::AutomaticAssignment::Filter::UserDefined;
use strict;
use warnings;
use base 'RT::Extension::AutomaticAssignment::Filter';

sub FilterOwnersForTicket {
    my $class   = shift;
    my $Ticket  = shift;
    my @Users   = @{ shift(@_) };
    my $Config  = shift;
    my $Context = shift;

    my @matches;

    for my $User (@Users) {
        push @matches, $User if eval $Config->{code};
        if ($@) {
            RT::Logger->error("AutomaticAssignment filter ChooseOwnerForTicket for ticket #" . $Ticket->Id . " failed: ".$@);
            return (undef);
        }
    }

    return \@matches;
}

sub Description { "User Defined" }

sub FiltersUsersArray {
    return 1;
}

sub CanonicalizeConfig {
    my $class = shift;
    my $input = shift;

    my $code = $input->{code};

    return { code => $code };
}

1;

