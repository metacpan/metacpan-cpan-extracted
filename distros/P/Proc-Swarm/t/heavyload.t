#!env perl
use strict;use warnings;

use lib '../lib';
use Test::More;
use_ok('Proc::Swarm');

my $code = sub {
    my $arg = shift;
    sleep rand(20);
    $arg++;
    return $arg;
};

my $retvals = Proc::Swarm::swarm({
    code => $code,
    children => 40,
    work => [1..100]
});
my @sorted_results = sort {$a <=> $b} $retvals->get_result_objects;
my @expected_values = (2..101);
is_deeply(\@sorted_results, \@expected_values, 'sorted results match');
done_testing();
