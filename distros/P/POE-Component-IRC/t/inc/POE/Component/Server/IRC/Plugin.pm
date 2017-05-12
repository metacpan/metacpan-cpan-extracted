package POE::Component::Server::IRC::Plugin;
BEGIN {
  $POE::Component::Server::IRC::Plugin::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::Server::IRC::Plugin::VERSION = '1.52';
}

use strict;
use warnings FATAL => 'all';

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw(PCSI_EAT_NONE PCSI_EAT_CLIENT PCSI_EAT_PLUGIN PCSI_EAT_ALL);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

use constant {
    PCSI_EAT_NONE   => 1,
    PCSI_EAT_CLIENT => 2,
    PCSI_EAT_PLUGIN => 3,
    PCSI_EAT_ALL    => 4,
};

1;

=encoding utf8

=head1 NAME

POE::Component::Server::IRC::Plugin - Provides plugin documentation for
POE::Component::Server::IRC.

=head1 DESCRIPTION

This is the document coders/users should refer to when using/developing
plugins for POE::Component::Server::IRC.

The plugin system works by letting coders hook into aspects of
POE::Component::Server::IRC::Backend. More details are found in the docs
for L<Object::Pluggable|Object::Pluggable>.

The general architecture of using the plugins should be:

 # Import the stuff...
 use POE;
 use POE::Component::Server::IRC::Backend;
 use POE::Component::Server::IRC::Plugin::ExamplePlugin;

 # Create our session here
 POE::Session->create( ... );

 # Create the IRC session here
 my $irc = POE::Component::Server::IRC::Backend->spawn() or die 'Nooo!';

 # Create the plugin
 # Of course it could be something like $plugin = MyPlugin->new();
 my $plugin = POE::Component::Server::IRC::Plugin::ExamplePlugin->new( ... );

 # Hook it up!
 $irc->plugin_add( 'ExamplePlugin', $plugin );

 # OOPS, we lost the plugin object!
 my $pluginobj = $irc->plugin_get( 'ExamplePlugin' );

 # We want a list of plugins and objects
 my $hashref = $irc->plugin_list();

 # Oh! We want a list of plugin aliases.
 my @aliases = keys %{ $irc->plugin_list() };

 # Ah, we want to remove the plugin
 $plugin = $irc->plugin_del( 'ExamplePlugin' );

The plugins themselves will conform to the standard API described here. What
they can do is limited only by imagination and the IRC RFC's ;)

 package POE::Component::Server::IRC::ExamplePlugin;

 # Import the constants
 use POE::Component::Server::IRC::Plugin qw( :ALL );

 # Our constructor
 sub new {
     # ...
 }

 # Required entry point for POE::Component::Server::IRC::Backend
 sub PCSI_register {
     my ($self, $irc) = @_;
         # Register events we are interested in
         $irc->plugin_register( $self, 'SERVER', qw(connection) );

         # Return success
         return 1;
     }

     # Required exit point for PoCo-Server-IRC
     sub PCSI_unregister {
         my ($self, $irc) = @_;

         # PCSIB will automatically unregister events for the plugin

         # Do some cleanup...

         # Return success
         return 1;
     }

     # Registered events will be sent to methods starting with IRC_
     # If the plugin registered for SERVER - irc_355
     sub IRCD_connection {
         my ($self, $irc, $line) = @_;

         # Remember, we receive pointers to scalars, so we can modify them
         $$line = 'frobnicate!';

         # Return an exit code
         return PCSI_EAT_NONE;
     }

     # Default handler for events that do not have a corresponding
     # plugin method defined.
     sub _default {
         my ($self, $irc, $event) = splice @_, 0, 3;

         print "Default called for $event\n";

         # Return an exit code
         return PCSI_EAT_NONE;
     }

=head2 Pipeline

The plugins are given priority on a first come, first serve basis.
Therefore, plugins that were added before others have the first shot at
processing events. See
L<Object::Pluggable::Pipeline|Object::Pluggable::Pipeline> for details.

 my $pipeline = $ircd->pipeline();

=head1 EVENTS

=head2 SERVER hooks

Hooks that are targeted toward data received from the server will get the
exact same arguments as if it was a normal event, look at the
POE::Component::Server::IRC::Backend docs for more information.

B<Note:> Server methods are identified in the plugin namespace by the
subroutine prefix of IRCD_*. I.e. an ircd_cmd_kick event handler would be:

 sub IRCD_cmd_kick {}

The only difference is instead of getting scalars, the hook will get a
reference to the scalar, to allow it to mangle the data. This allows the
plugin to modify data *before* they are sent out to registered sessions.

They are required to return one of the exit codes so
POE::Component::Server::IRC::Backend will know what to do.

Names of potential hooks:

 socketerr
 connected
 plugin_del
 ...

Keep in mind that they are always lowercased, check out the
POE::Component::Server::IRC documentation.

=head2 C<_default>

If a plugin doesn't have a specific hook method defined for an event, the
component will attempt to call a plugin's C<_default> method. The first
parameter after the plugin and irc objects will be the handler name.

 sub _default {
     my ($self, $irc, $event) = splice @_, 0, 3;
     return PCSI_EAT_NONE;
 }

The C<_default> handler is expected to return one of the exit codes so
POE::Component::Server::IRC::Backend will know what to do.

=head1 EXPORTS

The following constants are exported on demand.

=head2 C<PCSI_EAT_NONE>

This means the event will continue to be processed by remaining plugins and
finally, sent to interested sessions that registered for it.

=head2 C<PCSI_EAT_CLIENT>

This means the event will continue to be processed by remaining plugins but
it will not be sent to any sessions that registered for it.

=head2 C<PCSI_EAT_PLUGIN>

This means the event will not be processed by remaining plugins, it will go
straight to interested sessions.

=head2 C<PCSI_EAT_ALL>

This means the event will be completely discarded, no plugin or session
will see it.

=head1 SEE ALSO

L<Object::Pluggable|Object::Pluggable>

=cut
