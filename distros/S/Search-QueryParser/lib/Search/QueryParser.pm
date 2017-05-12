package Search::QueryParser;

use strict;
use warnings;
use locale;

our $VERSION = "0.94";

=head1 NAME

Search::QueryParser - parses a query string into a data structure
suitable for external search engines

=head1 SYNOPSIS

  my $qp = new Search::QueryParser;
  my $s = '+mandatoryWord -excludedWord +field:word "exact phrase"';
  my $query = $qp->parse($s)  or die "Error in query : " . $qp->err;
  $someIndexer->search($query);

  # query with comparison operators and implicit plus (second arg is true)
  $query = $qp->parse("txt~'^foo.*' date>='01.01.2001' date<='02.02.2002'", 1);

  # boolean operators (example below is equivalent to "+a +(b c) -d")
  $query = $qp->parse("a AND (b OR c) AND NOT d");

  # subset of rows
  $query = $qp->parse("Id#123,444,555,666 AND (b OR c)");


=head1 DESCRIPTION

This module parses a query string into a data structure to be handled
by external search engines.  For examples of such engines, see
L<File::Tabular> and L<Search::Indexer>.

The query string can contain simple terms, "exact phrases", field
names and comparison operators, '+/-' prefixes, parentheses, and
boolean connectors.

The parser can be parameterized by regular expressions for specific
notions of "term", "field name" or "operator" ; see the L<new>
method. The parser has no support for lemmatization or other term
transformations : these should be done externally, before passing the
query data structure to the search engine.

The data structure resulting from a parsed query is a tree of terms
and operators, as described below in the L<parse> method.  The
interpretation of the structure is up to the external search engine
that will receive the parsed query ; the present module does not make
any assumption about what it means to be "equal" or to "contain" a
term.


=head1 QUERY STRING

The query string is decomposed into "items", where 
each item has an optional sign prefix, 
an optional field name and comparison operator, 
and a mandatory value.

=head2 Sign prefix

Prefix '+' means that the item is mandatory.
Prefix '-' means that the item must be excluded.
No prefix means that the item will be searched
for, but is not mandatory.

As far as the result set is concerned, 
C<+a +b c> is strictly equivalent to C<+a +b> : the search engine will
return documents containing both terms 'a' and 'b', and possibly
also term 'c'. However, if the search engine also returns
relevance scores, query C<+a +b c> might give a better score
to documents containing also term 'c'.

See also section L<Boolean connectors> below, which is another
way to combine items into a query.

=head2 Field name and comparison operator

Internally, each query item has a field name and comparison 
operator; if not written explicitly in the query, these
take default values C<''> (empty field name) and 
C<':'> (colon operator).

Operators have a left operand (the field name) and 
a right operand (the value to be compared with);
for example, C<foo:bar> means "search documents containing 
term 'bar' in field 'foo'", whereas C<foo=bar> means 
"search documents where field 'foo' has exact value 'bar'".

Here is the list of admitted operators with their intended meaning :

=over

=item C<:>

treat value as a term to be searched within field. 
This is the default operator.

=item C<~> or C<=~>

treat value as a regex; match field against the regex.

=item C<!~>

negation of above

=item C<==> or C<=>, C<E<lt>=>, C<E<gt>=>, C<!=>, C<E<lt>>, C<E<gt>>

classical relational operators

=item C<#>

Inclusion in the set of comma-separated integers supplied
on the right-hand side. 


=back

Operators C<:>, C<~>, C<=~>, C<!~> and C<#> admit an empty 
left operand (so the field name will be C<''>).
Search engines will usually interpret this as 
"any field" or "the whole data record".

=head2 Value

A value (right operand to a comparison operator) can be 

=over

=item *

just a term (as recognized by regex C<rxTerm>, see L<new> method below)

=item *

A quoted phrase, i.e. a collection of terms within
single or double quotes.

Quotes can be used not only for "exact phrases", but also
to prevent misinterpretation of some values : for example
C<-2> would mean "value '2' with prefix '-'", 
in other words "exclude term '2'", so if you want to search for
value -2, you should write C<"-2"> instead. In the 
last example of the synopsis, quotes were used to
prevent splitting of dates into several search terms.

=item *

a subquery within parentheses.
Field names and operators distribute over parentheses, so for 
example C<foo:(bar bie)> is equivalent to 
C<foo:bar foo:bie>. 
Nested field names such as C<foo:(bar:bie)> are not allowed.
Sign prefixes do not distribute : C<+(foo bar) +bie> is not
equivalent to C<+foo +bar +bie>.


=back


=head2 Boolean connectors

