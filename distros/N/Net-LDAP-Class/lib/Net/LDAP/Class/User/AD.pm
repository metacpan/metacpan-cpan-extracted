package Net::LDAP::Class::User::AD;
use strict;
use warnings;
use base qw( Net::LDAP::Class::User );
use Carp;
use Data::Dump ();
use Net::LDAP::SID;

my $PRIMARY_GROUP_NOT_USED = 513;
my $AD_TIMESTAMP_OFFSET    = 116444736390271392;
my $AD_TIMESTAMP_OFFSET2   = 11644524000;

use Net::LDAP::Class::MethodMaker (
    'scalar --get_set_init' => [qw( default_home_dir default_email_suffix )],
);

our $VERSION = '0.27';

=head1 NAME

Net::LDAP::Class::User::AD - Active Directory User class

=head1 SYNOPSIS

# subclass this class for your local LDAP
 package MyLDAPUser;
 use base qw( Net::LDAP::Class::User::AD );

 __PACKAGE__->metadata->setup(
    base_dn             => 'dc=mycompany,dc=com',
    attributes          => __PACKAGE__->AD_attributes,
    unique_attributes   => __PACKAGE__->AD_unique_attributes,
 );

 1;

 # then use your class
 my $ldap = get_and_bind_LDAP_object(); # you write this

 use MyLDAPUser;
 my $user = MyLDAPUser->new( ldap => $ldap, sAMAccountName  => 'foobar' );
 $user->read_or_create;
 for my $group ($user->group, @{ $user->groups }) {
     printf("user %s in group %s\n", $user, $group);
 }

=head1 DESCRIPTION

Net::LDAP::Class::User::AD isa Net::LDAP::Class::User implementing
the Active Directory LDAP schema.

=head1 CLASS METHODS

=head2 AD_attributes

Returns array ref of a subset of the default Active Directory
attributes. Only a subset is used since the default schema contains
literally 100s of attributes. The subset was chosen based on its
similarity to the POSIX schema.

=cut

# full attribute list here:
# http://windowsitpro.com/article/articleid/84714/jsi-tip-9910-what-attribute-names-exist-in-my-active-directory-schema.html
# we list only a "relevant" subset

sub AD_attributes {
    [   qw(
            accountExpires
            adminCount
            canonicalName
            cn
            codePage
            countryCode
            description
            displayName
            distinguishedName
            givenName
            groupAttributes
            homeDirectory
            homeDrive
            instanceType
            lastLogoff
            lastLogon
            logonCount
            mail
            memberOf
            middleName
            modifyTimeStamp
            name
            notes
            objectClass
            objectGUID
            objectSID
            primaryGroupID
            profilePath
            pwdLastSet
            sAMAccountName
            sAMAccountType
            sn
            uid
            unicodePwd
            userAccountControl
            userPrincipalName
            uSNChanged
            uSNCreated
            whenCreated
            whenChanged
            )
    ];
}

=head2 AD_unique_attributes

Returns array ref of unique Active Directory attributes.

=cut

sub AD_unique_attributes {
    [qw( sAMAccountName distinguishedName objectSID )];
}

=head1 OBJECT METHODS

All the init_* methods can be specified to the new() constructor without
the init_ prefix.

=head2 fetch_group

Required MethodMaker method for retrieving primary group from LDAP.

Returns an object of type group_class().

=cut

sub fetch_group {
    my $self  = shift;
    my $class = $self->group_class or croak "group_class() required";
    my $gid   = shift || $self->gid;

    if ( !$gid ) {
        croak "cannot fetch group without a gid (primaryGroupID) set";
    }

    # because AD does not store primaryGroupToken but computes it,
    # we must do gymnastics using SIDs
    $self->debug and warn "gid = $gid";

    my $user_sid_string = Net::LDAP::SID->new( $self->objectSID )->as_string;

    $self->debug and warn "user_sid_string:  $user_sid_string";
    ( my $group_sid_string = $user_sid_string ) =~ s/\-[^\-]+$/-$gid/;

    $self->debug and warn "group_sid_string: $group_sid_string";

    return $class->new(
        objectSID => $group_sid_string,
        ldap      => $self->ldap
    )->read;
}

