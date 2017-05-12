package SomeApp::Plugins::example;
use strict;    # always
use warnings;
use POE;       # just for the constants
our $name     = "SomeApp::Plugins::example";                                  # the name, has to match the classname
our $longname = "example plugin that demonstrates how to write plugins.";    # something descriptive
our $license  = "GPL";                                                       # the license
our $VERSION  = "0.1";                                                       # the version
our $author   = 'whoppix <elektronenvolt@quantentunnel.de>';                 # the author

my $pluginmanager;                                                           # the pluginmanager object. used to report errors.
my $shutdown_reason;                                                         # the reason to shut down, for simplicty stored in a global.

sub new {
    my $type = shift;
    $pluginmanager = shift;
    my $init_data = shift;                                                   # data that can be given as parameter when loading the plugin
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
