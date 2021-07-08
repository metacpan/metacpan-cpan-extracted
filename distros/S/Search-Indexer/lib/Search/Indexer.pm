package Search::Indexer;
use strict;
use warnings;
use Carp;
use BerkeleyDB;
use Search::QueryParser;
use List::Util                      qw/min sum/;
use List::MoreUtils                 qw/all uniq/;
use Text::Transliterator::Unaccent;

our $VERSION = "1.01";

#======================================================================
# CONSTANTS AND GLOBAL VARS
#======================================================================

use constant unaccenter => Text::Transliterator::Unaccent->new(upper => 0);
use constant {

  # encodings for pack/unpack
  IXDPACK     => 'ww',       # ixd values : pairs (compressed int, nb_occur)
  IXDPACK_L   => '(ww)*',    # list of above
  IXPPACK     => 'w*',       # word positions : list of compressed ints
  IXPKEYPACK  => 'ww',       # key for ixp : (docId, wordId)
  GLOBSTATPACK=> 'ww',       # global stats : (total nb of docs, total nb of words)

  WRITECACHESIZE => (1 << 24), # arbitrary big value; seems good enough but may need tuning

  # default values for args to new()
  DEFAULT     => {
    writeMode => 0,
    positions => 1,
    wregex    => qr/\p{Word}+/,
    wfilter   => (   # if possible ($] >= 5.016) : normalize through foldcase
                     eval q{sub {my $word = CORE::fc($_[0]); unaccenter->($word); return $word}}
                  || # otherwise : normalize through lowercase
                     sub {my $word = lc($_[0]); unaccenter->($word); return $word}),
    fieldname => '',

    # default constants for generating excerpts
    ctxtNumChars => 35,
    maxExcerpts  => 5,
    preMatch     => "<b>",
    postMatch    => "</b>",

    # default constants for computing BM25 relevance.
    # See https://en.wikipedia.org/wiki/Okapi_BM25.
    # ElasticSearch and Sqlite FTS5 use the same values
    bm25_k1      => 1.2,
    bm25_b       => 0.75,
  }
};


#======================================================================
# CLASS METHODS
#======================================================================

# constructor
sub new {
  my $class = shift;

  # options can be supplied either as a hashref or a plain hash
  my $args = ref $_[0] eq 'HASH' ? $_[0] : {@_};

  # parse options
  my $self = bless {}, $class;
  $self->{$_} = exists $args->{$_} ? delete $args->{$_} : DEFAULT->{$_} 
    foreach keys %{ DEFAULT() };
  my $dir = delete $args->{dir} || ".";
  $dir =~ s{[/\\]$}{};          # remove trailing slash
  my $stopwords = delete $args->{stopwords};

  # complain if we found invalid options
  my @remaining = keys %$args;
  croak "unexpected option : $remaining[0]" if @remaining;

  # remember if this is a fresh database
  my $is_fresh_db = ! -e "$dir/ixp.bdb";

  # utility sub to connect to one of the databases
  my $tie_db = sub {
    my ($db_name, $db_kind) = @_;
    my $db_file = "$dir/$db_name.bdb";
    my @args = ( -Filename => $db_file,
                 (-Flags => ($self->{writeMode} ? DB_CREATE : DB_RDONLY)),
                 ($self->{writeMode} ? (-Cachesize => WRITECACHESIZE) : ()) );

    # for example for 'ixw', store the DB handle under ->{ixwDb} and the tied hash under ->{ixw}
    $self->{$db_name . 'Db'} =
      $db_kind eq 'Recno' ? tie @{$self->{$db_name}}, "BerkeleyDB::$db_kind", @args
                          : tie %{$self->{$db_name}}, "BerkeleyDB::$db_kind", @args
      or croak "open $db_file : $! $^E $BerkeleyDB::Error";
  };

  # open the three databases
  $tie_db->(ixw => 'Btree'); # of shape word   => wordId (or -1 for stopwords)
  $tie_db->(ixd => 'Recno'); # of shape wordId => list of (docId, nOccur)
  $tie_db->(ixp => 'Btree'); # of shape (packed pair of ints) => data, namely:
  #    (0, 0)          => (total nb of docs, average word count per doc)
  #    (0, docId)      => nb of words in docId
  #    (1, 0)          => flag to store the value of $self->{positions}
  #    (docId, wordId) => list of positions of word in doc -- only if $self->{positions}
  # NOTE : the utility method $self->(x, y) can be used to read/write with pairs of ints


  # an optional list of stopwords may be given as a list or as a filename
  if ($stopwords) {
    $self->{writeMode} or croak "must be in writeMode to specify stopwords";

    # if scalar, this is treated as the name of the stopwords file => read it
    if (not ref $stopwords) { 
      my $fh;
      open $fh, "<", $stopwords or
        open $fh, "<", "$dir/$stopwords" or
          croak "can't open stopwords file $stopwords : $^E ";
      local $/ = undef;
      my $buf = <$fh>;
      close $buf;
      $stopwords = [$buf =~ /$self->{wregex}/g];
    }

    # store stopwords in ixw, marked with wordId value = -1
    foreach my $word (@$stopwords) {
      $self->{ixw}{$word} = -1;
    }
  }

  if ($is_fresh_db) {
    if ($self->{positions}) {
      # mark under ixp(1, 0) that we are using positions
      $self->ixp(1, 0) = 1;
    }
  }

  else {
    # must know if this DB used word positions or not when it was created
    my $has_positions = $self->ixp(1, 0);

    croak "can't require 'positions => 1' after index creation time"
      if $self->{writeMode} && $self->{positions} && !$has_positions;

    # flag $self->{positions} indicates what was found in the DB
    $self->{positions} = $has_positions;
  }

  return $self;
}


