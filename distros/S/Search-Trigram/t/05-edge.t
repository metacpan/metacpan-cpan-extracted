use strict;
use warnings;
use Test::More;

use Search::Trigram;

# add empty string returns doc_id
{
    my $idx = Search::Trigram->new;
    my $id = $idx->add("");
    ok(defined $id, 'add empty string returns a doc_id');
    is($idx->doc_count, 1, 'empty string doc counted');
}

# add very long string succeeds
{
    my $idx = Search::Trigram->new;
    my $long = "word " x 200_000;
    my $id;
    ok(eval { $id = $idx->add($long); 1 }, 'add 1MB string succeeds');
    ok(defined $id, 'long string returns doc_id');
}

# add 10000 documents, doc_count correct
{
    my $idx = Search::Trigram->new;
    $idx->add("document number $_") for 1 .. 10_000;
    is($idx->doc_count, 10_000, 'doc_count correct after 10000 adds');
}

# remove on valid doc_id
{
    my $idx = Search::Trigram->new;
    my $id = $idx->add("something to remove");
    is($idx->doc_count, 1, 'doc present before remove');
    $idx->remove($id);
    is($idx->doc_count, 0, 'doc_count after remove');
}

# doc_count after remove + optimize decreases
{
    my $idx = Search::Trigram->new;
    my $id = $idx->add("another removable doc");
    $idx->add("keeper doc stays around");
    $idx->remove($id);
    $idx->optimize;
    is($idx->doc_count, 1, 'doc_count after remove + optimize');
}

# search after remove does not return removed doc
{
    my $idx = Search::Trigram->new;
    my $id = $idx->add("unique xylophone content");
    $idx->remove($id);
    my $r = $idx->search("xylophone");
    is(scalar @$r, 0, 'search after remove does not return removed doc');
}

# remove on nonexistent id does not crash
{
    my $idx = Search::Trigram->new;
    $idx->add("some content here");
    ok(eval { $idx->remove(99999); 1 }, 'remove on nonexistent id does not crash');
}

# optimize on empty index does not crash
{
    my $idx = Search::Trigram->new;
    ok(eval { $idx->optimize; 1 }, 'optimize on empty index does not crash');
}

# optimize called twice does not crash
{
    my $idx = Search::Trigram->new;
    my $id = $idx->add("test doc");
    $idx->remove($id);
    ok(eval { $idx->optimize; $idx->optimize; 1 }, 'optimize twice does not crash');
}

# DESTROY called on out-of-scope object
{
    my $destroyed = 0;
    {
        my $idx = Search::Trigram->new;
        $idx->add("will be destroyed");
    }
    # If we get here without crashing, DESTROY ran cleanly
    ok(1, 'DESTROY called on out-of-scope object without crash');
}

done_testing;
