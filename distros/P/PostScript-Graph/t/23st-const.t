#!/usr/bin/perl
use strict;
use warnings;

use Test;
BEGIN { plan tests => 8 };
use PostScript::File 0.12 qw(check_file);
ok(1);
use PostScript::Graph::Bar 0.03;
ok(1);
use PostScript::Graph::Style 0.07;
ok(1);

my $bar = new PostScript::Graph::Bar(
	file => {
	    landscape => 1,
	    debug => 2,
	    errors => 1,
	},
	x_axis => {
	    rotate => 0,
	},
	style => {
	    auto => [qw(red green blue)],
	    bar => {},
	},
);
ok(1);

$bar->build_chart("t/const.csv");
ok(1);

my $name = "t/23st-const";
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
