#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX qw(:sco bundle);
use STIX::Common::Hashes;


my $file = file(
    name   => 'gedit-bin',
    hashes => STIX::Common::Hashes->new(sha_256 => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f')
);

my $process = process(
    pid          => 1221,
    created_time => '2016-01-20T14:11:25',
    command_lime => './gedit-bin --new-window',
    image_ref    => $file
);

my $object = bundle(objects => [$file, $process]);

my @errors = $object->validate;

diag 'Basic Process', "\n", "$object";

isnt "$object", '';

is $object->type,               'bundle';
is $object->objects->[0]->type, 'file';
is $object->objects->[1]->type, 'process';

is @errors, 0;

done_testing();
