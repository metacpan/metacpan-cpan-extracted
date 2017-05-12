#!env perl
use strict;use warnings;

use lib '../lib';
use Test::More;
use_ok('Proc::Swarm');
#test module to see if the returned processing time is correct.

#simple call that generates an error on even numbers
my $code = sub {
    my $arg = shift;
    sleep $arg;
    return $arg;
};

my $retvals = Proc::Swarm::swarm({
    code     => $code,
    children => 2,
    sort => 1,
    work => [1,2,3]
});
my @runtimes = $retvals->get_result_times;

#sleep is a tricky thing on UNIX.  This test is very conservative.
ok((($runtimes[0] > 0) and ($runtimes[1] > 1) and ($runtimes[2] > 2)), 'correctly returned processing time');
done_testing();
