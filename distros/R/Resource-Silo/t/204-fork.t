#!/usr/bin/env perl

=head1 DESCRIPTION

Ensure that forking erases cache.

=cut

use strict;
use warnings;

my @forked;
my @normal;
{
    package My::Res;
    use Resource::Silo -class;
    my $count;
    resource foo =>
        init            => sub { ++$count },
        cleanup         => sub { push @normal, shift },
        fork_cleanup    => sub { push @forked, shift };
}

my $inst = My::Res->new;

my $fst = $inst->foo;
my $snd = $inst->foo;

if (my $pid = fork // die "Fork failed: $!") {
    waitpid $pid, 0;
    exit $? >> 8;
} else {
    # make sure Test::More return nonzero status on error
    # so call it after fork
    require Test::More;
    Test::More->import();

    is( $fst, 1, "first call to foo correct" );
    is( $snd, 1, "second call to foo cached" );
    is_deeply( \@forked, [], "no cleanup happened yet" );
    is( $inst->foo, 2, "call within a fork causes reinit" );
    is_deeply( \@forked, [1], "fork_cleanup happened on fetching resource" );
    is_deeply( \@normal, [], "no normal cleanup so far" );
    undef $inst;
    is_deeply( \@forked, [1], "fork_cleanup happened only once" );
    is_deeply( \@normal, [2], "normal cleanup happened for new instance" );

    done_testing();
}
