use Test::More 0.88;
use Test::CheckDeps;

check_dependencies();

if (0) {
    BAIL_OUT("Missing dependencies") if !Test::More->builder->is_passing;
}

done_testing;

