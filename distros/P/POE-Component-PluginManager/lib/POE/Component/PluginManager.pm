package POE::Component::PluginManager::PluginAPI;

# this is the plugin API.
# i decided to put it in its own class
# so that nobody can mess up with calling
# the wrong methods.
# it also made the design somewhat clearer.
sub new {
    my ( $class, $kernel, $alias ) = @_;
    my $self = {};
    $self->{kernel} = $kernel;
    $self->{alias}  = $alias;
    bless $self, $class;
}

sub warning {
    my $self   = shift;
    my $string = shift;
    $self->{kernel}->post( $self->{alias}, 'plugin_warning', $string );

    # maybe i should rather use poe callbacks here?
}

sub error {
    my $self = shift;
    my $ex   = shift;
    $self->{kernel}->post( $self->{alias}, 'plugin_error', $ex );
}

package POE::Component::PluginManager;
our $VERSION = "0.67";

use strict;
use warnings;
use POE;
use Carp;
use Data::Dumper;
use Class::Unload;

# we need this to unload classes, otherwise
# plugins can't be "reloaded". Maybe in the
# future there should be an option to disable
# this feature, so that PluginManager doesn't
# necesarily depend on this module.
# However, its just working fine for me, so far.

my $pluginmanager_shutdown = 0;
my $DEBUG                  = 0;
my $alias;

sub debug {
    print @_ if $DEBUG;
}

sub new {
    my $type = shift;
    if ( @_ & 1 ) {
        carp('PluginManager->new needs even number of options');
    }
    my %options = @_;

    if ( exists $options{'Alias'} ) {    # the alias
        $alias = $options{'Alias'};
        delete $options{'Alias'};
    }
    else {
        carp '[pluginmanager] Using default Alias \'pluginmanager\'';
        $alias = 'pluginmanager';
    }
    if ( exists $options{'Debug'} ) {    # debugging on/off
        $DEBUG = $options{'Debug'};
        delete $options{'Debug'};
    }
    if ( keys %options > 0 ) {
        carp '[$alias]: Unrecognized options in new(): ' . join( ', ', keys %options );
    }

    # Create a new session for ourself
    POE::Session->create(

        # Our subroutines
        'inline_states' => {

            # Maintenance events
            '_start'            => \&start,                 # initial startup
            '_stop'             => \&stop,                  # cleanup, if needed
            '_dump'             => \&_dump,                 # for debugging purposes
            '_generate_event'   => \&_generate_event,       # for broadcasting events
            '_child'            => \&child,                 # to catch _child events
            'shutdown'          => \&component_shutdown,    # shuts down the component
            'unload'            => \&unload_plugin,         # unload a plugin
            'load'              => \&load_plugin,           # load a plugin.
            'show_plugin_table' => \&show_plugin_table,     # sends a hash
            'register'          => \&register,              # registers your session
            'unregister'        => \&unregister,            # unregisters your session
            'unregister_all'    => \&unregister_all,        # unregisters all sessions.

            'add_plugin'     => \&add_plugin,               # internally used
            'remove_plugin'  => \&remove_plugin,            # internally used
            'plugin_error'   => \&plugin_error,             # internally used
            'plugin_warning' => \&plugin_warning,           # internally used
            'relayed_warning'=> \&relayed_warning,          # to delay warnings.
        },
    ) or die 'Unable to create a new session!';

    # Return success
    return 1;
}

sub child {
    my ( $reason, $child, $return ) = @_[ ARG0 .. ARG2 ];
    my $plugin_id = $child->ID();

    if ( $reason eq 'create' ) {

        # a new plugin session has been started.
        POE::Kernel->yield( 'add_plugin', $plugin_id, $return );
    }
    elsif ( $reason eq 'lose' ) {

        # a plugin session has stopped
        POE::Kernel->yield( 'remove_plugin', $plugin_id, $return );
    }
}

sub start {
    debug( "[$alias] Plugin manager session has started. Alias: " . $alias . "\n" );
    POE::Kernel->alias_set($alias);

    # make an alias, so that this session won't go away.
    # maybe a feature for later versions: if no alias is specified, increase
    # refcount and return session object.
    my $plugin_api = POE::Component::PluginManager::PluginAPI->new( $_[KERNEL], $alias );

    # create the plugin API (seperate class)
    $_[HEAP]->{plugin_api} = $plugin_api;

}

