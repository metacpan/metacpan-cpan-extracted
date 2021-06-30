use utf8;
use Test2::V0;
use FindBin;
use Search::Indexer;

my ($docs, undef) = do "$FindBin::Bin/data/base_texts_and_tests.pl";

my $tests = [

 '"it is still"' =>		# a sequence of words
 {'1' => ['... Along the city streets <b>It is still</b> high tide, Yet the garr...'],
  '2' => []},  # wrong; indexer was fooled because 'it' and 'is' are stopwords

 '"occhi miei"' =>		# another sequence
 {'8'  => ['... Rendete agli <b>occhi miei</b>, o fonte, o fiume, L\'on...'],
  '11' => ['... Gli sguardi agli <b>occhi miei</b> tue luci sante, Ch\'io p...'],

  # normally document 9 should NOT match, but since we indexed
  # without positions, document 9 contains both words 'occhi' and 'miei'
  # (yet not contiguous). So there is a result, but with empty excerpts.
  '9' => []},
];


unlink foreach (<*.bdb>);	# remove previous index databases


# create indexer with some example stopwords
my $ix = new Search::Indexer(writeMode    =>  1,
                             ctxtNumChars => 40,
                             positions    =>  0,
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



# before removing a doc : make sure the result is there
my $r = $ix->search("contemple");
is(scalar(keys %{$r->{scores}}), 1,  "before remove");

# removing a doc
$ix->remove(17, $docs->{17});
$r = $ix->search("contemple");
is(scalar(keys %{$r->{scores}}), 0,  "after remove");

done_testing;

# remove index databases
unlink foreach (<*.bdb>);

