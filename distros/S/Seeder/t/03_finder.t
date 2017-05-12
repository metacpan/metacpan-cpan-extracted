#!/usr/bin/perl -w

use Seeder::Finder;
use Test::More tests => 3;

BEGIN {
    use_ok( 'Seeder::Finder' );
}

my $finder = Seeder::Finder->new( 
    seed_width    => "6", 
    motif_width   => "8", 
    n_motif       => "1", 
    hd_index_file => "t/6.index", 
    seq_file      => "t/pseq.fasta", 
    bkgd_file     => "t/bseq.bkgd", 
    out_file      => "t/6.out", 
    strand        => "revcom", 
); 

isa_ok($finder, 'Seeder::Finder');
can_ok($finder, qw(find_motifs));