=head2 last_logon_localtime

Returns human-readable version of lastLogon attribute.

=cut

sub last_logon_localtime {
    my $self = shift;
    return scalar localtime( $self->ad_time_as_epoch('lastLogon') );
}

=head2 pwd_last_set_localtime

Returns human-readable version of pwdLastSet attribute.

=cut

sub pwd_last_set_localtime {
    my $self = shift;
    return scalar localtime( $self->ad_time_as_epoch('pwdLastSet') );
}

=head2 ad_time_as_epoch( I<attribute_name> )

Returns epoch time for I<attribute_name>.

=cut

sub ad_time_as_epoch {
    my $self = shift;
    my $attr = shift or croak "attribute_name required";
    return $self->__ad_ts_to_epoch( $self->$attr );
}

sub _domain_attrs {
    my $self    = shift;
    my $ldap    = $self->ldap;
    my $base_dn = $self->base_dn;
    my %args    = (
        base   => $base_dn,
        scope  => 'base',
        attrs  => [],
        filter => '(objectClass=*)',
    );

    #Data::Dump::dump \%args;

    my $msg = $ldap->search(%args);

    if ( $msg->code ) {
        croak $self->get_ldap_error($msg);
    }

    return $msg->entries();
}

sub _pwd_max_age {
    my $self        = shift;
    my @domain_attr = $self->_domain_attrs();
    my $maxPwdAge   = $domain_attr[0]->get_value('maxPwdAge');

    #warn "maxPwdAge = $maxPwdAge";
    my $expires_now = $self->__epoch_to_ad( time() ) + $maxPwdAge;

    #warn "expires_now = $expires_now";
    return $expires_now;
}

# was helfpul:
# http://www.macosxhints.com/article.php?story=20060925114138223

=head2 pwd_will_expire_localtime

Returns human-readable time when password will expire,
based on pwdLastSet attribute and the domain-level maxPwdAge value.

=cut

sub pwd_will_expire_localtime {
    my $self        = shift;
    my $expires_now = $self->_pwd_max_age;
    my $seconds_till_expire
        = ( ( $self->pwdLastSet - $expires_now ) / 10000000 );

    #warn "seconds $seconds_till_expire";
    #warn "days " . ( $seconds_till_expire / 86400 );
    return scalar localtime( time() + $seconds_till_expire );
}

=head2 fetch_groups

Required MethodMaker method for retrieving secondary groups from LDAP.

Returns array or array ref (based on context) of objects of type
group_class().

=cut

sub fetch_groups {
    my $self = shift;
    my @groups;

    if ( $self->ldap_entry ) {
        my @group_dns   = $self->ldap_entry->get_value('memberOf');
        my $group_class = $self->group_class;

        for my $dn (@group_dns) {
            $dn =~ s/^cn=([^,]+),.+/$1/i;
            push(
                @groups,
                $group_class->new(
                    cn   => $dn,
                    ldap => $self->ldap
                    )->read
            );
        }
    }

    return wantarray ? @groups : \@groups;
}

=head2 groups_iterator([I<opts>])

Returns a Net::LDAP::Class::Iterator object with all the secondary
groups. This is the same data as fetch_groups() but as an iterator
instead of an array.

See the advice about iterators versus arrays in L<Net::LDAP::Class::Iterator>.

=cut

sub groups_iterator {
    my $self        = shift;
    my $group_class = $self->group_class or croak "group_class required";
    my $ldap        = $self->ldap or croak "ldap required";
    my @DNs         = $self->memberOf;
    if ( !@DNs ) {
        @DNs = $self->read->memberOf;
    }

    return Net::LDAP::Class::SimpleIterator->new(
        code => sub {
            my $dn = shift @DNs or return undef;
            $dn =~ s/^cn=([^,]+),.+/$1/i;
            $group_class->new(
                cn   => $dn,
                ldap => $ldap
            )->read;

        }
    );
}

=head2 gid

Alias for primaryGroupID() attribute.

=cut

sub gid {
    my $self = shift;
    $self->primaryGroupID(@_);
}

=head2 init_default_home_dir

Returns B<\home>.

=cut

sub init_default_home_dir {'\home'}

=head2 init_default_email_suffix

Returns an empty string.