sub stop {
    debug "[$alias] plugin manager session stopped.\n";
}

sub add_plugin {
    my $plugin_id = $_[ARG0];
    my $arguments = $_[ARG1];

    # a new plugin has come to life. register it to the plugin table.
    my ( $name, $longname, $license, $version, $author ) = @{$arguments} unless ref($arguments) ne 'ARRAY';
    unless ( $name && $longname && $license && $version && $author ) {
        warn "[$alias] $name did not correctly set all values (name, longname, license and version)";
        POE::Kernel->yield( '_generate_event', 'plugin_invalid_values', $name );

        # if a plugin didn't specify at least the name correctly, we will not be able
        # to unload it.
    }
    $_[HEAP]->{plugins}->{$name}->{id}       = $plugin_id;
    $_[HEAP]->{plugins}->{$name}->{longname} = $longname;
    $_[HEAP]->{plugins}->{$name}->{license}  = $license;
    $_[HEAP]->{plugins}->{$name}->{version}  = $version;
    $_[HEAP]->{plugins}->{$name}->{author}   = $author;
    $_[HEAP]->{lookup}->{$plugin_id}         = $name;

    # $_[HEAP]->{lookup} is a reverse lookup table for looking up plugin names by their ID
    POE::Kernel->yield( '_generate_event', 'plugin_started', $name );
}

sub remove_plugin {
    my $plugin_id    = $_[ARG0];
    my $quit_message = $_[ARG1];
    my $name         = $_[HEAP]->{lookup}->{$plugin_id};

    # a plugin has died away.
    # $quit_message is the returned value, if any.
    $quit_message = "quit" unless $quit_message;
    unless ($name) {
        warn "[$alias] WARNING: plugin $plugin_id unregistered, but the pluginmanager didn't knew about it.";
        warn "[$alias] WARNING: this might have been caused by a plugin not registering correctly.";
    }
    delete $_[HEAP]->{plugins}->{$name};
    delete $_[HEAP]->{lookup}->{$plugin_id};
    Class::Unload->unload($name);

    # all of this pretty printing is a bit superfluous.
    # remove it.
    my $spaces = 34 - length($name);
    my $spacer = " " x $spaces;
    debug "[$alias] Plugin unloaded: $name$spacer Quitmsg: $quit_message\n";
    POE::Kernel->yield( '_generate_event', 'plugin_unloaded', $name, $quit_message );

    #check if we want to shutdown
    my $plugin_count = 0;
    if ($pluginmanager_shutdown) {
        foreach ( keys %{ $_[HEAP]->{plugins} } ) {
            $plugin_count++;
        }
        if ( $plugin_count == 0 ) {

            # there are no plugins left, shutdown
            # shut down component here: remove alias
            POE::Kernel->alias_remove($alias);
            POE::Kernel->yield( '_generate_event', 'plugin_manager_shutdown', $plugin_count );
            POE::Kernel->yield("unregister_all");
        }
        else {
            debug "[$alias] waiting for plugins to shut down. Remaining: $plugin_count\n";
            POE::Kernel->yield( '_generate_event', 'plugin_waiting', $plugin_count );
        }
    }
}

