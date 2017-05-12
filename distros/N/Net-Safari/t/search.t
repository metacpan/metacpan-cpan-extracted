#!/usr/bin/perl
use strict;
# t/001_load.t - check module loading and create testing directory

use Test::More qw( no_plan );
use Data::Dumper;
use lib qw(/home/tonys/projects/safari/lib);
BEGIN { use_ok( 'Net::Safari' ); }

my $saf = Net::Safari->new();

my $res = $saf->search( TITLE => "perl");
foreach my $book ($res->books) {
    print "\n\n########################################\n\n";
    print $book->title . "\n";
    foreach my $section ($book->sections) {
        print "\t" . $section->title . "\n";
        print "EXTRACT:" . $section->extract . "\n";
    }
}

