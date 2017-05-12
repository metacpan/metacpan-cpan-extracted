#!/usr/bin/perl -w
#
# test the SRS::EPP::Packets class

use 5.010;
use strict;
use Test::More qw(no_plan);
use FindBin qw($Bin);
use lib $Bin;
use Mock;

use t::Log4test;

# gah, this should really be split into its own distribution.
use_ok("SRS::EPP::Packets");

my $test_case = Mock::Session->new(pack("N",17+4), "U" x 17);

my $packeter = SRS::EPP::Packets->new(session => $test_case);
isa_ok($packeter, "SRS::EPP::Packets", "new Packets");

$packeter->input_event;
is(
	$test_case->{output}[0], undef,
	"single input event without data doesn't do too much"
);
$packeter->input_event;
is_deeply($test_case->{output}, [ "U" x 17 ], "unpacked a single packet");
shift @{$test_case->{output}};

srand 42;
my @test_packets = map { chr(rand(42)+ord("A")) x int(rand(37)) }
	1..27;
my $test_stream = join(
	"",
	map { pack("N", length($_)+4) . $_ }
		@test_packets,
);

while ( length $test_stream ) {
	my $frag = substr $test_stream, 0, rand(71), "";
	$packeter->input_event($frag);
}
is_deeply($test_case->{output}, \@test_packets, "input line discipline worked!");

# now do some tests with high-bit data

(my $test_file = $0) =~ s{\.t}{/example-stream.raw};
my $session = Mock::Session::FromFile->new($test_file);
$packeter = SRS::EPP::Packets->new(
	session => $session,
);

while ( !eof $session->{fh} ) {
	$packeter->input_event;
}

is(@{ $session->{output} }, 2, "got 2 packets out");
is(length($session->{output}[1]), 1247, "length in bytes");
use Encode;
my $utf_8 = decode("utf8", $session->{output}[1]);
is(length($utf_8), 1227, "length in characters");

# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>
