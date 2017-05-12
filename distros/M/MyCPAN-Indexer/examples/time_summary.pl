#!env perl
use strict;
use warnings;

use YAML qw(LoadFile);

chdir $ARGV[0];

my %times;

foreach my $file ( glob( '*.yml' ) )
	{
	print "Processing $file\n";
	my $yaml = LoadFile( $file );
	
	my $time = $yaml->{run_info}{examine_time};
	
	$times{$file} = $time;
	}
	
foreach my $file ( sort { $times{$b} <=> $times{$a} } keys %times )
	{
	last if $times{$file} < 2;
	
	printf "%5d  %s\n", $times{$file}, $file; 
	}