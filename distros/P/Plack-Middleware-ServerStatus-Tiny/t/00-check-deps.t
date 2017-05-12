use Test::More 0.94;
use Test::CheckDeps 0.004;

check_dependencies('suggests');

if (1) {
    BAIL_OUT("Missing dependencies") if !Test::More->builder->is_passing;
}

done_testing;

