use strict;
use warnings;
use Test::More;
use Module::Build::Prereqs::FromCPANfile;

if(!eval q{use Module::Build; 1}) {
    plan "skip_all", "Module::Build is not installed. Skip.";
    exit 0;
}

my %got = mb_prereqs_from_cpanfile(cpanfile => "t/merged.cpanfile");
is_deeply $got{requires}, {Runtime => "1.50"}, "at least runtime requires is supported with any MB version";

is Module::Build::Prereqs::FromCPANfile::_get_mb_version(), $Module::Build::VERSION, "MB version OK";

done_testing;

