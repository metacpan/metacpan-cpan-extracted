#!/usr/bin/env perl

use 5.010;
use utf8;
use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::Exception;
use Test::MockObject;

use lib::relative '../lib';

use POE::Filter::SimpleXML;

my $filter = POE::Filter::SimpleXML->new;

subtest 'startup' => sub {
	plan 'tests' => 8;

	isa_ok($filter,           'POE::Filter::SimpleXML');
	isa_ok($filter->callback, 'CODE');
	isa_ok($filter->parser,   'XML::LibXML');

	is_deeply $filter->buffer, [], 'buffer is empty';
	is $filter->has_buffer, 0, 'buffer 0 length';

	$filter->get_one_start;

	is $filter->has_buffer, 0, 'buffer still 0 length';

	is_deeply $filter->get_one, [], 'nothing to get';

	is $filter->has_buffer, 0, 'buffer still 0 length, again';
};

subtest 'valid XML works' => sub {
	plan 'tests' => 4;

	$filter->get_one_start([ <<'EOT' ]);
<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
<command>
<check>
<domain:check
xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
<domain:name>example.com</domain:name>
<domain:name>example.net</domain:name>
<domain:name>example.org</domain:name>
</domain:check>
</check>
<clTRID>ABC-12345</clTRID>
</command>
</epp>
EOT

	is $filter->has_buffer, 1, 'got one buffer';

	my $out = $filter->get_one;

	is scalar @{$out}, 1, 'got one result';
	isa_ok $out->[0], 'XML::LibXML::Document';
	is $filter->has_buffer, 0, 'empty buffer now';
};

subtest 'invalid xml throws' => sub {
	plan 'tests' => 1;
	$filter->get_one_start([<<'EOT']);
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
EOT

	throws_ok { $filter->get_one } qr/Parsing error happened/oms;
};

subtest 'put' => sub {
	plan 'tests' => 2;

	is_deeply $filter->put([]), [], 'empty put';

	my $mockedxml = Test::MockObject->new;

	$mockedxml->mock('toString', sub { return 'got called' });

	is_deeply $filter->put([$mockedxml]), ['got called'], 'put with something';
};

1;
