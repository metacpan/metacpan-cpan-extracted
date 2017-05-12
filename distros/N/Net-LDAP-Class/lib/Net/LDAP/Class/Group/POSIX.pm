package Net::LDAP::Class::Group::POSIX;
use strict;
use warnings;
use Carp;
use base qw( Net::LDAP::Class::Group );

our $VERSION = '0.27';

my $RESERVED_GID = 999999;    # used when renaming groups

# see http://www.ietf.org/rfc/rfc2307.txt

=head1 NAME

Net::LDAP::Class::Group::POSIX - group class for POSIX LDAP schema

=head1 SYNOPSIS

 # create a subclass for your local LDAP
 package MyLDAPGroup;
 use base qw( Net::LDAP::Class::Group::POSIX );
 
 __PACKAGE__->metadata->setup(
     base_dn             => 'dc=mycompany,dc=com',
    attributes          => __PACKAGE__->POSIX_attributes,
    unique_attributes   => __PACKAGE__->POSIX_unique_attributes,
 );
 
 1;
 
 # then use your class
 my $ldap = get_and_bind_LDAP_object(); # you write this
 
 use MyLDAPGroup;
 my $group = MyLDAPGroup->new( ldap => $ldap, cn   => 'foobar' );
 $group->read_or_create;
 for my $user ($group->users) {
     printf("user %s in group %s\n", $user, $group);
 }

=head1 DESCRIPTION

Net::LDAP::Class::Group::POSIX isa Net::LDAP::Class::Group implementing
the POSIX LDAP schema.

=head1 CLASS METHODS

=head2 POSIX_attributes

Returns array ref of 'cn', 'gidNumber' and 'memberUid'.

=cut

sub POSIX_attributes {

    # these attributes refer to the posixGroup object
    # which SUPER::read() will refer to.
    return [
        qw(
            cn gidNumber memberUid
            )
    ];

}

=head2 POSIX_unique_attributes

Returns array ref of 'cn' and 'gidNumber'.

=cut

sub POSIX_unique_attributes {
    return [qw( cn gidNumber )];
}

=head1 OBJECT METHODS

=head2 read

Overrides (and calls) base method to perform additional sanity check
that the matching organizational unit exists for the primary posixGroup.

=cut

sub read {
    my $self = shift;
    $self->SUPER::read( base_dn => 'ou=Group,' . $self->base_dn, @_ )
        or return;

    my $name = $self->cn;

    # double check that organizational unit exists too
    if (!$self->find(
            base_dn => 'ou=People,' . $self->base_dn,
            scope   => 'sub',
            filter  => "(ou=$name)"
        )
        )
    {
        croak
            "fatal LDAP error: posixGroup $name found but no matching organizational unit";
    }

    return $self;
}

=head2 action_for_create([ cn => I<cn_value>, gidNumber => I<gid> ])

Add a group to the database.

May be called as a class method with explicit B<cn> and B<gidNumber>
key/value pairs.

=cut

sub action_for_create {
    my $self = shift;
    my %opts = @_;
    my $name = delete $opts{cn} || $self->cn
        or croak "cn required to create()";
    my $gid = delete $opts{gidNumber} || $self->gidNumber
        or croak "gidNumber required to create()";
    my @actions = (

        add => [

            # first the posixGroup
            {   dn   => "cn=$name,ou=Group," . $self->base_dn,
                attr => [
                    objectClass => [ 'top', 'posixGroup' ],
                    cn          => $name,
                    gidNumber   => $gid,
                ],
            },

            # second the organizational unit
            {   dn   => "ou=$name,ou=People," . $self->base_dn,
                attr => [
                    objectClass => [ 'top', 'organizationalUnit' ],
                    ou          => $name
                ],
            },
        ]
    );

    # special case of passing in '0' (zero) means do not
    # create actions for memberUid.
    my $memberUid = delete $opts{memberUid};
    if ( !defined $memberUid ) {
        $memberUid = $self->memberUid;
    }
    if ( defined $memberUid and ref $memberUid and @$memberUid ) {
        push(
            @actions,
            update => {
                search => [
                    base   => "ou=Group," . $self->base_dn,
                    scope  => "sub",
                    filter => "(cn=$name)"
                ],
                replace => { memberUid => $memberUid },
            }
        );
    }
    elsif ( defined $memberUid and !ref $memberUid and $memberUid ne '0' ) {
        push(
            @actions,
            update => {
                search => [
                    base   => "ou=Group," . $self->base_dn,
                    scope  => "sub",
                    filter => "(cn=$name)"
                ],
                replace => { memberUid => [$memberUid] },
            }
        );
    }

    return @actions;

}

