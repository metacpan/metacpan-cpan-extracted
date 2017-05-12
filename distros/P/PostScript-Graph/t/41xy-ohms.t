#!/usr/bin/perl
use strict;
use warnings;
use Test;
BEGIN { plan tests => 7 };
use PostScript::File      0.12 qw(check_file);
use PostScript::Graph::XY 0.04;
ok(1);

my $xy = new PostScript::Graph::XY();
ok($xy);

$xy->line_from_file( "t/ohms.csv", "Current (mA)" );
ok(1);

$xy->build_chart();
ok(1);

my $name = "t/41xy-ohms";
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
