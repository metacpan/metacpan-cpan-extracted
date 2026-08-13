package Search::Trigram;

use strict;
use warnings;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Search::Trigram', $VERSION);

1;

__END__

=head1 NAME

Search::Trigram - Trigram inverted index search with Dice coefficient scoring

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Search::Trigram;

    my $idx = Search::Trigram->new;

    my $id1 = $idx->add("The quick brown fox jumps over the lazy dog");
    my $id2 = $idx->add("Pack my box with five dozen liquor jugs");
    my $id3 = $idx->add("How vexingly quick daft zebras jump");

    my $results = $idx->search("quick fox", 5);
    for my $r (@$results) {
        printf "score=%.3f  %s\n", $r->{score}, $r->{text};
    }

    $idx->remove($id2);
    $idx->optimize;

    printf "docs=%d  trigrams=%d\n", $idx->doc_count, $idx->trigram_count;

=head1 METHODS

=head2 new

    my $idx = Search::Trigram->new;

=head2 add

    my $doc_id = $idx->add($text);

Index a document. Returns an unsigned integer doc_id. Accepts UTF-8 text.

=head2 search

    my $results = $idx->search($query);
    my $results = $idx->search($query, $limit);

Returns an arrayref of hashrefs C<{ doc_id, score, text }> sorted by score
descending. Default limit is 10. Scoring uses the Dice coefficient over
shared trigrams (case-insensitive, byte-level UTF-8).

=head2 remove

    $idx->remove($doc_id);

Mark a document deleted. Takes effect on next C<optimize>.

=head2 optimize

    $idx->optimize;

Compact posting lists and remove deleted documents.

=head2 clear

    $idx->clear;

Remove all documents and reset the index.

=head2 doc_count

    my $n = $idx->doc_count;

Number of live (non-deleted) documents.

=head2 trigram_count

    my $n = $idx->trigram_count;

Number of distinct trigrams in the index.

=head1 C ABI

An XS module can index and query without a Perl frame in between.
F<include/sg_abi.h> declares a function-pointer table with five entries:

=over 4

=item * C<index_of> - the opaque index behind a blessed Search::Trigram
object. Returns C<NULL> for anything that is not one rather than
dereferencing whatever it was handed, so it is safe to probe with on a
fall-back path.

=item * C<add> - index a document, returning its id. The text is copied,
so the caller may free or reuse its buffer immediately.

=item * C<optimize> - compact the postings after a batch of adds.

=item * C<doc_count>

=item * C<search> - writes at most C<max_hits> C<sg_abi_hit> structs into
an array the caller supplies, and returns how many it wrote. Passing a
stack array is the expected use.

=back

The table is resolved at runtime through C<Search::Trigram::_abi_ptr> and
gated on its C<abi_version>, so there is no link-time coupling and the two
distributions upgrade independently; entries are only ever appended.
C<_abi_ptr> hands the address back as an unsigned integer, so read it with
C<SvUV> and not C<SvIV>: where the loader maps this object decides whether
the top bit is set, and it is on a 32-bit perl above C<0x7fffffff> or on
illumos, which puts shared objects up at C<0xfffffd7f...>.
Reach the header with L<ExtUtils::Depends>:

    my $pkg = ExtUtils::Depends->new('My::Module', 'Search::Trigram');

Two things about that table are deliberate and worth knowing.

C<search> writes into your array rather than handing back the allocated
result block L</search>'s own C layer pairs with a free function. Pairing
a malloc in one shared object with a free in another is a good way to
find out that each can carry its own heap, so both halves stay on the
provider's side.

There is no constructor or destructor. A consumer that allocated an index
through the table would have to release it through the table too, with
the same hazard; let the Perl object own the lifetime, since it already
does that correctly. Hold a reference to the B<object> and call
C<index_of> on it.

Only C<index_of> takes C<pTHX_>. The rest never touches an SV, and
threading the interpreter through calls that have no use for it would be
cargo cult.

The C<text> pointer on a hit is borrowed from the index and is
invalidated by the next mutation of it. Copy it if you intend to keep it.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
