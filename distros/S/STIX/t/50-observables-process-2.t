#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX qw(:sco);


my $object = process(
    pid          => 314,
    created_time => '2016-01-20T14:11:25',
    extensions   => [
        windows_process_ext(
            aslr_enabled => !!1,
            dep_enabled  => !!1,
            priority     => 'HIGH_PRIORITY_CLASS',
            owner_sid    => 'S-1-5-21-186985262-1144665072-74031268-1309',
        )
    ]
);

my @errors = $object->validate;

diag 'Basic Windows Process', "\n", "$object";

isnt "$object", '';

is $object->type, 'process';

is @errors, 0;

done_testing();
