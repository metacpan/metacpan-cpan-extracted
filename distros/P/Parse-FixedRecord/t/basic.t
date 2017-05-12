#!/usr/bin/perl

use strict; use warnings;
use Test::More;
use FindBin '$Bin';

use lib "$Bin/lib";
use Row::Test;

my $test_data = 'Fred J Bloggs | 2009-03-17 | 02:03';
               #           1         2         3
               # 0123456789012345678901234567890123
               # 0..3
               #      5
               #        7...12
               #                 16......25
               #                              29.33

my $obj = Row::Test->parse( $test_data );

my @fields = (qw/ first middle last date duration /);

can_ok 'Row::Test',              @fields;

isa_ok $obj,           'Row::Test';
is $obj->first,        'Fred';
is $obj->middle,       'J';
is $obj->last,         'Bloggs';
isa_ok $obj->date,     'DateTime';
isa_ok $obj->duration, 'DateTime::Duration';

is $obj->date->day, 17,                      'Day parsed ok';
is $obj->duration->in_units('minutes'), 123, 'Duration parsed ok';


is ''.$obj->date,     '2009-03-17',  'Format date';
is ''.$obj->duration, '02:03',       'Format duration';

my $expected = $test_data;

is $obj->output, $test_data, 'Round trip output (explicit picture)';
is ''.$obj,      $test_data, '... with overloading';

done_testing;
