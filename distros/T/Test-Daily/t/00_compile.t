use strict;
use Test::More;

eval "use Test::Compile 0.08";
plan skip_all => "Test::Compile 0.08 required for testing compilation"
    if $@;

my @pmdirs = qw(lib blib sbin bin);
all_pm_files_ok(all_pm_files(@pmdirs));
