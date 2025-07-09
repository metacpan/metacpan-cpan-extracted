=encoding utf8

=head1 NAME

Query::Tags - Raku-inspired query language for attributes

=head1 SYNOPSIS

    use Query::Tags;

    # Select all @books for which the 'title' field matches the regex /Perl/.
    my $q = Query::Tags->new(q[:title/Perl/]);
    my @shelf = $q->select(@books);

=head2 VERSION

This document describes v0.0.2 of Query::Tags.

=cut

package Query::Tags v0.0.2;

=head1 DESCRIPTION

Query::Tags implements a simple query language for stringy object attributes.
Its main features are:

=over

=item Attribute syntax

C<< :key(value) >> designates that an object should have a field or method
named C<< key >> whose value should match C<< value >>. If C<< value >> is
missing (is C<undef>), the key or field should exist.

=item Regular expressions

Perl regular expressions are fully supported.

=item Junctions

Simple logic operations on queries is supported in the form of junctions
(as in Raku). For example, C<< :title!</Dummies/ /in \d+ days/> >> matches
all books whose C<title> field matches neither C</Dummies/> nor makes an
C</in \d+ days/>.

=item Pegex grammar

The language is specified using a L<Pegex> grammar which means that it can
be easily changed and extended. You can also supply your own L<Pegex::Receiver>
to the Pegex parser engine, for instance to compile a Query::Tags query to SQL.

=back

This feature set allows for reasonably flexible filtering of tagged, unstructured
data (think of email headers). They also allow for a straightforward query syntax
and quick parsing (discussed in detail below).

It does not support:

=over

=item Nested data structures

There is no way to match values inside a list, for example.

=item Types

There is no type information. All matching is string-based. There are no
operators for comparing numbers, dates or ranges (but they could be added
without too much work).

=item Complex logic

Junctions provide only a limited means for using logical connectives with
query assertions. You I<can> specify "all books whose title is X or Y" but
you I<cannot> specify "all books whose title is X or whose author is Y".

=back

=cut

use v5.16;
use strict;
use warnings;

use Pegex;
use Query::Tags::Grammar;
use Query::Tags::To::AST;

use Exporter qw(import);
our @EXPORT_OK = qw(parse_query);

=head2 Methods

=head3 new

    my $q = Query::Tags->new($query_string, \%opts);

Parses the query string and creates a new query object.
The query is internally represented by a syntax tree.

The optional argument C<\%opts> is a hashref containing
options. Only one option is supported at the moment:

=over

=item B<default_key>

Controls the matching of assertions in the query for
pairs with an empty I<key> part. If the given value is
a CODEREF, it is invoked with each tested object together
with the I<value> part of an assertion (and the C<\%opts>
hashref unaltered). It should return a truthy or falsy
value depending on match. If the B<default_key> value
is not a CODEREF it is assumed to be a string and is
used instead of any missing I<key> in an assertion.

=back

=cut

