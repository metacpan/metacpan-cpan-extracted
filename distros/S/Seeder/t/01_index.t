#!/usr/bin/perl -w 

use Seeder::Index;
use Test::More tests => 4;

BEGIN {
    use_ok( 'Seeder::Index' );
}

my $index = Seeder::Index->new(
    seed_width => "6",
    out_file   => "t/6.index",
);

isa_ok($index, 'Seeder::Index');
can_ok($index, qw(get_index));
ok($index->get_index);