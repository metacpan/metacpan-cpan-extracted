package RTx::RightsMatrix::Util;

use strict;

use RT::Groups;
use RTx::RightsMatrix::RolePrincipal;

=head1 NAME

RTx::RightsMatrix::Util - Subroutines for rights processing.

=head1 SYNOPSIS

Utility subroutines to support RTx::RightsMatrix.

=head2 Documentation

These routines probably shouldn't be used outside of RightsMatrix.

=head2 Todo

=head2 Repository

You can find repository of this project at
L<svn://svn.chaka.net/RTx-RightsMatrix>

=head1 AUTHOR

        Todd Chapman <todd@chaka.net>

=cut

=head2 build_group_lists  { RT::Group }

A helper function which takes an RT:Group and reutrns a list of lists of RT::Group objects.
So if group A has group B as member and group B has groups C and D as a member, the
resulting lol looks like:

[ [ 'A', 'B'. 'C' ],
  [ 'A', 'B'. 'D' ] ]

If group A has a member group E then it would look like this:

[ [ 'A', 'E' ],
  [ 'A', 'B'. 'C' ],
  [ 'A', 'B'. 'D' ] ]

The order of the outer list is not guaranteed.

=cut

sub build_group_lists {

    my $group  = shift;

    return undef unless ref ($group) eq 'RT::Group';
    my $lol = [[$group]];

    if ( $group->Domain =~ /::System-Role$/ ) {
        # we need the object if it is a system role
        my $object_type = shift;
        my $object_id = shift;

        my $queue_role_group = RT::Group->new($RT::SystemUser);
        $queue_role_group->LoadQueueRoleGroup( Queue => $object_id, Type => $group->Type );
        push @{$lol->[0]}, $queue_role_group;
    }

    _build_group_lol($lol);
    return $lol;

}

# do the heavy lifting of recursively finding groups and building lists

sub _build_group_lol {

    my $lol = shift;

    my $current_group = $lol->[-1][-1];
    my $members = $current_group->MembersObj;
    $members->LimitToGroups;
    return unless $members->Count;

    my @sub_groups = @{$members->ItemsArrayRef};
    my $first = shift @sub_groups;
    if (_not_seen( $lol->[-1] , $first->MemberObj->Object )) {
        push @{$lol->[-1]}, $first->MemberObj->Object;
        _build_group_lol($lol);
    }

    # evert time we have more than one subgroup (including $first) we have
    # encountered a "split" and must clone the last list and process that
    # part of the group tree
    foreach my $other ( @sub_groups ) {

        if (_not_seen( $lol->[-1] , $other->MemberObj->Object)) {
            my @copy;
            foreach my $elem ( @{$lol->[-1]} ) {
                push @copy, $elem;
                last if $elem->id == $current_group->id;
            }
            push @{$lol}, [ @copy, $other->MemberObj->Object ];
            _build_group_lol($lol);
        }

    }

}

# checks a list of groups to see if the group in the first argument is in it
# used to avoid circular group relationships, but RT seems to protect from
# creating those...

sub _not_seen {

return 1; #disabled because RT should already protect us and I think it's messing us up

    my $list = shift;
    my $check = shift;

    foreach my $group (@$list) {

        if ($group->id == $check->id) { return 0; }

    }

    1;

}

sub showme {

    my $lol = shift;
    my $copy = Storable::dclone($lol);
    foreach my $list (@$copy) {
        foreach my $elem (@$list) {
            $elem = $elem->Name . ': ' . $elem->id if ref $elem;
        }
    }

    return Data::Dumper::Dumper($copy);
}

=head2 acl_for_object  ( RightName => $Right, ObjectType => $Type, ObjectId => $ObjectId )

Returns a list of ACEs for a given object and right.

=cut

sub acl_for_object_and_right {

    my %args = @_;
    my ($Right, $ObjectType, $ObjectId) = @args{'RightName', 'ObjectType', 'ObjectId'};

    my @acl;

    {
        # get ACEs on the object with the specified right
        my $acl = RT::ACL->new($RT::SystemUser);
        $acl->Limit(FIELD => 'RightName', VALUE => $Right);
        $acl->Limit(FIELD => 'ObjectType', VALUE => $ObjectType);
        $acl->Limit(FIELD => 'ObjectId', VALUE => $ObjectId);
        push @acl, @{$acl->ItemsArrayRef};
    }

    $ObjectType =~ /(.*)::.*$/;
    my $module = $1;
    if ($Right ne 'SuperUser' and $ObjectType !~ /^RTx?.*::System$/ ) {
        # get ACEs on System with the specified right
        my $acl = RT::ACL->new($RT::SystemUser);
        $acl->Limit(FIELD => 'RightName', VALUE => $Right);
        $acl->Limit(FIELD => 'ObjectType', VALUE => "${module}::System");
        # less than 2 to get around bug where Id of System is 1 or 0
        $acl->Limit(FIELD => 'ObjectId', VALUE => 2, OPERATOR => '<');
        push @acl, @{$acl->ItemsArrayRef};
    }
    
    if ($Right ne 'SuperUser') {
        # get ACEs on System with the right SuperUser
        my $acl = RT::ACL->new($RT::SystemUser);
        $acl->Limit(FIELD => 'RightName', VALUE => 'SuperUser');
        $acl->Limit(FIELD => 'ObjectType', VALUE => "${module}::System");
        # less than 2 to get around bug where Id of System is 1 or 0
        $acl->Limit(FIELD => 'ObjectId', VALUE => 2, OPERATOR => '<');
        push @acl, @{$acl->ItemsArrayRef};
    }

    # Because an RT SuperUser is an RTx::AssetTracker SuperUser
    # (thanks to the EquivObjects assumptions of Principal::HasRight)
    if ($Right ne 'SuperUser' and $module ne 'RT') {
        # get ACEs on System with the right SuperUser
        my $acl = RT::ACL->new($RT::SystemUser);
        $acl->Limit(FIELD => 'RightName', VALUE => 'SuperUser');
        $acl->Limit(FIELD => 'ObjectType', VALUE => "RT::System");
        # less than 2 to get around bug where Id of System is 1 or 0
        $acl->Limit(FIELD => 'ObjectId', VALUE => 2, OPERATOR => '<');
        push @acl, @{$acl->ItemsArrayRef};
    }

    return @acl;

}

