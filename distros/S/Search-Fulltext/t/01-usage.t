use strict;
use warnings;
use utf8;
use Test::More;

use Search::Fulltext;
use Search::Fulltext::TestSupport;

plan tests => 3;

my $query = 'beer';
my @docs = (
    'I like beer the best',
    'Wine makes people saticefied',  # does not include beer
    'Beer makes people happy',
);

# Common usage
{
    my $fts = Search::Fulltext->new({
        docs => \@docs,
    });
    my $results = $fts->search($query);
    is_deeply($results, [0, 2]);
}

# Using index file on disk (when 'docs' is large)
# TODO: Large docs should not come with array. Rather (filepath0, filepath1, ...) is better.
{
    my $dbfile = Search::Fulltext::TestSupport::make_tmp_file;
    my $fts = Search::Fulltext->new({
        docs       => \@docs,
        index_file => $dbfile,
    });
    my $results = $fts->search($query);
    is_deeply($results, [0, 2]);
}

# Using non-default tokenizer
{
    my $dbfile = Search::Fulltext::TestSupport::make_tmp_file;
    my $fts = Search::Fulltext->new({
        docs      => \@docs,
        tokenizer => 'porter',
    });
    my $results = $fts->search($query);
    is_deeply($results, [0, 2]);
}
