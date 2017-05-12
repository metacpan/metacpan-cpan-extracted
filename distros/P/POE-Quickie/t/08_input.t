use strict;
use warnings FATAL => 'all';
use POE;
use POE::Quickie;
use Test::More tests => 2;

POE::Session->create(
    package_states => [
        (__PACKAGE__) => [qw(
            _start
            stdout
        )],
    ],
);

POE::Kernel->run;

sub _start {
    my $heap = $_[HEAP];

    $heap->{quickie} = POE::Quickie->new();
    $heap->{quickie}->run(
        Program     => sub { print while <STDIN> },
        StdoutEvent => 'stdout',
        Context     => 'baz',
        Input       => "0\n",
    );
}

sub stdout {
    my ($heap, $output, $pid, $context) = @_[HEAP, ARG0..ARG2];
    is($output, '0', 'Got stdout');
    is($context, 'baz', 'Got context');
}