sub acl_for_object_right_and_principal {

    my %args = @_;
    my $Principal = $args{Principal};
    my $ObjectType = $args{ObjectType};
    my $ObjectId = $args{ObjectId};

    my @acl = acl_for_object_and_right(@_);

    # filter for groups the principal is a member of
    # filter out when group IS the principal. we will test that later with _HasDirectRight
    @acl = grep { 
              my $ace_principal = RT::Principal->new($RT::SystemUser);
              $ace_principal->Load($_->PrincipalId);
              my $group = RT::Group->new($RT::SystemUser);
              $group->Load($ace_principal->Id);
              $group->HasMemberRecursively($Principal)
              or (
                     $_->PrincipalType ne 'Group'
                     and
                     $_->ObjectType =~ /RTx?.*::System$/
                     and
                     IsMemberOfObjectRole(Principal => $Principal, Domain => "$ObjectType-Role",
                                          Type => $_->PrincipalType, Instance => $ObjectId )
                 )
                } @acl;

    return @acl;
}

sub IsMemberOfObjectRole {
    my %args = @_;

    my $group = RT::Group->new($RT::SystemUser);
    $group->LoadByCols( Domain => $args{Domain}, Type => $args{Type}, Instance => $args{Instance} );
    return $group->HasMemberRecursively($args{Principal});
}

# Takes a lists of RT::Group objects and returns true if it HasMember
sub list_has_member {

    my $list = shift;
    my $member = shift;
    my $object = shift;

    return 0 unless @$list;

#    if ( $list->[0]->Domain =~ /System-Role$/ ) {
#        return 0 unless $object;
#        my $queue_role_group = RT::Queue->new($RT::SystemUser);
#        $queue_role_group->LoadQueueRoleGroup( Queue => $object->id, Type => $list->[0]->Type );
#    }

    foreach my $group (@$list) {
        return 1
           if $group->HasMember($member); # not recursive!
                                          # we are walking a specific group chain
        return 1
           if $member->IsGroup and $member->Object->id == $group->id;
    }

    return 0;
}

# returns true if two lists have the same objects in the same order
# (really only checks length and $object->id)
sub same {

    my $list_a = shift;
    my $list_b = shift;

    return 0 if (scalar(@$list_a) != scalar(@$list_b));
    foreach my $n (0..$#$list_a) {
        return 0 if $list_a->[$n]->id != $list_b->[$n]->id;
    }

    1;
}

# given a list of groups truncate the list to the last group
# that the principal is a member of, or if the principal is
# a group, to the last group the principal is a member of or
# is the same group
# returns the reduces list
sub reduce_list {

    my $list = shift;
    my $member = shift;
    my @result;
    my $include = 0;

    foreach my $group (reverse @$list) {
        if ( $include or $member->IsGroup and $member->Object->Id == $group->Id ) {
            push @result, $group;
            $include = 1;
        }
        elsif ( $member->IsGroup ) {
            next;
        }
        elsif ( ( $group->HasMember($member) or $include  ) ) {
            push @result, $group;
            $include = 1;
        }
    }

    return [ reverse @result ];
}

sub get_principal {

    my %args = @_;
    my $principal;

    if ($args{Principal} =~ /^\d+$/) {
        $principal = RT::Principal->new($args{CurrentUser});
        my ($rv, $msg) = $principal->Load($args{Principal});
        if (! $rv) {
            return( undef, "Principal not found");
        }
    }
    elsif ($args{Principal} =~ /^(.*)-Role$/) {
        $principal = RTx::RightsMatrix::RolePrincipal->new($1);
    }
    elsif ($args{User}) {
        my $user = RT::User->new($args{CurrentUser});
        my ($rv, $msg) = $user->Load($args{User});
        if (! $rv) {
            return( undef, loc("User [_1] not found: [_2]", $args{User}, $msg) );
        }
        $principal = $user->PrincipalObj;
    }
    else {
        $principal = $args{CurrentUser}->PrincipalObj;
    }

    return $principal, "Principal found";

}

1;