sub has_index_in_dir {
  my ($class, $dir) = @_;
  return all {-f "$dir/$_.bdb"} qw/ixw ixd ixp/;
}

#======================================================================
# BUILDING THE INDEX
#======================================================================


sub add {
  my $self = shift;
  my $docId = shift;
  # my $buf = shift; # using $_[0] instead for avoiding a copy

  my %positions;
  my $word_position = 1;
  my $next_wordId   = $self->{ixdDb}->FETCHSIZE + 1;
  my $nb_words      = 0;

  # extract words from the $_[0] buffer
 WORD:
  while ($_[0] =~ /$self->{wregex}/g) {
    my $word = $self->{wfilter} ? $self->{wfilter}->($&) : $&
      or next WORD;

    # get the wordId for this word, or create a new one. If -1, this is a stopword
    my $wordId = $self->{ixw}{$word} ||= $next_wordId++;

    if ($wordId > 0) { # if it's not a stopword ...
      # record the position of this word
      push @{$positions{$wordId}}, $word_position;

      # increment the word counter
      $nb_words      += 1;
    }

    # increment the position, no matter if it's a stopword or not
    $word_position += 1;

  }

  # record nb of words in this document -- under pair (0, $docId) in ixp
  croak "docId $docId is already used" if defined $self->ixp(0, $docId);
  $self->ixp(0, $docId) = $word_position;

  # open a cursor for more efficient write into ixd
  my $c = $self->{ixdDb}->db_cursor;

  # insert words into the indices
  foreach my $wordId (keys %positions) { 

    # prepare data for inserting this doc into the ixd list for $wordId
    my $n_occur     = @{$positions{$wordId}};
    my $to_be_added = pack(IXDPACK, $docId, $n_occur);
    my ($k, $v)     = ($wordId, undef);

    # either update or insert
    my $status = $c->c_get($k, $v, DB_SET);
    if ($status == 0) {
      # this $wordId already has a list of docs. Let's append to that list
      my $current_length = length($v);
      $c->partial_set($current_length, length($to_be_added)); # next put() will be at end of string
      $status = $c->c_put($k, $to_be_added, DB_CURRENT);
      warn "add() : c_put error: $status\n" if $status > 0;
      $c->partial_clear;
    }
    else {
      # create a new entry for this $wordId
      $status = $self->{ixdDb}->db_put($k, $to_be_added);
      warn "add() : db_put error: $status\n" if $status > 0;
    }

    # insert the word positions into ixp
    if ($self->{positions}) {
      $self->ixp($docId, $wordId) = pack(IXPPACK, @{$positions{$wordId}});
    }
  }

  # take this new doc into account in the global stats
  $self->update_global_stats(+1, +$nb_words);
}


