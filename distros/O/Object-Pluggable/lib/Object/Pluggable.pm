package Object::Pluggable;
BEGIN {
  $Object::Pluggable::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $Object::Pluggable::VERSION = '1.29';
}

use strict;
use warnings;
use Carp;
use Object::Pluggable::Pipeline;
use Object::Pluggable::Constants qw(:ALL);

sub _pluggable_init {
    my ($self, %opts) = @_;
  
    $self->{'_pluggable_' . lc $_} = delete $opts{$_} for keys %opts;
    $self->{_pluggable_reg_prefix} = 'plugin_' if !$self->{_pluggable_reg_prefix};
    $self->{_pluggable_prefix} = 'pluggable_' if !$self->{_pluggable_prefix};
  
    if (ref $self->{_pluggable_types} eq 'ARRAY') {
        $self->{_pluggable_types} = { map { $_ => $_ } @{ $self->{_pluggable_types} } };
    }
    elsif (ref $self->{_pluggable_types} ne 'HASH') {
        croak "Argument 'types' must be supplied";
    }
  
    return 1;
}

sub _pluggable_destroy {
    my ($self) = @_;
    $self->plugin_del( $_ ) for keys %{ $self->plugin_list() };
    return;
}

sub _pluggable_event {
    return;
}

sub _pluggable_process {
    my ($self, $type, $event, $args) = @_;

    if (!defined $type || !defined $event) {
        carp 'Please supply an event type and name!';
        return;
    }

    $event = lc $event;
    my $pipeline = $self->pipeline;
    my $prefix = $self->{_pluggable_prefix};
    $event =~ s/^\Q$prefix\E//;
    my $sub = join '_', $self->{_pluggable_types}{$type}, $event;
    my $return = PLUGIN_EAT_NONE;
    my $self_ret = $return;
    my @extra_args;

    local $@;
    if ($self->can($sub)) {
        eval { $self_ret = $self->$sub($self, \(@$args), \@extra_args ) };
        $self->_handle_error($self, $sub, $self_ret);
    }
    elsif ( $self->can('_default') ) {
        eval { $self_ret = $self->_default($self, $sub, \(@$args), \@extra_args) };
        $self->_handle_error($self, '_default', $self_ret);
    }

    $self_ret = PLUGIN_EAT_NONE unless defined $self_ret;
    return $return if $self_ret == PLUGIN_EAT_PLUGIN;
    $return = PLUGIN_EAT_ALL if $self_ret == PLUGIN_EAT_CLIENT;
    return PLUGIN_EAT_ALL if $self_ret == PLUGIN_EAT_ALL;

    if (@extra_args) {
        push @$args, @extra_args;
        @extra_args = ();
    }

    for my $plugin (@{ $pipeline->{PIPELINE} }) {
        if ($self eq $plugin
          || !$pipeline->{HANDLES}{$plugin}{$type}{$event}
          && !$pipeline->{HANDLES}{$plugin}{$type}{all}) {
            next;
        }

        my $ret = PLUGIN_EAT_NONE;

        my $alias = ($pipeline->get($plugin))[1];
        if ($plugin->can($sub)) {
            eval { $ret = $plugin->$sub($self, \(@$args), \@extra_args) };
            $self->_handle_error($plugin, $sub, $ret, $alias);
        }
        elsif ( $plugin->can('_default') ) {
            eval { $ret = $plugin->_default($self, $sub, \(@$args), \@extra_args) };
            $self->_handle_error($plugin, '_default', $ret, $alias);
        }

	$ret = PLUGIN_EAT_NONE unless defined $ret;
        return $return if $ret == PLUGIN_EAT_PLUGIN;
        $return = PLUGIN_EAT_ALL if $ret == PLUGIN_EAT_CLIENT;
        return PLUGIN_EAT_ALL if $ret == PLUGIN_EAT_ALL;

        if (@extra_args) {
            push @$args, @extra_args;
            @extra_args = ();
        }
    }

    return $return;
}

