#!/usr/bin/perl

use strict;

use File::Spec;
use File::Basename;
use Test::More;

eval "use Test::CheckManifest tests => 2";
plan skip_all => "Test::CheckManifest required" if $@;

$Test::CheckManifest::HOME = '/tmp/' . $$ . '/test';

my $error;
local *Test::Builder::BAILOUT = sub {
    $error = 'BAILOUT';
};

my $success = ok_manifest({
    filter  => [qr/\.(git|build)/],
    exclude => ['/t/test'],
}, 'filter OR exclude');

is $error, 'BAILOUT';
is $success, undef;



