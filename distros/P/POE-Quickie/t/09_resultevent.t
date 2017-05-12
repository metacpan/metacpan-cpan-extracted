use strict;
use warnings FATAL => 'all';
use POE;
use POE::Quickie;
use Test::More tests => 6;
use Test::Deep;

POE::Session->create(
    package_states => [
        (__PACKAGE__) => [qw(
            _start
            result
        )],
    ],
);

POE::Kernel->run;

sub _start {
    $_[HEAP]{pid} = quickie_run(
        ResultEvent => 'result',
        Context     => { a => 'b' },
        Program     => sub {
            print STDERR "BAR\n";
            print STDOUT "FOO\n";
        },
    );
}

sub result {
    my ($heap, $pid, $stdout, $stderr, $merged, $status, $context)
        = @_[HEAP, ARG0..$#_];

    is($pid, $heap->{pid}, 'Correct pid');
    is_deeply($stdout, ['FOO'], 'Got stdout');
    is_deeply($stderr, ['BAR'], 'Got stderr');
    ok(eq_deeply($merged, ['BAR', 'FOO'])
        || eq_deeply($merged, ['FOO', 'BAR']), 'Got merged output');
    is(($status >> 8), 0, 'Correct exit status');
    is($context->{a}, 'b', 'Correct context');
}
