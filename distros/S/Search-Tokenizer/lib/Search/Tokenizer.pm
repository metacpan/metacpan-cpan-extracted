package Search::Tokenizer;
use warnings;
use strict;
use Carp              qw(croak);
use Unicode::CaseFold qw(fc);    # because CORE::fc only came with Perl 5.16

our $VERSION = '1.03';

#======================================================================
# MAIN FUNCTIONALITY
#======================================================================

sub new {
  my $class = shift;

  # defaults
  my $regex           = qr/\p{Word}+/;
  my $lower           = 1;
  my $filter          = undef;
  my $filter_in_place = undef;
  my $stopwords       = undef;

  # parse arguments
  unshift @_, "regex" if @_ == 1; # positional API
  while (my ($arg, $val) = splice(@_, 0, 2)) {
    $arg .= "=>" . (ref($val) || "SCALAR");
  CHECK:
    for ($arg) {
      /^regex=>Regexp$/         and do { $regex = $val;           last CHECK};
      /^lower=>SCALAR$/         and do { $lower = !!$val;         last CHECK};
      /^filter=>CODE$/          and do { $filter = $val;          last CHECK};
      /^filter_in_place=>CODE$/ and do { $filter_in_place = $val; last CHECK};
      /^stopwords=>HASH$/       and do { $stopwords = $val;       last CHECK};
      croak "Invalid option or invalid operand: $arg";
    }
  }

  # check that regex doest not match the empty string
  not "" =~ $regex
    or croak "regex $regex matches the empty string: cannot tokenize";

  # return tokenizer factory: closure
  return sub { 
    my ($string, @other_args) = @_;
    not @other_args
      or croak "too many args -- just a single string is expected";

    my $term_index = -1;

    # return tokenizer : additional closure on $string and $term_index
    return sub {

      # get next occurrence of $regex in $string (thanks to the /g flag)
      while ($string =~ /$regex/g) {

        # index of this term within the input string
        $term_index += 1;

        # boundaries for the match
        my $end   = pos($string);
        my $term  = $&; # used to be slow in older perls, but now OK
        my $start = $end - length($term);

        # the old way used to be as follows, but it is ridiculously slow on utf8 strings
        # .. see https://github.com/Perl/perl5/issues/18786
        #
        # my ($start, $end) = ($-[0], $+[0]); 
        # my $term = substr($string, $start, $end-$start);

        # apply filtering and stopwords, if any
        $term = Unicode::CaseFold::fc($term) if $lower;
        $term = $filter->($term)             if $filter;
        $filter_in_place->($term)            if $filter_in_place;
        undef $term                          if $stopwords and $stopwords->{$term};

        # if $term was not cancelled by filters above, return it
        if ($term) {
          return wantarray ? ($term, length($term), $start, $end, $term_index)
                           : $term;
        }
      } # otherwise, loop again to extract next term

      # otherwise, that's the end of the input string, return undef or empty list
      return;
    };
  };
}

#======================================================================
# BUILTIN TOKENIZERS
#======================================================================


sub word {
  __PACKAGE__->new(regex => qr/\w+/, @_);
}

sub word_locale {
  use locale;
  __PACKAGE__->new(regex => qr/\w+/, @_);
}

sub word_unicode {
  __PACKAGE__->new(regex => qr/\p{Word}+/, @_);
}

sub unaccent {
  require Text::Transliterator::Unaccent;
  my %args = @_;
  my $want_lower      = !exists $args{lower} || $args{lower};
  my %unaccenter_args = $want_lower ? () : (upper => 0);
  my $unaccenter = Text::Transliterator::Unaccent->new(%unaccenter_args);
  __PACKAGE__->new(regex           => qr/\p{Word}+/,
                   filter_in_place => $unaccenter,
                   %args);
}


#======================================================================
# UTILITY FUNCTION
#======================================================================

