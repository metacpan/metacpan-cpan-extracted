use strict;
use warnings FATAL => 'all';
use POE;
use POE::Quickie;
use Test::More tests => 1;

POE::Session->create(
    package_states => [
        (__PACKAGE__) => [qw(
            _start
        )],
    ],
);

POE::Kernel->run;

sub _start {
    my $heap = $_[HEAP];

    $heap->{quickie} = POE::Quickie->new();
    eval {
        $heap->{quickie}->run(
            Program     => sub { sleep 10 },
            ProgramArgs => { },
        );
    };
    ok($@, 'Got exception from POE::Wheel::Run');
}