=cut

sub init_default_email_suffix {''}

=head2 password([I<plain_password>])

Convenience wrapper around unicodePwd() attribute method.

This method will verify I<plain_password> is in the correct
encoding that AD expects and set it in the ldap_entry().

If no argument is supplied, returns the
string set in ldap_entry() (if any).

=cut

sub password {
    my $self      = shift;
    my $attribute = 'unicodePwd';

    if ( !defined $self->ldap_entry && grep { $_ eq $attribute }
        @{ $self->attributes } )
    {

        if ( scalar @_ ) {
            $self->{_not_yet_set}->{$attribute}
                = $self->_encode_pass( $_[0] );
        }
        return
            exists $self->{_not_yet_set}->{$attribute}
            ? $self->{_not_yet_set}->{$attribute}
            : undef;

    }

    if (@_) {
        my $octets = $self->_encode_pass( $_[0] );
        my @old    = $self->ldap_entry->get_value($attribute);
        $self->ldap_entry->replace( $attribute, $octets );
        $self->{_was_set}->{$attribute}->{new} = $octets;

       # do not overwrite an existing 'old' value, since we might need to know
       # what was originally in the ldap_entry in order to replace it.
        unless ( exists $self->{_was_set}->{$attribute}->{old} ) {
            $self->{_was_set}->{$attribute}->{old}
                = @old > 1 ? \@old : $old[0];
        }
    }

    return $self->ldap_entry->get_value($attribute);
}

sub _is_encoded {
    my $str = shift;
    if ( $str =~ m/^"\000.+"\000$/ ) {
        return 1;
    }
    return 0;
}