sub update_global_stats {
  my ($self, $delta_docs, $delta_words) = @_;

  my $current_stats                = $self->ixp(0, 0);
  my ($nb_tot_docs, $nb_tot_words) = $current_stats ? unpack GLOBSTATPACK, $current_stats : (0,0);
  $nb_tot_docs                    += $delta_docs;
  $nb_tot_words                   += $delta_words;
  $self->ixp(0, 0)                 = pack GLOBSTATPACK, $nb_tot_docs, $nb_tot_words;
}



sub remove {
  my $self = shift;
  my $docId = shift;
  # my $buf = shift; # using $_[0] instead for avoiding a copy

  # retrieve or recompute the word ids
  my $n_occur_per_word;
  if ($self->{positions}) {
    # we can know the list of wordIds from the positions database
    not defined $_[0] or carp "remove() : unexpected 'buf' argument";
    $n_occur_per_word = $self->wordIds_in_doc($docId);
  }
  else {
    # the only way to know the list of wordIds is to tokenize again the buffer
    defined $_[0] or carp "->remove(\$docId, \$buf) : missing \$buf argument";

  WORD:
    while ($_[0] =~ /$self->{wregex}/g) {
      my $word   = $self->{wfilter} ? $self->{wfilter}->($&) : $&  or next WORD;
      my $wordId = $self->{ixw}{$word}                             or next WORD;
      if ($wordId > 0) {
        $n_occur_per_word->{$wordId} += 1;
      }
    }
  }

  # remove from the document index and positions index
  foreach my $wordId (keys %$n_occur_per_word) {
    my %docs = unpack IXDPACK_L, $self->{ixd}[$wordId];
    delete $docs{$docId};
    $self->{ixd}[$wordId] = pack IXDPACK_L, %docs;
    if ($self->{positions}) {
      my $k = pack IXPKEYPACK, $docId, $wordId;
      delete $self->{ixp}{$k};
    }
  }

  # remove nb of words from $self->{ixp}
  my $k = pack IXPKEYPACK, 0, $docId;
  delete $self->{ixp}{$k};

  # adjust global stats
  my $nb_words = sum values %$n_occur_per_word;
  $self->update_global_stats(-1, -$nb_words);
}



#======================================================================
# SEARCH THE INDEX
#======================================================================


sub search { # front-end entry point
  my $self = shift;
  my $query_string = shift;
  my $implicitPlus = shift;

  # parse the query string
  $self->{qp} ||= new Search::QueryParser;
  my $q = $self->{qp}->parse($query_string, $implicitPlus);

  # translate the query structure
  my ($translated_query, $killedWords, $wordsRegexes) = $self->translateQuery($q);

  # regex that will be used for highlighting excerpts
  my $strRegex = "(?:" . join("|", uniq @$wordsRegexes) . ")";

  # return structure
  return { scores      => $self->_search($translated_query),
           killedWords => [keys %$killedWords],
           regex       => qr/$strRegex/i,        };
}

sub _search { # backend
  my ($self, $q) = @_;

  my $scores = undef;           # hash {doc1 => score1, doc2 => score2 ...}

  # 1) deal with mandatory subqueries

  foreach my $subQ ( @{$q->{'+'}} ) {
    my $sc =  $self->docsAndScores($subQ) or next;
    $scores = $sc and next if not $scores;  # if first result set, just store

    # otherwise, intersect with previous result set
    foreach my $docId (keys %$scores) {
      if (defined $sc->{$docId}) {
        $scores->{$docId} += $sc->{$docId};
      }
      else {
        delete $scores->{$docId};
      }
    }
  }

  my $noMandatorySubq = not $scores;

  # 2) deal with non-mandatory subqueries 

  foreach my $subQ (@{$q->{''}}) {
    my $sc =  $self->docsAndScores($subQ) or next;
    $scores = $sc and next if not $scores;  # if first result set, just store

    # otherwise, combine with previous result set
    foreach my $docId (keys %$sc) {
      if (defined $scores->{$docId}) { # docId was already there, add new score
        $scores->{$docId} += $sc->{$docId};
      }
      elsif ($noMandatorySubq){ # insert a new docId to the result set
        $scores->{$docId} = $sc->{$docId};
      }
      # else do nothing (ignore this docId)
    }
  }

  return undef if not $scores or not %$scores; # no results

  # 3) deal with negative subqueries (remove corresponding docs from results)

  foreach my $subQ (@{$q->{'-'}}) {
    my $negScores =  $self->docsAndScores($subQ) or next;
    delete $scores->{$_}  foreach keys %$negScores;
  }

  return $scores;
}

