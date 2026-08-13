#!perl

# The shared C ABI (include/sg_abi.h), resolved at runtime through
# Search::Trigram::_abi_ptr. Consumers such as Punk's markdown mount fetch
# that pointer once at boot, gate on abi_version, and then search with no Perl
# frame in between.
#
# There is no second distribution here to consume it, so the coverage comes
# from _abi_selftest, which drives the table the way a consumer would: resolve
# the pointer, check the version, then go through the function pointers rather
# than calling the C directly. If the table is mis-ordered or an entry is
# wired to the wrong function, these fail.

use 5.010;
use strict;
use warnings;
use Test::More;
use Search::Trigram;

# ---- the pointer and the gate -----------------------------------------------

# Unsigned: the address is whatever the loader picked, and on a 32-bit perl
# or on illumos (shared objects up at 0xfffffd7f...) the top bit is set. The
# only thing that makes an address unusable here is being zero.
my $ptr = Search::Trigram::_abi_ptr();
ok defined $ptr, '_abi_ptr returns something';
ok $ptr != 0, 'and it is a usable address';
ok $ptr !~ /^-/, 'handed back unsigned, whatever the sign bit says';
is Search::Trigram::_abi_version(), 1, 'compiled against ABI version 1';
is Search::Trigram::_abi_ptr(), $ptr,
    'the table is a fixed address, not rebuilt per call';

# ---- index_of / add / optimize / doc_count ----------------------------------

my @DOCS = (
    'the quick brown fox jumps over the lazy dog',
    'markdown rendering engine written in c',
    'perl xs extension building notes',
    'quick start guide for markdown authors',
);

my $idx = Search::Trigram->new;

{
    my @ids = map { Search::Trigram::_abi_selftest_add($idx, $_) } @DOCS;
    is scalar @ids, scalar @DOCS, 'add returned an id per document';
    is_deeply [ sort { $a <=> $b } @ids ], [ 0 .. $#DOCS ],
        'ids are the sequence the index assigns';

    is Search::Trigram::_abi_selftest_doc_count($idx), scalar @DOCS,
        'doc_count through the table agrees with what was added';
    is $idx->doc_count, scalar @DOCS,
        'and with the Perl-visible method, so both see one index';
}

# ---- search -----------------------------------------------------------------

{
    my @hits = Search::Trigram::_abi_selftest($idx, 'markdown', 10);
    ok scalar @hits >= 2, 'search found the markdown documents';

    for my $h (@hits) {
        ok exists $h->{doc_id}, 'hit carries a doc_id';
        ok exists $h->{score},  'and a score';
        ok exists $h->{text},   'and the indexed text';
        last;   # shape is uniform; one is enough
    }

    # The top hit should be one of the two documents that actually say
    # "markdown", not the one that merely shares trigrams with it.
    my %by_id = map { $_ => $DOCS[$_] } 0 .. $#DOCS;
    like $by_id{ $hits[0]{doc_id} }, qr/markdown/,
        'the best-scoring hit is a document containing the term';

    ok $hits[0]{score} >= $hits[-1]{score},
        'hits come back in descending score order';
}

{
    my @hits = Search::Trigram::_abi_selftest($idx, 'quick', 10);
    my @texts = map { $_->{text} } @hits;
    ok scalar( grep { /quick/ } @texts ) >= 2,
        'a second query matches its own documents';
}

{
    my @hits = Search::Trigram::_abi_selftest($idx, 'zzzznowhere', 10);
    is scalar @hits, 0, 'a query matching nothing returns no hits';
}

# ---- the limit is honoured --------------------------------------------------

{
    my @hits = Search::Trigram::_abi_selftest($idx, 'markdown', 1);
    is scalar @hits, 1, 'the limit caps the number of hits returned';
}

# ---- index_of rejects a non-index without croaking --------------------------

{
    # A consumer probing whether an SV is a usable index must be able to ask
    # without an eval, so index_of returns NULL rather than dereferencing
    # whatever it was handed, and the selftest reports that as an empty list.
    my @out = eval { Search::Trigram::_abi_selftest(bless({}, 'Not::An::Index'), 'x') };
    is $@, '', 'probing a foreign object does not croak';
    is scalar @out, 0, 'and yields nothing, which is the fall-back signal';

    @out = eval { Search::Trigram::_abi_selftest(\'plain ref', 'x') };
    is $@, '', 'nor does a plain reference';
    is scalar @out, 0, 'also nothing';

    @out = eval { Search::Trigram::_abi_selftest('not a ref', 'x') };
    is $@, '', 'nor does a string';
    is scalar @out, 0, 'also nothing';
}

# ---- the text pointer survives the result free -------------------------------

{
    # search copies hits into the caller's array and frees the provider-side
    # result allocation before returning; the text pointers it copies out are
    # borrowed from the index, not from that array, so they must still read
    # correctly afterwards.
    my @hits = Search::Trigram::_abi_selftest($idx, 'markdown', 10);
    for my $h (@hits) {
        ok length $h->{text}, 'hit text is non-empty after the results were freed';
        ok scalar( grep { $_ eq $h->{text} } @DOCS ),
            'and matches a document that was indexed';
    }
}

# ---- unicode ----------------------------------------------------------------

{
    my $u = Search::Trigram->new;
    Search::Trigram::_abi_selftest_add($u, "caf\x{e9} r\x{e9}sum\x{e9} notes");
    Search::Trigram::_abi_selftest_add($u, 'plain ascii document');
    my @hits = Search::Trigram::_abi_selftest($u, "caf\x{e9}", 5);
    ok scalar @hits, 'a non-ASCII query finds its document';
    like $hits[0]{text}, qr/caf\x{e9}/, 'and the text comes back as characters';
}

done_testing();
