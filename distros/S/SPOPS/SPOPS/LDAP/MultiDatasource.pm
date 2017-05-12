package SPOPS::LDAP::MultiDatasource;

# $Id: MultiDatasource.pm,v 3.3 2004/06/02 00:48:23 lachoy Exp $

use strict;
use base qw( SPOPS::LDAP );
use Log::Log4perl qw( get_logger );

use SPOPS;
use SPOPS::Exception::LDAP;

$SPOPS::LDAP::MultiDatasource::VERSION = sprintf("%d.%02d", q$Revision: 3.3 $ =~ /(\d+)\.(\d+)/);

use constant DEFAULT_CONNECT_KEY => 'main';

my $log = get_logger();

sub base_dn  {
    my ( $class, $connect_key ) = @_;
    my $partial_dn = $class->get_partial_dn( $connect_key );
    unless ( $partial_dn ) {
        SPOPS::Exception->throw( "No Base DN defined in configuration key 'ldap_base_dn'" );
    }
    my $connect_info = $class->connection_info( $connect_key );
    return join( ',', $partial_dn, $connect_info->{base_dn} );
}

# Retrieves the 'partial dn', or the section that's prepended to the
# server's 'base DN' to identify the branch on which these objects
# live

sub get_partial_dn {
    my ( $class, $connect_key ) = @_;
    my $base_dn_info = $class->CONFIG->{ldap_base_dn};
    return $base_dn_info unless ( ref $base_dn_info eq 'HASH' );
    $connect_key ||= $class->get_connect_key;
    return $base_dn_info->{ $connect_key };
}


sub get_connect_key {
    my ( $class ) = @_;
    return $class->CONFIG->{default_datasource} || DEFAULT_CONNECT_KEY;
}


sub fetch {
    my ( $class, $id, $p ) = @_;

    # If passed in a handle, we will always use only that

    if ( $p->{ldap} ) {
        return $class->SUPER::fetch( $id, $p );
    }

    my @ds_list = $class->_get_datasource_list( 'fetch', $id, $p );

    # Step through the datasource listing and try to retrieve each one
    # in turn

    foreach my $ds ( @ds_list ) {
        $log->is_info &&
            $log->info( "(fetch) Trying to use datasource ($ds) for class ($class)" );
        $p->{connect_key} = $ds;
        my $object = eval { $class->SUPER::fetch( $id, $p ) };
        if ( $object ) {
            $object->{_datasource} = $ds;
            return $object;
        }
    }
    return undef;
}


sub fetch_by_dn {
    my ( $class, $dn, $p ) = @_;
    if ( $p->{ldap} ) {
        return $class->SUPER::fetch_by_dn( $dn, $p );
    }
    my @ds_list = $class->_get_datasource_list( 'fetch_by_dn', $dn, $p );

    # Step through the datasource listing and try to retrieve each one
    # in turn

    foreach my $ds ( @ds_list ) {
        $log->is_info &&
            $log->info( "(fetch_by_dn) Trying to use datasource ($ds) for class ($class)" );
        $p->{connect_key} = $ds;
        my $object = eval { $class->SUPER::fetch_by_dn( $dn, $p ) };
        if ( $object ) {
            $object->{_datasource} = $ds;
            return $object
        }
    }
}

sub fetch_group_all {
    my ( $class, $p ) = @_;

    if ( $p->{ldap} ) {
        return $class->SUPER::fetch_group( $p );
    }
    my @ds_list = $class->_get_datasource_list( 'fetch_group', $p );
    my @all_objects = ();
    foreach my $ds ( @ds_list ) {
        $p->{connect_key} = $ds;
        $log->is_info &&
            $log->info( "Trying to fetch from datasource ($ds)" );
        my $object_list = $class->SUPER::fetch_group( $p );
        if ( $object_list and ref $object_list eq 'ARRAY' ) {
            foreach my $object ( @{ $object_list } ) {
                $object->{_datasource} = $ds;
                push @all_objects, $object;
            }
        }
    }
    return \@all_objects;
}


# Just be sure we grab the right LDAP handle before saving or removing
# -- if people pass in a handle, we'll defer to their judgement that
# they know what they're doing

