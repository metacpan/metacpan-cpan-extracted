#!/usr/bin/env perl

use 5.010;
use utf8;
use strict;
use warnings;

use Test::More 'tests' => 8;
use Test::LongString qw(is_string);

use lib::relative '../lib';

use POE::Filter::EPPTCP;

my $filter = POE::Filter::EPPTCP->new;

sub make_length {
	my $str = shift;
	return pack 'N', 4 + length $str;
}

isa_ok($filter, 'POE::Filter::EPPTCP');

is_deeply $filter->buffer, [], 'buffer is empty';
is $filter->has_buffer, 0, 'buffer 0 length';

my @list = ('badaboum', 'bom bom bom bom', "some long string with multiple lines\n" x 10, 'and a short one to end', <<'EOT');
<?xml version="1.0" encoding="UTF-8"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
  | <login>
  | ¦ <clID>abso-info</clID>
  | </login>
  | <clTRID>test-27670-170-1</clTRID>
  </command>
</epp>
EOT

subtest 'get_one_start / get_one, one complete str at a time' => sub {
	plan 'tests' => 6;

	$filter->get_one_start;

	is $filter->has_buffer, 0, 'buffer still 0 length';

	is_deeply $filter->get_one, [], 'nothing to get';

	is $filter->has_buffer, 0, 'buffer still 0 length, again';

	subtest 'fill buffer' => sub {

		plan 'tests' => scalar @list;

		my $buffer_length = 0;

		for my $str (@list) {
			my $header = make_length($str);

			$filter->get_one_start([ $header . $str ]);

			$buffer_length++;

			is_string $filter->has_buffer, $buffer_length, "buffer now has $buffer_length";
		} ## end for my $str (@list)
	};

	my $ret = $filter->get_one;

	subtest 'empty buffer' => sub {
		plan 'tests' => 1 + scalar @list;

		is scalar @{$ret}, scalar @list, 'got four entry';

		my $buffer_length = 0;
		for my $str (@list) {
			is_string $ret->[$buffer_length], $str, "got the entry $buffer_length in order";
			$buffer_length++;
		}
	};

	is $filter->has_buffer, 0, 'buffer empty';
};

subtest 'get_one_start/get_one with many strings as one' => sub {
	plan tests => 1 + scalar @list;

	$filter->get_one_start([ join q{}, map { make_length($_) . $_ } @list ]);

	my $ret = $filter->get_one;
	is scalar @{$ret}, scalar @list, 'got one entry';

	my $buffer_length = 0;

	for my $str (@list) {
		is_string $ret->[$buffer_length], $str, "got the entry $buffer_length in order";
		$buffer_length++;
	}
};

subtest 'get_one_start/get_one with many strings as one but madly splitted' => sub {
	plan tests => 1 + scalar @list;

	$filter->get_one_start([ split /(.{3})/oms, join q{}, map { make_length($_) . $_ } @list ]);

	my $ret = $filter->get_one;
	is scalar @{$ret}, scalar @list, 'got one entry';

	my $buffer_length = 0;

	for my $str (@list) {
		is_string $ret->[$buffer_length], $str, "got the entry $buffer_length in order";
		$buffer_length++;
	}
};

subtest 'partial buffer when get_one' => sub {
	my $str = "some long string with multiple lines\n" x 5;

	my $header = make_length($str);

	my @entries = split /(.{20})/oms, $header . $str;

	plan 'tests' => scalar @entries;

	my $last = pop @entries;

	for my $line (@entries) {
		$filter->get_one_start([$line]);

		is_deeply $filter->get_one, [], 'still filling up the buffer, no entry';
	}

	$filter->get_one_start([$last]);

	my $ret = $filter->get_one;

	is_string $ret->[0], $str, 'got the correct string in the end';
};

subtest 'put' => sub {
	plan 'tests' => 1 + 4 * scalar @list;

	is_deeply $filter->put([]), [], 'empty put';

	for my $str (@list) {

		my $out = $filter->put([$str]);

		my $length = 4 + length $str;

		is scalar @{$out}, 1, 'one result';
		is length($out->[0]), $length, "output length ok, $length";
		is substr($out->[0], 0, 4), pack('N', $length), "packed length ok, $length";
		is substr($out->[0], 4), $str, 'content ok';
	} ## end for my $str (@list)
};

1;