Queries can contain boolean connectors 'AND', 'OR', 'NOT'
(or their equivalent in some other languages).
This is mere syntactic sugar for the '+' and '-' prefixes :
C<a AND b> is translated into C<+a +b>;
C<a OR b> is translated into C<(a b)>;
C<NOT a> is translated into C<-a>.
C<+a OR b> does not make sense, 
but it is translated into C<(a b)>, under the assumption
that the user understands "OR" better than a 
'+' prefix.
C<-a OR b> does not make sense either, 
but has no meaningful approximation, so it is rejected.

Combinations of AND/OR clauses must be surrounded by
parentheses, i.e. C<(a AND b) OR c> or C<a AND (b OR c)> are
allowed, but C<a AND b OR c> is not.


=head1 METHODS

=over

=cut

use constant DEFAULT => {
  rxTerm      => qr/[^\s()]+/,
  rxField     => qr/\w+/,

  rxOp        => qr/==|<=|>=|!=|=~|!~|[:=<>~#]/, # longest ops first !
  rxOpNoField => qr/=~|!~|[~:#]/, # ops that admit an empty left operand

  rxAnd       => qr/AND|ET|UND|E/,
  rxOr        => qr/OR|OU|ODER|O/,
  rxNot       => qr/NOT|PAS|NICHT|NON/,

  defField    => "",
};

=item new

  new(rxTerm   => qr/.../, rxOp => qr/.../, ...)

Creates a new query parser, initialized with (optional) regular
expressions :

=over

=item rxTerm

Regular expression for matching a term.
Of course it should not match the empty string.
Default value is C<qr/[^\s()]+/>.
A term should not be allowed to include parenthesis, otherwise the parser
might get into trouble.

=item rxField

Regular expression for matching a field name.
Default value is C<qr/\w+/> (meaning of C<\w> according to C<use locale>).

=item rxOp

Regular expression for matching an operator.
Default value is C<qr/==|E<lt>=|E<gt>=|!=|=~|!~|:|=|E<lt>|E<gt>|~/>.
Note that the longest operators come first in the regex, because
"alternatives are tried from left to right" 
(see L<perlre/Version 8 Regular Expressions>) :
this is to avoid C<aE<lt>=3> being parsed as
C<a E<lt> '=3'>.

=item rxOpNoField

Regular expression for a subset of the operators
which admit an empty left operand (no field name).
Default value is C<qr/=~|!~|~|:/>.
Such operators can be meaningful for comparisons
with "any field" or with "the whole record" ;
the precise interpretation depends on the search engine.

=item rxAnd

Regular expression for boolean connector AND.
Default value is C<qr/AND|ET|UND|E/>.

=item rxOr

Regular expression for boolean connector OR.
Default value is C<qr/OR|OU|ODER|O/>.

=item rxNot

Regular expression for boolean connector NOT.
Default value is C<qr/NOT|PAS|NICHT|NON/>.

=item defField

If no field is specified in the query, use I<defField>.
The default is the empty string "".

=back

=cut

sub new {
  my $class = shift;
  my $args = ref $_[0] eq 'HASH' ? $_[0] : {@_};

  # create object with default values
  my $self = bless {}, $class;
  $self->{$_} = $args->{$_} || DEFAULT->{$_} 
    foreach qw(rxTerm rxField rxOp rxOpNoField rxAnd rxOr rxNot defField);
  return $self;
}

=item parse

  $q = $queryParser->parse($queryString, $implicitPlus);

Returns a data structure corresponding to the parsed string.
The second argument is optional; if true, it adds an implicit
'+' in front of each term without prefix, so
C<parse("+a b c -d", 1)> is equivalent to C<parse("+a +b +c -d")>.
This is often seen in common WWW search engines
as an option "match all words".

The return value has following structure :

  { '+' => [{field=>'f1', op=>':', value=>'v1', quote=>'q1'}, 
            {field=>'f2', op=>':', value=>'v2', quote=>'q2'}, ...],
    ''  => [...],
    '-' => [...]
  }

In other words, it is a hash ref with 3 keys C<'+'>, C<''> and C<'-'>,
corresponding to the 3 sign prefixes (mandatory, ordinary or excluded
items). Each key holds either a ref to an array of items, or 
C<undef> (no items with this prefix in the query).

An I<item> is a hash ref containing 

=over

=item C<field>

scalar, field name (may be the empty string)

=item C<op>

scalar, operator

=item C<quote>

scalar, character that was used for quoting the value ('"', "'" or undef)

=item C<value> 

Either

=over

=item *

a scalar (simple term), or

=item *

a recursive ref to another query structure. In that case, 
C<op> is necessarily C<'()'> ; this corresponds
to a subquery in parentheses.

=back

=back

In case of a parsing error, C<parse> returns C<undef>;
method L<err> can be called to get an explanatory message.

=cut



sub parse { return (_parse(@_))[0]; } # just return 1st result from _parse

sub _parse{ # returns ($parsedQuery, $restOfString)
  my $self = shift;
  my $s = shift;
  my $implicitPlus = shift;
  my $parentField = shift;	# only for recursive calls
  my $parentOp = shift;		# only for recursive calls

  my $q = {};
  my $preBool = '';
  my $err = undef;
  my $s_orig = $s;

  $s =~ s/^\s+//; # remove leading spaces

LOOP : 
  while ($s) { # while query string is not empty
    for ($s) { # temporary alias to $_ for easier regex application
      my $sign = $implicitPlus ? "+" : "";
      my $field = $parentField || $self->{defField};
      my $op = $parentOp || ":";

      last LOOP if m/^\)/; # return from recursive call if meeting a ')'

      # try to parse sign prefix ('+', '-' or 'NOT')
      if    (s/^(\+|-)\s*//)             { $sign = $1;  }
      elsif (s/^($self->{rxNot})\b\s*//) { $sign = '-'; }

      # try to parse field name and operator
      if (s/^"($self->{rxField})"\s*($self->{rxOp})\s*// # "field name" and op
          or 
          s/^'($self->{rxField})'\s*($self->{rxOp})\s*// # 'field name' and op
          or 
          s/^($self->{rxField})\s*($self->{rxOp})\s*//   # field name and op
	  or
	  s/^()($self->{rxOpNoField})\s*//) {          # no field, just op
      	$err = "field '$1' inside '$parentField'", last LOOP if $parentField;
	($field, $op) = ($1, $2); 
      }

      # parse a value (single term or quoted list or parens)
      my $subQ = undef;

      if (s/^(")([^"]*?)"\s*// or 
	  s/^(')([^']*?)'\s*//) { # parse a quoted string. 
	my ($quote, $val) = ($1, $2);
	$subQ = {field=>$field, op=>$op, value=>$val, quote=>$quote};
      }
      elsif (s/^\(\s*//) { # parse parentheses 
	my ($r, $s2) = $self->_parse($s, $implicitPlus, $field, $op);
	$err = $self->err, last LOOP if not $r; 
	$s = $s2;
	$s =~ s/^\)\s*// or $err = "no matching ) ", last LOOP;
	$subQ = {field=>'', op=>'()', value=>$r}; 
      }
      elsif (s/^($self->{rxTerm})\s*//) { # parse a single term
	$subQ = {field=>$field, op=>$op, value=>$1};
      }

      # deal with boolean connectors
      my $postBool = '';
      if    (s/^($self->{rxAnd})\b\s*//) { $postBool = 'AND' }
      elsif (s/^($self->{rxOr})\b\s*//)  { $postBool = 'OR'  }
      $err = "cannot mix AND/OR in requests; use parentheses", last LOOP
	if $preBool and $postBool and $preBool ne $postBool;
      my $bool = $preBool || $postBool;
      $preBool = $postBool; # for next loop

      # insert subquery in query structure
      if ($subQ) {
	$sign = ''  if $sign eq '+' and $bool eq 'OR';
	$sign = '+' if $sign eq ''  and $bool eq 'AND';
	$err = 'operands of "OR" cannot have "-" or "NOT" prefix', last LOOP
	  if $sign eq '-' and $bool eq 'OR';
	push @{$q->{$sign}}, $subQ;
      }
      else {
	$err = "unexpected string in query : $_", last LOOP if $_;
	$err = "missing value after $field $op", last LOOP if $field;
      }
    }
  }

  $err ||= "no positive value in query" unless $q->{'+'} or $q->{''};
  $self->{err} = $err ? "[$s_orig] : $err" : "";
  $q = undef if $err;
  return ($q, $s);
}


=item err

  $msg = $queryParser->err;

Message describing the last parse error

=cut

sub err {
  my $self = shift;
  return $self->{err};
}


=item unparse

  $s = $queryParser->unparse($query);

Returns a string representation of the C<$query> data structure.

=cut

sub unparse {
  my $self = shift;
  my $q = shift;

  my @subQ;
  foreach my $prefix ('+', '', '-') {
    next if not $q->{$prefix};
    push @subQ, $prefix . $self->unparse_subQ($_) foreach @{$q->{$prefix}};
  }
  return join " ", @subQ;
}

sub unparse_subQ {
  my $self = shift;
  my $subQ = shift;

  return  "(" . $self->unparse($subQ->{value}) . ")"  if $subQ->{op} eq '()';
  my $quote = $subQ->{quote} || "";
  return "$subQ->{field}$subQ->{op}$quote$subQ->{value}$quote";
}

=back

=head1 AUTHOR

Laurent Dami, E<lt>laurent.dami AT etat ge chE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2007 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;

