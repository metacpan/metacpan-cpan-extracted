use strict;
use warnings;

use File::Object;
use NKC::Transform::MARC2RDA;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = NKC::Transform::MARC2RDA->new;
my $input = slurp($data_dir->file('cnb002955079.xml')->s);
my $ret = $obj->transform($input);
my $expected_string = slurp($data_dir->file('cnb002955079-expected.xml')->s);
is($ret, $expected_string, 'Compare transformed with expected (default).');
