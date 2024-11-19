#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX ':sco';
use Time::Piece;


my $object = software(
    name    => 'Word',
    cpe     => 'cpe:2.3:a:microsoft:word:2000:*:*:*:*:*:*:*',
    version => '2002',
    vendor  => 'microsoft'
);

my @errors = $object->validate;

diag 'Typical Software Instance', "\n", "$object";

isnt "$object", '';

is $object->type, 'software';

is @errors, 0;

done_testing();
