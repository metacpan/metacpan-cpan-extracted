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

        return 1 if $self->_pluggable_process(EXAMPLE => $event, \(@args)) == PLUGIN_EAT_ALL;
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
