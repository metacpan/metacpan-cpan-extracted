# ABSTRACT: Parse the results of a benchmark

use strict;
use warnings;
use Carp;
use Text::TabularDisplay;
use Getopt::Long::Descriptive;
use Log::Any::App qw( $log ), -level => 'info';

my( $opt, $usage ) = describe_options(
	'%c %o file',
	[ 'unit-name=s', 'name for the units' ],
	[ 'format=s', 'format for divided value', { default => '%7.3f' } ],
);

my @labels = (
	'method', 'CPU time (s)', 'n', 'rate (1/s)', 'time/iter. (ms)',
	$opt->unit_name, 'time/iter./' . $opt->unit_name . ' (ns)',
	'command_line',
);

my $db;
my $debug_table;
my $cmdline;
my $divisor;
my $in_benchmark = 0;
while( <> ) {
	$log->debug( "++ Parsing $_" );
	/^\+ perl/ and do {
		chomp( $cmdline = $_ );
		$log->debug( "Benchmark table for experiment $cmdline" );
		next;
	};
	/^%%(\d+)\s*$/ and $divisor = $1;
	/^Benchmark:/ and do {
		$in_benchmark = 1;
		next;
	};
	$in_benchmark && /^\s*(\w+):/ and do {
		$log->debug( "Benchmark line: $_" );
		my $method = $1;
		/\s+=\s+(\d+\.\d+) CPU/ and my $cpu = $1;
		/\s+@\s+(\d+\.\d+)\/s\s+/ and my $measured_rate = $1;
		/\(n=(\d+)\)/ and my $n = $1;
		my $calculated_time = $cpu / $n;
		if( sprintf( '%.2f/s', 1/$calculated_time ) ne sprintf( '%.2f/s', $measured_rate ) ) {
			croak 'measured and calculated rate do not agree: '
				. sprintf( '%.2f/s', 1/$calculated_time )
				. " vs "
				. sprintf( '%.2f/s', $measured_rate );
		}
		my $divided_time = $calculated_time / $divisor;
		my @data = (
			$method, sprintf( '%7.2f', $cpu ),
			$n,      sprintf( '%7.2f', $measured_rate ),
			sprintf( '%9.3f',      1000 * $calculated_time ), $divisor,
			sprintf( $opt->format, 1e9 * $divided_time ),     $cmdline,
		);
		$debug_table ||= Text::TabularDisplay->new( @labels );
		$debug_table->add( @data );
		push @{ $db->{ $method } }, \@data;
		next;
	};
	$in_benchmark && /^\s*$/ and do {
		$log->debug( "Debug table:\n" . $debug_table->render );
		$debug_table = undef;
		$divisor = undef;
		$in_benchmark = 0;
		next;
	};
}

my $table = Text::TabularDisplay->new( @labels );
for my $key ( sort keys %$db ) {
	my $array = $db->{ $key };
	$table->add( @$_ ) for @$array;
}
print $table->render, "\n\n";
