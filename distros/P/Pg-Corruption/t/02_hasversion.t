use Test::More  'no_plan';

eval 'use Test::HasVersion';

SKIP: {
	skip 'Test::HasVersion not installed', 1        if $@;
	all_pm_version_ok( qw( ../blib blib) );
}
