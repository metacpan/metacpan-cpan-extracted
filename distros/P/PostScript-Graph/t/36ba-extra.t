#!/usr/bin/perl
use strict;
use warnings;
use Test;
BEGIN { plan tests => 9 };
use PostScript::File       0.12 qw(check_file);
use PostScript::Graph::Bar 0.03;
ok(1);

my $bar = new PostScript::Graph::Bar(
	file => {
	    landscape => 1,
	    debug => 2,
	    errors => 1,
	},
	layout  => {
	    heavy_color => [0, 0, 0.7],
	    mid_color => [0, 0.5, 1],
	},
	x_axis => {
	    rotate => 0,
	    show_lines => 1,
	},
	style => {
	    auto => [qw(blue red green)],
	},
);
ok($bar);

my $data2 =
    [ [ "", "First", "Second", ],
      [ "eee", 5, 6, ],
      [ "fff", 6, 7, ], ];
    
$bar->series_from_array($data2, 1);
ok(1);

my $data1 =
    [ [ "", "First", "Second", ],
      [ "aaa", 1, 2, ],
      [ "bbb", 2, 3, ],
      [ "ccc", 3, 4, ],
      [ "ddd", 4, 5, ], ];
    
$bar->series_from_array($data1, 0);
ok(1);

my $data3 =
    [ [ "", "Third", "Fourth", ],
      [ "aaa", 11, 12, ],
      [ "bbb", 12, 13, ],
      [ "eee", 15, 16, ],
      [ "fff", 16, 17, ], ];
    
$bar->series_from_array($data3, 1);
ok(1);

$bar->build_chart();
ok(1);

my $name = "t/36ba-extra";
$bar->output( $name );
ok(1);
my $psfile = check_file( "$name.ps" );
ok($psfile);
ok( check_filesize($psfile, -s $psfile) );	# the chart looks different?
warn "Use ghostview or similar to inspect results file:\n$psfile\n";

sub check_filesize {
    my ($psfile, $pssize) = @_;
    my %fs;
    my $filesizes = 't/filesizes';
    
    if (open(IN, '<', $filesizes)) {
	while (<IN>) {
	    chomp;
	    my ($size, $file) = m/^(\d+)\t(.+)$/;
	    $fs{$file} = $size;
	}
	close IN;
    }
    
    my $exists = $fs{$psfile};
    my $res = ($fs{$psfile} == $pssize);
    $fs{$psfile} = $pssize;

    open(OUT, '>', $filesizes) or die "Unable to write to $filesizes : $!\n";
    while( my ($file, $size) = each %fs ) {
	print OUT "$size\t$file\n" if defined $file and defined $size;
    }
    close OUT;

    return 1 unless $exists;
    return $res;
}
