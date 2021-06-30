use utf8;
use Test2::V0;
use FindBin;
use Search::Indexer;

my ($docs, $tests) = do "$FindBin::Bin/data/base_texts_and_tests.pl";

my $ix = new Search::Indexer(writeMode    => 0,
                             ctxtNumChars => 40,
                             # no need for stopwords -- they are already stored in the database
                           );

# test the search() and excerpts() methods -- apply all queries from %$tsts
while (my ($query, $expected) = splice @$tests, 0, 2) {
  my $r = $ix->search($query);

  my %excerpts;
  foreach (keys %{$r->{scores}}) {
    $excerpts{$_} = $ix->excerpts($docs->{$_}, $r->{regex});
  }
  is(\%excerpts, $expected, $query);
}

my $words_sa = $ix->indexed_words_for_prefix("sa");
is($words_sa, [qw(sagen sails salda sans sante say)], "words starting with 'sa'");

done_testing();
