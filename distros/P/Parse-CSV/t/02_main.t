#!/usr/bin/perl

# Compile testing for Parse::CSV

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 83;
use File::Spec::Functions ':ALL';
use Parse::CSV;

my $readfile = catfile( 't', 'data', 'simple.csv' );
ok( -f $readfile, "$readfile exists" );

my $readfile2 = catfile( 't', 'data', 'newlines.csv' );
ok( -f $readfile2, "$readfile2 exists" );




#####################################################################
# Parsing a basic file in array ref mode

SCOPE: {
	my $csv = Parse::CSV->new(
		file => $readfile,
	);
	isa_ok( $csv, 'Parse::CSV' );
	is( $csv->row,    0,  '->row returns 0' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply( [ $csv->names ], [ ], '->names returns a null list' );

	# Pull the first line
	my $fetch1 = $csv->fetch;
	is_deeply( $fetch1, [ qw{a b c d e} ], '->fetch returns as expected' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Pull the first line
	my $fetch2 = $csv->fetch;
	is_deeply( $fetch2, [ qw{this is also a sample} ], '->fetch returns as expected' );
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );
	

	# Pull the first line
	my $fetch3 = $csv->fetch;
	is_deeply( $fetch3, [ qw{1 2 3 4.5 5} ], '->fetch returns as expected' );
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Pull the first non-line
	my $fetch4 = $csv->fetch;
	is( $fetch4, undef, '->fetch returns undef' );
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns "" still' );
}

SCOPE: {
	my $csv = Parse::CSV->new(
		file => $readfile2,
	);

	# Pull the first line
	my $line = $csv->fetch;
	is_deeply( $line, [ qw{a b c d e} ], '->fetch returns as expected' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Pull the second line
	$line = $csv->fetch;
	is_deeply( $line, [ "this", "\nis\n", "also", "a", "sample with some\nembedded newlines\nin it" ], '->fetch returns as expected' );
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Pull the third line
	$line = $csv->fetch;
	is_deeply( $line, [ qw{1 2 3 4.5 5} ], '->fetch returns as expected' );
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
}




#####################################################################
# Test fields

SCOPE: {
	my $csv = Parse::CSV->new(
		file  => $readfile,
		names => 1,
	);
	isa_ok( $csv, 'Parse::CSV' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		[ $csv->names ],
		[ qw{a b c d e} ],
		'->names ok',
	);
	is_deeply(
		[$csv->fields],
		[ qw{a b c d e} ],
		'->fields() before first line and after open $csv returns as expected'
	);

	# Get the first line
	my $fetch1 = $csv->fetch;
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch1,
		{ a => 'this', b => 'is', c => 'also', d => 'a', e => 'sample' },
		'->fetch returns as expected',
	);

	# TODO string() should not be expected to return data here, according to the Text::CSV_XS docs.
	my $line = $csv->string; 
	chomp($line); # $csv->string has linefeed
	is( $line,"this,is,also,a,sample",'->string() works');
	is_deeply(
		[ $csv->fields ],
		[ qw{this is also a sample} ],
		'->fields() after first line returns as expected'
	);

	# Get the second line
	my $fetch2 = $csv->fetch;	
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch2,
		{ a => 1, b => 2, c => 3, d => 4.5, e => 5 },
		'->fetch returns as expected',
	);
	is_deeply(
		[ $csv->names ],
		[ qw{a b c d e} ],
		'->colnames() (get) returns as expected',
	);
	is_deeply(
		[ $csv->names(qw{aa b c d e fext}) ],
		[ qw{aa b c d e fext} ],
		'->colnames() (set) returns as expected',
	);

	# Get the line after the end
	my $fetch3 = $csv->fetch;
	is( $fetch3, undef, '->fetch returns undef' );
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
}

# Ensure back-compatible with 'fields'
SCOPE: {
	my $csv = Parse::CSV->new(
		file   => $readfile,
		fields => 'auto',
	);
	isa_ok( $csv, 'Parse::CSV' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		[$csv->fields],
		[ qw{a b c d e} ],
		'->fields() before first line and after open $csv returns as expected',
	);

	# Get the first line
	my $fetch1 = $csv->fetch;
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch1,
		{ a => 'this', b => 'is', c => 'also', d => 'a', e => 'sample' },
		'->fetch returns as expected',
	);

	my $line = $csv->string; 
	chomp($line);  # $csv->string has linefeed
	is( $line,"this,is,also,a,sample",'->string() works');
	is_deeply(
		[ $csv->fields ],
		[ qw{this is also a sample} ],
		'->fields() after first line returns as expected',
	);

	# Get the second line
	my $fetch2 = $csv->fetch;	
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch2,
		{ a => 1, b => 2, c => 3, d => 4.5, e => 5 },
		'->fetch returns as expected',
	);
	is_deeply(
		[ $csv->names ],
		[ qw{a b c d e} ],
		'->colnames() (get) returns as expected',
	);
	is_deeply(
		[ $csv->names( qw{aa b c d e fext} ) ],
		[ qw{aa b c d e fext} ],
		'->colnames() (set) returns as expected',
	);

	# Get the line after the end
	my $fetch3 = $csv->fetch;
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is( $fetch3, undef, '->fetch returns undef' );
}





#####################################################################
# Test filters

# Basic filter usage
SCOPE: {
	my $csv = Parse::CSV->new(
		file   => $readfile,
		fields => 'auto',
		filter => sub { bless $_, 'Foo' },
	);
	isa_ok( $csv, 'Parse::CSV' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Get the first line
	my $fetch1 = $csv->fetch;
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch1,
		bless( { a => 'this', b => 'is', c => 'also', d => 'a', e => 'sample' }, 'Foo' ),
		'->fetch returns as expected',
	);

	# Get the second line
	my $fetch2 = $csv->fetch;	
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch2,
		bless( { a => 1, b => 2, c => 3, d => 4.5, e => 5 }, 'Foo' ),
		'->fetch returns as expected',
	);

	# Get the line after the end
	my $fetch3 = $csv->fetch;
	is( $fetch3, undef, '->fetch returns undef' );
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
}

# Filtering out of records
SCOPE: {
	my $csv = Parse::CSV->new(
		file   => $readfile,
		fields => 'auto',
		filter => sub { $_->{a} =~ /\d/ ? undef : $_ },
	);
	isa_ok( $csv, 'Parse::CSV' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Get the first line
	my $fetch1 = $csv->fetch;
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch1,
		bless( { a => 'this', b => 'is', c => 'also', d => 'a', e => 'sample' }, 'Foo' ),
		'->fetch returns as expected',
	);

	# Get the line after the end
	my $fetch2 = $csv->fetch;
	is( $fetch2, undef, '->fetch returns undef' );
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
}