sub _handle_error {
    my ($self, $object, $sub, $return, $source) = @_;
    $source = defined $source ? "plugin '$source'" : 'self';

    if ($@) {
        chomp $@;
        my $error = "$sub call on $source failed: $@";
        warn "$error\n" if $self->{_pluggable_debug};

        $self->_pluggable_event(
            "$self->{_pluggable_prefix}plugin_error",
            $error, ($object == $self ? ($object, $source) : ()),
        );
    }
    elsif ( !defined $return || 
      ($return != PLUGIN_EAT_NONE
      && $return != PLUGIN_EAT_PLUGIN
      && $return != PLUGIN_EAT_CLIENT
      && $return != PLUGIN_EAT_ALL) ) {
        my $error = "$sub call on $source did not return a valid EAT constant";
        warn "$error\n" if $self->{_pluggable_debug};

        $self->_pluggable_event(
            "$self->{_pluggable_prefix}plugin_error",
            $error, ($object == $self ? ($object, $source) : ()),
        );
    }

    return;
}

# accesses the plugin pipeline
sub pipeline {
    my ($self) = @_;
    local $@;
    eval { $self->{_PLUGINS}->isa('Object::Pluggble::Pipeline') };
    $self->{_PLUGINS} = Object::Pluggable::Pipeline->new($self) if $@;
    return $self->{_PLUGINS};
}

# Adds a new plugin object
sub plugin_add {
    my ($self, $name, $plugin, @args) = @_;

    if (!defined $name || !defined $plugin) {
        carp 'Please supply a name and the plugin object to be added!';
        return;
    }

    return $self->pipeline->push($name, $plugin, @args);
}

# Removes a plugin object
sub plugin_del {
    my ($self, $name, @args) = @_;

    if (!defined $name) {
        carp 'Please supply a name/object for the plugin to be removed!';
        return;
    }

    my $return = scalar $self->pipeline->remove($name, @args);
    return $return;
}

# Gets the plugin object
sub plugin_get {
    my ($self, $name) = @_;  

    if (!defined $name) {
        carp 'Please supply a name/object for the plugin to be removed!';
        return;
    }

    return scalar $self->pipeline->get($name);
}

# Lists loaded plugins
sub plugin_list {
    my ($self) = @_;
    my $pipeline = $self->pipeline;
  
    my %return = map {$pipeline->{PLUGS}{$_} => $_} @{ $pipeline->{PIPELINE} };
    return \%return;
}

# Lists loaded plugins in order!
sub plugin_order {
    my ($self) = @_;
    return $self->pipeline->{PIPELINE};
}

sub plugin_register {
    my ($self, $plugin, $type, @events) = @_;
    my $pipeline = $self->pipeline;

    if (!grep { $_ eq $type } keys %{ $self->{_pluggable_types} }) {
        carp "The event type '$type' is not supported!";
        return;
    }

    if (!defined $plugin) {
        carp 'Please supply the plugin object to register events for!';
        return;
    }

    if (!@events) {
        carp 'Please supply at least one event to register!';
        return;
    }

    for my $ev (@events) {
        if (ref $ev and ref $ev eq 'ARRAY') {
            $pipeline->{HANDLES}{$plugin}{$type}{lc $_} = 1 for @$ev;
        }
        else {
            $pipeline->{HANDLES}{$plugin}{$type}{lc $ev} = 1;
        }
    }

    return 1;
}

sub plugin_unregister {
    my ($self, $plugin, $type, @events) = @_;
    my $pipeline = $self->pipeline;

    if (!grep { $_ eq $type } keys %{ $self->{_pluggable_types} }) {
        carp "The event type '$type' is not supported!";
        return;
    }

    if (!defined $plugin) {
        carp 'Please supply the plugin object to register!';
        return;
    }

    if (!@events) {
        carp 'Please supply at least one event to unregister!';
        return;
    }

    for my $ev (@events) {
        if (ref $ev and ref $ev eq "ARRAY") {
            for my $e (map { lc } @$ev) {
                if (!delete $pipeline->{HANDLES}{$plugin}{$type}{$e}) {
                    carp "The event '$e' does not exist!";
                    next;
                }
            }
        }
        else {
            $ev = lc $ev;
            if (!delete $pipeline->{HANDLES}{$plugin}{$type}{$ev}) {
                carp "The event '$ev' does not exist!";
                next;
            }
        }
    }

    return 1;
}

1;
__END__

=encoding utf8

=head1 NAME

Object::Pluggable - A base class for creating plugin-enabled objects

