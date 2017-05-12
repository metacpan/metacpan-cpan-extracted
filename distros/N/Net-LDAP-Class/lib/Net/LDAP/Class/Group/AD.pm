package Net::LDAP::Class::Group::AD;
use strict;
use warnings;
use base qw( Net::LDAP::Class::Group );
use Carp;
use Data::Dump ();

our $VERSION = '0.27';

=head1 NAME

Net::LDAP::Class::Group::AD - Active Directory group class

=head1 SYNOPSIS

 # create a subclass for your local Active Directory
 package MyLDAPGroup;
 use base qw( Net::LDAP::Class::Group::AD );
 
 __PACKAGE__->metadata->setup(
    base_dn             => 'dc=mycompany,dc=com',
    attributes          => __PACKAGE__->AD_attributes,
    unique_attributes   => __PACKAGE__->AD_unique_attributes,
 );
 
 1;
 
 # then use your class
 my $ldap = get_and_bind_LDAP_object(); # you write this
 
 use MyLDAPGroup;
 my $group = MyLDAPGroup->new( ldap => $ldap, cn => 'foobar' );
 $group->read_or_create;
 my $users = $group->users_iterator( page_size => 50 );
 while ( my $user = $users->next ) {
     printf("user %s in group %s\n", $user, $group);
 }

=head1 DESCRIPTION

Net::LDAP::Class::Group::AD isa Net::LDAP::Class::Group implementing
the Active Directory LDAP schema.

=head1 CLASS METHODS

=head2 AD_attributes

Returns array ref of a subset of the default Active Directory
attributes. Only a subset is used since the default schema contains
literally 100s of attributes. The subset was chosen based on its
similarity to the POSIX schema.

=cut

sub AD_attributes {
    [   qw(
            canonicalName
            cn
            description
            distinguishedName
            info
            member
            primaryGroupToken
            whenChanged
            whenCreated
            objectClass
            objectSID
            )
    ];
}

=head2 AD_unique_attributes

Returns array ref of unique Active Directory attributes.

=cut

sub AD_unique_attributes {
    [qw( cn objectSID distinguishedName )];
}

=head1 OBJECT METHODS

=head2 fetch_primary_users

Required MethodMaker method for retrieving primary_users from LDAP.

Returns array or array ref based on context, of related User objects
who have this group assigned as their primary group.

=cut

sub fetch_primary_users {
    my $self       = shift;
    my $user_class = $self->user_class;
    my $pgt        = $self->primaryGroupToken;
    my @users      = $user_class->find(
        scope   => 'sub',
        filter  => "(primaryGroupID=$pgt)",
        ldap    => $self->ldap,
        base_dn => $self->base_dn,
    );

    return wantarray ? @users : \@users;
}

=head2 primary_users_iterator([I<opts>])

Returns a Net::LDAP::Class::Iterator object for all the related
primary users for the group.

This is the same data as primary_users() returns, but is more
efficient since it pages the results and only fetches
one at a time.

=cut

sub primary_users_iterator {
    my $self = shift;
    my $user_class = $self->user_class or croak "user_class required";
    my $pgt = $self->primaryGroupToken || $self->read->primaryGroupToken;
    return Net::LDAP::Class::Iterator->new(
        class   => $user_class,
        ldap    => $self->ldap,
        base_dn => $self->base_dn,
        filter  => "(primaryGroupID=$pgt)",
        @_
    );
}

=head2 fetch_secondary_users

Required MethodMaker method for retrieving secondary_users from LDAP.

Returns array or array ref based on context, of related User objects
who have this group assigned as a secondary group (memberOf).

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

Like primary_users_iterator, only for secondary_users.

This is the same data as secondary_users() returns, but is more
efficient since it pages the results and only fetches
one at a time.

=cut

sub secondary_users_iterator {
    my $self = shift;
    my $dn = $self->distinguishedName || $self->cn;

    # escape any parens
    $dn =~ s/\(/\\(/g;
    $dn =~ s/\)/\\)/g;

    # there's a subtle bug possible here.
    # unlike secondary_users, which will croak if there's
    # a mismatch in the list of members the group claims
    # and what LDAP actually returns for the $dn value,
    # this query will silenty miss any users who don't have
    # memberOf set correctly. I don't *think* it's an issue
    # since we're looking for memberOf specifically,
    # rather than parsing the $dn for the user's distinguishedName
    # but you never know.
    # The behaviour in secondary_users() is actually more brittle,
    # as it will point out the problems in parsing the $dn.
    return Net::LDAP::Class::Iterator->new(
        class   => $self->user_class,
        ldap    => $self->ldap,
        base_dn => $self->base_dn,
        filter  => qq{(memberOf=$dn)},
        @_
    );
}

=head2 gid

Alias for calling primaryGroupToken() method.
Note that primaryGroupToken is dynamically generated 
by the server and cannot be assigned (set).