sub load_plugin {

    # loads a plugin, parameter: Classname (f.ex YourProgram::Plugins::Foobarplugin)
    my $plugin = $_[ARG0];
    my $data   = $_[ARG1];
    warn "[$alias] warning: no plugin name specified" unless $plugin;
    my $classname = $plugin;      # the classname equals the plugin name supplied
    my $filename  = $classname;
    $filename =~ s#::#/#g;
    $filename .= ".pm";
    if ( $_[HEAP]->{plugins}->{$classname} ) {
        warn "[$alias] warning: plugin $classname already loaded!\n";
        POE::Kernel->yield( '_generate_event', 'plugin_compile_failed', $classname, "plugin already loaded" );
        return;
    }

    #my $classname = ( split( /\./, $filename ) )[0];

    my $spaces = 40 - length($classname);
    my $spacer = " " x $spaces;
    my ( $name, $longname, $license, $version );    #name, longname, license, version (all strings)
    debug "[$alias] loading $classname...$spacer compile: ";
    # this makes the load_plugin signal re-entrant. Thanks to Tim Esselens for the patch.
    if ($INC{$filename}) { delete $INC{$filename};
                          debug "[$alias] class was still in \@INC, removing...\n";
                          };
    eval { require $filename; };
    if ($@) {
        debug "FAIL\n";
        debug "[$alias] Error: $@\n";
        POE::Kernel->yield( '_generate_event', 'plugin_compile_failed', $classname, $@ );
        Class::Unload->unload($classname); # fixes the "attempt to reload $plugin" warnings
    }
    else {
        debug "OK ";
        debug "run: ";
        eval { $classname->new( $_[HEAP]->{plugin_api}, $data ); };
        if ($@) {
            debug "FAIL\n";
            debug "[$alias] Error: $@\n";
            POE::Kernel->yield( '_generate_event', 'plugin_init_failed', $classname, $@ );
            Class::Unload->unload($classname);
        }
        else {
            debug "OK\n";
        }
    }
}

sub unload_plugin {
    my $plugin = $_[ARG0];
    my $mode   = $_[ARG1];
    my $reason = $_[ARG2];

    # checking
    warn "[$alias] warning: no plugin name specified" unless $plugin;
    $mode = 'smart' unless $mode;    # fallback to "smart" if no mode is specified
    if ( exists $_[HEAP]->{plugins}->{$plugin} ) {
        my $sid = $_[HEAP]->{plugins}->{$plugin}->{id};
        POE::Kernel->post( $sid, 'shutdown', $mode, $reason );
    }
    else {
        warn "[$alias] the plugin $plugin wasn't registered to the pluginmanager";
        POE::Kernel->yield( '_generate_event', 'plugin_unload_failed', $plugin, "no such plugin" );
    }
}

sub plugin_error {

    # a plugin reported an error.
    my $id   = $_[SENDER]->ID();
    my $name = $_[HEAP]->{lookup}->{$id};
    $name = $id unless $name;

    # $name may be unspecified, if a plugin reports an error
    # in _start, because the pluginmanager didn't have a chance
    # to register the plugin yet. In this case, we simply return
    # the session ID. Anyone interested could look up the corresponding
    # plugin name in the plugin list later on.
    my $error_hashref = $_[ARG0];
    POE::Kernel->yield( '_generate_event', 'plugin_error', $name, $error_hashref );
}

sub plugin_warning {
    my $id   = $_[SENDER]->ID();
    my $name = $_[HEAP]->{lookup}->{$id};
    if(!$name){ # were delaying a bit
        print "unresolved warning!\n";
        $_[KERNEL]->yield('relayed_warning', $id, $_[ARG0]);
        return 1;
    }

    # see above, the same goes for warnings.
    my $string = $_[ARG0];
    POE::Kernel->yield( '_generate_event', 'plugin_warning', $name, $string );
}

sub relayed_warning {  # a little helper function, that delays warnings until the _child
    my $id = $_[ARG0]; # event had time to be dispatched
    my $string = $_[ARG1];
    my $name = $_[HEAP]->{lookup}->{$id};
    $name = 'unresolved' unless $name;
    POE::Kernel->yield( '_generate_event', 'plugin_warning', $name, $string );
}

sub _dump {

    # for debugging purposes, outputting the plugin and the lookup table.
    debug "[$alias] Dumping plugin table to STDOUT...\n";
    debug Dumper $_[HEAP]->{plugins};
    debug "[$alias] Dumping lookup table to STDOUT...\n";
    debug Dumper $_[HEAP]->{lookup};
}

