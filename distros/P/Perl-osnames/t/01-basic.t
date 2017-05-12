#!perl

use Perl::osnames qw($data is_posix is_unix);
use Test::More 0.98;

subtest is_posix => sub {
    ok( is_posix('linux'));
    ok(!is_posix('MSWin32'));
    ok(!defined(is_posix('foo')));
};

subtest is_unix => sub {
    ok( is_unix('linux'));
    ok(!is_unix('MSWin32'));
    ok(!defined(is_unix('foo')));
};

done_testing;