sub new {
    my ($class, $query, $opts) = @_;
    my $root = Pegex::Parser->new(
        grammar  => Query::Tags::Grammar->new,
        receiver => Query::Tags::To::AST->new,
    )->parse($query);
    bless { query => $query, tree => $root, opts => $opts // +{ } }, $class
}

=head3 tree

    my $root = $q->tree;

Get the root of the underlying syntax tree representation.
It is an object of class L<Query::Tags::To::AST::Query|Query::Tags::To::AST/"Query::Tags::To:AST::Query">.

=cut

sub tree {
    $_[0]->{tree}
}

=head3 test

    $q->test($obj) ? 'PASS' : 'FAIL'

Check if the given object passes all query assertions in C<$q>.

=cut

sub test {
    my ($self, $obj) = @_;
    $self->{tree}->test($obj, $self->{opts})
}

=head3 select

    my @pass = $q->select(@objs);

Return all objects which pass all query assertions in C<$q>.

=cut

sub select {
    my $self = shift;
    my $tree = $self->{tree};
    grep { $tree->test($_, $self->{opts}) } @_
}

=head2 Exports

=head3 parse_query

    my $q = parse_query($query_string);

Optional export which provides a more procedural interface
to L<the constructor|/"new"> of this package.

=cut

sub parse_query {
    __PACKAGE__->new(@_)
}

=head2 Query syntax

The query language is specified in a L<Pegex> grammar called C<query-tags>
which is included in the distribution's C<share> directory. See that file
for detailed technical information. What follows is an overview of the
language.

=over

=item Query

A C<query> is represented by a L<Query::Tags::To::AST::Query|Query::Tags::To::AST/"Query::Tags::To::AST::Query">
object. It contains a list of assertions in the form of C<pairs>.

=item Pair

A C<pair> consists of a I<key> and a I<value>. Keys are alphanumeric strings
(beginning with an alphabetic character) also permitting the punctuation
characters C<.>, C<-> and C<_>. The value can be a C<quoted string>, a C<regex>
or a C<junction>. A pair starts with a colon C<:> and the value is written
directly after the key. E.g., C<:key'value'> (for a string value),
C<:key/value/> (for a regex value) or C<< :key&<value1 value2> >> (for a
junction value). The value is optional.

=item Quoted string

A C<quoted string> is a string delimited by single quotes C<'>.
E.g., C<'Perl'> but B<not> C<Perl> or C<"Perl"> or C<< «Perl» >>.

=item Regex

A C<regex> is a standard Perl regex, as usual between a pair of slahes C</>
but not allowing modifiers. E.g., C</Perl/> or C</(?i)Perl/> but B<not>
C</Perl/i>.

=item Junction

A C<junction> is a superposition of several values together with a I<mode>.
The mode can be C<&> (meaning the object should match I<all> of the given
values), C<|> (the object should match I<at least one> of the given values)
and C<!> (the object should match I<none> of the given values). The list
of values is given in angular backets C<< < ... > >> and is whitespace-separated.
It can contain (and freely mix) quoted strings, regexes, junctions and barewords.
A junction can also be negated by prefixing its mode with a tilde C<~>.
E.g., C<< &</Perl/ /Master/> >> (both match) or C<< |</Perl/ /Raku/> >>
(at least one matches) or C<< ~&</AI/ /.*coin/ /as a service/> >> (not all match).

=item Bareword

All of the above constructs start with a non-alphabetical character:
C<:> for pairs, C<'> for quoted strings, C</> for regexes and C<&>,
C<|>, C<!> or C<~> for junctions. Hence, single word strings do not
actually have to be written in quotes as they can be distinguished
from non-strings. A C<bareword> is a string of C<\w> characters,
C<\d> numbers or the punctuation characters C<.>, C<-> or C<_>.
It is internally converted to a string. Barewords can appear in
junctions as well as the top-level query. At the top level, they are
converted to pairs with B<no key> and with the bareword as a string
value. It is up to the application to decide what to do with them.

=back

=head1 EXAMPLES

=head2 Searching a small database

Get all books (co-)authored by C</foy/>:

    use Modern::Perl;
    use Query::Tags qw(parse_query);

    my @books = (
        { title => 'Programming Perl', authors => 'Tom Christiansen, brian d foy, Larry Wall, Jon Orwant' },
        { title => 'Learning Perl', authors => 'Randal L. Schwartz, Tom Phoenix, brian d foy' },
        { title => 'Intermediate Perl', authors => 'Randal L. Schwartz and brian d foy, with Tom Phoenix' },
        { title => 'Mastering Perl', authors => 'brian d foy' },
        { title => 'Perl Best Practices', authors => 'Damian Conway' },
        { title => 'Higher-Order Perl', authors => 'Mark-Jason Dominus' },
        { title => 'Object Oriented Perl', authors => 'Damian Conway' },
        { title => 'Modern Perl', authors => 'chromatic' }
    );

    say $_->{title} for parse_query(q[:authors/foy/])->select(@books);

=head2 Email headers

Find all work emails from a mailing list that mention C</seminar/> or C</talk/>:

    use v5.16;
    use Mail::Header;
    use Path::Tiny;
    use Query::Tags qw(parse_query);

    my @mail = map { Mail::Header->new([$_->lines]) } path('~/Mail/work/cur')->children;
    my @headers = map { my $mh = $_; +{ map { fc $_ => $mh->get($_) } $mh->tags } } @mail;
    say $_->{subject} for
        parse_query(q[:list-id :subject|</(?i)seminar/ /(?i)talk/>])->select(@headers);

=cut

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2025 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