sub component_shutdown {
    debug "[$alias] received shutdown signal, shutting down all plugins...\n";
    my $mode = $_[ARG0];
    $mode = 'smart' unless $mode;    # fallback
    my $plugins_pending = 0;
    $pluginmanager_shutdown = 1;     # setting the global shutdown flag
                                     # sending the shutdown signal to all plugins.
                                     # then, when all plugins are shut down, the plugin manager will go away.
    foreach my $plugin ( keys %{ $_[HEAP]->{plugins} } ) {
        debug "shutting down $plugin, id: " . $_[HEAP]->{plugins}->{$plugin}->{id} . "\n";
        POE::Kernel->post( $_[HEAP]->{plugins}->{$plugin}->{id}, 'shutdown', $mode, 'pluginmanager shutdown' );
        $plugins_pending++;
    }
    if ( $plugins_pending == 0 ) {

        # no plugins pending, shut down immediately
        POE::Kernel->alias_remove($alias);
        POE::Kernel->yield( '_generate_event', 'plugin_manager_shutdown', 0 );
        #POE::Kernel->delay("unregister_all", 1);
        POE::Kernel->yield("unregister_all");
    }
    #$_[KERNEL]->delay("unregister_all", 1);
}

sub show_plugin_table {

    # renamed from "show_plugin_list" to "show_plugin_table", since
    # "list" implies we would send back a list, or an arrayref.
    my $plugins = {};
    foreach my $plugin ( keys %{ $_[HEAP]->{plugins} } ) {
        $plugins->{$plugin}->{id}       = $_[HEAP]->{plugins}->{$plugin}->{id};
        $plugins->{$plugin}->{longname} = $_[HEAP]->{plugins}->{$plugin}->{longname};
        $plugins->{$plugin}->{license}  = $_[HEAP]->{plugins}->{$plugin}->{license};
        $plugins->{$plugin}->{version}  = $_[HEAP]->{plugins}->{$plugin}->{version};
        $plugins->{$plugin}->{author}   = $_[HEAP]->{plugins}->{$plugin}->{author};
    }
    POE::Kernel->yield( '_generate_event', 'plugin_table', $plugins );
    return $plugins;
}

sub register {
    my $session = $_[ARG0];
    if ( !$session ) {
        $session = $_[SENDER]->ID();
    }
    $_[HEAP]->{RecvSessions}->{$session} = 1;
    POE::Kernel->refcount_increment($session);

    # incrementing the refcount, so that the session can't go away
    # as long as we are sending events.

}

sub unregister {
    my $session = $_[ARG0];
    if ( !$session ) {
        $session = $_[SENDER]->ID();
    }
    delete $_[HEAP]->{RecvSessions}->{$session};
    POE::Kernel->refcount_decrement($session);

    # now you can go away.
}
sub unregister_all {
        foreach(keys %{$_[HEAP]->{RecvSessions}}){
        $_[KERNEL]->refcount_decrement($_);
    }
    delete $_[HEAP]->{RecvSessions};
}

