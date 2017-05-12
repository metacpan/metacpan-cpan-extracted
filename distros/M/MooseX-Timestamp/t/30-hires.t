#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;

BEGIN{ use_ok("MooseX::Timestamp", ":all") }

like(timestamp(0.001),
     qr{\.001$},
     "timestamp(frac)");

BEGIN{ use_ok("MooseX::TimestampTZ", ":all", { hires => 1 }); }

my $ts;
my $hires_time = qr/\d+:\d+\.\d+/;

for (1..3) {
    $ts = timestamptz;
    last if $ts =~ m{$hires_time};
}

like( $ts, $hires_time, "Use MooseX::TimestampTZ with hires curry flag");

my ($zone) = timestamptz(10.123) =~ m{([\+-]\d+)$};
my ($zone2) = timestamptz(10) =~ m{([\+-]\d+)$};

is($zone, $zone2, "HiRes timestamts don't break the zone");

my ($sec) = posixtime("2007-12-02T00:00:00.123456");
is(0+$sec, 0.123456, "posixtime(HiRes Timestamp)");

{
	package MyClass;
	use Moose;
	has 'stamp' => (
		isa => "Timestamp",
		is => "rw",
		coerce => 1,
	       );
	has 'stamptz' => (
		isa => "TimestampTZ",
		is => "rw",
		coerce => 1,
	       );
}

my $obj = MyClass->new;
$obj->stamp("2007-12-02T00:00:00.123456");
is($obj->stamp, "2007-12-02 00:00:00.123456", "HiRes Stamp");

$obj->stamptz("2007-12-02T00:00:00.123456");
like($obj->stamptz, qr/00\.123456[+\-]\d+$/, "HiRes StampTZ");

