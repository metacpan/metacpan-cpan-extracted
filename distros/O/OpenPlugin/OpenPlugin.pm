package OpenPlugin;

use strict;
use vars                qw( $AUTOLOAD );
use OpenPlugin::Plugin  qw();
use OpenPlugin::Utility qw();
use Log::Log4perl       qw( get_logger );

use constant STATE      => '_state';
use constant TOGGLE     => '_toggle';
use constant PLUGIN     => '_plugin';
use constant PLUGINCONF => '_pluginconf';
use constant INSTANCE   => '_instance';

$OpenPlugin::VERSION = '0.11';

# We'll need the logger var throughout this entire file
my $logger;

sub new {
    my $pkg    = shift;
    my $params = { @_ };
    my $class  = ref $pkg || $pkg;
    my $self   = bless( {}, $class );

    $self->init( $params->{'init'} );

    # Save all the parameters which were passed in
    $self->state("command_line", $params );

    # TODO: We should try and get all this config stuff into the Config plugin
    # if at all possible, I don't think it belongs here

    # Read configuration from file if given.  Otherwise, see if the package var
    # has our config in it
    $params->{'config'}{'src'} ||= $OpenPlugin::Config::Src;

    if ( $params->{'config'}{'src'} or $params->{'config'}{'data'} ) {

        $self->load_config( $params );

    }
    # Quit if we haven't been given some sort of config to use
    else {
        die "No configuration given!  You need to pass in the location ",
            "to your configuration file, or pass in a hashref containing ",
            "your configuration data.";
    }

    $self->register_plugins;

    return $self;
}

# Set up some stuff before we begin loading any plugins
sub init {
    my ( $self, $params ) = @_;

    my $log_conf = $params->{'log'} || q(
        log4perl.rootLogger              = WARN, stderr
        log4perl.appender.stderr         = Log::Dispatch::Screen
        log4perl.appender.stderr.layout  = org.apache.log4j.PatternLayout
        log4perl.appender.stderr.layout.ConversionPattern  = %C (%L) %m%n
    );

    Log::Log4perl::init( \$log_conf );
    $logger = get_logger("OpenPlugin");

}

########################################
# Public methods
########################################

# This gets and sets state information for user requests.  For instance, we can
# maintain the current user and group, whether the user is an administrator,
# etc.
sub state {
    my ( $self, $key, $value ) = @_;


    # Just a key passed in, return a single value
    if( defined $key and not defined $value ) {
        $logger->info("Calling state() with key [$key].");

        return $self->{ STATE() }{ $key };
    }

    # We have a key and value, so assign the value to the key
    elsif( defined $key and defined $value ) {
        $logger->info("Calling state() with key [$key] and value [$value].");

        return $self->{ STATE() }{ $key } = $value;
    }

    # No key or value, return the entire state hash
    else {
        $logger->info("Calling state() with no parameters.");

        return $self->{ STATE() };
    }
}


# Cleans up the current state in this object and sends a message to
# all plugins to cleanup their state as well.
sub cleanup {
    my ( $self ) = @_;

    $logger->info( "Running cleanup()" );

    # Allow plugins to clean up their own state
    foreach my $plugin ( $self->loaded_plugins ) {
        $self->$plugin()->cleanup;
    }

    # Completely erase all state related information
    $self->{ STATE() } = {};

    # FIXME: This might not be necessary anymore
    # Recreate a hash key for each plugin
    foreach my $plugin ( $self->loaded_plugins ) {
        $self->state( $plugin, {} );
    }

}

# This should be called before the object is taken out of scope and
# should probably incorporated into a DESTROY() method.

sub shutdown {
    my ( $self ) = @_;
    $logger->info( "Calling shutdown() from OP" );
    $self->cleanup();

    # ... do any additional cleanup so we don't have dangling/circular
    # references, etc....

}


########################################
# Accessor methods
########################################

