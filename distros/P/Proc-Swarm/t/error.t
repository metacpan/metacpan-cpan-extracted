#!env perl
use strict;use warnings;

use lib '../lib';
use Test::More;
use_ok('Proc::Swarm');

#simple call that generates an error on even numbers
my $code = sub {
    my $arg = shift;
    my $val = $arg % 2;
    return(4 / $val);    #This blows up on even $arg
};

my $retvals = Proc::Swarm::swarm({
    code     => $code,
    children => 2,
    work     => [2,5,7,10]
});
is($retvals->get_result(2)->get_result_type, 'error', 'error properly returned');
done_testing();