=head1 SYNOPSIS

 # A simple POE Component that sends ping events to registered sessions
 # and plugins every second.

 {
     package SimplePoCo;

     use strict;
     use warnings;
     use base qw(Object::Pluggable);
     use POE;
     use Object::Pluggable::Constants qw(:ALL);

     sub spawn {
         my ($package, %opts) = @_;
         my $self = bless \%opts, $package;

         $self->_pluggable_init(
             prefix => 'simplepoco_',
             types  => [qw(EXAMPLE)],
             debug  => 1,
         );

         POE::Session->create(
             object_states => [
                 $self => { shutdown => '_shutdown' },
                 $self => [qw(_send_ping _start register unregister __send_event)],
             ],
         );

         return $self;
     }

     sub shutdown {
         my ($self) = @_;
         $poe_kernel->post($self->{session_id}, 'shutdown');
     }

     sub _pluggable_event {
         my ($self) = @_;
         $poe_kernel->post($self->{session_id}, '__send_event', @_);
     }

     sub _start {
         my ($kernel, $self) = @_[KERNEL, OBJECT];
         $self->{session_id} = $_[SESSION]->ID();

         if ($self->{alias}) {
             $kernel->alias_set($self->{alias});
         }
         else {
             $kernel->refcount_increment($self->{session_id}, __PACKAGE__);
         }

         $kernel->delay(_send_ping => $self->{time} || 300);
         return;
     }

     sub _shutdown {
          my ($kernel, $self) = @_[KERNEL, OBJECT];

          $self->_pluggable_destroy();
          $kernel->alarm_remove_all();
          $kernel->alias_remove($_) for $kernel->alias_list();
          $kernel->refcount_decrement($self->{session_id}, __PACKAGE__) if !$self->{alias};
          $kernel->refcount_decrement($_, __PACKAGE__) for keys %{ $self->{sessions} };

          return;
     }

     sub register {
         my ($kernel, $sender, $self) = @_[KERNEL, SENDER, OBJECT];
         my $sender_id = $sender->ID();
         $self->{sessions}->{$sender_id}++;

         if ($self->{sessions}->{$sender_id} == 1) { 
             $kernel->refcount_increment($sender_id, __PACKAGE__);
             $kernel->yield(__send_event => 'simplepoco_registered', $sender_id);
         }

         return;
     }

     sub unregister {
         my ($kernel, $sender, $self) = @_[KERNEL, SENDER, OBJECT];
         my $sender_id = $sender->ID();
         my $record = delete $self->{sessions}->{$sender_id};

         if ($record) {
             $kernel->refcount_decrement($sender_id, __PACKAGE__);
             $kernel->yield(__send_event => 'simplepoco_unregistered', $sender_id);
         }

         return;
     }
  
     sub __send_event {
         my ($kernel, $self, $event, @args) = @_[KERNEL, OBJECT, ARG0..$#_];

         return 1 if $self->_pluggable_process(EXAMPLE => $event, \@args) == PLUGIN_EAT_ALL;
         $kernel->post($_, $event, @args) for keys %{ $self->{sessions} };
     }

     sub _send_ping {
         my ($kernel, $self) = @_[KERNEL, OBJECT];

         $kernel->yield(__send_event => 'simplepoco_ping', 'Wake up sleepy');
         $kernel->delay(_send_ping => $self->{time} || 1);
         return;
     }
 }

 {
     package SimplePoCo::Plugin;
     use strict;
     use warnings;
     use Object::Pluggable::Constants qw(:ALL);

     sub new {
         my $package = shift;
         return bless { @_ }, $package;
     }

     sub plugin_register {
         my ($self, $pluggable) = splice @_, 0, 2;
         print "Plugin added\n";
         $pluggable->plugin_register($self, 'EXAMPLE', 'all');
         return 1;
     }

     sub plugin_unregister {
         print "Plugin removed\n";
         return 1;
     }

     sub EXAMPLE_ping {
         my ($self, $pluggable) = splice @_, 0, 2;
         my $text = ${ $_[0] };
         print "Plugin got '$text'\n";
         return PLUGIN_EAT_NONE;
     }
 }

 use strict;
 use warnings;
 use POE;

 my $pluggable = SimplePoCo->spawn(
     alias => 'pluggable',
     time  => 1,
 );

 POE::Session->create(
     package_states => [
         main => [qw(_start simplepoco_registered simplepoco_ping)],
     ],
 );

 $poe_kernel->run();

 sub _start {
     my $kernel = $_[KERNEL];
     $kernel->post(pluggable => 'register');
     return;
 }

 sub simplepoco_registered {
     print "Main program registered for events\n";
     my $plugin = SimplePoCo::Plugin->new();
     $pluggable->plugin_add('TestPlugin', $plugin);
     return;
 }

 sub simplepoco_ping {
     my ($heap, $text) = @_[HEAP, ARG0];
     print "Main program got '$text'\n";
     $heap->{got_ping}++;
     $pluggable->shutdown() if $heap->{got_ping} == 3;
     return;
 }

=head1 DESCRIPTION

Object::Pluggable is a base class for creating plugin enabled objects. It is
a generic port of L<POE::Component::IRC|POE::Component::IRC>'s plugin system.

If your object dispatches events to listeners, then Object::Pluggable may be
a good fit for you.

Basic use would involve subclassing Object::Pluggable, then overriding
C<_pluggable_event()> and inserting C<_pluggable_process()> wherever you
dispatch events from.

Users of your object can then load plugins using the plugin methods provided
to handle events generated by the object.

You may also use plugin style handlers within your object as
C<_pluggable_process()> will attempt to process any events with local method
calls first. The return value of these handlers has the same significance as
the return value of 'normal' plugin handlers.

=head1 PRIVATE METHODS

Subclassing Object::Pluggable gives your object the following 'private'
methods:

=head2 C<_pluggable_init>

This should be called on your object after initialisation, but before you want
to start processing plugins. It accepts a number of argument/value pairs:

 'types', an arrayref of the types of events that your poco will support,
          OR a hashref with the event types as keys and their abbrevations
          (used as plugin event method prefixes) as values. This argument is
          mandatory.

 'prefix', the prefix for your events (default: 'pluggable_');
 'reg_prefix', the prefix for the register()/unregister() plugin methods 
               (default: 'plugin_');
 'debug', a boolean, if true, will cause a warning to be printed every time a
          plugin call fails.

Notes: 'prefix' should probably end with a '_'. The types specify the prefixes
for plugin handlers. You can specify as many different types as you require. 

=head2 C<_pluggable_destroy>

This should be called from any shutdown handler that your poco has. The method
unloads any loaded plugins.

=head2 C<_pluggable_process>

This should be called before events are dispatched to interested sessions.
This gives pluggable a chance to discard events if requested to by a plugin.

The first argument is a type, as specified to C<_pluggable_init()>.

 sub _dispatch {
     my ($self, $event, $type, @args) = @_;

     # stuff

     my $type = ...

     return 1 if $self->_pluggable_process($type, $event, \@args)) == PLUGIN_EAT_ALL;

     # dispatch event to interested sessions.
 }

