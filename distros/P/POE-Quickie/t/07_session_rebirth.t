use strict;
use warnings FATAL => 'all';
use POE;
use POE::Quickie;
use Test::More tests => 2;

POE::Session->create(
    package_states => [
        (__PACKAGE__) => [qw(
            _start
            _one
            _two
            _three
        )],
    ],
);

POE::Kernel->run;

sub _start {
    my ($stdout) = quickie(sub { print "foo\n" });
    is_deeply($stdout, ['foo'], 'Got stdout');
    $_[KERNEL]->yield('_one');
}

sub _one {
    $_[KERNEL]->yield('_two');
}

sub _two {
    $_[KERNEL]->yield('_three');
}

sub _three {
    my ($stdout) = quickie(sub { print "bar\n" });
    is_deeply($stdout, ['bar'], 'Got stdout');
}
