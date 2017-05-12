#!/usr/bin/perl -w

use Test::More no_plan;
use strict;
BEGIN { use_ok("MooseX::Timestamp", qw(:all)); }

ok(defined &timestamp, "imported 'timestamp'");

is(timestamp(gmtime 1234567890),
   "2009-02-13 23:31:30",
   "timestamp(list)");

like(timestamp(1234567890),
     qr{2009-02-1[34] \d{2}:\d{2}:30},
     "timestamp(epoch)");

like(timestamp,
     qr{2\d{3}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}},
     "timestamp()");

use POSIX qw(strftime);
is(strftime("%I:%M:%S %d/%m/%y", posixtime "2007-12-06 23:15"),
   "11:15:00 06/12/07",
   "posixtime(Str)");

like(timestamp(posixtime),
     qr{2\d{3}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}},
     "posixtime()");

{
	package MyClass;
	use Moose;
	has 'stamp' =>
		(isa => "Timestamp",
		 is => "rw",
		 coerce => 1,
		);
}

my $obj = MyClass->new(stamp => "2007-01-02 12:00:12"); # ok
is($obj->stamp, "2007-01-02 12:00:12",
   "set value matching type constraint");

$obj->stamp("2007-01-02 12:01");
is($obj->stamp, "2007-01-02 12:01:00", "coerce from Str");

$obj->stamp("2007-01-02 12");
is($obj->stamp, "2007-01-02 12:00:00", "coerce from Str 2");

eval { $obj->stamp("2007-01-02 12:00:00Gibbons") };
isnt($@, "", "detected trailing Gibbons")
	or diag "interpreted as: ".$obj->stamp;

eval { $obj->stamp("2007-13-02 12:00:00") };
isnt($@, "", "detected invalid date")
	or diag "interpreted as: ".$obj->stamp;

eval { $obj->stamp("2007-02-29 12:00:00") };
isnt($@, "", "detected invalid date (29 feb 2007)")
	or diag "interpreted as: ".$obj->stamp;
eval { $obj->stamp("1900-02-29 12:00:00") };
isnt($@, "", "detected invalid date (29 feb 1900)")
	or diag "interpreted as: ".$obj->stamp;
eval { $obj->stamp("1904-02-29 12:00:00") };
is($@, "", "valid leap year (29 feb 1904)")
	or diag "interpreted as: ".$obj->stamp;
eval { $obj->stamp("2000-02-29 12:00:00") };
is($@, "", "valid leap year (29 feb 2000)")
	or diag "interpreted as: ".$obj->stamp;

eval { $obj->stamp("2007-12-02T12:00:00") };
is($obj->stamp, "2007-12-02 12:00:00",
   "ISO form with 'T'");

eval { $obj->stamp("2007-12-02Gibberish12:00:00") };
isnt($@, "", "Detecting embedded Gibberish");

$obj->stamp("2007-12-02T");
is($obj->stamp, "2007-12-02 00:00:00", "Date only");

