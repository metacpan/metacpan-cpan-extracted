#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX ':sco';
use Time::Piece;


my $object = url(value => 'https://example.com/research/index.html');

my @errors = $object->validate;

diag 'Typical URL', "\n", "$object";

isnt "$object", '';

is $object->type, 'url';

is @errors, 0;

done_testing();
