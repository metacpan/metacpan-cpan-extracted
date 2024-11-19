#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX qw(:sco bundle);
use STIX::Common::Hashes;


my $file = file(
    name   => 'sirvizio.exe',
    hashes => STIX::Common::Hashes->new(sha_256 => 'bf07a7fbb825fc0aae7bf4a1177b2b31fcf8a3feeaf7092761e18c859ee52a9c')
);

my $process = process(
    pid          => 2217,
    created_time => '2016-01-20T14:11:25',
    command_lime => 'C:\\Windows\\System32\\sirvizio.exe /s',
    image_ref    => $file,
    extensions   => [
        windows_service_ext(
            service_name   => 'sirvizio',
            display_name   => 'Sirvizio',
            start_type     => 'SERVICE_AUTO_START',
            service_type   => 'SERVICE_WIN32_OWN_PROCESS',
            service_status => 'SERVICE_RUNNING'
        )
    ]
);

my $object = bundle(objects => [$file, $process]);

my @errors = $object->validate;

diag 'Basic Windows Service', "\n", "$object";

isnt "$object", '';

is $object->type,               'bundle';
is $object->objects->[0]->type, 'file';
is $object->objects->[1]->type, 'process';

is @errors, 0;

done_testing();
