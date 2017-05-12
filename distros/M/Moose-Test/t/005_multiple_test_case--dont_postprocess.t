#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;

BEGIN {
    use_ok('Moose::Test');
    use_ok('Moose::Test::Case');
}

my $test_case = Moose::Test::Case->new;
isa_ok($test_case, 'Moose::Test::Case');

isa_ok($test_case->test_dir, 'Path::Class::Dir');
is($test_case->test_dir->stringify, "$FindBin::Bin/005_multiple_test_case", '... got the path we expected');

is_deeply($test_case->pm_files, ['001_Foo.pm'], '... got the right pm file');
is_deeply($test_case->test_files, ['001_test_Foo.pl'], '... got the right test file');

lives_ok {
    $test_case->load_pm_files;
} '... loaded the PM files okay';

my @test_files = $test_case->prepare_test_files;
is(@test_files, 1, '.. got the right number of test files');

do $_ for @test_files;