=cut

sub gid { shift->primaryGroupToken }

=head2 action_for_create([ cn => I<cn_value> ])

Add a group to the database.

May be called as a class method with explicit B<cn> key/value pair.

=cut

sub action_for_create {
    my $self = shift;
    my %opts = @_;
    my $name = delete $opts{cn} || $self->cn
        or croak "cn required to create()";

    my @actions = (
        add => [
            {   dn   => "CN=$name," . $self->base_dn,
                attr => [
                    objectClass => [ 'top', 'group' ],
                    cn          => $name,
                ],
            },
        ]
    );

    return @actions;

}

=head2 action_for_update

Save new cn (name) for an existing group.

=cut

sub action_for_update {
    my $self = shift;
    my %opts = @_;

    my $base_dn = delete $opts{base_dn} || $self->base_dn;

    my @actions;

    # users get translated to 'member' attribute
    if ( exists $self->{users} ) {

        my @names;
        for my $user ( @{ delete $self->{users} } ) {
            my $dn = $user->ldap_entry->dn;
            push @names, $dn;
        }
        $self->member( \@names );    # should trigger _was_set below

    }

    # which fields have changed.
    my %replace;
    for my $attr ( keys %{ $self->{_was_set} } ) {

        next if $attr eq 'cn';                   # part of DN
        next if $attr eq 'objectSID';            # set by server
        next if $attr eq 'primaryGroupToken';    # set by server

        my $old = $self->{_was_set}->{$attr}->{old};
        my $new = $self->{_was_set}->{$attr}->{new};

        if ( defined($old) and !defined($new) ) {
            $replace{$attr} = undef;
        }
        elsif ( !defined($old) and defined($new) ) {
            $replace{$attr} = $new;
        }
        elsif ( !defined($old) and !defined($new) ) {

            #$replace{$attr} = undef;
        }
        elsif ( $old ne $new ) {
            $replace{$attr} = $new;
        }

    }

    if (%replace) {
        my $cn = $self->name;
        push(
            @actions,
            update => {
                search => [
                    base   => $base_dn,
                    scope  => "sub",
                    filter => "(cn=$cn)",
                    attrs  => $self->attributes,
                ],
                replace => \%replace
            }
        );
    }

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

        # two steps since cn is part of the dn.
        # first, create a new group with the new name
        push( @actions, $self->action_for_create( cn => $new_name ) );

        # second, delete the old group.
        push( @actions, $self->action_for_delete( cn => $old_name ) );

    }

    if ( !@actions ) {
        warn "no attributes have changed for group $self. Skipping update().";
        return @actions;
    }

    return @actions;
}

=head2 action_for_delete( [cn => I<cn_value>] )

Removes array ref of actions for removing the Group.

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
    my $group
        = ref($self)
        ? $self
        : $self->new( cn => $name, ldap => $self->ldap )->read;
    if ( !$group ) {
        croak "no such Group to delete: $name";
    }

    # TODO update all related Users 'memberOf' ?

    my @actions = (
        {   search => [
                base   => $group->base_dn,
                scope  => 'sub',
                filter => "(cn=$name)",
                attrs  => $group->attributes,
            ],
        }
    );

    return ( delete => \@actions );
}

=head2 add_user( I<user_object> )

Push I<user_object> onto the list of member() DNs, checking
that I<user_object> is not already on the list.

=cut

sub add_user {
    my $self = shift;
    my $user = shift;
    if ( !$user or !ref($user) or !$user->isa('Net::LDAP::Class::User::AD') )
    {
        croak "Net::LDAP::Class::User::AD object required";
    }
    unless ( $user->username ) {
        croak
            "User object must have at least a username before adding to group $self";
    }
    if ( !defined $self->{users} ) {
        $self->{users} = $self->secondary_users;
    }
    my @users = @{ $self->{users} };
    for my $u (@users) {
        if ( "$u" eq "$user" ) {
            croak "User $user is already a member of group $self";
        }
    }
    push( @users, $user );
    $self->{users} = \@users;
}

=head2 remove_user( I<user_object> )

Drop I<user_object> from the list of member() DNs, checking
that I<user_object> is already on the list.

=cut

sub remove_user {
    my $self = shift;
    my $user = shift;
    if ( !$user or !ref($user) or !$user->isa('Net::LDAP::Class::User::AD') )
    {
        croak "Net::LDAP::Class::User::AD object required";
    }
    unless ( $user->username ) {
        croak
            "User object must have at least a username before removing from group $self";
    }
    if ( !defined $self->{users} ) {
        $self->{users} = $self->secondary_users;
    }
    my %users = map { $_->username => $_ } @{ $self->{users} };
    if ( !exists $users{ $user->username } ) {
        croak "User $user is not a member of group $self";
    }
    delete $users{ $user->username };
    $self->{users} = [ values %users ];
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
