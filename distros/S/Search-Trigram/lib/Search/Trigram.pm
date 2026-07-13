package Search::Trigram;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Search::Trigram', $VERSION);

1;

__END__

=head1 NAME

Search::Trigram - Trigram inverted index search with Dice coefficient scoring

=head1 VERSION

Version 0.01

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

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