=head2 action_for_update

Save new gidNumber (gid) or cn (name) for an existing group. 

B<NOTE:> Because of the POSIX schema layout, 
renaming a group means creating a new group, moving
existing users into it, and deleting the old group. This is handled
transparently in action_for_update().

=cut

sub action_for_update {
    my $self = shift;
    my %opts = @_;

    if ( !grep { exists $self->{_was_set}->{$_} } @{ $self->attributes } ) {
        warn "no attributes have changed for group $self. Skipping update().";
        return 1;
    }

    my @actions;

    # change gid alone is easy.
    if ( exists $self->{_was_set}->{gidNumber}
        and !exists $self->{_was_set}->{cn} )
    {

        push(
            @actions,
            update => {
                search => [
                    base   => "ou=Group," . $self->base_dn,
                    scope  => "sub",
                    filter => "(cn=" . $self->cn . ")"
                ],
                replace => { gidNumber => $self->gidNumber },
            }
        );

    }

    # changing name, not as easy.
    if ( exists $self->{_was_set}->{cn} ) {

        my $class = ref($self) || $self;

        my $old_name = $self->{_was_set}->{cn}->{old};
        my $new_name = $self->{_was_set}->{cn}->{new};
        if ( $self->debug ) {
            warn "renaming group $old_name to $new_name\n";
        }

        my $oldgroup
            = $class->new( ldap => $self->ldap, cn => $old_name )->read
            or croak "can't find $old_name in LDAP";

        my $new_gid
            = exists $self->{_was_set}->{gidNumber}
            ? $self->{_was_set}->{gidNumber}->{new}
            : $self->gidNumber;

        # LDAP schema requires we rename existing group
        # because we can't delete a non-leaf entry.

        # first, change gid of existing group so we don't get conflicts.
        push(
            @actions,
            update => {
                search => [
                    base   => "ou=Group," . $self->base_dn,
                    scope  => "sub",
                    filter => "(cn=$old_name)"
                ],
                replace => { gidNumber => $RESERVED_GID },
            }
        );

        # second, create the new group
        my $primary_users   = $oldgroup->fetch_primary_users;
        my $secondary_users = $oldgroup->fetch_secondary_users;

        if ( $self->debug ) {
            warn "rename group for $self primary users: "
                . join( ", ", @$primary_users );
            warn "rename group for $self secondary users: "
                . join( ", ", @$secondary_users );
        }

        my $newgroup = $class->new(
            ldap      => $self->ldap,
            cn        => $new_name,
            gidNumber => $self->gidNumber,
            memberUid => [ map {"$_"} @$secondary_users ],
        );
        push( @actions, $newgroup->action_for_create );

        # third, update the gid for any users for whom
        # $old_group is the primary group.
        # primary users need their gid and dn set in 2 steps
        for my $user (@$primary_users) {

            my $uid = $user->uid;

            push(
                @actions,
                update => [
                    {   search => [
                            base   => "ou=People," . $user->base_dn,
                            scope  => "sub",
                            filter => "(uid=$uid)",
                            attrs  => $user->attributes,
                        ],
                        replace => { gidNumber => $new_gid }
                    },
                    {   dn => {
                            'newrdn'       => "uid=$uid",
                            'deleteoldrdn' => 1,
                            'newsuperior'  => "ou=$newgroup,ou=People,"
                                . $self->base_dn,
                        },
                        search => [
                            base   => "ou=People," . $self->base_dn,
                            scope  => "sub",
                            filter => "(uid=$uid)",
                            attrs  => $self->attributes,
                        ],
                    }
                ],
            );

        }

        # fourth and finally, delete the original group
        push(
            @actions,
            $self->action_for_delete(
                gidNumber  => $RESERVED_GID,
                cn         => $old_name,
                skip_check => 1,
            )
        );

    }

    return @actions;
}

=head2 action_for_delete( [cn => I<cn_value>] )

Returns array ref of actions for removing the organizational unit
and the posixGroup.

You may call this as a class method with an explicit B<cn> key/value
pair.

=cut

