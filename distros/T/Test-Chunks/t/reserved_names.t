use Test::Chunks;

plan tests => 18;

for my $word (qw(
                 BEGIN
                 DESTROY
                 EXPORT
                 ISA
                 chunk_accessor
                 chunks_object
                 description
                 is_filtered
                 name
                 new
                 run_filters
                 seq_num
                 set_value
             )) {
    my $chunks = my_chunks($word);
    eval {$chunks->chunks};
    like($@, qr{'$word' is a reserved name}, "$word is a bad name");
}

for my $word (qw(
                 field
                 const
                 stub
                 super
             )) {
    my $chunks = my_chunks($word);
    my @chunks = $chunks->chunks;
    eval {$chunks->chunks};
    is("$@", '', "$word is a good name");
}

sub my_chunks {
    my $word = shift;
    Test::Chunks->new->spec_string(<<"...");
=== Fail test
--- $word
This is a test
--- foo
This is a test
...
}

my $chunks = Test::Chunks->new->spec_string(<<'...');
=== Fail test
--- bar
This is a test
--- foo
This is a test
...
eval {$chunks->chunks};
is("$@", '');
