use strict;
use warnings FATAL => 'all';
use POE;
use POE::Quickie;
use Test::More tests => 3;

POE::Session->create(
    package_states => [
        (__PACKAGE__) => [qw(
            _start
            exit
        )],
    ],
);

POE::Kernel->run;

sub _start {
    my $heap = $_[HEAP];

    $heap->{quickie} = POE::Quickie->new();
    $heap->{start} = time;
    $heap->{quickie}->run(
        Program   => sub { sleep 10 },
        ExitEvent => 'exit',
        Timeout   => 3,
    );
}

sub exit {
    my ($heap, $status) = @_[HEAP, ARG0];
    is(($status >> 8), 0, 'Got exit status');
    my $duration = time - $heap->{start};
    cmp_ok($duration, '>=', 3, "Timeout is long enough");
    cmp_ok($duration, '<', 10, "Timeout is short enough");
}