# Get a list of all plugins which the config plugin knows about
sub get_plugins {
    my ( $self, $plugin ) = @_;

    if( $plugin ) {
        return sort keys %{ $self->config->{'plugin'}{ $plugin }{'plugin'} };
    }
    else {
        return sort keys %{ $self->config->{'plugin'} };
    }
}

# Get a list of all drivers for a given plugin
sub get_drivers {
    my ( $self, $plugin ) = @_;

    return sort keys %{ $self->{ PLUGINCONF() }{ $plugin }{'driver'} }
}

# Save any info that we have relating to a plugins configuration
sub set_plugin_info {
    my ( $self, $plugin, $nested_plugin ) = @_;

    # $plugin_info contains all the information about a given plugin that was
    # found in the configuration file
    my $plugin_info;
    if( $nested_plugin ) {
        $plugin_info =
            $self->config->{'plugin'}{ $plugin }{'plugin'}{ $nested_plugin };
        $plugin = $nested_plugin;
    }
    else {
        $plugin_info = $self->config->{'plugin'}{ $plugin };
    }

    # We definitely cannot load a plugin without a driver.  Warn and skip if
    # that is the case.
    unless ( ref $plugin_info eq 'HASH' and $plugin_info->{'driver'} ) {
        $logger->warn("Invalid driver listed for [$plugin]: ",
                      "[$plugin_info->{driver}]. Skipping." );

        return undef;
    }

    $logger->info( "Driver type found for [$plugin]: ",
                   "[$plugin_info->{driver}]" );

    # Store this configuration for whenever we need it
    return $self->{ PLUGINCONF() }{ $plugin } = $plugin_info;

}

# Retrieve config information listed about a given plugin
sub get_plugin_info {
    my ( $self, $plugin ) = @_;

    return $self->{ PLUGINCONF() }{ $plugin };
}

# Get the name of the class name to use for a given driver
sub get_plugin_class {
    my ( $self, $plugin, $driver ) = @_;

    return undef unless $driver;

    # Get the class name for the driver, as defined in the drivermap file
    my $plugin_class = $self->config->{'drivermap'}{ $plugin }{ $driver };

    $logger->info( "Plugin class found for [$plugin]: [$plugin_class]" );

    return $plugin_class;
}


# Retrieve a list of plugins which are currently loaded, return the value we
# received when we called it's load() function earlier
sub loaded_plugins {
    my $self = shift;

    # Return an empty list if no plugins are loaded
    unless ( ref $self->{ PLUGIN() } eq 'HASH' ) {
        return ();
    }

    return sort keys %{ $self->{ PLUGIN() } };
}

# Save the plugin instance (object) that we received by calling its new()
# function
sub set_plugin_instance {
    my ( $self, $plugin, $driver, $instance ) = @_;

    return $self->{ INSTANCE() }{ $plugin }{ $driver } = $instance;
}

# Set which driver will be used when one isn't explicitely given
sub set_default_driver {
    my ( $self, $plugin, $driver ) = @_;

    return $self->{ PLUGINCONF() }{ $plugin }{'default'} = $driver;
}

# Get the name of the default driver for a given plugin
sub get_default_driver {
    my ( $self, $plugin ) = @_;

    return $self->{ PLUGINCONF() }{ $plugin }{'default'};
}


########################################
# Plugin Instanciation
########################################

# TODO: I'd like all these functions to be able to handle plugins defined in
# the config file to be nested at an arbitrary depth.  They currently can only
# be two levels deep.

# Get a list of plugins, and register them
sub register_plugins {
    my $self = shift;

    foreach my $plugin ( $self->get_plugins ) {
        $self->set_plugin_info( $plugin );

        $self->register_plugin( $plugin );
    }

}