sub docsAndScores { # returns a hash {docId => score} or undef (no info)
  my ($self, $subQ) = @_;

  # recursive call to _search if $subQ is a parenthesized query
  return $self->_search($subQ->{value}) if $subQ->{op} eq '()';

  # check op
  $subQ->{op} eq ':' or croak "unexpected op in subquery: '$subQ->{op}'";

  # 3 subcases, depending on $subq->{value}
  if (ref $subQ->{value}) {
    # subcase 1 : "exact phrase"
    return $self->matchExactPhrase($subQ);
  }
  elsif ($subQ->{value} <= -1) {
    # subcase 2 : stopword
    return undef;
  }
  else {
    # subcase 3 : single word

    # retrieve a hash, initially of shape (docId => nb_of_occurrences_of_that_word)
    my $wordId = $subQ->{value};
    my $scores = { unpack IXDPACK_L, ($self->{ixd}[$wordId] || "") };
    my @docIds = keys %$scores;
    my $n_docs_including_word = @docIds;

    # compute the bm25 relevancy score for each doc -- see https://en.wikipedia.org/wiki/Okapi_BM25
    # results are stored in %$scores (overwrite the nb of occurrences)
    if ($n_docs_including_word) {
      my ($n_total_docs, $n_total_words) = unpack GLOBSTATPACK, $self->ixp(0, 0);
      my $average_doc_length             = $n_total_docs ? $n_total_words / $n_total_docs : 0;
      my $inverse_doc_freq               = log(($n_total_docs - $n_docs_including_word + 0.5)
                                          /
                                           ($n_docs_including_word + 0.5));

      foreach my $docId (@docIds) {
        my $freq_word_in_doc = $scores->{$docId};
        my $n_words_in_doc   = $self->ixp(0, $docId);
        my $n_words_ratio    = $n_words_in_doc / $average_doc_length;
        $scores->{$docId}    = $inverse_doc_freq
                              * ($freq_word_in_doc * ($self->{bm25_k1} + 1))
                              / ($freq_word_in_doc + $self->{bm25_k1} *
                                                     (1 - $self->{bm25_b}
                                                        + $self->{bm25_b} * $n_words_ratio));
      }
    }

    return $scores;
  }
}



sub matchExactPhrase {
  my ($self, $subQ) = @_;

  if (! $self->{positions}) {
    # translate into an AND query
    my $fake_query = {'+' => [map {{op    => ':',
                                    value => $_  }} @{$subQ->{value}}]};
    # and search for that one
    return $self->_search($fake_query);
  };

  # otherwise, intersect word position sets
  my %pos;
  my $wordDelta = 0;
  my $combined_scores = undef;
  foreach my $wordId (@{$subQ->{value}}) {
    my $current_scores = $self->docsAndScores({op => ':', value => $wordId});
    if (not $combined_scores) {
      if ($current_scores) {
        $combined_scores = $current_scores;
        foreach my $docId (keys %$combined_scores) {
          $pos{$docId} = [unpack IXPPACK, $self->ixp($docId, $wordId)];
        }
      }
    }
    else {
      # must combine with previous scores
      $wordDelta++;
      foreach my $docId (keys %$combined_scores) {
        if ($current_scores) { # if $wordId is not a stopword ..
          if (not defined $current_scores->{$docId}) { # if $docId does not contain $wordId ..
            delete $combined_scores->{$docId};
          }
          else {
            # check if positions of $wordId in $docId are close enough to positions of the
            # previous word
            my @newPos   = unpack IXPPACK, $self->ixp($docId, $wordId);
            $pos{$docId} = nearPositions($pos{$docId}, \@newPos, $wordDelta);
            if ($pos{$docId}) {
              # positions are close enough, so keep this docId and sum the scores
              $combined_scores->{$docId} += $current_scores->{$docId};
            }
            else {
              delete $combined_scores->{$docId};
            }
          }
        }
      }  # end foreach my $docId (keys %$combined_scores)
    }
  } # end foreach my $wordId (@{$subQ->{value}})

  return $combined_scores;
}

