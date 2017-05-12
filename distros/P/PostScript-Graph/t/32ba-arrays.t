#!/usr/bin/perl
use strict;
use warnings;
use Test;
BEGIN { plan tests => 7 };
use PostScript::File 0.12 qw(check_file);
use PostScript::Graph::Bar 0.03;
ok(1);

my $bar = new PostScript::Graph::Bar(
	    file   => {
		landscape  => 1,
		errors     => 1,
		debug      => 2,
	    },
	    layout => {
		left_edge  => 100,
		background => [1, 1, 0.9],
	    },
	    x_axis => {
		smallest   => 8,
		rotate	   => 0,
	    },
	    y_axis => {
		smallest   => 4,
	    },
	    style  => {
		auto       => [qw(green blue red)],
	    }
	);
ok($bar);

my $data = [ [qw(Control First Second Third Fourth Fifth Sixth Seventh Eighth Nineth Tenth)],
	     [ "Line 1", 1, 2, 3, 4, 5, 6, 7, 8, 9,10 ],
	     [ "Line 2", 2, 3, 4, 5, 6, 7, 8, 9,10,11 ],
	     [ "Line 3", 3, 4, 5, 6, 7, 8, 9,10,11,12 ],
	     [ "Line 4", 4, 5, 6, 7, 8, 9,10,11,12,13 ], ];

$bar->series_from_array( $data );
ok(1);
$bar->build_chart();
ok(1);

my $name = "t/32ba-arrays";
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
