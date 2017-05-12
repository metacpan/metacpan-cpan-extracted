use Test::Chunks;

my $plan = 1 * chunks('foo') + 3;

plan tests => $plan;

is($plan, 5, 'Make sure plan adds up');

for my $chunk (chunks('foo')) {
    is($chunk->foo, exists($chunk->{bar}) ? $chunk->bar : 'no bar');
}

eval { chunks(foo => 'bar') };
like("$@", qr{^Invalid arguments passed to 'chunks'});

run_is foo => 'bar';

__DATA__

===
--- bar
excluded

===
--- foo
included
--- bar
included

===
--- foo chomp
no bar
