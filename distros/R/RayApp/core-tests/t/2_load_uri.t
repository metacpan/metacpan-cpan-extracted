#!/usr/bin/perl -Tw

use Test::More tests => 39;
use bytes;

$^W = 1;
use warnings;
use strict;

BEGIN { use_ok( 'RayApp' ); }
BEGIN { use_ok( 'POSIX' ); }
BEGIN { use_ok( 'XML::LibXML' ); }

POSIX::setlocale(POSIX::LC_ALL, 'C');

chdir 't' if -d 't';

my $rayapp = new RayApp;
isa_ok($rayapp, 'RayApp');

my $data;

ok($data = $rayapp->load_uri('nonxml.xml'), 'Loading plain text file');
is($rayapp->errstr, undef, 'Checking that there was no error');

like($data->uri, '/^file:.*nonxml.xml$/', 'Checking URI of the file');
is($data->md5_hex, 'd85c6d0c186475fcc2b9c2050103fdc5',
	'Checking MD5 of the file');

ok($data = $rayapp->load_uri('nonxml.xml'), 'Loading the file for the second time');
is($rayapp->errstr, undef, 'Checking that there was still no error');

like($data->uri, '/^file:.*nonxml.xml$/', 'Checking URI of the file');
is($data->md5_hex, 'd85c6d0c186475fcc2b9c2050103fdc5',
	'Checking MD5 of the file');


ok($data = $rayapp->load_string("This file is not XML.\n"), 'Loading string');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($data->uri, 'md5:d85c6d0c186475fcc2b9c2050103fdc5',
	'Checking URI of the string');
is($data->md5_hex, 'd85c6d0c186475fcc2b9c2050103fdc5',
	'Checking MD5 of the string');


ok($data = $rayapp->load_string("This file is not XML (1).\n"),
	'Another string');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($data->uri, 'md5:ff6560652a8a8381c37d9864562cf9fc',
	'Checking URI of the string');
is($data->md5_hex, 'ff6560652a8a8381c37d9864562cf9fc',
	'Checking MD5 of the string');


ok($data = $rayapp->load_string(''), 'Empty string');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($data->uri, 'md5:d41d8cd98f00b204e9800998ecf8427e',
	'Checking URI of the string');
is($data->md5_hex, 'd41d8cd98f00b204e9800998ecf8427e',
	'Checking MD5 of the string');


ok($data = $rayapp->load_string(undef), 'Undef string');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($data->uri, 'md5:d41d8cd98f00b204e9800998ecf8427e',
	'Checking URI of the string');
is($data->md5_hex, 'd41d8cd98f00b204e9800998ecf8427e',
	'Checking MD5 of the string');


is($data = $rayapp->load_uri('notexists.xml'), undef, 'Loading bad URI');
like($rayapp->errstr, qr/^File.*notexists\.xml.*does not exist$/,
	'Checking error message');


ok($data = $rayapp->load_uri('simple1.xml'), 'Load XML file as a plain URI');
is($rayapp->errstr, undef, 'Checking that there was no error');
is($data->md5_hex, 'a9eaba3064593944b9141aee064585cf',
	'Checking MD5 of the XML');


ok($data = $rayapp->load_xml('simple1.xml'), 'Load XML file');
is($rayapp->errstr, undef, 'Checking that there was no error');

is($data->md5_hex, 'a9eaba3064593944b9141aee064585cf',
	'Checking MD5 of the XML');
ok($data->xmldom, 'Checking that there is a XML DOM object');

my $root_element = $data->xmldom->documentElement if $data->xmldom;
isa_ok($root_element, 'XML::LibXML::Element',
	'Checking that the XML DOM has root element');

my $root_name = $root_element->nodeName if $root_element;
is($root_name, 'application',
	'Checking that the root element is application');

1;