sub save {
    my ( $self, $p ) = @_;
    $p->{ldap} ||= $self->global_datasource_handle( $self->{_datasource} );
    return $self->SUPER::save( $p );
}


sub remove {
    my ( $self, $p ) = @_;
    $p->{ldap} ||= $self->global_datasource_handle( $self->{_datasource} );
    return $self->SUPER::remove( $p );
}


# Retrieve a datasource list from the class configuration. If it
# doesn't work (no list or the list is empty), run a specified method
# in the parent class.

sub _get_datasource_list {
    my ( $class, $method, @args ) = @_;
    my $ds_list = $class->CONFIG->{datasource};

    # If there are not multiple datasources specified, then bounce
    # back to the SPOPS::LDAP-version of th method we were trying to
    # call in the first place.

    unless ( ref $ds_list eq 'ARRAY' and scalar @{ $ds_list } ) {
        $log->is_info &&
            $log->info( "No datasources in configuration for ($class).",
                        "Using SPOPS::LDAP->$method()" );
        my $full_method = "SUPER::$method";
        return $class->$full_method( @args );
    }
    return @{ $ds_list };
}

1;

__END__

=pod

=head1 NAME

SPOPS::LDAP::MultiDatasource -- SPOPS::LDAP functionality but fetching objects from multiple datasources

=head1 SYNOPSIS

 # In your configuration
 my $config = {
    class      => 'My::LDAPThings',
    datasource => [ 'main', 'secondary', 'tertiary' ],
    isa        => [ ... 'SPOPS::LDAP::MultiDatasource' ],
    ...,
 };

 # Fetch an object and see where it came from

 my $object = My::LDAPThings->fetch( 'superuser' );
 print "My DN is ", $object->dn, " and I came from $object->{_datasource}";

=head1 DESCRIPTION

This class extends L<SPOPS::LDAP|SPOPS::LDAP> with one purpose: be
able to fetch objects from multiple datasources. This can happen when
you have got objects dispersed among multiple directories -- for
instance, your 'Accounting' department is on one LDAP server and your
'Development' department on another. One class can (more or less --
see below) link the two LDAP servers.

Every object is tagged with the datasource it came from (in the
C<_datasource> property, if you ever need it), and any calls to
C<save()> or C<remove()> will use this datasource to retrieve the
proper connection for the object.

=head2 Caveats

The C<fetch()> method is the only functional method overridden from
L<SPOPS::LDAP|SPOPS::LDAP>. The C<fetch_group()> or
C<fetch_iterator()> methods will only use the first datasource in the
listing, whatever datasource you pass in with the parameter
'connect_key' or whatever LDAP connection handle you pass in with the
parameter 'ldap'. If you want to retrieve objects from multiple
datasources using the same filter, use the C<fetch_group_all()>
method.

The C<fetch_iterator()> method is not supported at all for multiple
datasources -- use C<fetch_group_all()> in conjunction with
L<SPOPS::Iterator::WrapList|SPOPS::Iterator::WrapList> if your
implementation expects an L<SPOPS::Iterator|SPOPS::Iterator> object.

=head1 SETUP

There are a number of items to configure and setup to use this
class. Please see
L<SPOPS::Manual::Configuration|SPOPS::Manual::Configuration> for the
configuration keys used by this module.

=head2 Methods You Must Implement

B<connection_info( $connect_key )>

This method should look at the C<$connect_key> and return a hashref of
information used to connect to the LDAP directory. Keys (hopefully
self-explanatory) should be:

=over 4

=item *

B<host> ($)

=item *

B<base_dn> ($)

=back

Other keys are optional and can be used in conjunction with a
connection/resource manager (example below).

=over 4

=item *

B<port> ($) (optional, default is '389')

=item *

B<bind_dn> ($) (optional, will use anonymous bind without)

=item *

B<bind_password> ($) (optional, only used if 'bind_dn' specified)

=back

