use strict;
use warnings FATAL => 'all';
use POE;
use Test::More tests => 5;

my ($SESSION_GOT_BAR, $SESSION_GOT_BAZ);

{
    package MyComponent;

    use strict;
    use warnings FATAL => 'all';
    use Object::Pluggable::Constants 'PLUGIN_EAT_NONE';
    use POE;
    use Test::More;
    use base 'POE::Component::Syndicator';

    sub spawn {
        my ($package, %args) = @_;
        my $self = bless \%args, $package;
        $self->_syndicator_init(
            debug         => 1,
            prefix        => 'my_',
            object_states => [
                $self => [qw(syndicator_started shutdown)],
            ],
        );
        return $self;
    }

    sub syndicator_started {
        my ($kernel, $self) = @_[KERNEL, OBJECT];
        pass('Subclass got syndicator_started event');
    }

    sub U_foo {
        my ($self) = $_[OBJECT];
        pass('Subclass got user event foo');
        $self->send_event('my_bar');
        $self->send_event('my_baz');
        return PLUGIN_EAT_NONE;
    }

    sub S_bar {
        ok(!$SESSION_GOT_BAR, 'Subclass got server event bar before a registered session did');
        return PLUGIN_EAT_NONE;
    }

    sub S_baz {
        ok($SESSION_GOT_BAR, 'Registered session got server event bar before subclass got server event baz');
        return PLUGIN_EAT_NONE;
    }

    sub shutdown {
        my ($self) = $_[OBJECT];
        $self->_syndicator_destroy();
    }
}

my $synd = MyComponent->spawn();

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            my_bar
            my_shutdown
            _shutdown
        )],
    ],
);

$poe_kernel->run();

sub _start {
    $poe_kernel->delay('_shutdown', 60, 'Timed out');
    $synd->yield('register', qw(bar baz shutdown));
    $synd->yield('foo');
}

sub my_bar {
    my ($kernel, $sender, $heap) = @_[KERNEL, SENDER, HEAP];
    pass('Interested session got server event my_bar');
    $SESSION_GOT_BAR = 1;
    $kernel->post($sender, 'shutdown');
}

sub my_shutdown {
    $poe_kernel->yield('_shutdown');
}

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $kernel->signal($kernel, 'SYNDICATOR_SHUTDOWN');
}