# Decide how and when to load a plugin
sub register_plugin {
    my ( $self, $plugin ) = @_;

    my @drivers        = $self->get_drivers( $plugin );
    my $driver_count   = scalar @drivers;
    my $default_driver = $self->get_default_driver( $plugin );

    foreach my $driver ( @drivers ) {

        if( $driver_count == 1 and not defined $default_driver ) {
            $self->set_default_driver( $plugin, $driver );
        }

        my $class_identifier = $plugin . "-" . $driver;
        my $class = $self->get_plugin_class( $plugin, $driver );

        # These plugins have a "load" time of "Startup", meaning they are
        # loaded when the main OpenPlugin module is
        if( $self->get_plugin_info( $plugin )->{'load'} eq "Startup" ) {

            unless( grep m/^$class$/,
                        OpenPlugin::Plugin->get_loaded_classes ) {

                # Tell OpenPlugin::Plugin that we have a new class that we
                # wish to load now
                OpenPlugin::Plugin->add_factory_type(
                    $class_identifier => $class );
            }

            $self->init_plugin( $plugin, $driver );
        }

        # These plugins have a "load" time of "Auto", meaning they are
        # loaded on demand.  If they aren't ever used, they'll never be
        # loaded
        elsif ( $self->get_plugin_info( $plugin )->{'load'} eq "Auto" ) {

            unless( grep m/^$class$/,
                        OpenPlugin::Plugin->get_registered_classes ) {

                # Tell OpenPlugin::Plugin about a class, so it can load it
                # if and when we finally decide to use it
                OpenPlugin::Plugin->register_factory_type(
                   $class_identifier => $self->get_plugin_class( $plugin,
                                                                 $driver ));

            }
        }

        # We need to know how to load a plugin, it doesn't seem appropriate
        # to guess.  If the configuration isn't correct, give a warning
        # message, but skip loading it.
        else {
            $logger->warn("Invalid load time listed for [$plugin]: [",
                          $self->{ PLUGINCONF() }{ $plugin }{'load'},
                          "]. Skipping." );
        }
    }

    # Handle plugins defined within other plugins
    foreach my $nested_plugin ( $self->get_plugins( $plugin )) {
        $self->set_plugin_info( $plugin, $nested_plugin );

        $self->register_plugin( $nested_plugin );
    }

}

# Make a plugin available to programs using us
sub init_plugin {
    my ( $self, $plugin, $driver ) = @_;

    unless( $plugin ) {
        $self->exception->throw( "You must call init_plugin() with a ",
                                 "plugin name!" );
    }

    unless( $self->get_plugin_info( $plugin )) {
        $self->exception->throw( "You attemped to call [$plugin], which is ",
                                 "not a valid plugin!" );
    }

    # No driver name is okay, we'll just use the default
    $driver ||= $self->get_default_driver( $plugin );

    # Create and save an instance for this driver
    my $instance = $self->create_plugin_instance( $plugin, $driver );
    $self->set_plugin_instance( $plugin, $driver, $instance );

    $self->generate_plugin_method_call( $plugin );

    $self->{ PLUGIN() }{ $plugin } = $self->$plugin( $driver )->load();
}

# Create a new instance of a plugin
sub create_plugin_instance {
    my ( $self, $plugin, $driver ) = @_;

    my $class_identifier = $plugin . "-" . $driver;

    return OpenPlugin::Plugin->new( $class_identifier, $self,
                                    $self->state->{'command_line'}{ $plugin });
}

# Build a method call for a given plugin
sub generate_plugin_method_call {
    my ( $self, $plugin ) = @_;

    # Create the new method in the current package's namespace
    my $method = __PACKAGE__ . '::' . $plugin;
    no strict 'refs';

    # Don't redefine existing method names.  This will both save us time, and
    # is more secure.
    unless ( defined &{ $method } ) {

        $logger->info("Generating method [$method]");

        *{ $method } =
            sub {
                my ( $self, $driver ) = @_;
                $driver ||= $self->get_default_driver( $plugin );

                unless( $driver ) {
                    $self->exception->throw( "No driver found for [$plugin].",
                                             "If you have multiple drivers ",
                                             "defined, you must assign one ",
                                             "as the default." );
                }

                # If there is already an instance for this particular driver,
                # return it
                if( $self->{ INSTANCE() }{ $plugin }{ $driver } ) {
                    return $self->{ INSTANCE() }{ $plugin }{ $driver };
                }

                # If there isn't yet an instance (typical when the plugin isn't
                # loaded at startup), create one and return it
                else {
                    my $instance = $self->create_plugin_instance( $plugin,
                                                                  $driver );

                    return $self->set_plugin_instance( $plugin, $driver,
                                                       $instance );
                }
            }
    }
}


