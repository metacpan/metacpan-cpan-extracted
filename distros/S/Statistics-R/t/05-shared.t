#! perl

use strict;
use warnings;
use Test::More;
use Statistics::R;

my ($R1, $R2, $R3, $R4);

ok $R1 = Statistics::R->new( shared => 1 ), 'Starting in shared mode';
ok $R2 = Statistics::R->new( shared => 1 );
ok $R3 = Statistics::R->new( shared => 1 );
ok $R4 = Statistics::R->new( shared => 1 );

is $R1->is_shared, 1;
is $R2->is_shared, 1;
is $R3->is_shared, 1;
is $R4->is_shared, 1;

ok $R2->start;
ok $R4->start;

is $R1->is_started, 1;
is $R2->is_started, 1;
is $R3->is_started, 1;
is $R4->is_started, 1;

ok $R1 =~ m/\d+/, 'PIDs';
is $R1->pid, $R2->pid;
is $R1->pid, $R3->pid;
is $R1->pid, $R4->pid;

ok $R1->set( 'x', "string" ), 'Sharing data';

ok $R2->set( 'y', 3  );

is $R2->get( 'x' ), "string";

ok $R3->set( 'z', 10 );

is $R4->run( q`a <- y / z` ), '';

is $R4->get( 'a' ), 0.3;

ok $R3->stop();

is $R1->is_started, 0;
is $R2->is_started, 0;
is $R3->is_started, 0;
is $R4->is_started, 0;

done_testing;
