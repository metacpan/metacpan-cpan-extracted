package OpenPlugin::Datasource;

# $Id: Datasource.pm,v 1.20 2003/04/28 17:43:48 andreychek Exp $

use strict;
use base                  qw( OpenPlugin::Plugin );
use Data::Dumper          qw( Dumper );

$OpenPlugin::Datasource::VERSION = sprintf("%d.%02d", q$Revision: 1.20 $ =~ /(\d+)\.(\d+)/);

my %DS     = ();  # Holds a copy of all our datasource information/handles
my %LOADED = ();  # Holds a copy of all loaded datasource drivers

sub type { return 'datasource' }
sub OP   { return $_[0]->{_m}{OP} }

sub connect {
    my ( $self, $ds_name ) = @_;

    # There's nothing we can do if we weren't give a datasource to connect to
    unless ( $ds_name ) {
        $self->OP->exception->throw( "No datasource specified!");
    }

    $self->OP->log->info( "Trying to find datasource ($ds_name)" );

    # If we don't alreay have a datasource handle for this datasource, create
    # one
    unless ( $DS{ $ds_name } ) {

        $self->OP->log->info( "Datasource ($ds_name) not connected yet" );

        # Get info on this particular datasource from the config
        my $ds_info = $self->OP->config->{datasource}{ $ds_name };

        unless ( ref $ds_info eq 'HASH' ) {
            $self->OP->exception->throw
                ( "No information defined for datasource [$ds_name]" );
        }

        # A 'type' is something like 'DBI' or 'LDAP'
        unless ( $ds_info->{type} ) {
            $self->OP->exception->throw
                ( "Datasource ($ds_name) must have 'type' defined" );
        }

        my $mgr_class = $self->OP->get_plugin_class( "datasource",
                                                     $ds_info->{'type'} );

        $mgr_class =~ m/^([\w:]+)$/g;
        $mgr_class = $1;

        unless ( $mgr_class ) {
            $self->OP->exception->throw( "Specified datasource type ",
                                         "[$ds_info->{type}] for datasource ",
                                         "[$ds_name] does not map to a ",
                                         "known driver." );
        }

        # Checks to see if a given driver class is loaded -- for example,
        # OpenPlugin::Datasource::DBI or OpenPlugin::Datasource::LDAP
        unless ( $LOADED{ $mgr_class } ) {

            $self->OP->log->info( "Loading driver [$mgr_class]." );
            eval "require $mgr_class";

            if ( $@ ) {
                $self->OP->exception->throw( "Cannot load datasource ",
                                             "driver class: $@" );
            }

            $self->OP->log->info( "Driver [$mgr_class] loaded ok" );
            $LOADED{ $mgr_class }++;
        }

        my $item = eval { $mgr_class->connect( $self->OP, $ds_name,
                                               $ds_info ); };
        if ( $@ ) {
            $self->OP->exception->throw( $@ );
        }

        # Store the info for this particular datasource for future reference
        $DS{ $ds_name } = { manager    => $mgr_class,
                            connection => $item,
                            config     => $ds_info };
    }

    # Return the datasource handle
    return $DS{ $ds_name }->{'connection'};
}

sub disconnect {
    my ( $self, $ds_name ) = @_;

    unless ( $DS{ $ds_name } ) {
        $self->OP->exception->throw( "No datasource by name [$ds_name] ",
                                     "available" );
    }

    my $mgr_class = $DS{ $ds_name }->{'manager'};

    # Pass in am OpenPlugin object and the datasource handle to the driver
    return $mgr_class->disconnect( $self->OP, $DS{ $ds_name }->{connection} );
}

# Disconnect all datasources
sub shutdown {
    my ( $self ) = @_;
    foreach my $ds_name ( keys %DS ) {
        $self->disconnect( $ds_name );
    }
    return 1;
}

1;

__END__

=pod

=head1 NAME

OpenPlugin::Datasource - Datasource connection manager plugin

=head1 SYNOPSIS

 my $dbh  = $OP->datasource->connect( 'MyDataSourceName' );
 my $ldap = $OP->datasource->connect( 'LDAP_DataSourceName' );

 ...

 $OP->datasource->disconnect( 'MyDataSourceName' );

=head1 DESCRIPTION

This plugin provides a simple means of connecting to datasources such as DBI,
LDAP or any other type of connections needed. It caches the connections for
reuse throughout the lifetime of the application, although it contains no
behavior (yet) for keeping the connections alive.

=head1 METHODS

B<connect( $datasource_name, [ \%datasource_info ] )>

Returns a datasource mapping to C<$datasource_name>.  Datasources are defined
in the config file.

B<disconnect( $datasource_name )>

Disconnects datasource C<$datasource_name>.

B<shutdown()>

Disconnects all datasources.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

See the individual datasource drivers for details on configuration and usage.

L<OpenPlugin>, L<OpenPlugin::Datasource::DBI>, L<OpenPlugin::Datasource::LDAP>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
