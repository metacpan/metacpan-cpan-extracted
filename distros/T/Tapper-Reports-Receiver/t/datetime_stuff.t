#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use DateTime::Format::Natural;
use DateTime::Format::Mail;

plan tests => 7;

my $value = 'Wed, 06 Aug 2008 14:34:48 +0200';

#my $parser = new DateTime::Format::Natural;
my $parser = new DateTime::Format::Mail;
my $dt = $parser->parse_datetime( $value );
isa_ok( $dt, 'DateTime', "isa DateTime" );

is($dt->year, "2008", "it's 2008");
is($dt->day, "6", "it's 6th");
is($dt->month, "8", "it's august");
is($dt->hour, "14", "it's 14 o'clock");
is($dt->min, "34", "it's 20min after 10");
is($dt->sec, "48", "it's nearly the next minute");

#print STDERR "time string:    ". Dumper($value);
#print STDERR "parsed natural: ". Dumper($dt);
