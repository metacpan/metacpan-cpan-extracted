#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {chdir 't' if -d 't'}
use lib '../lib';

use Module::Metadata::Changes;

# ----------------------------

my($config) = Module::Metadata::Changes -> new(verbose => 0);

is(-e './Non.standard.name', 1, './Non.standard.name file exists before conversion');

# Override the default file name (Changes) to be converted:
# Convert ./Non.standard.name to ./Changelog.ini.

$config -> inFileName('./Non.standard.name');
$config -> convert(1);

my($result) = $config -> run;

is(-e './Changelog.ini', 1, './Changelog.ini exists after conversion');

my($release) = $config -> get_latest_release();
my($expect)  = '4.30';

is($config -> get_latest_version(), $expect, "Version of latest revision is $expect");

$expect = '2008-04-25T00:00:00';

is($$release{'Date'}, $expect, "Date of latest revision is $expect");

done_testing();