sub unroll {
  my $iterator   = shift;
  my $no_details = shift;
  my @results;

  while (my @r = $iterator->() ) {
    push @results, $no_details ? $r[0] : \@r;
  }
  return @results;
}


1; # End of Search::Tokenizer


__END__

=head1 NAME

Search::Tokenizer - Decompose a string into tokens (words)

=head1 SYNOPSIS

  # generic usage
  use Search::Tokenizer;
  my $tokenizer = Search::Tokenizer->new(
     regex     => qr/.../,
     filter    => sub { ... },
     stopwords => {word1 => 1, word2 => 1, ... },
     lower     => 1,
   );
  my $iterator = $tokenizer->($string);
  while (my ($term, $len, $start, $end, $index) = $iterator->()) {
    ...
  }

  # usage for DBD::SQLite (with builtin tokenizers: word, word_locale,
  #   word_unicode, unaccent)
  use Search::Tokenizer;
  $dbh->do("CREATE VIRTUAL TABLE t "
          ."  USING fts3(tokenize=perl 'Search::Tokenizer::unaccent')");


=head1 DESCRIPTION

This module builds an iterator function that will progressively
extract terms from a given input string. Terms are defined by a
regular expression (for example C<\w+>).  Extraction of terms relies on the
builtin "global match" operator of Perl (the 'g' flag), and therefore
is quite efficient.

Before being returned to the caller, terms may be filtered by an
auxiliary function, for performing tasks such as stemming or stopword
elimination.

A tokenizer returned from the L<new|/"new"> method is a code
reference, I<not> a regular Perl object. To use the tokenizer, just
call it with a string to parse : this will return another code
reference, which works as an iterator. Each call to the iterator
will return the next term from the string, until the string is exhausted.

This API was explicitly designed for integrating Perl with the
FTS3 fulltext search engine in L<DBD::SQLite>; however, the API
is general enough to be useful for other purposes, which is why
it is published in its own, separate distribution.

=head1 METHODS

=head2 Creating a tokenizer

  my $tokenizer = Search::Tokenizer->new($regex);
  my $tokenizer = Search::Tokenizer->new(%options);

Builds a new tokenizer, returned as a code reference. 
The first syntax with a single Regexp argument is a shorthand
for C<< ->new(regex => $regex) >>. The second syntax, with
named arguments, has the following available options :

=over

=item C<< regex => $regex >>

