#!/usr/bin/perl

# Unit tests for various things that have identifiers

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 18;
use Data::UUID ();
use PITA::XML  ();

my $md5sum = '0123456789abcdef0123456789abcdef';

sub dies_like {
	my $code   = shift;
	my $regexp = shift;
	eval { &$code() };
	like( $@, $regexp, $_[0] || 'Code dies like expected' );
}

my $uuid = Data::UUID->new;
isa_ok( $uuid, 'Data::UUID' );





#####################################################################
# Basic tests

# Create a normal request
my $dist = PITA::XML::Request->new(
	scheme   => 'perl5',
	distname => 'Foo-Bar',
	file     => PITA::XML::File->new(
		filename => 'Foo-Bar-0.01.tar.gz',
		digest   => 'MD5.' . $md5sum,
	),
);
isa_ok( $dist, 'PITA::XML::Request' );
is( $dist->distname, 'Foo-Bar', '->distname matches expected'             );
is( $dist->file->filename, 'Foo-Bar-0.01.tar.gz', '->filename matches expected' );
is( $dist->file->digest->digest, lc($md5sum), '->md5sum is normalised as expected'   );
is( $dist->authority, '', '->authority returns "" as expected'            );
is( $dist->authpath,  '', '->authpath returns "" as expected'             );

# Create a request with an id
my $id = $uuid->to_string( $uuid->create );
my $distid = PITA::XML::Request->new(
	id       => $id,
	scheme   => 'perl5',
	distname => 'Foo-Bar',
	file     => PITA::XML::File->new(
		filename => 'Foo-Bar-0.01.tar.gz',
		digest   => 'MD5.' . $md5sum,
	),
);
isa_ok( $distid, 'PITA::XML::Request' );
is( $distid->id,       $id,       '->id returns as expected'                );
is( $distid->distname, 'Foo-Bar', '->distname matches expected'             );
is( $distid->file->filename, 'Foo-Bar-0.01.tar.gz', '->filename matches expected' );
is( $distid->file->digest->digest,    lc($md5sum), '->md5sum is normalised as expected'   );
is( $distid->authority, '', '->authority returns "" as expected'            );
is( $distid->authpath,  '', '->authpath returns "" as expected'             );

# Write out to XML
my $output = '';
ok( $distid->write( \$output ), '->write returns ok' );
my $expected = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<request xmlns='http://ali.as/xml/schema/pita-xml/$PITA::XML::Request::VERSION' id='$id'>
<scheme>perl5</scheme>
<distname>Foo-Bar</distname>
<file>
<filename>Foo-Bar-0.01.tar.gz</filename>
<digest>MD5.0123456789abcdef0123456789abcdef</digest>
</file>
</request>
END_XML
chomp $expected;
$expected =~ s/\n//g;
is( $output, $expected, 'Wrote XML with id in it ok' );

# Parse it back in
my $distid2 = PITA::XML::Request->read( \$output );
isa_ok( $distid2, 'PITA::XML::Request' );
is_deeply( $distid2, $distid, 'Request with id roundtrips ok' );