sub nearPositions {
  my ($set1, $set2, $wordDelta) = @_;
# returns the set of positions in $set2 which are "close enough" (<= $wordDelta)
# to positions in $set1. Assumption : input sets are sorted.


  my @result;
  my ($i1, $i2) = (0, 0); # indices into sets

  while ($i1 < @$set1 and $i2 < @$set2) {
    my $delta = $set2->[$i2] - $set1->[$i1];
    ++$i1 and next             if $delta > $wordDelta;
    push @result, $set2->[$i2] if $delta > 0;
    ++$i2;
  }

  return @result ? \@result : undef;
}

sub translateQuery { # replace words by ids, remove irrelevant subqueries
  my ($self, $query) = @_;

  my %killedWords;
  my @wordsRegexes;

  my $recursive_translate;
  $recursive_translate = sub {
    my $q = shift;
    my $result = {};

    foreach my $k ('+', '-', '') {
      foreach my $subQ (@{$q->{$k}}) {

        # ignore items concerning other field names
        next if $subQ->{field} and $subQ->{field} ne $self->{fieldname};

        my $val = $subQ->{value};

        my $clone = undef;
        if ($subQ->{op} eq '()') {
        $clone = { op => '()', 
                   value => $recursive_translate->($val), };
        }
        elsif ($subQ->{op} eq ':') {
          # split query according to our notion of "term"
          my @words = ($val =~ /$self->{wregex}/g);

          # TODO : 1) accept '*' suffix; 2) find keys in $self->{ixw}; 3) rewrite into
          #        an 'OR' query

          my $regex1 = join "\\P{Word}+", map quotemeta, @words;
          my $regex2 = $self->{wfilter} ? join "\\P{Word}+", map quotemeta,
                                               map {$self->{wfilter}->($_)} @words
                                        : undef;
          for my $regex (grep {$_} $regex1, $regex2) {
            $regex = "\\b$regex" if $regex =~ /^\p{Word}/;
            $regex = "$regex\\b" if $regex =~ /\p{Word}$/;
          }

          push @wordsRegexes, $regex1;
          push @wordsRegexes, $regex2 if $regex2 && $regex2 ne $regex1;

          # now translate into word ids
          foreach my $word (@words) {
            my $wf = $self->{wfilter} ? $self->{wfilter}->($word) : $word;
            my $wordId = $wf ? ($self->{ixw}{$wf} || 0) : -1;
            $killedWords{$word} = 1 if $wordId < 0;
            $word = $wordId;
          }

          $val = (@words>1) ? \@words   : # several words : return an array
                 (@words>0) ? $words[0] : # just one word : return its id
                 0;                       # no word : return 0 (means "no info")

          $clone = {op => ':', value=> $val};
        }

        push @{$result->{$k}}, $clone if $clone;
      }
    }

    return $result;
  };


  return ($recursive_translate->($query), \%killedWords, \@wordsRegexes);
}


sub excerpts {
  my $self = shift;
  # $_[0] : text buffer ; no copy for efficiency reason
  my $regex = $_[1];

  my $nc = $self->{ctxtNumChars};

  # find start and end positions of matching fragments
  my $matches = []; # array of refs to [start, end, number_of_matches]
  while ($_[0] =~ /$regex/g) {
    my ($start, $end) = ($-[0], $+[0]);
    if (@$matches and $start <= $matches->[-1][1] + $nc) {
      # merge with the last fragment if close enough
      $matches->[-1][1] = $end; # extend the end position
      $matches->[-1][2] += 1;   # increment the number of matches
    }
    else {
      push @$matches, [$start, $end, 1];
    }
  }

  foreach (@$matches) { # extend start and end positions by $self->{ctxtNumChars}
    $_->[0] = ($_->[0] < $nc) ? 0 : $_->[0] - $nc;
    $_->[1] += $nc;
  }

  my $excerpts = [];
  foreach my $match (sort {$b->[2] <=> $a->[2]} @$matches) {
    last if @$excerpts >= $self->{maxExcerpts};
    my $x = substr($_[0], $match->[0], $match->[1] - $match->[0]); # extract
    $x =~ s/$regex/$self->{preMatch}$&$self->{postMatch}/g ;       # highlight
    $x =~ s/\s+/ /g;                                               # remove multiple spaces
    push @$excerpts, "...$x...";
  }
  return $excerpts;
}



