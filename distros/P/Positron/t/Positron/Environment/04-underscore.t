#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Positron::Environment');
}

my $data = {
    one => 1,
    two => [1, 2],
    three => { 3 => 'hash' },
};
my $env = Positron::Environment->new($data);
lives_and {
    is_deeply($env->get('_') // undef, $data);
} "Underscore gives complete environment again";

lives_and {
    my $newdata = { new => 'data'};
    $env->set('_', $newdata);
    is_deeply($env->{'data'}, $newdata);
} "Setting underscore changes data";

done_testing();