########################################
# AUTOLOAD
#   (so great it gets its own section!)
########################################

sub AUTOLOAD {
    my ( $self, $driver ) = @_;
    my $request = $AUTOLOAD;

    $request =~ s/.*://;

    $logger->info( "Autoload request: [$request]\n" );
    $self->init_plugin( $request, $driver );
    $self->$request( $driver );
}


# Lets not go looking for DESTROY via AUTOLOAD
sub DESTROY { }


########################################
# CONFIGURATION
########################################

# Configuration is different from other plugins because of the bootstrapping
# issue.
sub load_config {
    my ( $self, $params ) = @_;

    unless( grep m/^OpenPlugin::Config$/,
                OpenPlugin::Plugin->get_loaded_classes ) {

            OpenPlugin::Plugin->add_factory_type(
                            "config" => 'OpenPlugin::Config' );
    }

    my $config = OpenPlugin::Plugin->new( 'config', $self,
                                          $params->{'config'} );

    if( $params->{'config'}{'src'} ) {
        $self->set_plugin_instance( "config", 'built-in', $config->read );
    }
    elsif( $params->{'config'}{'data'} ) {
        $self->set_plugin_instance( "config", 'built-in',
                                 $config->read( $params->{'config'}{'data'} ));
    }

    $self->generate_plugin_method_call( "config" );
    $self->set_default_driver( "config", "built-in" );

    if( $params->{'config'}{'data'} and $params->{'config'}{'src'} ) {
        $self->config->read( $params->{'config'}{'data'} );
    }

}



1;

__END__

=head1 NAME

OpenPlugin - Plugin manager for web applications

=head1 SYNOPSIS

  use OpenPlugin();
  my $r = shift;

  my $OP = OpenPlugin->new( config  => { src    => '/etc/myconf.conf' },
                            request => { apache => $r } );

  my $is_authenticated = $OP->authenticate->authenticate({ username => 'badguy',
                                                           password => 'scylla' });
  unless ( $is_authenticated ) {
      $OP->exception->throw( "Login incorrect!" );
  }

  my $session_id = $OP->param->get_incoming('session_id');
  $session = $OP->session->fetch( $session_id );

  $session->{'hair'} = $OP->param->get_incoming('hair');
  $session->{'eyes'} = $OP->param->get_incoming('eyes');
  $OP->session->save( $session );

  $OP->httpheader->send_outgoing();
  print "You have $session->{'hair'} hair and $session->{'eyes'} eyes<br>";

=head1 DESCRIPTION

OpenPlugin is an architecture which manages plugins for web applications.  It
allows you to incorporate any number of plugins and drivers into your web
application.  For example, the Log plugin has drivers for logging to STDERR,
Files, Syslog, Email, and so on.  The Session plugin has drivers for storing
sessions in Files, Databases, and the like.  Changing drivers is easy, you just
change the driver name in a config file.

OpenPlugin even has plugins for Params, Cookies, HttpHeaders, and Uploads.
Each of these plugins have an Apache and CGI driver.  These plugins abstract
Apache::Request and CGI.pm, allowing you to build applications that can work
seamlessly under mod_perl or CGI. If you want to move your application from one
environment to another, you again can just change the driver being used in the
config file.

Also in this config file, you can define whether a plugin loads at startup
time, or only on demand.

OpenPlugin is designed to be able to handle any number of plugins.  Likewise,
plugins can have any number of drivers which can manipulate how the plugin
functions, or where it can find it's data.

