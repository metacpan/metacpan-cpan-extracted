package Search::Tokenizer;
use warnings;
use strict;
use Unicode::CaseFold ();

our $VERSION = '1.01';

sub new {
  my $class = shift;

  # defaults
  my $regex           = qr/\w+/;
  my $lower           = 1;
  my $filter          = undef;
  my $filter_in_place = undef;
  my $stopwords       = undef;

  # parse arguments
  unshift @_, "regex" if @_ == 1; # positional API
  while (my $arg = shift) {
    my $val = shift;
    $arg .= "=>" . (ref($val) || "NOREF");
    for ($arg) {
      /^regex=>Regexp$/         and do { $regex = $val;           last};
      /^lower=>NOREF$/          and do { $lower = !!$val;         last};
      /^filter=>CODE$/          and do { $filter = $val;          last};
      /^filter_in_place=>CODE$/ and do { $filter_in_place = $val; last};
      /^stopwords=>HASH$/       and do { $stopwords = $val;       last};
      die "Invalid option or invalid operand: $arg";
    }
  }

  # check that regex doest not match the empty string
  not "" =~ $regex
    or die "regex $regex matches the empty string: cannot tokenize";

  # return tokenizer factory: closure
  return sub { 
    my $string = shift;
    my $term_index = -1;

    # return tokenizer : additional closure on $string and $term_index
    return sub {

      # get next occurrence of $regex in $string (thanks to the /g flag)
      while ($string =~ /$regex/g) {

        # index of this term within the input string
        $term_index += 1;

        # boundaries for the match
        my ($start, $end) = ($-[0], $+[0]);

        # extract matched substring (more efficient than $&)
        my $term = substr($string, $start, $end-$start);

        # apply filtering and stopwords, if any
        $term = Unicode::CaseFold::fc($term) if $lower;
        $term = $filter->($term)             if $filter;
        $filter_in_place->($term)            if $filter_in_place;
        undef $term            if $stopwords and $stopwords->{$term};

        # if $term was not cancelled by filters above, return it
        if ($term) {
          return wantarray ? ($term, length($term), $start, $end, $term_index)
                           : $term;
        }
      } # otherwise, loop again to extract next term

      # otherwise, no more term in input string, return undef or empty list
      return;
    };
  };
}

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
regular expression (for example C<\w+>).  Term matching relies on the
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
match the empty string (otherwise the tokenizer would enter an
infinite loop). The default is C<qr/\w+/>. Here are some examples of more
advanced regexes :

  # take 'locale' into account
  $regex = do {use locale; qr/\w+/}; 

  # rely on Unicode's definition of "word characters"
  $regex = qr/\p{Word}+/;

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

where terms "once" and "a" in positions 0 and 2 have been canceled.

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
called in a list context, it returns a tuple composed from

=over

=item $term

the term (after filtering)

=item $len

the term length

=item $start

the starting offset in the string where this term was found

=item $end

the end offset (where the search for the next term will start)

=item $index

the index of this term within the string, starting at 0

=back

Length and start/end offsets are computed in characters, not in bytes
(note for SQLite users : the C layer in SQLite needs byte values, but
the conversion will be automatically taken care of by the C
implementation in L<DBD::SQLite>).

Beware that ($end - $start) is the length of the original
term extracted by the regex, while $len is the length
of the final $term, after filtering; both
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

Laurent Dami, C<< <lau.....da..@justice.ge.ch> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-tokenizer
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Tokenizer>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Tokenizer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Tokenizer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Tokenizer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Tokenizer>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Tokenizer/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


