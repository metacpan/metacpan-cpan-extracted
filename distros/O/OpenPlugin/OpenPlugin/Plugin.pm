package OpenPlugin::Plugin;

# $Id: Plugin.pm,v 1.22 2003/04/28 17:43:48 andreychek Exp $

use strict;
use Class::Factory  0.04 qw();
use base                 qw( Class::Factory );
use Log::Log4perl        qw( get_logger );

use constant STATE  => '_state';

$OpenPlugin::Plugin::VERSION = sprintf("%d.%02d", q$Revision: 1.22 $ =~ /(\d+)\.(\d+)/);

my $logger = get_logger();

sub load {
    my $self = shift;
    my $class = ref $self;
    $logger->info( "Calling default method load() for ($class)" );
    return $class;
}

sub OP {
    my $self = shift;
    my $class = ref $self;

    $self->{_m}{OP}->exception->throw("In ($class): OP() must be implemented in plugin");
}

# Constructor for all plugins
sub new {
    my ( $pkg, $type, $OP, @params ) = @_;
    my $class = $pkg->get_factory_class( $type );
    my $self = bless( { _m => { OP => $OP } }, $class );
    $self->OP->state( $class, {} );
    return $self->init( @params );
}

# Retrieve state information for whatever plugin is calling us
sub state {
    my ( $self, $key, $value ) = @_;

    my $plugin = ref $self;

    #$plugin =~ m/OpenPlugin::(\w+)/;
    #$plugin = $1;

    # Just a key passed in, return a single value
    if( defined $key and not defined $value ) {
        $logger->info("Calling state() for [$plugin] with key [$key].");

        return $self->OP->state->{ $plugin }{ $key };
    }

    # We have a key and value, so assign the value to the key
    elsif( defined $key and defined $value ) {
        $logger->info("Calling state() for [$plugin] with key [$key] and ",
                      "value [$value].");

        return $self->OP->state->{ $plugin }{ $key } = $value;
    }

    # No key or value, return the entire state hash
    else {
        $logger->info("Calling state() for [$plugin] with no parameters.");

        return $self->OP->state->{ $plugin };
    }

}

sub cleanup  {
    my ( $self ) = @_;

    my $plugin = ref $self || $self;
    #$plugin =~ m/OpenPlugin::(\w+)/;
    #$plugin = $1;

    return $self->OP->state->{ $plugin } = {};
}

sub shutdown { return 1 }

1;

__END__

=pod

=head1 NAME

OpenPlugin::Plugin - Base class for all plugins

=head1 SYNOPSIS

 use OpenPlugin::Plugin;

 @MyPlugin::Config::ISA = qw( OpenPlugin::Plugin );

 # or

 use base qw( OpenPlugin::Plugin );

=head1 DESCRIPTION

This class is a base class for all plugins, and provides a series of methods
which can all be overloaded by the individual plugins or drivers.

=head1 METHODS

B<init()>

This method is called whenever a plugin is loaded for the first time, and can
be used to initiate settings, objects, and any other resources that a plugin
may need.

B<load()>

Returns the class name for a given plugin (OpenPlugin::PluginName).

B<new()>

Constructor for plugins.  Returns an object for a given plugin.

B<type()>

This method must be implemented within each plugin.  It returns the name of the
plugin.

B<OP()>

This method must be implemented within each plugin.  It simply returns the
'root' OpenPlugin object.

For example, within the Log plugin, $self is-a OpenPlugin::Plugin object, but
not a OpenPlugin.  To access methods of the main OpenPlugin class or other
plugins, from within the Log plugin, you would use:

 $self->OP->method_name();

 or to access another plugin from within any given plugin:

 $self->OP->plugin_name->plugin_method();

B<state()>

This method is used to save and retrieve state information in a namespace just
for the plugin using this function.

B<cleanup()>

This method is used to tell the plugin that the application is exiting, and to
clean up any information it may have sitting around.  At the very least, this
consists of it's state information.

B<shutdown()>

This method is used to tell the plugin to shutdown.  This would include things
like closing database connections and such.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<OpenPlugin>

L<Class::Factory>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
