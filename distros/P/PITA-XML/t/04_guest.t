#!/usr/bin/perl

# Unit tests for the PITA::XML::Request class

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 30;
use File::Spec::Functions ':ALL';
use PITA::XML ();

sub dies_like {
	my $code   = shift;
	my $regexp = shift;
	eval { &$code() };
	like( $@, $regexp, $_[0] || 'Code dies like expected' );
}





#####################################################################
# Basic tests

# Create a new object
SCOPE: {
	my $dist = PITA::XML::Guest->new(
		id     => '17585D96-2896-11DC-B63B-8D0B94882154',
		driver => 'Local',
	);
	isa_ok( $dist, 'PITA::XML::Guest' );
	is( $dist->id, '17585D96-2896-11DC-B63B-8D0B94882154' );
	is( $dist->driver, 'Local', '->driver matches expected' );
	is_deeply( [ $dist->files ], [], '->files matches expected (list)' );
	is( scalar($dist->files), 0, '->files matches expected (scalar)' );
	is_deeply( $dist->config, {}, '->config returns an empty hash' );
}

# Create another one with more details and no id
my $file = PITA::XML::File->new(
	filename => 'guest.img',
	digest   => 'MD5.abcdefabcd0123456789abcdefabcd01',
	resource => 'hda',
);
isa_ok( $file, 'PITA::XML::File' );

my @params = (
	driver   => 'Image::Test',
	memory   => 256,
	snapshot => 1,
);
SCOPE: {
	my $dist = PITA::XML::Guest->new( @params );
	isa_ok( $dist, 'PITA::XML::Guest' );
	is( $dist->id, undef, '->id ok ' );
	ok( $dist->add_file( $file ), '->add_file ok' );
	is( $dist->driver,  'Image::Test', '->driver matches expected' );
	is( scalar($dist->files), 1, '->files returns as expected (scalar)' );
	is( ($dist->files)[0]->filename, 'guest.img', '->filename returns undef'  );
	is( ($dist->files)[0]->digest->as_string, 'MD5.abcdefabcd0123456789abcdefabcd01',
		'->digest returns undef' );
	is_deeply( $dist->config, { memory => 256, snapshot => 1 },
		'->config returns the expected hash' );
}

# Load the same thing from a file
SCOPE: {
	my $filename = catfile( 't', 'samples', 'guest.pita' );
	ok( -f $filename, 'Sample Guest file exists' );
	my $dist = PITA::XML::Guest->read( $filename );
	isa_ok( $dist, 'PITA::XML::Guest' );
	is( $dist->id, '17585D96-2896-11DC-B63B-8D0B94882154', '->id ok' );
	is( $dist->driver,  'Image::Test', '->driver matches expected' );
	is( ($dist->files)[0]->filename, 'guest.img', '->filename returns undef'  );
	is( ($dist->files)[0]->digest->as_string, 'MD5.abcdefabcd0123456789abcdefabcd01',
		'->md5sum returns undef' );
	is_deeply( $dist->config, { memory => 256, snapshot => 1 },
		'->config returns the expected hash' );
	my $made = PITA::XML::Guest->new(
		@params,
		base => rel2abs(
			catdir('t', 'samples'),
		),
	);
	isa_ok( $made, 'PITA::XML::Guest' );
	is( $made->id, undef, '->id is undef' );
	ok( $made->set_id('17585D96-2896-11DC-B63B-8D0B94882154'), '->set_id ok' );
	is( $made->id, '17585D96-2896-11DC-B63B-8D0B94882154', '->id ok' );
	ok( $made->add_file( $file ), '->add_file ok' );
	is_deeply( $dist, $made, 'File-loaded version exactly matches manually-created one' );

	# Check that the guest object round-trips ok
	my $output = '';
	$dist->write( \$output );
	my $round = PITA::XML::Guest->read(
		\$output,
		base => rel2abs(
			catdir('t', 'samples'),
		),
	);
	is_deeply( $dist, $round, 'Guest round-trips ok' );
	is_deeply( $made, $round, 'Guest round-trips ok' );
}

exit(0);
