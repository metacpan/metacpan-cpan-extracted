#!/usr/bin/perl
use strict;
use warnings;
use Test;
BEGIN { plan tests => 6 };
use PostScript::File       0.12 qw(check_file);
use PostScript::Graph::Bar 0.02;
ok(1);

my $bar = new PostScript::Graph::Bar(
	file  => {
	    landscape => 1,
	    debug => 2,
	    errors => 1,
	},
	layout => {
	    heavy_color => [0, 0, 0.7],
	    mid_color => [0, 0.5, 1],
	},
	style => {
	    bar => {
		color => [0.8, 0.4, 0],
	    },
	},
	x_axis => {
	    show_lines => 1,
	},
);
ok($bar);

$bar->build_chart("t/single.csv");
ok(1);

my $name = "t/35ba-single";
$bar->output( $name );
ok(1);
my $psfile = check_file( "$name.ps" );
ok($psfile);
ok( check_filesize($psfile, -s $psfile));	# the chart looks different?
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
