use strict;
use warnings FATAL => 'all';
use POE;
use POE::Quickie;
use Test::More tests => 8;
use Test::Deep;
use Capture::Tiny qw(capture);

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

    my $before = time;
    my ($stdout, $stderr, $status) = quickie(sub { sleep 3; print "foo\n" });
    my $after = time;
    is(($status >> 8), 0, 'Correct exit status');
    is_deeply($stdout, ['foo'], 'Got stdout');
    cmp_ok($after - $before, '>=', 2, 'The program runs');

    my ($merged) = quickie_merged(sub { warn "foo\n"; print "bar\n" });
    ok(eq_deeply($merged, [qw(foo bar)]) || eq_deeply($merged, [qw(bar foo)]),
        'Got merged output');

    ($stdout, $stderr) = capture {
        quickie_tee(sub { print "stdout\n"; warn "stderr\n"});
    };

    is($stdout, "stdout\n", 'Got teed stdout');
    is($stderr, "stderr\n", 'Got teed stderr');


    ($stdout, $stderr) = capture {
        quickie_tee_merged(sub { warn "stderr\n"; print "stdout\n" });
    };

    ok($stdout eq "stderr\nstdout\n" || $stdout eq "stdout\nstderr\n",
        'Got tee merged stdout');
    is($stderr, '', 'Got tee merged stderr');
}
