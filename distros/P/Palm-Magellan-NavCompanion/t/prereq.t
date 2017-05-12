use Test::More;
eval "use Test::Prereq 1.00";
plan skip_all => "Test::Prereq 1.00 required for testing prereqs" if $@;
prereq_ok();