A reference to the argument array is passed. This allows the plugin system
to mangle the arguments or even add new ones.

=head2 C<_pluggable_event>

This method should be overridden in your class so that pipeline can dispatch
events through your event dispatcher. Pipeline sends a prefixed 'plugin_add'
and 'plugin_del' event whenever plugins are added or removed, respectively.
A prefixed 'plugin_error' event will be sent if a plugin a) raises an
exception, b) fails to return a true value from its register/unregister
methods, or c) fails to return a valid EAT constant from a handler.

 sub _pluggable_event {
     my $self = shift;
     $poe_kernel->post($self->{session_id}, '__send_event', @_);
 }

There is an example of this in the SYNOPSIS.

=head1 PUBLIC METHODS

Subclassing Object::Pluggable gives your object the following public
methods:

=head2 C<pipeline>

Returns the L<Object::Pluggable::Pipeline|Object::Pluggable::Pipeline>
object.

=head2 C<plugin_add>

Accepts two arguments:

 The alias for the plugin
 The actual plugin object
 Any number of extra arguments

The alias is there for the user to refer to it, as it is possible to have
multiple plugins of the same kind active in one Object::Pluggable object.

This method goes through the pipeline's C<push()> method, which will call
C<< $plugin->plugin_register($pluggable, @args) >>.

Returns the number of plugins now in the pipeline if plugin was initialized,
C<undef>/an empty list if not.

=head2 C<plugin_del>