#======================================================================
# OTHER PUBLIC METHODS
#======================================================================

sub indexed_words_for_prefix {
  my $self = shift;
  my $prefix = shift;

  my $regex = qr/^$prefix/;
  my @words = ();

  # position cursor at the first word starting with the $prefix
  my $c = $self->{ixwDb}->db_cursor;
  my ($k, $v);
  $k = $prefix;
  my $status = $c->c_get($k, $v, DB_SET_RANGE);

  # proceed sequentially through the words with same $prefix
  while ($status == 0) {
    last if $k !~ $regex;
    push @words, $k;
    $status = $c->c_get($k, $v, DB_NEXT);
  }

  return \@words;
}

sub dump {
  my $self = shift;
  foreach my $word (sort keys %{$self->{ixw}}) {
    my $wordId = $self->{ixw}{$word};
    if ($wordId == -1) {
      print "$word : STOPWORD\n";
    }
    else {
      my %docs = unpack IXDPACK_L, $self->{ixd}[$wordId];
      print "$word : ", join (" ", keys %docs), "\n";
    }
  }
}




#======================================================================
# INTERNAL UTILITY METHODS
#======================================================================



sub ixp : lvalue { # utility for reading or writing into {ixp}, with pairs of ints as keys
  my ($self, $v1, $v2) = @_;
  my $ixpKey = pack IXPKEYPACK, $v1, $v2;
  return $self->{ixp}{$ixpKey};
}


sub wordIds_in_doc {
  my $self         = shift;
  my $target_docId = shift;

  $self->{positions}
    or croak "wordIds_in_doc() not available (index was created without positions)";

  # position cursor at pair ($target_docId, 1n)
  my %n_occur_for_word;
  my $c = $self->{ixpDb}->db_cursor;
  my ($k, $v);
  $k = pack IXPKEYPACK, $target_docId, 1;
  my $status = $c->c_get($k, $v, DB_SET_RANGE);

  # proceed sequentially through the pairs with same $target_docId
  while ($status == 0) {
    my ($docId, $wordId) = unpack IXPKEYPACK, $k;
    my @positions        = unpack IXPPACK, $v;

    last if $docId != $target_docId;
    $n_occur_for_word{$wordId} = scalar @positions;
    $status = $c->c_get($k, $v, DB_NEXT);
  }

  return \%n_occur_for_word;
}

1;


__END__

=head1 NAME

Search::Indexer - full-text indexer

=head1 SYNOPSIS

  use Search::Indexer;

  # feed the index
  my $ix = new Search::Indexer(dir => $dir, writeMode => 1);
  while (my ($docId, $docContent) = get_next_document() ) {
    $ix->add($docId, $docContent);
  }
  
  # search
  my $result      = $ix->search('normal_word +mandatory_word -excludedWord "exact phrase"');
  my $scores      = $result->{scores};
  my $n_docs      = keys %$scores;
  my @best_docs   = (sort {$scores->{$b} <=> $scores->{$a}} keys %$scores)[0 .. $max];
  my $killedWords = join ", ", @{$result->{killedWords}};
  
  # show results
  print "$n_docs documents found, displaying the first $max\n";
  print "words $killedWords were ignored during the search\n" if $killedWords;
  foreach my $docId (@best_docs) {
    my $excerpts = join "\n", $ix->excerpts(doc_content($docId), $result->{regex});
    print "DOCUMENT $docId (score $scores->{$docId}) :\n$excerpts\n\n";
  }
  
  # boolean search
  my $result2 = $ix->search('word1 AND (word2 OR word3) AND NOT word4');
  
  # removing a document
  $ix->remove($someDocId);

