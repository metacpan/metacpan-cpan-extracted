package OpenInteract::SPOPS::DBI;

# $Id: DBI.pm,v 1.12 2002/01/02 02:43:53 lachoy Exp $

use strict;
use OpenInteract::SPOPS;
use SPOPS::ClassFactory qw( OK NOTIFY );

@OpenInteract::SPOPS::DBI::ISA     = qw( OpenInteract::SPOPS );
$OpenInteract::SPOPS::DBI::VERSION = sprintf("%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);

sub global_datasource_handle {
    my ( $self, $connect_key ) = @_;
    my $R = OpenInteract::Request->instance;
    $connect_key ||= $self->CONFIG->{datasource} ||
                     $R->CONFIG->{datasource}{default_connection_db};
    return $R->db( $connect_key );
}

sub global_db_handle { goto &global_datasource_handle }

sub connection_info {
    my ( $self, $connect_key ) = @_;
    my $R = OpenInteract::Request->instance;
    $connect_key ||= $self->CONFIG->{datasource} ||
                     $R->CONFIG->{datasource}{default_connection_db} ||
                     $R->CONFIG->{default_connection_db};
    $connect_key = $connect_key->[0] if ( ref $connect_key eq 'ARRAY' );
    return \%{ $self->CONFIG->{db_info}->{ $connect_key } };
}

########################################
# CLASS FACTORY BEHAVIOR
########################################

sub behavior_factory {
    my ( $class ) = @_;
    return { manipulate_configuration => \&discover_fields };
}

sub discover_fields {
    my ( $class ) = @_;
    my $CONFIG = $class->CONFIG;
    unless ( $CONFIG->{field_discover} and $CONFIG->{field_discover} eq 'yes' ) {
        return ( OK, undef );
    }

    my $dbh = $class->global_datasource_handle( $CONFIG->{datasource} );
    unless ( $dbh ) {
      return ( NOTIFY, "Cannot discover fields because no DBI database " .
                       "handle available to class ($class)" );
    }
    my $sql = $class->sql_fetch_types( $CONFIG->{base_table} );
    my ( $sth );
    eval {
        $sth = $dbh->prepare( $sql );
        $sth->execute;
    };
    return ( NOTIFY, "Cannot discover fields\n -> $sql\n -> $@" ) if ( $@ );
    $CONFIG->{field} = $sth->{NAME};
    return ( OK, undef );
}

1;

=pod

=head1 NAME

OpenInteract::SPOPS::DBI - Common SPOPS::DBI-specific methods for objects

=head1 SYNOPSIS

 # In configuration file
 'myobj' => {
    'isa'   => [ qw/ ... OpenInteract::SPOPS::DBI ... / ],

    # Yes, I want OI to find my fields for me.
    'field_discover' => 'yes',
 }

=head1 DESCRIPTION

This class provides common datasource access methods required by
L<SPOPS::DBI|SPOPS::DBI>.

=head1 METHODS

B<global_datasource_handle( [ $connect_key ] )>

Returns a DBI handle corresponding to the connection key
C<$connect_key>. If C<$connect_key> is not given, then the connection
key specified for the object class is used. If the object class does
not have a connection key (which is normal if you are using only one
database), we use the key specified in the server configuration file
in 'default_connection_db'.

B<global_db_handle( [ $connect_key ] )>

Alias for C<global_datasource_handle()> (kept for backward
compatibility).

B<connection_info( [ $connect_key ] )>

Returns a hashref of DBI connection information. If no C<$connect_key>
is given then we get the value of 'datasource' from the object
configuration, and if that is not defined we get the default
datasource from the server configuration.

See the server configuration file for documentation on what is in the
hashref.

=head2 SPOPS::ClassFactory Methods

You will never need to call the following methods from your object,
but you should be aware of them.

B<behavior_factory( $class )>

Creates the 'discover_fields' behavior (see below) in the
'manipulate_configuration' slot of the
L<SPOPS::ClassFactory|SPOPS::ClassFactory> process.

B<discover_fields( $class )>

If 'field_discover' is set to 'yes' in your class configuration, this
will find the fields in your database table and set the configuration
value 'field' as appropriate. Pragmatically, this means you do not
have to list your fields in your class configuration -- every time the
server starts up the class interrogates the table for its properties.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::DBI|SPOPS::DBI>

L<SPOPS::ClassFactory|SPOPS::ClassFactory>

L<SPOPS::Manual::CodeGeneration|SPOPS::Manual::CodeGeneration>

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut
