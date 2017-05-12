#!/usr/bin/perl

# Unit tests for the PITA::XML::Request class

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 33;
use File::Spec::Functions ':ALL';
use PITA::XML ();

# Create a valid file for testing
my $digest = 'MD5.5cf0529234bac9935fc74f9579cc5be8';
my $file   = PITA::XML::File->new(
	filename => 'Task-CVSMonitor-0.006003.tar.gz',
	resource => 'package',
	digest   => $digest,
	);
isa_ok( $file, 'PITA::XML::File' );

sub dies_like {
	my $code   = shift;
	my $regexp = shift;
	eval { &$code() };
	like( $@, $regexp, $_[0] || 'Code dies like expected' );
}

sub new_dies_like {
	my $params = shift;
	my $regexp = shift;
	eval { PITA::XML::Request->new(
		scheme    => 'perl5',
		distname  => 'Task-CVSMonitor',
		file      => $file,
		authority => 'cpan',
		authpath  => '/authors/id/A/AD/ADAMK/Task-CVSMonitor-0.006003.tar.gz',
		%$params,
		);
	};
	like( $@, $regexp, $_[0] || 'Constructor fails like expected' );			
}





#####################################################################
# Basic tests

# Create a new object
my $dist = PITA::XML::Request->new(
	scheme   => 'perl5',
	distname => 'Foo-Bar',
	file     => $file,
	);
isa_ok( $dist, 'PITA::XML::Request' );
is( $dist->distname, 'Foo-Bar', '->distname matches expected'             );
isa_ok( $dist->file, 'PITA::XML::File' );
is( $dist->authority, '', '->authority returns "" as expected'            );
is( $dist->authpath,  '', '->authpath returns "" as expected'             );

# Create a new CPAN dist
my $cpan = PITA::XML::Request->new(
	scheme    => 'perl5',
	distname  => 'Task-CVSMonitor',
	file      => $file,
	authority => 'cpan',
	authpath  => '/authors/id/A/AD/ADAMK/Task-CVSMonitor-0.006003.tar.gz',
	);
isa_ok( $cpan, 'PITA::XML::Request' );
is( $cpan->distname, 'Task-CVSMonitor',
	'->distname matches expected' );
is( $cpan->file->filename, 'Task-CVSMonitor-0.006003.tar.gz',
	'->filename matches expected' );
is( $cpan->file->digest->as_string, 'MD5.5cf0529234bac9935fc74f9579cc5be8',
	'->md5sum matches expected' );
is( $cpan->authority, 'cpan',
	'->authority returns as expected' );
is( $cpan->authpath, '/authors/id/A/AD/ADAMK/Task-CVSMonitor-0.006003.tar.gz',
	'->authpath returns as expected' );

# Check the case where there is no authority
my $noauth = PITA::XML::Request->new(
	scheme    => 'perl5',
	distname  => 'Task-CVSMonitor',
	file      => $file,
	);
isa_ok( $noauth, 'PITA::XML::Request' );
is( $noauth->distname, 'Task-CVSMonitor',
	'->distname matches expected' );
is( $noauth->file->filename, 'Task-CVSMonitor-0.006003.tar.gz',
	'->filename matches expected' );
is( $noauth->file->digest->as_string, 'MD5.5cf0529234bac9935fc74f9579cc5be8',
	'->md5sum matches expected' );
is( $noauth->authority, '',
	'->authority returns as expected' );
is( $noauth->authpath, '',
	'->authpath returns as expected'  );





#####################################################################
# Check for specific errors

# Missing scheme
new_dies_like(
	{ scheme => '' }, 
	qr/Missing, invalid or unsupported scheme/,
	'->new(missing scheme) dies like expected',
);

# Bad scheme
new_dies_like(
	{ scheme => '' },
	qr/Missing, invalid or unsupported scheme/,
	'->new(bad scheme) dies like expected',
);

# X-scheme is ok
isa_ok( PITA::XML::Request->new(
	scheme    => 'x_foo',
	distname  => 'Task-CVSMonitor',
	file      => $file,
	authority => 'cpan',
	authpath  => '/authors/id/A/AD/ADAMK/Task-CVSMonitor-0.006003.tar.gz',
	), 'PITA::XML::Request' );

# Missing distname
new_dies_like(
	{ distname => '' },
	qr/Missing or invalid distname/,
	'->new(missing distname) dies like expected',
);

# bad distname
new_dies_like(
	{ distname => 'a bad distname' },
	qr/Missing or invalid distname/,
	'->new(bad distname) dies like expected',
);

# Missing file
new_dies_like(
	{ file => '' },
	qr/Missing or invalid file/,
	'->new(missing file) dies like expected',
);

# Bad file
new_dies_like(
	{ file => \'' },
	qr/Missing or invalid file/,
	'->new(bad file) dies like expected',
);

# Missing authority
new_dies_like(
	{ authority => '' },
	qr/No authority provided with authpath/,
	'->new(missing authority) dies like expected',
);

# Bad authority
new_dies_like(
	{ authority => \"" },
	qr/Invalid authority/,
	'->new(bad authority) dies like expected',
);

# Missing authpath
new_dies_like(
	{ authpath => '' },
	qr/No authpath provided with authority/,
	'->new(missing authpath) dies like expected',
);

# Bad authpath
new_dies_like(
	{ authpath => \"" },
	qr/Invalid authpath/,
	'->new(bad authpath) dies like expected',
);





#####################################################################
# Load a request, and then locate the real file

SCOPE: {
	my $file = catfile( 't', 'request', 'request.pita' );
	ok( -f $file, 'Test file exists' );
	my $request = PITA::XML::Request->read( $file );
	isa_ok( $request, 'PITA::XML::Request' );
	my $tarball = $request->find_file( $file );
	ok( $tarball, 'Got a tarball' );
	ok( -f $tarball, 'Tarball file exists' );
}

exit(0);