=head1 DESCRIPTION

This module builds a fulltext index for a collection of
documents.  It provides support for searching through the collection and
displaying the sorted results, together with contextual excerpts of
the original documents.

Unlike L<Search::Elasticsearch>, which is a client to an indexing
server, here we have an I<embedded index>, running in the same process
as your application.  Index data is stored in L<BerkeleyDB> databases,
accessed through a C-code library, so indexing is fast; the storage
format use
L<perlpacktut/Another Portable Binary Encoding|compressed integers>,
so it can accomodate large collections.

=head2 Documents

As far as this module is concerned, a I<document> is just a buffer of
plain text, together with a unique identifying number. The caller is
responsible for supplying unique numbers, and for converting the
original source (HTML, PDF, whatever) into plain text. Metadata
about documents (fields like date, author, Dublin Core, etc.)
must be handled externally, in a database or any
other store. For collections of moderate size, a candidate
for storing metadata could be L<File::Tabular|File::Tabular>, which
uses the same query parser.

=head2 Search syntax

Searching requests may include plain terms, "exact phrases",
'+' or '-' prefixes, boolean operators and parentheses.
See L<Search::QueryParser> for details.

=head2 Index files

The indexer uses three files in BerkeleyDB format : a) a mapping from
words to wordIds; b) a mapping from wordIds to lists of documents ; c)
a mapping from pairs (docId, wordId) to lists of positions within the
document. This third file holds detailed information and therefore uses
more disk space ; but it allows us to quickly retrieve "exact phrases"
(sequences of adjacent words) in the document. Optionally, this positional
information can be omitted, yielding to smaller index files, but
less precision in searches (a query for "exact phrase" will be downgraded
to a search for all words in the phrase, even if not adjacent).

NOTE: the internal representation in v1.0 has slightly changed from previous
versions; B<existing indexes are not compatible and must be rebuilt>.

=head2 Indexing steps

Indexing of a document buffer goes through the following
steps :

=over

=item *

terms are extracted, according to the I<wregex> regular expression

=item *

extracted terms are normalized or filtered out
by the I<wfilter> callback function. This function can for example
remove accented characters, perform lemmatization, suppress
irrelevant terms (such as numbers), etc.

=item *

normalized terms are eliminated if they belong to
the I<stopwords> list (list of common words to exclude from the index).

=item *

remaining terms are stored, together with the positions where they
occur in the document.

=back

=head2 Related modules

This module depends on L<Search::QueryParser> for analyzing requests and
on L<BerkeleyDB> for storing the indexes.

This module was originally designed together with L<File::Tabular>; however
it can be used independently. In particular, it is used in the L<Pod::POM::Web>
application for indexing all local Perl modules and documentation.





=head1 METHODS

=head2 Class methods

=head3 C<< new(arg1 => expr1, ...) >>

Instantiates an indexer (either for a new index, or for
accessing an existing index). Parameters are :

=over

=item dir

Directory for index files and possibly for the stopwords file.
Defaults to the current directory.

=item writeMode

Flag which must be set to true if the application intends to write into the index.

=item wregex 

Regex for matching a word (C<< qr/\p{Word}+/ >> by default).
Used both for L<add> and L<search> method.
The regex should not contain any capturing parentheses
(use non-capturing parentheses C<< (?: ... ) >> instead).

=item wfilter

Ref to a callback sub that may normalize or eliminate a word.  The
default wfilter performs case folding and translates accented characters
into their non-accented form.

=item stopwords

List of words that will be marked into the index as "words to exclude".
Stopwords are stored in the index, so they need not be supplied again
when opening an index for searches or updates.

The list may be supplied either as a ref to an array of scalars, or
as a the name of a file containing the stopwords (full pathname
or filename relative to I<dir>).


=item fieldname

This paramete will only affect the L<search> method.
Search queries are passed to a general parser
(see L<Search::QueryParser>).
Then, before being applied to the present indexer module,
queries are pruned of irrelevant items.
Query items are considered relevant if they have no
associated field name, or if the associated field name is
equal to this C<fieldname>.

