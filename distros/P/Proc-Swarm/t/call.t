#!env perl
use strict;use warnings;

use lib '../lib';
use Test::More;
use_ok('Proc::Swarm');


my $code = sub {
    my $arg = shift;
    $arg++;
    return($arg);
};

my $retvals = Proc::Swarm::swarm({
    code        => $code,
    children    => 2,
    work        => [1,5,7,10]
});
my @sorted_results = sort {$a <=> $b} $retvals->get_result_objects;
my @expected_values = (2,6,8,11);
is_deeply(\@sorted_results, \@expected_values, 'sorted results match');
done_testing();