C<$regex> is a compiled regular expression that
specifies how to match a term; that regular expression should I<not>
match the empty string (otherwise the tokenizer would enter into an
infinite loop). The default is C<qr/\p{Word}+/>. Here are some examples of more
advanced regexes :

  # perl's basic notion of "word"
  $regex = qr/\w+/;

  # take 'locale' into account
  $regex = do {use locale; qr/\w+/}; 

  # words like "don't", "it's" are treated as a single term
  $regex = qr/\w+(?:'\w+)?/;

  # same thing but also with internal hyphens like "fox-trot"
  $regex = qr/\w+(?:[-']\w+)?/;

=item C<< lower => $bool >>

If true, the term returned by the C<$regex> is
converted to lowercase (or more precisely: is
"case-folded" through L<Unicode::CaseFold/fc>).
This option is activated by default.

=item C<< filter => $filter >>

C<$filter> is a reference to a function that may modify or cancel
a term before it is returned to the caller. The filter takes one
single argument (the term) and returns a scalar (the modified term).
If the value returned from the filter is empty, then this term is canceled.

=item C<< filter_in_place => $filter >>

Like C<filter>, except that the filtering function directly
modifies the term in its C<< $_[0] >> argument instead of returning
a new term. This is useful for example when building a filter
from L<Lingua::Stem::Snowball|Lingua::Stem::Snowball>
or from L<Text::Transliterator::Unaccent|Text::Transliterator::Unaccent>.

=item C<< stopwords => $hashref >>

The keys in C<$hashref> are terms to cancel (usually : common terms
for which indexing would consume lots of resources with little
added value). Values in the hash should evaluate to true.
Lists of stopwords for various languages may be found in
the L<Lingua::StopWords|Lingua::StopWords> module.
Stopwords filtering is applied after the C<filter> or
C<filter_in_place> function (if any).

=back

Whenever a term is canceled through the filter or stopwords options,
the tokenizer does not return that term to the client, but nevertheless
rembembers the canceled position: so for example when tokenizing 
"Once upon a time" with

 $tokenizer = Search::Tokenizer->new(
    stopwords => Lingua::StopWords::getStopWords('en')
 );

we get the term sequence

  ("upon", 4,  5,  9, 1)
  ("time", 4, 12, 16, 3)

where terms "once" and "a" in positions 0 and 2 have been canceled,
so the only remaining terms are in positions 1 and 3.

=head2 Creating an iterator

  my $iterator = $tokenizer->($text);

  # loop over terms ..
  while (my $term = $iterator->()) {
    work_with_term($term);
  }

  # .. or loop over terms with detailed information
  while (my @term_details = $iterator->()) {
    work_with_details(@term_details); # ($term, $len, $start, $end, $index)
  }

The tokenizer takes one string argument and returns an iterator.  The
iterator takes no argument; each call returns a next term from the
string, until the string is exhausted, at which point the iterator
returns an empty result.

If called in a scalar context, the iterator returns just a string; if
called in a list context, it returns a tuple composed from :

=over

=item $term

the term (after filtering);

=item $len

the length of this term;

=item $start

the starting offset in the string where this term was found;

=item $end

the end offset. This is also the place where the search for the next term will start;

=item $index

the position of this term within the string, starting at 0.

=back

Length and start/end offsets are computed in characters, not in bytes.
Note for SQLite users : the C layer in SQLite needs byte values, but
the conversion will be automatically taken care of by the C
implementation in L<DBD::SQLite>.

Beware that ($end - $start) is the length of the original
extracted term, while $len is the length
of the final $term, after filtering; both lengths
may differ, especially if stemming is being applied.

=head1 BUILTIN TOKENIZERS

For convenience, the following tokenizers are builtin :

=over

=item C<Search::Tokenizer::word>

Terms are "words" according to Perl's notion of C<\w+>.

=item C<Search::Tokenizer::word_locale>

Terms are "words" according to Perl's notion of C<\w+>
under C<use locale>.

=item C<Search::Tokenizer::word_unicode>

Terms are "words" according to Unicode's notion of 
C<\p{Word}+>.

=item C<Search::Tokenizer::unaccent>

Like C<Search::Tokenizer::word_unicode>, but filtered
through L<Text::Transliterator::Unaccent|Text::Transliterator::Unaccent>
to replace all accented characters by their base character.

=back


These builtin tokenizers may take the same arguments
as C<new()>: for example

  use Search::Tokenizer;
  my $tokenizer = Search::Tokenizer::unaccent(lower => 0, stopwords => ...);


=head1 UNROLLING THE ITERATOR

=head2 unroll

  my @tokens = Search::Tokenizer::unroll($iterator, $no_details);

This utility method returns the list of all tokens obtained from repetitive
calls to the C<$iterator>. The C<$no_details> argument is optional; if true,
the results are just strings, instead of tuples with positional information.


=head1 SEE ALSO

=over

=item *

Other tokenizers on CPAN : 
L<KinoSearch::Analysis::Tokenizer|KinoSearch::Analysis::Tokenizer>
and
L<Search::Tools::Tokenizer|Search::Tools::Tokenizer>.

=item * 

Stopwords :
L<Lingua::StopWords|Lingua::StopWords>

=item *

Stemming :
L<Lingua::Stem::Snowball|Lingua::Stem::Snowball>

=item *

Removing accented characters : 
L<Text::Transliterator::Unaccent|Text::Transliterator::Unaccent>

=back


=head1 AUTHOR

Laurent Dami, C<< <dami@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010, 2021 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


