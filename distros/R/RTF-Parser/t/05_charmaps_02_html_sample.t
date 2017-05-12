#!/usr/bin/perl

use strict;
use warnings;

use RTF::TEXT::Converter;
use Test::More tests => 1;

my $data = join '', (<DATA>);
my $output;
my $object = RTF::TEXT::Converter->new( output => \$output );
$object->parse_string($data);

ok( ( $output =~ m/abc... def/ ),
    "ANSI file read properly, used as appropriate" );

__DATA__
{\rtf1\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fswiss\fcharset0 Arial;}}
\viewkind4\uc1\pard\ul\f0\fs20 abc\'85 def
}
