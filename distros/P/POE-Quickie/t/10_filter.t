use strict;
use warnings FATAL => 'all';
use POE;
use POE::Filter::Reference;
use POE::Quickie;
use Test::More tests => 1;

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
        ResultEvent  => 'result',
        StdoutFilter => POE::Filter::Reference->new(),
        Program      => sub {
            my $filter = POE::Filter::Reference->new();
            print $filter->put([{ a => 'b' }])->[0];
        },
    );
}

sub result {
    my ($heap, $pid, $stdout, $stderr, $merged, $status, $context)
        = @_[HEAP, ARG0..$#_];
    is_deeply($stdout->[0], {a => 'b'}, 'Got stdout');
}
