package RT::Extension::AutomaticAssignment::Filter::MemberOfRole;
use strict;
use warnings;
use base 'RT::Extension::AutomaticAssignment::Filter';

sub FilterOwnersForTicket {
    my $class  = shift;
    my $ticket = shift;
    my $users  = shift;
    my $config = shift;

    my $role = $config->{role}
        or die "Unable to filter MemberOfRole; no role provided.";

    my ($ticket_group, $queue_group);

    if ($role eq 'AdminCc' || $role eq 'Cc' || $role eq 'Requestor') {
        $ticket_group = $ticket->RoleGroup($role);
        $queue_group = $ticket->QueueObj->RoleGroup($role);
    }
    elsif (RT::Handle::cmp_version($RT::VERSION,'4.4.0') < 0) {
        die "Unable to filter MemberOfRole role '$role'; custom roles require RT 4.4 or greater.";
    }
    else {
        my $customrole = RT::CustomRole->new( $ticket->CurrentUser );
        $customrole->Load($role);

        $ticket_group = $ticket->RoleGroup($customrole->GroupType);
        $queue_group = $ticket->QueueObj->RoleGroup($customrole->GroupType);
    }

    $users->WhoBelongToGroups(
        Groups => [ map { $_->id } grep { $_ } $ticket_group, $queue_group ],
        IncludeSubgroupMembers => 1,
        IncludeUnprivileged    => 1, # no need to LimitToPrivileged again
    );
}

sub Description { "Member of Role" }

sub CanonicalizeConfig {
    my $class = shift;
    my $input = shift;

    my $role = $input->{role};
    unless ($role eq 'Cc' || $role eq 'AdminCc' || $role eq 'Requestor') {
        $role =~ s/[^0-9]//g; # allow only numeric id
    }

    return { role => $role };
}

1;

