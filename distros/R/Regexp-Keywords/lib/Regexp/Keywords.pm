package Regexp::Keywords;

require Exporter;
@ISA = (Exporter);
@EXPORT_OK = qw(keywords_regexp);

use warnings;
use strict;
use Carp;

=head1 NAME

Regexp::Keywords - A regexp builder to test against keywords lists

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This module helps you to search inside a list of keywords for some of them,
using a simple query syntax with AND, OR and NOT operators and grouping.

    use Regexp::Keywords;
    my $kw = Regexp::Keywords->new();
    
    my $wanted = 'comedy + ( action , romance ) - thriller';
    $kw->prepare($wanted);
    
    my $movie_tags = 'action,comedy,crime,fantasy,adventure';
    print "Buy ticket!\n" if $kw->test($movie_tags);

I<Keywords>, also known as I<tags>, are used to classify things in a category.
Many tags can be assigned at the same time to an item,
even if they belong to different available categories.

In real life, keywords lists are found in:

=over 4

=item *

Public databases like IMDB.

=item *

Metadata of HTML pages from public services, such as Picasa or Youtube

=item *

Metadata of Word, Excel and other documents.

=back


=head1 CONSTRUCTOR

=head2 new ( )

Creates a Keywords object.
Some attributes can be initialized from the constructor:

=over 4

=item *

L<< C<ignore_case>|/ignore_case >> C<< => [0|1] >>

=item *

L<< C<multi_words>|/multi_words >> C<< => [0|1|2] >>

=item *

L<< C<partial_words>|/partial_words >> C<< => [0|1] >>

=item *

L<< C<texted_ops>|/texted_ops >> C<< => [0|1] >>

=back

See L<Attributes|"ATTRIBUTES"> for a description
of these attributes.

Example: To create a Keywords object that will be used to test
strings with mixed case keywords:

  my $kw = Keywords->new(ignore_case => 1);

=cut

sub new {
  my $class = shift;
  my %passed_parms = @_;

  my %parms = (
    ignore_case   => 0,
    multi_words   => 0,
    partial_words => 0,
    texted_ops    => 0,
  );

  while ( my($key,$value) = each %passed_parms ) {
    if ( exists $parms{$key} ) {
      $parms{$key} = $value;
    } else {
      croak("Invalid parameter $key");
    }
  }

  my $self = {};
  $self->{query} = undef;
  $self->{parsed_query} = undef;
  $self->{regexp} = undef;
  $self->{ok} = undef;
  bless($self, $class);

  for my $parm ( keys %parms ) {
    $self->{$parm} = $parms{$parm};
  }

  return $self;
}

=head1 BUILDING METHODS

=head2 $kw->prepare( $query )

Parse a query and build a regexp pattern to be used for
keywords strings tests.
Dies on malformed query expressions.
See L<Query Expressions|"QUERY EXPRESSIONS"> later in this doc.

=cut

sub prepare {
  my $self = shift;
  my $query = shift;

  $self->{query} = $query;
  $self->{parsed_query} = _query_parser($query, $self->{texted_ops});
  $self->{regexp} = _regexp_builder($self->{parsed_query}, $self->{ignore_case}, $self->{multi_words}, $self->{partial_words});
  $self->{ok} = defined $self->{regexp};

  return $self->{regexp};
}

=head2 $kw->set( attribute => value [, ...] )

The following attributes can be changed after the object creation:

=over 4

=item *

L<< C<ignore_case>|/ignore_case >> C<< => [0|1] >>

=item *

L<< C<multi_words>|/multi_words >> C<< => [0|1|2] >>

=item *

L<< C<parsed_query>|/parsed_query >> C<< => "internal binary format" >>

=item *

L<< C<partial_words>|/partial_words >> C<< => [0|1] >>

=item *

L<< C<query>|/query >> C<< => "free-form text" >>

=item *

L<< C<texted_ops>|/texted_ops >> C<< => [0|1] >>

=back

Dies on unknown attributes.
See L<Attributes|"ATTRIBUTES"> section
for a description of each attribute.

B<Note:> Some of this attributes invalidates the associated
regexp if it was already built,
so an I<automatic> C<reparse> or C<rebuild> is done
after changing all the specified attributes.
For the same reason, is better to call C<set> with many
parameters instead of setting one at a time.

B<Note:> It's not recommended to modify the attributes directly
from the object, or you could get unexpected results
if the query is not parsed or built again.