=head1 BACKGROUND

Currently, there are a number of web application frameworks available.
And while each one is unique, there is a certain amount of functionality that
each shares.  Often, that functionality is built in to the particular
framework, instead of being a seperate component.  This means the shared
functionality will only benefit from the developers of that one project.  Also,
if you ever switch frameworks, you may end up with a lot of code that will no
longer work.

OpenPlugin offers this functionality that is common between frameworks, but it
is designed to be a reusable component.  OpenPlugin can be used within any
framework or standalone web application.  This gives OpenPlugin a unique
advantage of being able to grow beyond the abilities of any one developer, and
beyond the scope of any one framework.

OpenPlugin has developed into a powerful architecture allowing for extensible
applications.

=head1 USAGE

There is documentation in the Plugin and Driver files offering specific details
on all of it's capabilities.  The following is a general overview of how to
make use of OpenPlugin.

To use OpenPlugin in your application, first thing you'll do is create a new
OpenPlugin object:

 my $OP = OpenPlugin->new( config => { src => /path/to/OpenPlugin.conf } );

OpenPlugin offers a number of plugins and drivers.  To make use of any of
these, you will use a syntax like:

 $OP->plugin->method();

Some people would rather see:

 $OP->plugin()->method();

It's up to you which to use, they both work.  For the examples in this
document, I'll tend to use the first example.

So, to retrieve a saved session:

 my $session = $OP->session->fetch( $session_id );

To send an outgoing HTTP header:

 $OP->httpheader->send_outgoing();

Or to authenticate a user:

 my $login = $OP->authenticate->authenticate( 'username', 'password' );

The above syntax assumes that OpenPlugin has some knowledge about what it is
we're trying to do.  That is, when we attempt to retrieve a session, we never
said where to fetch it from, we only told it what session_id we were looking
for.  And when we authenticate a user, we didn't specify where we are to find
the usernames.

This is where the config file comes in.  The config file defines all the
information about our plugins, and what driver they are to use.  Here is an
example of how the configuration for the Session plugin might look:

 <plugin session>
     load        = Startup
     expires     = +3h

     <driver ApacheSession>
         Store           = File
         Directory       = /tmp/openplugin
         LockDirectory   = /tmp/openplugin
     </driver>
 </plugin>

This example defines several things for our Session plugin.

First, it tells the plugin to load at the same time OpenPlugin does (startup
time).  This is particularly useful when running under mod_perl, where you can
have OpenPlugin, along with any number of plugins, load at the same time Apache
does.  You'll find this to be a significant speed increase since Apache is
happy to keep these modules compiled and cached within it's memory.

Secondly, we tell Session that it should expire sessions that have been
innactive for 3 hours.

Third, we define a driver.  We use the ApacheSession driver in this case, and
then define a few parameters that this driver needs.  We'll store our sessions
in files, and those files will be kept in /tmp/openplugin.

So, when we look at our example again:

 my $session = $OP->session->fetch( $session_id );

It makes a bit more sense.  The Session plugin has been configured to store
sessions in files.  We also said that it needs to look in the /tmp/openplugin
directory for the session_id that we passed it.  Cool!

With sessions, having one driver typically works great.  There usually isn't a
need to store sessions in more than one place.  But what about a plugin like
Authenticate?  Different applications may desire to keep their usernames in a
variety of places.  What if one application needs to authenticate users with a
Windows NT Server, and another wants to use a UNIX password file?  To
accomplish this, you can define two drivers:

 <plugin authenticate>
     load       = Startup
     default    = Passwd

     <driver Passwd>
     </driver>

     <driver SMB>
        pdc     = My_NT_Server
        bdc     = My_Backup_Server
        domain  = NT_DOMAIN
     </driver>

 </plugin>

You already know the C<load> parameter, which is telling Authenticate to load
whenever OpenPlugin does.

We define two drivers this time, Passwd and SMB (SMB is the protocol Windows NT
uses).  When using more than one driver, you should tell OpenPlugin which one
is your default driver.  As you can see above, this example sets Passwd as the
default with the statement C<default = Password>.

