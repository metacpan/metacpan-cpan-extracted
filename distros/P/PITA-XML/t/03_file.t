#!/usr/bin/perl

# Unit tests for the PITA::XML::File class

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 14;
use Config    ();
use PITA::XML ();

# Extra testing functions
sub dies {
	my $code = shift;
	eval { &$code() };
	ok( $@, $_[0] || 'Code dies as expected' );
}

sub dies_like {
	my $code   = shift;
	my $regexp = shift;
	eval { &$code() };
	like( $@, $regexp, $_[0] || 'Core dies like expected' );
}

my $digest = 'MD5.0123456789abcdef0123456789abcdef';





#####################################################################
# Testing a sample of the functionality

# Creating with bad params dies
dies( sub { PITA::XML::File->new },
	'->new(no params) dies' );

dies( sub { PITA::XML::File->new(
	filename => '',
	) },
	'->new(bin) dies as expected' );

# Create a file legally
my $file = PITA::XML::File->new(
	filename => 'foo.tar.gz',
	resource => 'package',
	digest   => $digest,
	);
isa_ok( $file, 'PITA::XML::File' );
is( $file->filename, 'foo.tar.gz', '->filename returns as expected' );
is( $file->resource, 'package',    '->resource returns as expected' );
isa_ok( $file->digest, 'Data::Digest' );
is( $file->digest->as_string, $digest, '->digest returns as expected' );





#####################################################################
# Check for specific errors

# A missing filename
dies_like( sub { PITA::XML::File->new(
	filename => undef,
	) },
	qr/Missing or invalid filename/,
	'->new(missing filename) dies like expected',
);
dies_like( sub { PITA::XML::File->new(
	filename => '',
	) },
	qr/Missing or invalid filename/,
	'->new(missing filename) dies like expected',
);

# A bad resource name
dies_like( sub { PITA::XML::File->new(
	filename => 'foo.tar.gz',
	resource => undef,
	) },
	qr/Cannot provide a null resource type/,
	'->new(missing filename) dies like expected',
);

# Bad resource name
dies_like( sub { PITA::XML::File->new(
	filename => 'foo.tar.gz',
	resource => '',
	) },
	qr/Cannot provide a null resource type/,
	'->new(missing filename) dies like expected',
);

# Bad digest
dies_like( sub { PITA::XML::File->new(
	filename => 'foo.tar.gz',
	resource => 'foo',
	digest   => undef,
	) },
	qr/Missing or invalid digest/,
	'->new(missing filename) dies like expected',
);
dies_like( sub { PITA::XML::File->new(
	filename => 'foo.tar.gz',
	resource => 'foo',
	digest   => '',
	) },
	qr/Missing or invalid digest/,
	'->new(missing filename) dies like expected',
);
dies_like( sub { PITA::XML::File->new(
	filename => 'foo.tar.gz',
	resource => 'foo',
	digest   => 'MD5.asd',
	) },
	qr/Missing or invalid digest/,
	'->new(missing filename) dies like expected',
);

exit(0);
