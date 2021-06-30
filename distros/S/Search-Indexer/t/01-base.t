use utf8;
use Test2::V0;
use FindBin;
use Search::Indexer;

my ($docs, $tests) = do "$FindBin::Bin/data/base_texts_and_tests.pl";

# make sure we start with a fresh environment -- remove previous BerkeleyDB files
unlink foreach (<*.bdb>);

# create indexer with some example stopwords
my $ix = new Search::Indexer(writeMode    => 1,
                             ctxtNumChars => 40,
                             stopwords    => [qw(a i o or of it is and are my the)],
                           );

# index all documents
$ix->add($_, $docs->{$_}) foreach (keys %$docs);

# test the search() and excerpts() methods -- apply all queries from %$tsts
while (my ($query, $expected) = splice @$tests, 0, 2) {
  my $r = $ix->search($query);

  my %excerpts;
  foreach (keys %{$r->{scores}}) {
    $excerpts{$_} = $ix->excerpts($docs->{$_}, $r->{regex});
  }
  is(\%excerpts, $expected, $query);
}

# test the indexed_words_for_prefix() method
my $words_sa = $ix->indexed_words_for_prefix("sa");
is($words_sa, [qw(sagen sails salda sans sante say)], "words starting with 'sa'");

# remove a document
$ix->remove(1);
my $r = $ix->search("garrulous");
ok (! keys %{$r->{scores}}, "doc deleted");

# insert again so that the database is identical for next test 02-readonly.t
$ix->add(1, $docs->{1});

# that's the end
done_testing;



