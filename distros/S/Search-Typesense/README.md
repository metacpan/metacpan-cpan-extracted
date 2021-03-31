# NAME

Search::Typesense - Perl interface to the Typesense search engine

# VERSION

version 0.08

# SYNOPSIS

    my $typesense = Search::Typesense->new(
        host      => $host,    # required
        api_key   => $key,     # required
        port      => $port,    # defaults to 8108
        use_https => $bool,    # defaults to true
    );
    
    my $results = $typesense->search(
        $collection_name,
        { q => 'Search String' },
    );
    if ( $results->{found} ) {
        foreach my $hit ( @{ $results->{hits} } ) {
            ...;
        }
    }

[Check here for a comparison to ElasticSearch and similar technologies](https://typesense.org/typesense-vs-algolia-vs-elasticsearch-vs-meilisearch/).

# DESCRIPTION

**ALPHA CODE**. The interface can and will change without warning.

This is an interface to the [Typesense](https://typesense.org/) search
engine. Most methods will do one of three things:

- Return results as defined in the Typesense documentation (listed per section)
- Return nothing if Typesense returns a 404.
- `croak` if Typesense returns an error.

# CONSTRUCTOR

The constructor takes a list (or hashref) of key/value pairs.

    my $typesense = Search::Typesense->new(
        host      => $host,    # required
        api_key   => $key,     # required
        port      => $port,    # defaults to 8108
        use_https => $bool,    # defaults to true
    );

## `api_key`

The api key to which will be sent as the `X-TYPESENSE-API-KEY` header.

## `host`

The hostname to connect to.

## `port`

Optional port number to connect to. Defaults to 8108 if not supplied.

## `use_https`

Optional boolean. Whether or not to connect to Typesense over https. Default true.

# METHODS

For CRUD operations on collections and documents, see the documentation for
`collections` ([Search::Typesense::Collection](https://metacpan.org/pod/Search::Typesense::Collection)) and `documents`
([Search::Typesense::Document](https://metacpan.org/pod/Search::Typesense::Document)).

## `collections`

    my $collections = $typesense->collections;
    my $collection  = $collections->get($collection_name);
    my $results     = $collections->search($collection_name, {q => 'London'});

Returns an instance of [Search::Typesense::Collection](https://metacpan.org/pod/Search::Typesense::Collection) for managing Typesense collections.

## `search`

    my $results = $typesense->search($collection_name, {q => 'London'});

Shorthand that delegated to `$typesense->collections->search(...)`.

We provide this on the top-level `$typesense` object because this is the
common case.

## `documents`

    my $documents = $typesense->documents;
    my $document  = $documents->delete($collection_name, $document_id);

Returns an instance of [Search::Typesense::Document](https://metacpan.org/pod/Search::Typesense::Document) for managing Typesense documents.

## `assert_is_running`

    $typesense->assert_is_running;

This does nothing if we can connect to Typesense. Otherwise, this method will
`croak` with a message explaining the error.

## `typesense_version`

    my $version = $typesense->typesense_version;

Returns an instance of [Search::Typesense::Version](https://metacpan.org/pod/Search::Typesense::Version).

If your version of Typesense is older than `0.8.0`, this method will return
nothing.

# INTERNATIONALIZATION (I18N)

Currently Typesense supports languages that use spaces as a word separator. In
the future, a new tokenizer will be added to support languages such as Chinese
or Japanese. I do not know the timeframe for this.

# AUTHOR

Curtis "Ovid" Poe, `<ovid at allaroundtheworld.fr>`

# BUGS

Please report any bugs or feature requests to
`https://github.com/Ovid/Search-Typesense/issues`.  I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Typesense

You can also look for information at:

- Github Repo

    [https://github.com/Ovid/Search-Typesense/](https://github.com/Ovid/Search-Typesense/)

- Issue Tracker

    [https://github.com/Ovid/Search-Typesense/issues](https://github.com/Ovid/Search-Typesense/issues)

- Search CPAN

    [https://metacpan.org/release/Search-Typesense](https://metacpan.org/release/Search-Typesense)

# ACKNOWLEDGEMENTS

Thanks for Sebastian Reidel and Matt Trout for feedback.

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Curtis "Ovid" Poe.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

# AUTHOR

Curtis "Ovid" Poe <ovid@allaroundtheworld.fr>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
