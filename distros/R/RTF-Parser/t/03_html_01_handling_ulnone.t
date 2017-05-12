#!/usr/bin/perl

# \ulnone should be treated as \ul0
# So we're going to throw out a character property
# event as if it *were* \ul0... We'll test for this
# by looking for a<\u>b

use strict;
use warnings;

use Test::More tests => 1;
use RTF::HTML::Converter;

my $string;

my $object = RTF::HTML::Converter->new(

    output => \$string

);

$object->parse_string(
    q!{\rtf1\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fswiss\fcharset0 Arial;}}
\viewkind4\uc1\pard\ul\f0\fs20 a\ulnone b\par
}! );

ok( ( $string =~ m!a</u>b! ), '\ulnone treated like \ul0' );

