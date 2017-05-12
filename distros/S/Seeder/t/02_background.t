#!/usr/bin/perl -w 

use Seeder::Background;
use Test::More tests => 4;

BEGIN {
    use_ok( 'Seeder::Background' );
}

my $background = Seeder::Background->new( 
    seed_width    => "6", 
    hd_index_file => "t/6.index", 
    seq_file      => "t/bseq.fasta", 
    out_file      => "t/bseq.bkgd", 
    strand        => "revcom", 
); 

isa_ok($background, 'Seeder::Background');
can_ok($background, qw(get_background));
ok($background->get_background);