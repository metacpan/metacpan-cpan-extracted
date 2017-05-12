use Test::Chunks;

plan tests => 7;

eval {
filters_map {
    perl => ['eval'],
    text => ['chomp', 'lines', 'array'],
};
};
like($@, qr{Can't locate object method "filters_map"});

filters {
    perl => ['eval'],
    text => ['chomp', 'lines', 'array'],
};

run {
    my $chunk = shift;
    is(ref($chunk->perl), 'ARRAY');
    is(ref($chunk->text), 'ARRAY');
    is_deeply($chunk->perl, $chunk->text);
};

__DATA__
=== One
--- perl
[
    "One\n",
    "2nd line\n",
    "\n",
    "Third time's a charm",
]
--- text
One
2nd line

Third time's a charm
=== Two
--- text
tic tac toe
--- perl
[ 'tic tac toe' ]

