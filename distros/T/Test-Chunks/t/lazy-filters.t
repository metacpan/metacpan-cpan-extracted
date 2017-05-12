use Test::Chunks;

plan tests => 2;

sub shouldnt_be_run {
    fail("shouldnt_be_run was run");
}

run_is foo => 'bar';

my ($chunk) = chunks;
is($chunk->foo, "1234");

__DATA__
===
--- foo shouldnt_be_run
--- bar



===
--- ONLY
--- foo chomp
1234
--- bar chomp
1234
