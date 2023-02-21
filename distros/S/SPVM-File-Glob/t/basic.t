use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'File::Glob';
use SPVM 'TestCase::File::Glob';

my $test_dir = "$FindBin::Bin/ftest";

ok(SPVM::TestCase::File::Glob->test);

is_deeply(SPVM::File::Glob->glob("$test_dir/foo.txt")->to_strings, [glob("$test_dir/foo.txt")]);

is_deeply(SPVM::File::Glob->glob("$test_dir/foo")->to_strings, [glob("$test_dir/foo")]);

is_deeply(SPVM::File::Glob->glob("$test_dir/?oo")->to_strings, [glob("$test_dir/?oo")]);

is_deeply(SPVM::File::Glob->glob("$test_dir/foo*")->to_strings, [glob("$test_dir/foo*")]);

is_deeply(SPVM::File::Glob->glob("$test_dir/*")->to_strings, [glob("$test_dir/*")]);

done_testing;