=cut

sub set {
  my $self = shift;
  my %passed_parms = @_;

  my %valid_parms = (
    ignore_case   => 1,
    multi_words   => 1,
    parsed_query  => 2,
    partial_words => 1,
    query         => 2,
    texted_ops    => 2,
  );
  my $rebuild_needed = 0;
  my $reparse_needed = 0;

  while ( my($key,$value) = each %passed_parms ) {
    if ( exists $valid_parms{$key} ) {
      $rebuild_needed++ if $valid_parms{$key} && $self->{$key} ne $value;
      $reparse_needed++ if $valid_parms{$key} == 2 && $self->{$key} ne $value;
      $self->{$key} = $value;
    } else {
      croak("Invalid parameter $key");
    }
  }
#  $self->{ok} = 0 if $rebuild_needed + $reparse_needed;
  # The previous removed because of the following auto updates:
  $self->reparse() if $reparse_needed && $self->{query};
  $self->rebuild() if $rebuild_needed && $self->{parsed_query};
}

=head2 $kw->get( 'attribute' )

This method returns the current value for the specified attribute.
Dies on unknown attributes.
See L<Attributes|"ATTRIBUTES"> section for a list of available attributes.

=cut

sub get {
  my $self = shift;
  my $key = shift;

  croak("Invalid parameter $key") unless exists $self->{$key};

  return $self->{$key};
}

=head2 $kw->reparse( )

If any of the object's attribute changes,
a reparse of the source query may be required,
depending on the affected attribute. 
Dies on bad queries.

=cut

sub reparse {
  my $self = shift;

  $self->{parsed_query} = _query_parser($self->{query}, $self->{texted_ops});
  $self->{ok} = 0;
}

=head2 $kw->rebuild( )

If any of the object's attribute changes,
a rebuild of the regexp may be required,
depending on the affected attribute. 
Dies on bad parsed queries.

=cut

sub rebuild {
  my $self = shift;

  $self->{regexp} = _regexp_builder($self->{parsed_query}, $self->{ignore_case}, $self->{multi_words}, $self->{partial_words});
  $self->{ok} = defined $self->{regexp};

  return $self->{regexp};
}

=head1 KEYWORDS TESTING METHODS

=head2 $kw->test( $keyword_list )

Returns I<true> if the list matches the parsed query, otherwise returns I<false>.
Dies if no query has been parsed yet.

=cut

sub test {
  my $self = shift;
  my $list = shift;

  croak "Query not prepared for test" unless $self->{ok};

  return $list =~ /$self->{regexp}/;
}

=head2 $kw->grep( @list_of_kwlists )

