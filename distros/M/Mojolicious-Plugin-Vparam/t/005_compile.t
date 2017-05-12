use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More;
plan tests => 1;
use Test::Compile;

subtest 'Perl modules' => sub {
    all_pm_files_ok();
};