Having a default driver means that when we say:

 my $login = $OP->authenticate->authenticate( 'username', 'password' );

The authentication is takes place using the UNIX password file, the default.

To authenticate using the SMB driver, we simply would use:

 my $login = $OP->authenticate('SMB')->authenticate( 'username', 'password' );

While the available drivers for each plugin differs, the above syntax remains
the same when you want to use multiple drivers.  So, if you wanted to be able
to cache data in two different places (which of course, uses two different
drivers):

 # Cache to the default location
 $OP->cache->save( $data_to_cache );

 # Cache to a DBI compatible database
 $OP->cache('DBI')->save( $data_to_cache );

=head1 BUILDING YOUR APPLICATION

As you've begun to see, OpenPlugin makes a lot of functionality available to
you.  If you are not already using an application framework that helps you
organize all of your code, I'd like to recommend that you use the
<Application|OpenPlugin::Application> plugin.  With all the functionality
you'll have at your fingertips, the Application plugin will help keep your
code neat and organized.

The Application plugin (also known as OpenPlugin::Application) is a subclass
of L<CGI::Application>.  It provides the same functionality as CGI::Application,
except that you use OpenPlugin instead of CGI.pm.  Even though it's a subclass
of CGI::Application, CGI.pm will B<not> be loaded.  Unless, of course, you are
using the CGI driver in OpenPlugin.

OpenPlugin::Application works under the philosophy that web applications can be
organized into a series of "run modes".  A run mode is typically a single
screen of information.  OpenPlugin::Application uses this to help you better
organize your code, so it's both easier to maintain, and easier to reuse.

While use of this plugin is optional, I find it highly useful, and I definitely
recommend it's use.  See the documentation for L<OpenPlugin::Application> for
more information.

=head1 FUNCTIONS

While the main OpenPlugin class does provide some publicaly available
functions, you'll find the majority of OpenPlugin's funcionality in it's
plugins.

=over 4

=item B<new( %params )>

You can pass a number of parameters into the B<new()> method.  Each of those
parameters can effect how a given plugin, or OpenPlugin as a whole, functions.

The parameters in %params will be available to each plugin as they are
loaded.

The syntax for the %params hash is:

 %params = qw(
    plugin_name  => { plugin_param => plugin_value },
    other_plugin => { plugin_param => plugin_value },
 );

For example:

 %params = qw(
    config  => { src    => /path/to/OpenPlugin.conf },
    request => { apache => $r },
 );

There is a special parameter called C<init>.  There are certain settings which
are in place until a particular plugins are loaded.  Lets call that
bootstrapping.

You can override these bootstrapping defaults by passing in values to C<new>
using the init parameter.  The biggest example is logging.  The following is
the default setup for logging:

        log4perl.rootLogger              = WARN, stderr
        log4perl.appender.stderr         = Log::Dispatch::Screen
        log4perl.appender.stderr.layout  = org.apache.log4j.PatternLayout
        log4perl.appender.stderr.layout.ConversionPattern  = %C (%L) %m%n

You can learn what that all means by reading the L<Log::Log4perl|Log::Log4perl>
documentation.  But if there's something in that default that you don't like,
you may pass in values to override it.  Lets say that the default logging level
of C<WARN> that it establishes doesn't provide enough information during your
debugging session.  You can override it like so:

 my $log_info = q(
        log4perl.rootLogger              = INFO, stderr
        log4perl.appender.stderr         = Log::Dispatch::Screen
        log4perl.appender.stderr.layout  = org.apache.log4j.PatternLayout
        log4perl.appender.stderr.layout.ConversionPattern  = %C (%L) %m%n
 );

 my $OP = OpenPlugin->new( init   => { log => $log_info },
                           config => { src => "/path/to/config" },

 );

The C<new> function returns an OpenPlugin object.


=item B<state( [ key ], [ value ] )>

