#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Test::More;
use POSIX qw(isnan);
use Test::LeakTrace;
use Stats::LikeR;

# ==============================================================================
# 4. write_table: Nested Reference Memory Leaks
# ==============================================================================
# We supply a valid Array-of-Hashes, but one of the cells contains an Array reference.
# write_table cannot write deeply nested structures to a flat CSV and will croak.
# The fix ensures that the previously allocated header/row strings are freed before croaking.
my $nested_data = [
	{ Name => "Alice", Age => 30, Scores => [95, 90] }, # Nested 'Scores' array
	{ Name => "Bob",   Age => 25, Scores => [80, 85] }
];

no_leaks_ok {
	eval {
		write_table(
			data => $nested_data, 
			file => 'test_output_dummy.csv'
		);
	};
} 'write_table: No memory leaks when encountering illegal nested references';

# Cleanup dummy file if it was somehow created before the croak
unlink 'test_output_dummy.csv' if -e 'test_output_dummy.csv';