sub action_for_delete {
    my $self = shift;
    my %opts = @_;
    my $name = delete $opts{cn} || $self->cn;

    if ( !$name ) {
        croak "cn required to delete a Group";
    }

    # even if called a class method, we need an object
    # in order to find users, etc.
    my $group = ref($self) ? $self : $self->new( cn => $name )->read;
    if ( !$group ) {
        croak "no such Group to delete: $name";
    }

    unless ( $opts{skip_check} ) {

        # set since users() will require it
        $group->cn($name);

        # clear first so we re-read from the db
        $group->clear_primary_users;
        $group->clear_secondary_users;

        if ( scalar @{ $group->users } ) {
            croak
                "cannot delete Group $group -- it still has members: [primary] "
                . join( ", ", map {"$_"} @{ $group->primary_users } )
                . " [secondary] "
                . join( ", ", map {"$_"} @{ $group->secondary_users } );
        }

    }

    my @actions = (
        {   search => [
                base   => 'ou=People,' . $group->base_dn,
                scope  => 'sub',
                filter => "(ou=$name)",
                attrs  => $group->attributes,
            ],
        },
        {   search => [
                base   => "ou=Group," . $group->base_dn,
                scope  => "sub",
                filter => "(cn=$name)",
                attrs  => $group->attributes,
            ],
        },

    );

    return ( delete => \@actions );
}

=head2 fetch_primary_users

Required MethodMaker method for retrieving primary_users from LDAP.

Returns array or array ref based on context, of related User objects
who have this group assigned as their primary group.

=cut

sub fetch_primary_users {
    my $self       = shift;
    my $user_class = $self->user_class or croak "user_class() required";
    my $name       = $self->cn;
    my @u          = $user_class->find(
        base_dn => "ou=$name,ou=People," . $self->base_dn,
        scope   => "sub",
        filter  => "(objectClass=posixAccount)",
        ldap    => $self->ldap,
    );
    return wantarray ? @u : \@u;
}

=head2 primary_users_iterator

Returns Net::LDAP::Class::Iterator for the same query as fetch_primary_users().

See the advice in L<Net::LDAP::Class::Iterator> about iterators
versus arrays.

=cut

sub primary_users_iterator {
    my $self       = shift;
    my $user_class = $self->user_class or croak "user_class required";
    my $name       = $self->cn || $self->read->cn;
    return Net::LDAP::Class::Iterator->new(
        class   => $user_class,
        base_dn => "ou=$name,ou=People," . $self->base_dn,
        filter  => "(objectClass=posixAccount)",
        ldap    => $self->ldap,
        @_
    );
}

=head2 fetch_secondary_users

Required MethodMaker method for retrieving secondary_users from LDAP.

Returns array or array ref based on context, of related User objects
who have this group assigned as a secondary group.

Consider using secondary_users_iterator() instead, especially if you
have large groups. See L<Net::LDAP::Class::Iterator> for an explanation.
This method is just a wrapper around secondary_users_iterator().

=cut

# changed to using iterator to avoid surprises for large groups.
sub fetch_secondary_users {
    my $self = shift;
    my @users;
    my $iter = $self->secondary_users_iterator;
    while ( my $u = $iter->next ) {
        push @users, $u;
    }
    return wantarray ? @users : \@users;
}

=head2 secondary_users_iterator([I<opts>])

Returns Net::LDAP::Class::SimpleIterator for the same query as 
fetch_secondary_users().

See the advice in L<Net::LDAP::Class::Iterator> about iterators
versus arrays.

=cut

sub secondary_users_iterator {
    my $self       = shift;
    my $user_class = $self->user_class or croak "user_class required";
    my $ldap       = $self->ldap or croak "ldap required";
    $self->read;    # make sure we have latest memberUid list
    my @uids = $self->memberUid;

    return Net::LDAP::Class::SimpleIterator->new(
        code => sub {
            my $uid = shift @uids or return undef;
            return $user_class->new( ldap => $ldap, uid => $uid )->read;
        }
    );
}

=head2 gid

Alias for gidNumber() attribute.

=cut

sub gid {
    my $self = shift;
    $self->gidNumber(@_);
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-ldap-class at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-Class>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::Class

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LDAP-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LDAP-Class>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LDAP-Class>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT

Copyright 2008 by the Regents of the University of Minnesota.
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Net::LDAP

=cut
