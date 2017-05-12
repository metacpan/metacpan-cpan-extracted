# -*- mode: cperl; -*-
use Test::More;
eval "use App::scan_prereqs_cpanfile";

plan skip_all => "App::scan_prereqs_cpanfile required for testing module dependencies"
    if $@;

my $diff = `scan-prereqs-cpanfile --ignore=junk --diff cpanfile`;
ok !$diff;

done_testing;
