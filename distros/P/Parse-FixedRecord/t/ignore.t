#!/usr/bin/perl

use strict; use warnings;
use Test::More;

my @before_method_list;

{
    package Ignore::Test;
    use Parse::FixedRecord;

    @before_method_list = map { $_->name } __PACKAGE__->meta->get_all_methods;

    column first    => width => 4;
    pic    ' ';
    column middle   => width => 1;
    pic    ' ';
    column last     => width => 6;
    pic    ' | ';
    ignore 10;
    pic    ' | ';
    column duration => width => 5, isa =>'Duration';
}

my $test_data = 'Fred J Bloggs | 2009-03-17 | 02:03';
               #           1         2         3
               # 0123456789012345678901234567890123
               # 0..3
               #      5
               #        7...12
               #                 16......25
               #                              29.33

my $obj = Ignore::Test->parse( $test_data );
is_deeply(
    [ sort map { $_->name } $obj->meta->get_all_methods ],
    [ sort @before_method_list, qw(first middle last duration) ]
);

isa_ok $obj,           'Ignore::Test';
is $obj->first,        'Fred';
is $obj->middle,       'J';
is $obj->last,         'Bloggs';
isa_ok $obj->duration, 'DateTime::Duration';

is $obj->duration->in_units('minutes'), 123, 'Duration parsed ok';


is ''.$obj->duration, '02:03',       'Format duration';

my $expected = $test_data;

is $obj->output, $test_data, 'Round trip output (explicit picture)';
is ''.$obj,      $test_data, '... with overloading';

done_testing;
