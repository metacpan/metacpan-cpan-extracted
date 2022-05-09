#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use Encode qw//;
use Test::More tests => 5;

use_ok('Octets::To::Unicode');

is decode( Encode::encode( "cp1251", "Привет!" ) ), "Привет!";
is decode( Encode::encode( "koi8-r", "Привет!" ) ), "Привет!";
is decode( Encode::encode( "utf-8",  "Привет!" ) ), "Привет!";
is decode("Привет!"), "Привет!";
