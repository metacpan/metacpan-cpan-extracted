# NAME

Search::Fulltext - Fulltext search module

# SYNOPSIS

    use Search::Fulltext;
    

    my @docs = (
        'I like beer the best',
        'Wine makes people saticefied',  # does not include beer
        'Beer makes people happy',
    );
    

    my $fts = Search::Fulltext->new({
        docs => \@docs,
    });
    my $results = $fts->search('beer');
    is_deeply($results, [0, 2]);         # 1st & 3rd doc include 'beer'
    my $results = $fts->search('beer AND happy');
    is_deeply($results, [2]);            # 3rd doc includes both 'beer' & 'happy'

# DESCRIPTION

[Search::Fulltext](http://search.cpan.org/perldoc?Search::Fulltext) is a fulltext search module. It can be used in a few steps.

[Search::Fulltext](http://search.cpan.org/perldoc?Search::Fulltext) has __pluggable tokenizer__ feature, which possibly provides fulltext search for any language.
Currently, __English__ and __Japanese__ fulltext search are officially supported,
although any other languages which have spaces for separating words could be also used.
See [CUSTOM TOKENIZERS](#CUSTOM\_TOKENIZERS) section to learn how to search non-English languages.

__SQLite__'s __FTS4__ is used as an indexer.
Various queries supported by FTS4 (`AND`, `OR`, `NEAR`, ...) are fully provided.
See ["QUERIES"](#QUERIES) section for details.

# METHODS

## Search::Fulltext->new

Creates fulltext index for documents.

- `@param docs` __\[required\]__

    Reference to array whose contents are document to be searched.

- `@param index_file` __\[optional\]__

    File path to write fulltext index. By default, on-memory index is used.

- `@param tokenizer` __\[optional\]__

    Tokenizer name to use. `simple` (default) and `porter` must be supported.
    `icu` and `unicode61` could be used if your SQLite libarary used via [DBD::SQLite](http://search.cpan.org/perldoc?DBD::SQLite) module support them.
    See [http://www.sqlite.org/fts3.html\#tokenizer](http://www.sqlite.org/fts3.html\#tokenizer) for more details on FTS4 tokenizers.

    Japanese tokenizer `perl 'Search::Fulltext::Tokenizer::MeCab::tokenizer'` is also available after you install
    [Search::Fulltext::Tokenizer::MeCab](http://search.cpan.org/perldoc?Search::Fulltext::Tokenizer::MeCab) module.

    See [CUSTOM TOKENIZERS](#CUSTOM\_TOKENIZERS) section for developing other tokenizers.

## Search::Fulltext->search

Search terms in documents by query language.

- `@returns`

    Array of indexes of `docs` passed through `Search::Fulltext->new` in which `query` is matched.

- `@param query`

    Query to search from documents.
    See ["QUERIES"](#QUERIES) section for types of queries.

# QUERIES

The simplest query would be a term.

    my $results = $fts->search('beer');

Other queries below and combination of them can be also used.

    my $results = $fts->search('beer AND happy');
    my $results = $fts->search('saticefied OR happy');
    my $results = $fts->search('people NOT beer');
    my $results = $fts->search('make*');
    my $results = $fts->search('"makes people"');
    my $results = $fts->search('beer NEAR happy');
    my $results = $fts->search('beer NEAR/1 happy');

See [http://www.sqlite.org/fts3.html\#section\_3](http://www.sqlite.org/fts3.html\#section\_3) for an explanation of each type of query.

__NOTE:__ Some custom tokenizers might not support full of these queries above.
Check the document of each tokenizer before using complex queries.

# CUSTOM TOKENIZERS

Custom tokenizers can be implemented by pure perl thanks to ["Perl\_tokenizers" in DBD::SQLite](http://search.cpan.org/perldoc?DBD::SQLite#Perl\_tokenizers).
[Search::Fulltext::Tokenizer::MeCab](http://search.cpan.org/perldoc?Search::Fulltext::Tokenizer::MeCab) is an example of custom tokenizers.

See ["Perl\_tokenizers" in DBD::SQLite](http://search.cpan.org/perldoc?DBD::SQLite#Perl\_tokenizers) and [Search::Fulltext::Tokenizer::MeCab](http://search.cpan.org/perldoc?Search::Fulltext::Tokenizer::MeCab) module to learn how to develop custom tokenizers.

# SUPPORTS

Bug reports and pull requests are welcome at [https://github.com/laysakura/Search-Fulltext](https://github.com/laysakura/Search-Fulltext) !

# VERSION

Version 1.03

# AUTHOR

Sho Nakatani <lay.sakura@gmail.com>, a.k.a. @laysakura