This function is for storing and retrieving state information.  This
information is destroyed when the script exits (see the
L<Session|OpenPlugin::Session> and L<Cache|OpenPlugin::Cache> plugins
for storing information across requests).

This returns the full state hash if passed no parameters, a value if passed one
parameter (a key), or sets a key equal to a given value if sent two parameters.

=item B<cleanup()>

This function tells the main OpenPlugin module, and all of it's plugins, to
perform a "cleanup".

=back

=head1 PLUGINS

The API for individual plugins is available by looking at that particular
plugin's documentation.  The following plugins are available:

=over 4

=item * L<Application|OpenPlugin::Application>

=item * L<Authentication|OpenPlugin::Authentication>

=item * L<Cache|OpenPlugin::Cache>

=item * L<Config|OpenPlugin::Config>

=item * L<Cookie|OpenPlugin::Cookie>

=item * L<Datasource|OpenPlugin::Datasource>

=item * L<Exception|OpenPlugin::Exception>

=item * L<Httpheader|OpenPlugin::Httpheader>

=item * L<Log|OpenPlugin::Log>

=item * L<Param|OpenPlugin::Param>

=item * L<Session|OpenPlugin::Session>

=item * L<Upload|OpenPlugin::Upload>

=back

=head1 DOCUMENTATION

Many of these plugins accept parameters passed into OpenPlugin's B<new()>
constructor, and a few even require it.  You can obtain a list of what
parameters a plugin recognizes by reading the documentation for the plugin and
driver which you are using.  Generally speaking, the documentation for a plugin
shows how to program it's interface, and the documentation for the driver shows
how to configure it, along with what parameters you can pass into it.  The
following sections explain what you can expect to find when reading the
documentation for plugins and drivers.

=head2 PLUGINS

Each plugin contains documenation on how to use it.  It will contain, at a
minimum, the following sections:

=over 4

=item * SYNOPSIS

A brief usage example.

=item * DESCRIPTION

A general description of the module, perhaps containing more examples.

=item * METHODS

The methods you would use to interact with that particular plugin.

=back

=head2 DRIVERS

Each driver also contains documentation, describing how you configure or use
it.  At a minimum, each driver will contain the following sections:

=over 4

=item * PARAMETERS

Parameters describe information which you would pass in when you instanciate a
new OpenPlugin object.  Take the following illustration:

 my $OP = OpenPlugin->new( config => { src => "/path/to/OpenPlugin.conf" } );

In this example, we can see that the C<src> parameter is being passed in as a
parameter to the C<config> plugin.  These are the sorts of things you can
expect to find in the parameters section of any given driver.

=item * CONFIG OPTIONS

This describes options that you can put in the config file for a given driver.

=head1 TO DO

OpenPlugin is currently being used in every day production at my workplace.
Applications are being based off of it, and they are working great.  The
OpenThought Application Environment also makes use of it quite successfully.

That being said, OpenPlugin is still under heavy development.  There are a lot
of things to do.

I consider this alpha software.  It by all means has bugs.  Parts of the API
may change.  It's also been known to cause your significant other to think you
spend too much time on the computer.  Your milage may vary.

The API is not complete.  See the TO DO list for the individual plugins to see
a few of the ideas that I've written down.  Additionally, in order for this to
be useful for many people, more drivers need to be created to handle the wide
variety of environments OpenPlugin may find itself in.

We also need to create a bunch more documentation, examples, etc.

There is also a need for many more tests.

If you have any further suggestions, I would definitely like to hear them.  If
you have any patches, I like those too :-)

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=head1 CONTRIBUTORS

Chris Winters initially helped get things rolling.  OpenPlugin also makes use
of his L<Class::Factory> module, and I occasionally borrow code and ideas from
L<OpenInteract> and L<SPOPS>.  Thanks Chris!

=head1 SEE ALSO

Web applications which make use of OpenPlugin:

=over 4

=item * L<OpenThought|OpenThought>

=back

=cut
