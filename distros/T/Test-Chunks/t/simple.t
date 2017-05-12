use Test::Chunks;

plan tests => 1 * chunks;

# A silly test instead of pod2html
for my $chunk (chunks) {
    is(
        uc($chunk->pod),
        $chunk->upper,
        $chunk->name, 
    );
}

__END__
=== Header 1 Test
--- pod
=head1 The Main Event
--- upper
=HEAD1 THE MAIN EVENT
=== List Test
--- pod
=over
=item * one
=item * two
=back
--- upper
=OVER
=ITEM * ONE
=ITEM * TWO
=BACK
