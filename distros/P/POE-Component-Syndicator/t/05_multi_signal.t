use strict;
use warnings FATAL => 'all';
use POE;
use Test::More tests => 4;

{
    package MyComponent;

    use strict;
    use warnings FATAL => 'all';
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
                $self => [qw(shutdown)],
            ],
        );
        return $self;
    }

    sub shutdown {
        my ($self) = $_[OBJECT];
        $self->_syndicator_destroy();
    }
}

my $synd1 = MyComponent->spawn();
my $synd2 = MyComponent->spawn();

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            _shutdown
            my_registered
            my_shutdown
        )],
    ],
);

$poe_kernel->run();

sub _start {
    my ($kernel, $session) = @_[KERNEL, SESSION];
    $kernel->delay('_shutdown', 60, 'Timed out');
    $kernel->signal($kernel, 'SYNDICATOR_REGISTER', $session, 'all');
}

sub my_registered {
    pass('my_registered');
    $_[HEAP]{registered}++;
    if ($_[HEAP]{registered} == 2) {
        $poe_kernel->signal($poe_kernel, 'SYNDICATOR_SHUTDOWN');
    }
}

sub my_shutdown {
    pass('my_shutdown');
    $poe_kernel->yield('_shutdown');
}

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $kernel->signal($kernel, 'SYNDICATOR_SHUTDOWN');
}
