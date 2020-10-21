#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok( 'Pod::Definitions::Heuristic' );

{
    my $t = Pod::Definitions::Heuristic->new(text => 'Nibbling the carrot');
    is($t->clean, 'Carrot, Nibbling the');
}
{
    my $t = Pod::Definitions::Heuristic->new(text => 'Which versions are supported?');
    is($t->clean, 'Versions, supported');
}
{
    my $t = Pod::Definitions::Heuristic->new(text => 'How many roads must a man walk down?');
    is ($t->clean, 'Roads must a man walk down, How many');
}
{
    my $t = Pod::Definitions::Heuristic->new(text => 'What does the error "oops" during ignition mean?');
    is($t->clean, 'Oops during ignition, error');
}

{
    my $t = Pod::Definitions::Heuristic->new(text => 'How can I blip the blop?');
    is($t->clean, 'Blip the blop, How can I');
}
{
    my $t = Pod::Definitions::Heuristic->new(text => 'Why doesn\'t my socket have a packet?');
    is($t->clean, 'Socket have a packet, Why doesn\'t my');
}
{
    my $t = Pod::Definitions::Heuristic->new(text => 'Where are the pockets on the port?');
    is($t->clean, 'Pockets on the port, Where are the');
}
{
    my $t = Pod::Definitions::Heuristic->new(text => '');
    is($t->clean, '');
}

# # Various ways to say "ok"
# ok($got eq $expected, $test_name);

# is  ($got, $expected, $test_name);
# isnt($got, $expected, $test_name);

# # Rather than print STDERR "# here's what went wrong\n"
# diag("here's what went wrong");

# like  ($got, qr/expected/, $test_name);
# unlike($got, qr/expected/, $test_name);



done_testing();
