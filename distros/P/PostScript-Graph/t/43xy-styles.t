#!/usr/bin/perl
use strict;
use warnings;
use Test;
BEGIN { plan tests => 9 };
use PostScript::File         0.12 qw(check_file);
use PostScript::Graph::Style 0.07;
ok(1);
use PostScript::Graph::XY 0.03;
ok(1);

my $seq = new PostScript::Graph::Sequence;
ok(1);

my $xy = new PostScript::Graph::XY(
	    file   => {
		landscape  => 1,
		errors     => 1,
		debug      => 1,
	    },
	    layout  => {
		heading_font => 'Times-Bold-Italic',
		heading_font_size => 20,
		heading_font_color => [0.3, 0, 0.6],
		heading => 'Fixed ?',
		left_edge  => 60,
		background => [1, 1, 0.9],
		dots_per_inch => 72,
	    },
	    x_axis => {
		smallest   => 0.5,
	    },
	    y_axis => {
		smallest   => 4,
		title	   => 'Dependent variable',
	    },
	    style  => {
		auto       => [qw(color dashes)],
		same       => 0,
		line       => {
		    width => 2,
		},
	    }
	);
ok($xy);

my $data = [ [qw(Control First Second Third Fourth Fifth Sixth Seventh Eighth Nineth Tenth)],
	     [ 1, 1, 2, 3, 4, 5, 6, 7, 8, 9,10 ],
	     [ 2, 2, 3, 4, 5, 6, 7, 8, 9,10,11 ],
	     [ 3, 3, 4, 5, 6, 7, 8, 9,10,11,12 ],
	     [ 4, 4, 5, 6, 7, 8, 9,10,11,12,13 ], ];

$xy->line_from_array( $data );
ok(1);

$xy->build_chart();
ok(1);

my $name = "t/43xy-styles";
$xy->output( $name );
ok(1); # survived so far
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