For example:

 package My::ConnectionManage;

 use strict;

 my $connections = {
    main        => { host => 'localhost',
                     base_dn => 'dc=MyCompanyEast,dc=com' },
    accounting  => { host => 'accounting.mycompany.com',
                     base_dn => 'dc=MyCompanyWest,dc=com' },
    development => { host => 'dev.mycompany.com',
                     base_dn => 'dc=MyCompanyNorth,dc=com' },
    etc         => { host => 'etc.mycompany.com',
                     base_dn => 'dc=MyCompanyBranch,dc=com' },
 };

 sub connection_info {
     my ( $class, $connect_key ) = @_;
     return \%{ $connections->{ $connect_key } };
 }

Then put this class into the 'isa' for your SPOPS class:

 my $spops = {
   class      => 'My::Person',
   isa        => [ 'My::ConnectionManage', 'SPOPS::LDAP::MultiDatasource' ],
 };


B<global_datasource_handle( $connect_key )>

You will need an implementation that deals with multiple
configurations. For example:

 package My::DSManage;

 use strict;
 use Net::LDAP;

 my %DS = ();

 sub global_datasource_handle {
     my ( $class, $connect_key ) = @_;
     unless ( $connect_key ) {
         SPOPS::Exception->throw( "Cannot retrieve handle without connect key" );
     }
     unless ( $DS{ $connect_key } ) {
         my $ldap_info = $class->connection_info( $connect_key );
         $ldap_info->{port} ||= 389;
         my $ldap = Net::LDAP->new( $ldap_info->{host},
                                    port => $ldap_info->{port} );
         unless ( $ldap ) {
             SPOPS::Exception->throw( "Cannot create LDAP connection: $@" );
         }
         my ( %bind_params );
         if ( $ldap_info->{bind_dn} ) {
             $bind_params{dn}       = $ldap_info->{bind_dn};
             $bind_params{password} = $ldap_info->{bind_password};
         }
         my $bind_msg = $ldap->bind( %bind_params );
         if ( $bind_msg->code ) {
             SPOPS::Exception::LDAP->throw( "Cannot bind to directory: " . $bind_msg->error,
                                            { code   => $bind_msg->code,
                                              action => 'global_datasource_handle' } );
         $DS{ $connect_key } = $ldap;
     }
     return $DS{ $connect_key };
 }

Then put this class into the 'isa' for your SPOPS class:

 my $spops = {
   class      => 'My::Person',
   isa        => [ 'My::DSManage', 'SPOPS::LDAP::MultiDatasource' ],
 };

Someone with a thinking cap on might put the previous two items in the
same class :-)

=head1 METHODS

B<fetch( $id, \%params )>

Given the normal parameters for C<fetch()>, tries to retrieve an
object matching either the C<$id> or the 'filter' specified in
C<\%params> from one of the datasources. When it finds an object it is
immediately returned.

If you pass in the key 'ldap' in \%params, this functions as the
C<fetch()> does in L<SPOPS::LDAP|SPOPS::LDAP> and multiple datasources are not
used.

Returns: SPOPS object (if found), or undef.

B<fetch_group_all( \%params )>

Given the normal parameters for C<fetch_group()>, retrieves B<all>
objects matching the parameters from B<all> datasources. Use with
caution.

Returns: Arrayref of SPOPS objects.

B<save( \%params )>

Just pass along the right handle to the actual C<save()> method in
L<SPOPS::LDAP|SPOPS::LDAP>.

B<remove( \%params )>

Just pass along the right handle to the actual C<remove()> method in
L<SPOPS::LDAP|SPOPS::LDAP>.

B<base_dn( $connect_key )>

Returns the B<full> base DN associated with C<$connect_key>.

B<get_partial_dn( $connect_key )>

Retrieves the B<partial> base DN associated with C<$connect_key>.

B<get_connect_key()>

If called, returns either the value of the config key
'default_datasource' or the value of the class constant
'DEFAULT_CONNECT_KEY', which is normally 'main'.

=head1 BUGS

None known.

=head1 TO DO

Test some more.

=head1 SEE ALSO

L<SPOPS::LDAP|SPOPS::LDAP>

Example in SPOPS distribution: eg/ldap_multidatasource.pl

=head1 COPYRIGHT

Copyright (c) 2001-2004 MSN Marketing Service Nordwest, GmbH. All rights
reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

=cut
