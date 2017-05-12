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

my $synd = MyComponent->spawn();

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            my_registered
            my_delay_set
            my_delay_removed
            _shutdown
        )],
    ],
);

$poe_kernel->run();

sub _start {
    $poe_kernel->delay('_shutdown', 60, 'Timed out');
    $synd->yield(register => 'all');
}

sub my_registered {
    my ($heap, $irc) = @_[HEAP, ARG0];

    $heap->{alarm_id} = $irc->delay(['foo', 'bar'], 5);
    ok($heap->{alarm_id}, 'Set alarm');
}

sub my_delay_set {
    my ($heap, $event, $alarm_id) = @_[HEAP, STATE, ARG0];

    is($alarm_id, $heap->{alarm_id}, $_[STATE]);
    my $opts = $synd->delay_remove($alarm_id);
    ok($opts, 'Delay Removed');
}

sub my_delay_removed {
    my ($kernel, $heap, $alarm_id) = @_[KERNEL, HEAP, ARG0];

    is($alarm_id, $heap->{alarm_id}, $_[STATE] );
    $kernel->yield('_shutdown');
}

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $kernel->signal($kernel, 'SYNDICATOR_SHUTDOWN');
}
