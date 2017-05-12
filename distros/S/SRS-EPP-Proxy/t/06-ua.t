#!/usr/bin/perl -w
#
# test the SRS::EPP::Proxy::UA class

use strict;
use HTTP::Request::Common qw(GET);
use Time::HiRes qw(sleep);

use t::Log4test;

our $tests = 0;
our $pid = $$;
our $all_ok = 1;

END {
	print "1..$tests\n" if $pid == $$;
}

sub ok($;$) {
	my $test = shift;
	my $name = shift;
	unless ($test) {
		print "not ";
		$all_ok = 0;
	}
	print "ok ".(++$tests);
	if ($name) {
		print " - $name";
	}
	print "\n";
	return !!$test;
}

sub diag {
	while ( my $x = shift ) {
		$x =~ s{^}{# }gm;
		print STDERR "$x\n";
	}
}

ok(
	eval "use SRS::EPP::Proxy::UA; 1",
	"use SRS::EPP::Proxy::UA"
	)
	or do {
	diag("got error: $@");
	};

my $ua = SRS::EPP::Proxy::UA->new;
ok($ua && $ua->isa("SRS::EPP::Proxy::UA"), "made new UA");

ok($ua->state eq "waiting", "initial state");

my $request = GET("http://localhost/robots.txt");
$ua->request($request);
ok($ua->state eq "busy", "request transitions into busy state");
my $c;
do {
	sleep 0.2;
} until (++$c > 15 or $ua->ready);
my $response = $ua->get_response;

ok(
	$response && $response->isa("HTTP::Response"),
	"got a response"
);

exit(0);

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