=back

Below are some additional parameters that only affect the
L</excerpts> method :

=over

=item ctxtNumChars

Number of characters determining the size of contextual excerpts
return by the L</excerpts> method.
A I<contextual excerpt> is a part of the document text,
containg a matched word surrounded by I<ctxtNumChars> characters 
to the left and to the right. Default is 35.


=item maxExcerpts

Maximum number of contextual excerpts to retrieve per document.
Default is 5.

=item preMatch

String to insert in contextual excerpts before a matched word.
Default is C<< "E<lt>bE<gt>" >>.

=item postMatch

String to insert in contextual excerpts after a matched word.
Default is C<< "E<lt>/bE<gt>" >>.


=item positions

  my $indexer = new Search::Indexer(dir       => $dir, 
                                    writeMode => 1,
                                    positions => 0);

Truth value to tell whether or not, when creating a new index,
word positions should be stored. The default is true.

If you turn it off, index files will be smaller, indexing
will be faster, but results will be less precise,
because the indexer can no longer find "exact phrases".
So if you type  C<"quick fox jumped">, the query will be 
translated into C<quick AND fox AND jumped>, and therefore
will retrieve documents in which those three words are present,
even if not in the required order or proximity.

=item bm25_k1

Value of the I<k1> constant to be used when computing the
L<https://fr.wikipedia.org/wiki/Okapi_BM25|Okapi BM25> ranking
function. Default is 1.2.

=item bm25_b

Value of the I<b> constant to be used when computing the
L<https://fr.wikipedia.org/wiki/Okapi_BM25|Okapi BM25> ranking
function. Default is 0.75.

=back


=head3 C<has_index_in_dir($dir)>

Checks for presence of the three F<*.bdb> files in the given C<$dir>.


=head2 Building the index


=head3 C<add($docId, $buf)>

Add a new document to the index.
I<$docId> is the unique identifier for this doc
(the caller is responsible for uniqueness). Doc ids need not be consecutive.
I<$buf> is a scalar containing the text representation of this doc.

=head3 C<remove($docId [, $buf])>

Removes a document from the index.
If the index contains word positions (true by default), then
only the C<docId> is needed; however, if the index was created
without word positions, then the text representation
of the document must be given as a scalar string in the second argument
(of course this text should be the same as the one that was supplied
when calling the L</add> method).


=head2 Searching the index

=head3 C<search($queryString, [ $implicitPlus ])>

Searches the index. The query string may be a simple word or a complex
boolean expression, as described above in the  L</DESCRIPTION> section;
precise technical details are documented in L<Search::QueryParser>.
The second argument C<$implicitPlus> is optional ;
if true, all words without any prefix will implicitly take the prefix '+'
(all become mandatory words).

The return value is a hashref containing :

=over

=item scores

hash ref, where keys are docIds of matching documents, and values are
the corresponding relevancy scores, computed according to the
L<https://fr.wikipedia.org/wiki/Okapi_BM25|Okapi BM25> algorithm.
Documents with the highest scores are the most relevant.


=item killedWords

ref to an array of terms from the query string which were ignored
during the search (because they were filtered out or were stopwords)

=item regex

ref to a regular expression corresponding to all terms in the query
string. This will be useful if you later want to get contextual
excerpts from the found documents (see the L</excerpts> method).

=back


=head3 C<excerpts(buf, regex)>

Searches C<buf> for occurrences of C<regex>, 
extracts the occurences together with some context
(a number of characters to the left and to the right),
and highlights the occurences. See parameters C<ctxtNumChars>,
C<maxExcerpts>, C<preMatch>, C<postMatch> of the L</new> method.


=head2 Other public methods


=head3 C<indexed_words_for_prefix($prefix)>

Returns a ref to an array of words found in the dictionary, 
starting with the given prefix. For example, C<< $ix->indexed_words_for_prefix("foo") >> 
will return "foo", "food", "fool", "footage", etc.

=head3 C<dump()>

Debugging function that prints indexed words with lists of associated docs.


=head1 AUTHOR

Laurent Dami, C<< <dami@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2005, 2007, 2021 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