Accepts the following arguments:

 The alias for the plugin or the plugin object itself
 Any number of extra arguments

This method goes through the pipeline's C<remove()> method, which will call
C<< $plugin->plugin_unregister($pluggable, @args) >>.

Returns the plugin object if the plugin was removed, C<undef>/an empty list
if not.

=head2 C<plugin_get>

Accepts the following arguments:

 The alias for the plugin

This method goes through the pipeline's C<get()> method.

Returns the plugin object if it was found, C<undef>/an empty list if not.

=head2 C<plugin_list>

Takes no arguments.

Returns a hashref of plugin objects, keyed on alias, or an empty list if
there are no plugins loaded.

=head2 C<plugin_order>

Takes no arguments.

Returns an arrayref of plugin objects, in the order which they are
encountered in the pipeline.

=head2 C<plugin_register>

Accepts the following arguments:

 The plugin object
 The type of the hook (the hook types are specified with _pluggable_init()'s 'types')
 The event name[s] to watch

The event names can be as many as possible, or an arrayref. They correspond
to the prefixed events and naturally, arbitrary events too.

You do not need to supply events with the prefix in front of them, just the
names.

It is possible to register for all events by specifying 'all' as an event.

Returns 1 if everything checked out fine, C<undef>/an empty list if something
is seriously wrong.

=head2 C<plugin_unregister>

Accepts the following arguments:

 The plugin object
 The type of the hook (the hook types are specified with _pluggable_init()'s 'types')
 The event name[s] to unwatch

The event names can be as many as possible, or an arrayref. They correspond
to the prefixed events and naturally, arbitrary events too.

You do not need to supply events with the prefix in front of them, just the
names.

It is possible to register for all events by specifying 'all' as an event.

Returns 1 if all the event name[s] was unregistered, undef if some was not
found.

=head1 PLUGINS

The basic anatomy of a pluggable plugin is:

 # Import the constants, of course you could provide your own 
 # constants as long as they map correctly.
 use Object::Pluggable::Constants qw( :ALL );

 # Our constructor
 sub new {
     ...
 }

 # Required entry point for pluggable plugins
 sub plugin_register {
     my($self, $pluggable) = @_;

     # Register events we are interested in
     $pluggable->plugin_register($self, 'SERVER', qw(something whatever));

     # Return success
     return 1;
 }

 # Required exit point for pluggable
 sub plugin_unregister {
     my($self, $pluggable) = @_;

     # Pluggable will automatically unregister events for the plugin

     # Do some cleanup...

     # Return success
     return 1;
 }

 sub _default {
     my($self, $pluggable, $event) = splice @_, 0, 3;

     print "Default called for $event\n";

     # Return an exit code
     return PLUGIN_EAT_NONE;
 }

As shown in the example above, a plugin's C<_default> subroutine (if present)
is called if the plugin receives an event for which it has no handler.

The special exit code CONSTANTS are documented in
L<Object::Pluggable::Constants|Object::Pluggable::Constants>. You could
provide your own as long as the values match up, though.

=head1 TODO

Better documentation >:]

=head1 AUTHOR

Chris 'BinGOs' Williams <chris@bingosnet.co.uk>

=head1 LICENSE

Copyright C<(c)> Chris Williams, Apocalypse, Hinrik Örn Sigurðsson and Jeff Pinyan

This module may be used, modified, and distributed under the same terms as
Perl itself. Please see the license that came with your Perl distribution for
details.

=head1 KUDOS

APOCAL for writing the original L<POE::Component::IRC|POE::Component::IRC>
plugin system.

japhy for writing L<POE::Component::IRC::Pipeline|POE::Component::IRC::Pipeline>
which improved on it.

All the happy chappies who have contributed to POE::Component::IRC over the 
years (yes, it has been years) refining and tweaking the plugin system.

The initial idea was heavily borrowed from X-Chat, BIG thanks go out to the
genius that came up with the EAT_* system :)

=head1 SEE ALSO

L<POE::Component::IRC|POE::Component::IRC>

L<Object::Pluggable::Pipeline|Object::Pluggable::Pipeline>

Both L<POE::Component::Client::NNTP|POE::Component::Client::NNTP> and
L<POE::Component::Server::NNTP|POE::Component::Server::NNTP> use this module
as a base, examination of their source may yield further understanding.

=cut
