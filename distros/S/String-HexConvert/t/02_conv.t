#!/usr/bin/perl


use lib '../lib';

use strict;
use warnings;



use Test::More tests => 2;


use String::HexConvert ':all';

is(ascii_to_hex("hello world"), "68656c6c6f20776f726c64", "ascii_to_hex");

is(hex_to_ascii("68656c6c6f20776f726c64"), "hello world", "hex_to_ascii");





