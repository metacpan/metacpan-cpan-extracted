use Test::Chunks;

plan tests => 1 * chunks() + 1;

for (1..chunks) {
    ok(1, 'Jusk checking my chunking');
}

is(scalar(chunks), 2, 'correct number of chunks');

sub this_filter_fails {
    confess "Should never get here";
}

__DATA__
this
===
--- foo this_filter_fails
xxxx

===
--- foo this_filter_fails
yyyy
