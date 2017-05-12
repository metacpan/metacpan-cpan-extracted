#!env perl
use strict;use warnings;

use lib '../lib';
use Test::More;
use_ok('Proc::Swarm');

{   #simple call
    my $code = sub {
        my $arg = shift;
        select undef, undef, undef, rand(15);   #sleep rand 15 seconds to
                                                #make sure these come back out
                                                #of order.
        $arg++;
        return $arg;
    };

    my $retvals = Proc::Swarm::swarm({
        code     => $code,
        children => 3,
        sort     => 1,
        work     => ['a', 'z', 'I']
    });
    my @expected_values = ('b','aa','J');
    my @sorted_results = $retvals->get_result_objects;
    is_deeply(\@sorted_results, \@expected_values, 'properly incremented work');
}

{   #Same test, but un-sorted to make sure we come back OUT of order
    my $code = sub {
        my $arg = shift;
        select undef, undef, undef, rand(5);   #sleep rand 5 seconds to
                                                #make sure these come back out
                                                #of order.
        $arg++;
        return $arg;
    };

    my $retvals = Proc::Swarm::swarm({
        code     => $code,
        children => 7,
        work     => ['b','c','d','e','f','g','a','z','I']
    });
    my @expected_values = ('c','d','e','f','g','h','b','aa','J');
    my @unsorted_results = $retvals->get_result_objects;
    isnt(join(':', @unsorted_results),join(':', @expected_values),'work properly came back out of order');
}

done_testing();
