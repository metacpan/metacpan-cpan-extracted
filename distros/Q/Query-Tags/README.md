# NAME

Query::Tags - Raku-inspired query language for attributes

# SYNOPSIS

    use Query::Tags;

    # Select all @books for which the 'title' field matches the regex /Perl/.
    my $q = Query::Tags->new(q[:title/Perl/]);
    my @shelf = $q->select(@books);

## VERSION

This document describes v0.0.2 of Query::Tags.

# DESCRIPTION

Query::Tags implements a simple query language for stringy object attributes.
Its main features are:

- Attribute syntax

    `:key(value)` designates that an object should have a field or method
    named `key` whose value should match `value`. If `value` is
    missing (is `undef`), the key or field should exist.

- Regular expressions

    Perl regular expressions are fully supported.

- Junctions

    Simple logic operations on queries is supported in the form of junctions
    (as in Raku). For example, `:title!</Dummies/ /in \d+ days/>` matches
    all books whose `title` field matches neither `/Dummies/` nor makes an
    `/in \d+ days/`.

- Pegex grammar

    The language is specified using a [Pegex](https://metacpan.org/pod/Pegex) grammar which means that it can
    be easily changed and extended. You can also supply your own [Pegex::Receiver](https://metacpan.org/pod/Pegex%3A%3AReceiver)
    to the Pegex parser engine, for instance to compile a Query::Tags query to SQL.

This feature set allows for reasonably flexible filtering of tagged, unstructured
data (think of email headers). They also allow for a straightforward query syntax
and quick parsing (discussed in detail below).

It does not support:

- Nested data structures

    There is no way to match values inside a list, for example.

- Types

    There is no type information. All matching is string-based. There are no
    operators for comparing numbers, dates or ranges (but they could be added
    without too much work).

- Complex logic

    Junctions provide only a limited means for using logical connectives with
    query assertions. You _can_ specify "all books whose title is X or Y" but
    you _cannot_ specify "all books whose title is X or whose author is Y".

## Methods

### new

    my $q = Query::Tags->new($query_string, \%opts);

Parses the query string and creates a new query object.
The query is internally represented by a syntax tree.

The optional argument `\%opts` is a hashref containing
options. Only one option is supported at the moment:

- **default\_key**

    Controls the matching of assertions in the query for
    pairs with an empty _key_ part. If the given value is
    a CODEREF, it is invoked with each tested object together
    with the _value_ part of an assertion (and the `\%opts`
    hashref unaltered). It should return a truthy or falsy
    value depending on match. If the **default\_key** value
    is not a CODEREF it is assumed to be a string and is
    used instead of any missing _key_ in an assertion.

### tree

    my $root = $q->tree;

Get the root of the underlying syntax tree representation.
It is an object of class [Query::Tags::To::AST::Query](https://metacpan.org/pod/Query%3A%3ATags%3A%3ATo%3A%3AAST#Query::Tags::To:AST::Query).

### test

    $q->test($obj) ? 'PASS' : 'FAIL'

Check if the given object passes all query assertions in `$q`.

### select

    my @pass = $q->select(@objs);

Return all objects which pass all query assertions in `$q`.

## Exports

### parse\_query

    my $q = parse_query($query_string);

Optional export which provides a more procedural interface
to [the constructor](#new) of this package.

## Query syntax

The query language is specified in a [Pegex](https://metacpan.org/pod/Pegex) grammar called `query-tags`
which is included in the distribution's `share` directory. See that file
for detailed technical information. What follows is an overview of the
language.

- Query

    A `query` is represented by a [Query::Tags::To::AST::Query](https://metacpan.org/pod/Query%3A%3ATags%3A%3ATo%3A%3AAST#Query::Tags::To::AST::Query)
    object. It contains a list of assertions in the form of `pairs`.

- Pair

    A `pair` consists of a _key_ and a _value_. Keys are alphanumeric strings
    (beginning with an alphabetic character) also permitting the punctuation
    characters `.`, `-` and `_`. The value can be a `quoted string`, a `regex`
    or a `junction`. A pair starts with a colon `:` and the value is written
    directly after the key. E.g., `:key'value'` (for a string value),
    `:key/value/` (for a regex value) or `:key&<value1 value2>` (for a
    junction value). The value is optional.

- Quoted string

    A `quoted string` is a string delimited by single quotes `'`.
    E.g., `'Perl'` but **not** `Perl` or `"Perl"` or `«Perl»`.

- Regex

    A `regex` is a standard Perl regex, as usual between a pair of slahes `/`
    but not allowing modifiers. E.g., `/Perl/` or `/(?i)Perl/` but **not**
    `/Perl/i`.

- Junction

    A `junction` is a superposition of several values together with a _mode_.
    The mode can be `&` (meaning the object should match _all_ of the given
    values), `|` (the object should match _at least one_ of the given values)
    and `!` (the object should match _none_ of the given values). The list
    of values is given in angular backets `< ... >` and is whitespace-separated.
    It can contain (and freely mix) quoted strings, regexes, junctions and barewords.
    A junction can also be negated by prefixing its mode with a tilde `~`.
    E.g., `&</Perl/ /Master/>` (both match) or `|</Perl/ /Raku/>`
    (at least one matches) or `~&</AI/ /.*coin/ /as a service/>` (not all match).

- Bareword

    All of the above constructs start with a non-alphabetical character:
    `:` for pairs, `'` for quoted strings, `/` for regexes and `&`,
    `|`, `!` or `~` for junctions. Hence, single word strings do not
    actually have to be written in quotes as they can be distinguished
    from non-strings. A `bareword` is a string of `\w` characters,
    `\d` numbers or the punctuation characters `.`, `-` or `_`.
    It is internally converted to a string. Barewords can appear in
    junctions as well as the top-level query. At the top level, they are
    converted to pairs with **no key** and with the bareword as a string
    value. It is up to the application to decide what to do with them.

# EXAMPLES

## Searching a small database

Get all books (co-)authored by `/foy/`:

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

## Email headers

Find all work emails from a mailing list that mention `/seminar/` or `/talk/`:

    use v5.16;
    use Mail::Header;
    use Path::Tiny;
    use Query::Tags qw(parse_query);

    my @mail = map { Mail::Header->new([$_->lines]) } path('~/Mail/work/cur')->children;
    my @headers = map { my $mh = $_; +{ map { fc $_ => $mh->get($_) } $mh->tags } } @mail;
    say $_->{subject} for
        parse_query(q[:list-id :subject|</(?i)seminar/ /(?i)talk/>])->select(@headers);

# AUTHOR

Tobias Boege <tobs@taboege.de>

# COPYRIGHT AND LICENSE

This software is copyright (C) 2025 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.
