package RT::Extension::AutomaticAssignment::Filter::MemberOfGroup;
use strict;
use warnings;
use base 'RT::Extension::AutomaticAssignment::Filter';

sub FilterOwnersForTicket {
    my $class  = shift;
    my $ticket = shift;
    my $users  = shift;
    my $config = shift;

    my $group = RT::Group->new($ticket->CurrentUser);
    $group->LoadUserDefinedGroup($config->{group});

    if (!$group->Id) {
        die "Unable to filter MemberOfGroup; can't load group '$config->{group}'";
    }

    $users->MemberOfGroup($group->Id);
}

sub Description { "Member of Group" }

sub CanonicalizeConfig {
    my $class = shift;
    my $input = shift;

    my $group = $input->{group};
    $group =~ s/[^0-9]//g; # allow only numeric id

    return { group => $group };
}

1;