sub _encode_pass {
    my $self = shift;
    my $pass = shift or croak "password required";

    # detect if password is already encoded and do not double encode
    if ( _is_encoded($pass) ) {
        return $pass;
    }

    my $npass = '';
    map { $npass .= "$_\000" } split( //, "\"$pass\"" );

    return $npass;
}

sub _decode_pass {
    my $self = shift;
    my $pass = shift or croak "password required";
    if ( !_is_encoded($pass) ) {
        return $pass;
    }

    my $decoded = '';
    for my $char ( split( //, $pass ) ) {
        $char =~ s/\000$//;
        $decoded .= $char;
    }
    $decoded =~ s/^"|"$//g;

    return $decoded;
}

=head2 action_for_create([ sAMAccountName => I<username> ])

Returns hash ref suitable for creating a Net::LDAP::Batch::Action::Add.

May be called as a class method with explicit B<uid> and B<uidNumber>
key/value pairs.

=cut

sub action_for_create {
    my $self     = shift;
    my %opts     = @_;
    my $username = delete $opts{sAMAccountName} || $self->sAMAccountName
        or croak "sAMAccountName required to create()";
    my $base_dn = delete $opts{base_dn} || $self->base_dn;

    my ( $group, $gid, $givenName, $sn, $cn, $email )
        = $self->setup_for_write;

    #warn "AD setup_for_write() $base_dn";

    my $pass = $self->password || $self->random_string(10);
    $pass = $self->_encode_pass($pass);

# see
# http://www.sysoptools.com/support/files/Fixing%20user%20accounts%20flagged%20as%20system%20accounts%20-%20the%20UserAccountControl%20AD%20attribute.doc
# for details on userAccountControl.
# basically:
#  512 - normal active account requiring password
#  514 - normal disabled account requiring password
#  544 - system active account - no password required
#  546 - system disabled account - no password required (default)

    my %attr = (
        objectClass => [ "top", "person", "organizationalPerson", "user" ],
        sAMAccountName => $username,
        givenName      => $givenName,
        displayName    => $cn,
        sn             => $sn,
        cn             => $cn,          # must match $dn below
        homeDirectory => $self->default_home_dir . "\\$username",
        mail          => $email,
        userAccountControl => 512,      # so AD treats it as a Normal user
        unicodePwd         => $pass,
    );

    $attr{primaryGroupID} = $gid if $gid;

    # mix in whatever has been set
    for my $name ( keys %{ $self->{_not_yet_set} } ) {

        next if $name eq 'cn';    # because we alter this in setup_for_write()

        #warn "set $name => $self->{_not_yet_set}->{$name}";
        if ( !exists $attr{$name} ) {
            $attr{$name} = delete $self->{_not_yet_set}->{$name};
        }
        else {
            $attr{$name} = $self->{_not_yet_set}->{$name};
        }
    }

    my $dn = "CN=$cn,$base_dn";

    my @actions = (
        add => {
            dn   => $dn,
            attr => [%attr]
        }
    );

    #warn "AD checking groups $base_dn";

    # groups
    if ( exists $self->{groups} ) {

        #carp $self->dump;

        #warn "User $self has groups assigned";
        #warn Data::Dump::dump $self->{groups};

    G: for my $group ( @{ $self->{groups} } ) {
            if ( !$group->read ) {
                croak
                    "You must create group $group before you add User $self to it";
            }

            #warn "checking if $group has user $self";

            # only interested in new additions
            next G if $group->has_user($self);

            #warn "group $group does not yet have user $self";

            my $group_cn = $group->cn;
            my @members  = $group->member;
            push( @members, $dn );

            push(
                @actions,
                update => {
                    search => [
                        base   => $group->base_dn,
                        scope  => "sub",
                        filter => "(cn=$group_cn)",
                        attrs  => $group->attributes,
                    ],
                    replace => { member => \@members },
                }
            );

        }
    }

    return @actions;
}

=head2 setup_for_write

Utility method for generating default values for
various attributes. Called by both action_for_create()
and action_for_update().

Returns array of values in this order:

 $groupname, $gid, $givenName, $sn, $cn, $email

=cut

sub setup_for_write {
    my $self = shift;

    my $gid;
    my $group = $self->{group} || $self->gid;
    if ($group) {
        if ( ref $group and $group->isa('Net::LDAP::Class::Group') ) {
            $gid = $group->gid;
        }
        elsif ( $self->primaryGroupID == $PRIMARY_GROUP_NOT_USED ) {
            warn "primaryGroup feature not used\n";
        }
        else {
            my $group_obj = $self->fetch_group($group);
            if ( !$group_obj ) {
                confess "no such group in AD server: $group";
            }
            $gid = $group_obj->gid;
        }
    }

    # set name
    unless ( $self->displayName
        || $self->cn
        || $self->sn
        || $self->givenName )
    {
        croak "either displayName, cn, sn or givenName must be set";
    }

    # the name logic breaks horribly here for anything but trivial cases.
    my @name_parts = split( m/\s+/, $self->cn || $self->displayName || '' );

    my $givenName = $self->givenName;
    $givenName = shift(@name_parts) unless defined $givenName;
    my $sn = $self->sn;
    $sn = join( ' ', @name_parts ) unless defined $sn;
    my $cn = $self->cn;
    $cn = join( ' ', $givenName, $sn ) unless defined $cn;

    my $un = $self->username;
    if ( $cn ne $un and $cn !~ m!/$un$! ) {
        $cn .= "/$un";    # for uniqueness
    }

    my $email = $self->mail;
    $email = ( $un . $self->default_email_suffix )
        unless defined $email;

    return ( $group, $gid, $givenName, $sn, $cn, $email );
}

=head2 action_for_update

Returns array ref suitable for creating a Net::LDAP::Batch::Action::Update.

=cut

sub action_for_update {
    my $self     = shift;
    my %opts     = @_;
    my $username = $self->username;

    unless ($username) {
        croak "must have sAMAccountName set to update";
    }

    my $base_dn = delete $opts{base_dn} || $self->base_dn;

    my @actions;

    my ( $group, $gid, $givenName, $sn, $cn, $email, $pass )
        = $self->setup_for_write;

    my %derived = (
        cn             => $cn,
        givenName      => $givenName,
        sn             => $sn,
        sAMAccountName => $username,
        unicodePwd     => $pass,
        primaryGroupID => $gid,
        displayName    => $cn,
        mail           => $email,
        homeDirectory  => $self->default_home_dir . "\\$username",
    );

    # which fields have changed.
    my %replace;
    for my $attr ( keys %{ $self->{_was_set} } ) {

        next if $attr eq 'cn';    # because we mangle in setup_for_write()

        my $old = $self->{_was_set}->{$attr}->{old};
        my $new = $self->{_was_set}->{$attr}->{new} || $derived{$attr};

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

    # what group(s) have changed?
    # compare primary group first
    # this assumes that setting group() is preferred to
    # explicitly setting gidNumber.
    if (   defined $group
        && $group ne $PRIMARY_GROUP_NOT_USED
        && !exists $replace{primaryGroupID}
        && $self->group->gid != $self->gid )
    {

        # primary group has changed
        $replace{primaryGroupId} = $self->group->gid;

        # clear so next access re-fetches
        delete $self->{group};

    }

    # next, secondary group membership.
    # check if any have been set explicitly,
    # since otherwise there is nothing to be done.
    if ( exists $self->{groups} ) {

        #carp Data::Dump::dump $self->{groups};

        my $existing_groups = $self->fetch_groups;

        #carp Data::Dump::dump $existing_groups;

        my %existing = map { $_->cn => $_ } @$existing_groups;

        # the delete $self->{groups} has helpful side effect of clearing
        # cache.
        my %new = map { $_->cn => $_ } @{ delete $self->{groups} };

        #warn "User $self has " . scalar( keys %new ) . " groups set";
        #warn "existing group: $_" for sort keys %existing;
        #warn "new group     : $_" for sort keys %new;

        # which should be added
        my @to_add;
    G: for my $cn ( keys %new ) {
            if ( !exists $existing{$cn} ) {
                my $group = $new{$cn};

                if ( !$group->ldap_entry ) {
                    croak(
                        "you must create $group before adding user $self to it"
                    );
                }

                for my $u ( $group->secondary_users ) {

                    #warn " group member: $u <> user $self";

                    next G if "$u" eq "$self";

                }

                #warn "group $group does NOT have User $self assigned";
                $group->add_user($self);

                push( @to_add, $group->action_for_update );

            }
        }

        # which should be removed
        my @to_rm;
    G: for my $cn ( keys %existing ) {
            if ( !exists $new{$cn} ) {
                my $group = $existing{$cn};

                #next unless $group->has_user($self);

                for my $u ( $group->secondary_users ) {
                    next G unless "$u" eq "$self";
                }

                #warn "group $group does have User $self assigned";

                $group->remove_user($self);

                push( @to_rm, $group->action_for_update );

            }
        }

        push( @actions, @to_add, @to_rm );

    }

    if (%replace) {
        push(
            @actions,
            update => {
                search => [
                    base   => $base_dn,
                    scope  => "sub",
                    filter => "(sAMAccountName=$username)",
                    attrs  => $self->attributes,
                ],
                replace => \%replace
            }
        );
    }

    if ( !@actions ) {
        warn "no fields have changed for User $username. Skipping update().";
        return;
    }

    carp "updating User with actions: " . Data::Dump::dump( \@actions )
        if $self->debug;

    return @actions;

}

=head2 action_for_delete

Returns action suitable for creating a Net::LDAP::Batch::Action::Delete.

=cut

sub action_for_delete {
    my $self = shift;
    my %opts = @_;
    my $username 
        = delete $opts{sAMAccountName}
        || delete $opts{username}
        || $self->username;

    my $base_dn = delete $opts{base_dn} || $self->base_dn;

    if ( !$username ) {
        croak "username required to delete a User";
    }

    # delete the user
    my @actions = (
        delete => {
            search => [
                base   => $base_dn,
                scope  => "sub",
                filter => "(sAMAccountName=$username)",
                attrs  => $self->attributes,
            ]
        }
    );

    return @actions;
}

sub __ad_ts_to_epoch {
    my $self = shift;
    my $adts = shift;
    defined $adts or croak "Active Directory timestamp required";

    # convert windows time to unix time
    # thanks to http://quark.humbug.org.au/blog/?p=27

    return ( $adts / 10000000 ) - $AD_TIMESTAMP_OFFSET2;
}

sub __epoch_to_ad {
    my $self  = shift;
    my $epoch = shift;
    defined $epoch or croak "epoch seconds required";

    # convert unix time to windows time
    # thanks to http://quark.humbug.org.au/blog/?p=27

    return ( $epoch * 10000000 ) + $AD_TIMESTAMP_OFFSET;
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
