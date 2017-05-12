use Test::More  'no_plan';

eval ' use Test::MinimumVersion ';

my $version = v5.10;
my $args = { paths => [qw( ../t t  ../blib blib )] };


SKIP: {
	skip 'Test::MinimumVersion not installed', 1    if $@;
	all_minimum_version_ok($version,  $args  )
}