sub _generate_event {

    #function to generate events. this events receives the event that is to be broad
    #casted via ARG0 and ARG1 - $#_ are the arguments. then it iterates through
    #the hash of registered sessions and sends the event to all sessions.
    my $event     = $_[ARG0];
    my @arguments = @_[ ARG1 .. $#_ ];
    while ( my ( $key, $value ) = each %{ $_[HEAP]->{RecvSessions} } ) {
        POE::Kernel->post( $key, $event, @arguments );
    }

}
return 1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

POE::Component::PluginManager - Make your POE programs plugin capable, really easy!

=head1 SYNOPSIS

  use POE::Component::PluginManager;
  POE::Component::PluginManager->new(
    Alias => 'pluginmanager',   # The alias, defaults to "pluginmanager"
    Debug => 0,                 # prints Debug statements; usefull for debugging plugins
  );
  POE::Kernel->post( 'pluginmanager', 'register' );
  ...
  See below for a listing of all signals you can send and receive.

=head1 DESCRIPTION

POE::Component::PluginManager makes it really easy to enhance virtually
any POE application with powerfull, yet easy-to-create plugins.
POE::Component::PluginManager tries to make writing plugins simple (anyone who
has a good understanding about POE should be able to write plugins without further
complications), leaving the details of the plugin specifications to the designer
of the Application.

=head1 HOW PLUGINS WORK

There are a lot of different ideas and implementations out there, about what plugins are
and how they have to work. So i'll give you a short overview how PoCo::PluginManagers plugins
work, and what you can do with them.

Plugins are implemented as POE::Sessions, that are dynamically loaded from a module. The procedure is:
a module is loaded with require during runtime, and new() is executed (inside an eval block). The plugin
spawns a new POE::Session in new(), the PluginManager receives a _child signal, and will automatically
register that new session as a running plugin.

This Concept of plugins does put very little restrictions on what Plugins can do. This also means, that
PluginManager provides no means of plugin coordination, safe code execution, or the like. If you want
something like that, you will either have to implement it yourself, or use a different plugin system.
Also, PluginManager doesn't provide predefined hooks or anything a plugin will receive, except for the
shutdown signal.

=head1 GOOD AND BAD PRACTICE

A plugin can basically do inside an application whatever it wants, so when you are running a plugin, you'll
have to trust the plugin. That is part of my idea of what plugins are. If a plugin wants to, it can stop the
entire application by throwing a die() without catching it in sig_DIE. As perl doesn't enforce any kind of
private/public variables, a plugin can theoretically break into any sessions HEAP and mess around. However,
this is what i consider bad practice. There is a mechanism which allows to give the plugin initial data to
operate on, and a plugin should only operate on that data, and not simply break into any sessions HEAP, unless
absolutely necessary. Ideally, an application designed to be pluggable should offer a place for plugins to work
and live, for example a place in the user-interface that plugins can use to add new widgets, or something like that.
See also "Plugin Data sharing"

=head1 PERFORMANCE CONSIDERATIONS

Since the plugins code is executed native, there should be no performance hit on code inside a plugin, putting
the loading/unloading overhead aside. Plugin loading and unloading shouldn't consume a lot of CPU time, and
there is not much memory overhead by loading a lot of plugins.

Also, there is one important thing to consider: A plugin should always do the least possible work.
In this example, we have an IRC bot, which has 100 plugins, providing 5 commands each, that hooked into PoCo::IRCs
irc_public signal, waiting for their command to occur:

inside some_plugin:

    if ( $what =~ /^!foo$/ ) {
        $_[KERNEL]->post( 'irc' => 'privmsg' => $channel => "answer to !foo" );
    }
    if ( $what =~ /^!bar$/ ) {
        $_[KERNEL]->post( 'net' => 'privmsg' => $channel => "answer to !bar" );
    }
    if ( $what =~ /^!baz$/ ) {
        $_[KERNEL]->post( 'net' => 'privmsg' => $channel => "answer to !baz" );
    }
    ...

Here, for every public message, every plugin has to apply 5 regexpes on the message, to determine if the command is the
one we are waiting for. Considering, we have 100 plugins loaded, this might cause a significant delay.
Here a much better version, that follows the "do as little as possible"-rule:

    if(index($what, "!") == 0){
        if ( $what =~ /^!foo$/ ) {
            $_[KERNEL]->post( 'irc' => 'privmsg' => $channel => "answer to !foo" );
        }
        elsif( $what =~ /^!bar$/ ){
            $_[KERNEL]->post( 'irc' => 'privmsg' => $channel => "answer to !bar" );
        }
        ...
    }

=head1 PLUGIN DATA SHARING

To make data sharing with plugins a bit easier, the "load" signal provides an extra field for data that will be passed on unmodified
to the plugin. For example, if you want to allow the plugin to operate on your sessions HEAP, you can pass a reference to your heap here,
or any subset of it, if you want to.

=head1 THE PLUGINMANAGER API

Enough of the blah blah blah, here a listing of all methods you can sent or receive from the pluginmanagers session:

=head2 SIGNALS YOU CAN SEND
    
    load CLASSNAME(string), PLUGINDATA
        Loads the class CLASSNAME, and passes PLUGINDATA to the new() method.
    
    unload CLASSNAME(string), MODE(string), REASON(string)
        sends a shutdown signal to the plugin, unloads the class.
        MODE can be: "immediate", "smart" or "lazy", depending
        on how fast you want to get rid of the plugin. See the
        plugin API section for details.
        REASON can be any string you like, if at all.
        
    shutdown MODE(string)
        Sends a shutdown signal to all plugins, and waits for all
        plugins to unload. When finished, the pluginmanager is shut
        down. MODE can be "immediate", "smart" or "lazy".
        
    show_plugin_table
        Will send back a plugin_table event with a listing of all
        currently loaded plugins.
        
    register [SESSION]
        Registers SESSION to the pluginmanager to receive events.
        if SESSION is not specified, assumes the sending session
        as target. register will increase the refcount for your
        receiving session, so that your session will not go away
        until it unregisters.
    
    unregister [SESSION]
        Unregisters SESSION. If SESSION is not specified, assumes
        the sending session as target. Unregister will decrease the
        refcount of your session.
        
    _dump
        uses Data::Dumper to print plugin and reverse lookup table
        to STDOUT.

=head2 SIGNALS YOU CAN RECEIVE

    plugin_compile_failed PLUGIN_NAME(str) ERROR(str)
        Compilling of a plugin failed. ERROR will contain the error
        string. ($@)
        
    plugin_init_failed PLUGIN_NAME(str) ERROR(str)
        Initialisizing a plugin (calling new()) failed. ERROR will
        contain the error string. ($@)
    
    plugin_invalid_values PLUGIN_NAME(str)
        A plugin did not return the correct set of values in _start.
        The Plugin API section in this documentation describes how to
        correctly set those values.
    
        
    plugin_started PLUGIN_NAME(str)
        A plugin was successfully loaded and started.
        
    plugin_error PLUGIN_NAME(str) ERROR_HASHREF(hashref)
        A plugin encountered an error. ERROR_HASHREF will be the exception
        hash provided by POE (see POE::Kernels exception handling for
        details)
        
    plugin_warning PLUGIN_NAME(str) WARN_STRING(str)
        A plugin emitted a warning. WARN_STRING will be the warning.
        
    plugin_unloaded PLUGIN_NAME(str) QUIT_MESSAGE(string)
        A plugin unloaded. QUIT_MESSAGE will contain a string that holds the
        quit message of the plugin (might for example be "quit on user request"
        or "quit due to fatal exception")
        
    plugin_waiting PLUGIN_COUNT(int)
        You will receive this signal, when you instructed the pluginmanager to
        shut down, but there are plugins pending that have to be shut down before
        the plugin manager can shut down. plugin_waiting will be emitted every time
        the number of pending plugins changes, until its 0.
    
    plugin_table PLUGIN_LIST(hashref)
        You will receive this when you requested a plugin list with show_plugin_table.
        This table will hold a list of all loaded plugins, and their meta-information
        as for example license, author, description and so on. Youll best have a look
        at the structure with Data::Dumper.
    
    plugin_manager_shutdown
        You will receive this when the plugin manager shuts down.
        The pluginmanager will not shut down until all plugins are unloaded.

=head1 PLUGIN API

Here an example of what a plugin typically should look like.
You will find many more examples in examples/.
The example is well documented and should be self-explanating. There is one thing
to notice, however: If you write a plugin that spawns more than one session, do not
spawn them in the new() constructor. The pluginmanager listens for the _child event,
and when you spawn multiple sessions, the plugin manager will think that multiple
plugins have loaded. There is, however, no problem with spawning as many sessions as you
like in _start, or whereever you want (inside your "toplevel"-session.)


    package SomeApp::Plugins::example;
    use strict;    # always
    use warnings;
    use POE;       # just for the constants
    our $name     = "SomeApp::Plugins::example";
    # the name, has to match the classname
    our $longname = "example plugin that demonstrates how to write plugins.";
    # something descriptive
    our $license  = "GPL";
    # the license
    our $VERSION  = "0.1";
    # the version
    our $author   = 'whoppix <elektronenvolt@quantentunnel.de>';
    # the author
    
    my $pluginmanager;
    # the pluginmanager object. used to report errors.
    my $shutdown_reason;
    # the reason to shut down, for simplicty stored in a global.
    
    sub new {
        my $type = shift;
        $pluginmanager = shift;
        my $init_data = shift; # data that can be given as parameter when loading the plugin
        POE::Session->create(
            'inline_states' => {
                '_start'   => \&start,
                '_stop'    => \&stop,
                'sig_DIE'  => \&handle_die,
                'shutdown' => \&plugin_shutdown,
            },
        ) or die '[$name] Failed to spawn a new session.';
    
        # in this example we are spawning a new session straightforward.
        # theres no problem for a plugin to have multiple sessions running,
        # but the first session to start is treated by the pluginmanager as
        # the 'plugin'-session, so the best way is propably to spawn an
        # initial 'manager' session, and spawn more sessions from there.
    }
    
    sub start {
        $_[KERNEL]->sig( DIE => 'sig_DIE' );
    
        # this is an important thing to do. Plugins can terminate the entire
        # application, if they want to, but you should do this, to make sure
        # you don't crash the application by accident. For more information
        # on how this works, see POE::Kernel, section "exception handling"
        $_[KERNEL]->alias_set($name);
    
        # setting an alias to keep the session alive
        return [ $name, $longname, $license, $VERSION, $author ];
    
        # this has to be returned in this order! The plugin manager catches
        # the '_child' signal, and puts those values you specify here into
        # the plugin table. If you fail to provide all of those values, the
        # pluginmanager will send a warning about missing initial parameters.
    }
    
    sub stop {
        print "[$name] is unloaded.\n";
        return $shutdown_reason;
    
        # if you care about letting the pluginmanger know why you shut down,
        # this is the place to return it.
    }
    
    sub handle_die {
    
        # called when you die.
        print "[$name] plugin died\n";
        my ( $sig, $ex ) = @_[ ARG0, ARG1 ];
    
        # $sig is the signal (DIE), $ex is the exception hash (see POE::Kernel,
        # 'exception handling)
        $pluginmanager->error($ex);
    
        # if you want to let the pluginmanager know that an error ocurred.
        $_[KERNEL]->yield( 'shutdown', 'immediate', 'exception ocurred: plugin has to terminate.' );
    
        # if the error is so grave, that your plugin can't continue operating norm-
        # ally, shut yourself down, with an exception error.
        $_[KERNEL]->sig_handled();
    
        # if you don't do this, the application will terminate.
    }
    
    sub plugin_shutdown {
        my $timing = $_[ARG0];
    
        # timing can be "immediate", "smart" or "lazy".
        # this is just a convention, here an explanation how to handle timings:
        # immediate:
        #   shut down immediately, as fast as possible.
        # smart:
        #   its up to you to decide what work you think is needed to be done before
        #   shutting down. Do everything needed, but don't do too much.
        # lazy:
        #   lazy means you have plenty of time to shut down. This means you are
        #   allowed spending time on f.ex. saving your time to a database, making
        #   an integrity check, and make a general cleanup.
        # The pluginmanager will wait while all plugins shut down, and keep the app
        # up to date about how many plugins are pending, before the pluginmanager
        # can shutdown.
        # If the application didn't specify any shutdown timing, the default will
        # be "smart".
    
        my $message = $_[ARG1];
    
        # shutdown message, some string, most likely not interesting.
        # can be used as shutdown reason when session stops. Not guaranteed
        # to be meaningfull / defined.
        print "[$name] received shutdown signal: $timing because of: $message\n";
        $shutdown_reason = $message;
        $_[KERNEL]->alias_remove($name);
    
        # here you need to do everything needed to make your POE::Session stop.
        # here were just removing an alias, cleanly stopping the session could also
        # include f.ex. stopping spawned child-sessions, unregistering to other
        # sessions you registered too, and decreasing refcounts.
    }
    return 1;

=head1 SEE ALSO

There are many more examples of plugins in the examples/ folder.

related modules:
POE, POE::Session, POE::Kernel, POE::Component::Pluggable

=head1 BUGS

If you find any bugs or if you have any suggestions for improvements, you are welcome
to file a bug report or drop me a notice at E<lt>elektronenvolt@quantentunnel.deE<gt>

=head1 AUTHOR

whoppix, E<lt>elektronenvolt@quantentunnel.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by whoppix

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