Returns an array only with the keywords lists that matches de parsed query.
Dies if no query has been parsed yet.

  @selected_keys = $kw->grep_keys(map {$_ => $table{$_}[$col]} keys %table);

  @selected_indexes = $kw->grep_keys(map {$_ => $array[$_]} 1 .. $#table);

=cut

sub grep {
  my $self = shift;

  croak "Query not prepared for grep" unless $self->{ok};

  return grep {$_ =~ /$self->{regexp}/} @_;
}

=head2 $kw->grep_keys( %hash_of_kwlists )

Returns an array of keys from a hash when their corresponding values
satisfy the query.
Dies if no query has been parsed yet.

=cut

sub grep_keys {
  my $self = shift;

  croak "Query not prepared for grepkeys" unless $self->{ok};

  my %pairs = @_;
  return grep {$pairs{$_} =~ /$self->{regexp}/} keys %pairs;
}

=head1 EXPORTED FUNCTION

The following function can be imported and accessed directly from your program.

=head2 keywords_regexp( $query [, $ignore [, $multi [, $partial [, $texted ] ] ] ] )

Returns a regular expression (C<qr/.../>) for a query
to which keywords lists strings can be tested against.

See L<Attributes|"ATTRIBUTES"> section
for a description of the attributes for the corresponding
parameters and the default values if ommitted.

=cut

sub keywords_regexp {
  my $query = shift;

  my $texted = splice @_, 3, 1;
#  my $ignore = shift;
#  my $multi = shift;
#  my $partial = shift;

  return _regexp_builder(_query_parser($query, $texted), @_);
}

# INTERNALS

sub _regexp_builder {
  my $parsed_query = shift;
  my $ignore_case = shift;
  my $multi_words = shift;
  my $partial_words = shift;

  my $expr = $parsed_query;
  croak('Undefined query') unless $expr;

  my $bound = ($partial_words ? '' : '\b');

  my $space = ($multi_words == 1 ? '\s+' : '\W+');

  $expr =~ s/(!?)([\w\.\^]+)/($1?'(?!':'(?=').'.*'.$bound.$2.$bound.')'/ge;
  $expr =~ s/\&//g;
  $expr =~ s/\^/$space/g;
  $expr = ($ignore_case?'(?i)':'').'^('.$expr.')';

  return qr/$expr/;
}

sub _query_parser {
  my $query = shift;
  my $texted_ops = shift;

  croak('Query required')
    unless defined $query;

  # Cleanup:
  $query =~ tr/\+\-\,\"\[\]\{\}\<\>/\&\!\|\'\(\)\(\)\(\)/; # unify operators
  if ($texted_ops) {
    $query =~ s/\bAND\b/\&/gi;
    $query =~ s/\bOR\b/\|/gi;
    $query =~ s/\bNOT\b/\!/gi;
  }
  $query =~ s/\'\s*([\w\.\s]+?)\s*\'/_uqt($1)/ge;  # remove quotes
  $query =~ s/(?<=[\w\.\)])\s*(?=[(\!])/\&/g;      # add implicit ANDs before ( and NOT
  $query =~ s/(?<=\))\s*(?=[\w\.\(\!])/\&/g;       # add implicit ANDs after )
  $query =~ s/(?<=[\w\.])\s+(?=[\w\.])/\&/g;       # add implicit ANDs between words
  $query =~ s/\s*//g;                              # remove spaces
  $query =~ s/\!\!//g;                             # NOT NOT
  $query =~ s/\!\!//g                              # more NOT NOT after ...
    while $query =~ s/\((\!?[\w\.\^]+)\)/$1/g;     # remove extra ( )

  croak('Invalid expression in query')
    if $query =~ /[^\w\.\^\!\|\&\(\)]|^\||[\|\!]$|[\&\|\(\!][\&\|\)]|\![^\w\.\(]/;
  # not_valid_chars | op_begins | op_ends | no_consecutive_ops | negated_operator
  croak('At least one keyword expected in query')
    unless $query =~ /[\w\.]/;

  1 while $query =~ s/\!\(([^\)]+)\)/_neg($1)/ge;    # NOT ( )
  1 while $query =~ s/\(\(([^\(\)]+)\)\)/\($1\)/g;   # extra ( )

  my $pairs = $query;
  1 while $pairs =~ s/\((.*?)\)/$1/; # fast way!
  croak('Unpaired '.($1 eq '('?'opening':'closing').' parenteses in query')
    if $pairs =~ /([\(\)])/;

  return $query;
}

sub _neg {
  my $query = shift;
  $query =~ s/(\!?)([\w\.\^]+)/$1?$2:"!".$2/ge;
  $query =~ tr/\|\&/\&\|/;
  return "(".$query.")";
}

sub _uqt {
  my $words = shift;
  $words =~ s/\s+/\^/g;
  return "(".$words.")";
}

=head1 ATTRIBUTES

Object's attributes can control how to parse a query,
build a regular expression or test strings.

Is it possible to access them using C<< $kw->{attribute} >>,
it's better to read them with
L<< $kw-E<gt>get()|"$kw->get( 'attribute' )" >>
and change them with
L<< $kw-E<gt>set()|"$kw->set( attribute => value [, ...] )" >>,
because some validations are done to keep things consistent.

=head2 ignore_case

Defines if the L<regexp|/regexp> should be case (in)sensitive.

Defaults to case sensitive (a value of 0).
Set to 1 turn the L<regexp|/regexp> into case insenitive.

B<Note:> Changing this parameter with
L<< $kw-E<gt>set()|"$kw->set( attribute => value [, ...] )" >>
after regexp has been built, causes the
L<regexp|/regexp> to be rebuilt from L<parsed_query|/parsed_query>.

=head2 multi_words

This attribute controls whether the keywords list may include
many words as a single keyword.

The default (0) is to treat each word as a keyword.
When this attribute is 1, the keywords list may include many words
as a single keyword.
When is set to 2, the delimiter between words is not a space.
To search for such a keyword, write the words between quotes in the
query string.

B<Note:> Changing this parameter with
L<< $kw-E<gt>set()|"$kw->set( attribute => value [, ...] )" >>
after regexp has been built, causes the
L<regexp|/regexp> to be rebuilt from L<parsed_query|/parsed_query>.

B<Note:> When set to 0 or 2,
a query with strings in quotes could match a keyword list
if each word is present in the list, side by side in the same order.

=head2 parsed_query

Contains the query in the
L<internal boolean format|/"INTERNAL BOOLEAN FORMAT">,
which is required to build the L<regexp|/regexp>.

=head2 partial_words

By default (value of 0),
only words that match exactly would return I<true>
when a keywords list is tested.
Set this attribute to 1 if you want to match lists where
keywords contains words from the query.

For example, "word" will match if a list contains "words",
but "query" won't match "queries".

B<Note:> Changing this parameter with
L<< $kw-E<gt>set()|"$kw->set( attribute => value [, ...] )" >>
after regexp has been built, causes the
L<regexp|/regexp> to be rebuilt from L<parsed_query|/parsed_query>.

B<Note:> Setting both L<partial_words|/partial_words>
and L<multi_words|/multi_words> to 1
could return unexpected results on tests,
because just first and last words will be considered to be
partial strings only from the outside.

=head2 query

Contains the original query in the
L<free-style syntax|"QUERY EXPRESSIONS">.

=head2 regexp

Contains the regular expresion built for the object's query.
It's a C<qr/.../> value!

=head2 texted_ops

I<AND>, I<OR> and I<NOT> operators are represented
by some punctuation chars.
In default mode (0), any use one of that words would
try to match it in the keywords list.
Set this attribute to 1 to allow words C<AND>, C<OR> and C<NOT>
to be used as binary operators in query expressions
instead of keywords to match.

B<Note:> Changing this attribute with
L<< $kw-E<gt>set()|"$kw->set( attribute => value [, ...] )" >>
after a regexp has been built,
forces a L<query|/query> to be reparsed into L<parsed_query|/parsed_query>
and L<regexp|/regexp> to be rebuilt.

=head1 KEYWORD LISTS

A Keyword is a combination of letters, underlines and numbers
(C</\w+/> pattern).
Sometimes, more than one word can be used to create a keyword,
and a space is between them.

Keyword lists are string values with words, usually delimited by comma
or any other punctuation sign.
Spaces may also appear surrounding them.

There is no validation for field names inside a keywords list.
In fact, that names are also treated as keywords by themselves
(see L<Tricks|/Tricks>).

=head1 QUERY EXPRESSIONS

A I<query expression> is a list of keywords
with some operators surrounding them
to provide simple boolean conditions.

Query expressions are in the form of:

  term1 & term2              # AND operator
  term1 | term2              # OR operator
  !term1                     # NOT operator
  "term one"                 # multi-word keyword
  term1 & ( term2 | term3 )  # Grouping changes precedence

All spaces are optional in query expressions,
except for those in multi-word keywords when quoted.

=head2 Expression Terms

A C<term> is one of the following:

=over 4

=item *

A single keyword, build with letters, numbers and underscore.
"C<.>" (dot) can be used as a single char wildcard.

=item *

A sentence of multiple words as a single keyword, enclosed by quotes.

=item *

A query expression,
optionally enclosed by parenteses if precedence matters.

=back

=head2 Operators

=over 4

=item * term1 AND term2

Use I<AND> operator when both terms must be present in the keyword list.

I<AND> can be written as "C<&>" (andpersand) or "C<+>" (plus), but may be ommited.

  term1 & term2
  +term1 +term2
  term1 term2

=item * term1 OR term2

Use I<OR> operator when at least one of the terms is required
in the keyword list.

I<OR> can be written as "C<|>" (vertical bar) or "C<,>" (comma), and cannot be ommited.

  term1 | term2
  term1, term2

=item * NOT term

Use I<NOT> operator when the term must not be present in the keyword list.

I<NOT> can be written as "C<!>" (exclamation mark) or "C<->" (minus).

  ! term
  -term

=back

To allow the words "AND", "OR" and "NOT" to be treated as operators,
set the C<texted_ops> parameter.

=head2 Grouping

Precedence is as usual: I<NOT> has the highest,
then I<AND>, and I<OR> has the lowest.

Precedence order in a query expression can be changed
with the use of parenteses.
For example:

  word1 | word2 & word3

is the same as:

  word1 | ( word2 & word3 )

but not as:

  ( word1 | word2 ) & word3

where word3 is required at the same time than
either word1 or word2.

Is it possible to use I<NOT> for a whole group,
so the following two queries mean the same:

  +word1 -(word2,word3)
  +word1 -word2 -word3

Expresion groups can be nested.
Also, "C<[...]>", "C<{...}>" and "C<< <...> >>"
can be used just like "C<(...)>",
but there is no validation for balanced parenteses by type,
i.e. all of them gets translated into the same before
the validation to detect an orphan one.

=head2 Tricks

=over 4

=item *

If fields names and their corresponding values
are specified inside a keywords list,
is it possible to use a single dot "C<.>" to say "C<key.value>"
as a single term in a query expression for a better match.

For example, the following query expressions:

  bar & read.yes      # matches 2 record
  bar & read & yes    # matches 3 records
  bar & "read yes"    # matches 2 record when multi_words=2
                      #  else don't match

from these keywords lists:

  foo, own:yes, read:yes, rating:3
  foo, bar, own:yes, read:yes, rating:1
  foo, bar, baz, own:yes, read:no
  bar, baz, own:no, read:yes, rating:0

=item *

Query with strings in quotes could match a keyword list
if each word is present in the list,
side by side in the same order,
when the L<< C<multi_words>|/"multi_words" >> is NOT set to 1.

Using the previous sample list,
the query expressions:

  "foo bar"     # matches 2 records
  "bar foo"     # don't match anything

=item *

Use I<OR> operator when two or more different conditions
satisfies the request.
For example, use:

  own.yes (rating.0 | -rating)

to match 2 unrated owned books from the sample list.

=item *

You can use this module against a whole document,
not only to a keywords list:

  $kw->prepare('"form method post" !captcha');
  print "Unprotected form detected\n" if $kw->test($html_page);

=back

=head1 INTERNAL BOOLEAN FORMAT

Queries in the free-style format are parsed and translated into
an strict internal format. Note that space char is not allowed.

The elements of this format are:

=over 4

=item * C<&> (andpersand)

I<AND> operator.
It can't be ommited as in free-style format.
Must be surrounded by (negated) keywords or
parenteses from the outside.

=item * C<|> (vertical bar)

I<OR> operator.
Must be surrounded by (negated) keywords or
parenteses from the outside.

=item * C<!> (exclamation mark)

I<NOT> operator.
It can appear only preceding a keyword, not a parenteses
or another one.

=item * C<(> C<)> (parenteses)

Group delimiters.
Only keywords and other parenteses can touch them from inside.
Nested groups are allowed, empty groups are not.

=item * C<keyword>

A word that matches C</\w+/> (letters, numbers or underscore).
It can optionally contain wildcards or space placeholder
following their own rules.

=item * C<.> (dot)

Single char wildcard.
A word can contain multiple wildcards, but starting or ending with one
may give unpredictable results on test.
Use with care.

=item * C<^> (caret)

Space placeholder.
Used to join multiple words as a single keyword.
This is the internal representation of quoted strings with spaces
from the free-style query.
It's not allowed to start or finish a keyword with this space placeholder,
and consecutive placeholders are also invalid.

=back

Examples:

  tom&jerry|sylvester&tweety
  moe&(shemp|curly|joe)&larry
  popeye&olive&(!bluto&!brutus)
  hagar^the^horrible|popeye^the^sailor

Examples of bad queries:

  tom&jerry,sylvester&tweety
  moe(shemp|curly|joe)larry
  popeye&olive&!(bluto|brutus)
  ^the^

=head1 KNOWN LIMITATIONS

Currently, only ASCII chars are supported.
No UTF-8, no Unicode, no accented vowels, no Kanji... Sorry!

=head1 AUTHOR

Victor Parada, C<< <vitoco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-regexp-keywords at rt.cpan.org>,
or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Regexp-Keywords>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Regexp::Keywords

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Regexp-Keywords>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Regexp-Keywords>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Regexp-Keywords>

=item * Search CPAN

L<http://search.cpan.org/dist/Regexp-Keywords/>

=back

=head1 ACKNOWLEDGEMENTS

Thank's to the Monks from the Monastery at L<http://www.perlmonks.org/>.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Victor Parada.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Regexp::Keywords
