#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX ':sco';
use Time::Piece;


my $object = mutex(name => '__CLEANSWEEP__');

my @errors = $object->validate;

diag 'Malware mutex', "\n", "$object";

isnt "$object", '';

is $object->type, 'mutex';

is @errors, 0;

done_testing();
