#!perl

use Test::More;

plan skip_all => "MSWin32 not supported" if $^O eq 'MSWin32';

(eval 'use Test::CPAN::Changes; 1' and $ENV{RELEASE_TESTING}) or
    plan skip_all => 'author test';
changes_file_ok("Changes");
done_testing;
