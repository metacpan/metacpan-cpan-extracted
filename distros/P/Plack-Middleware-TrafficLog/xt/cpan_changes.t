#!/usr/bin/perl

use Test::More;
eval "use Test::CPAN::Changes;";
plan skip_all => "Test::CPAN::Changes required for testing" if $@;
changes_file_ok();
done_testing();
