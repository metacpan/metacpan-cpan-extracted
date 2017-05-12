#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;
use Test::More tests => 37;
#use Test::More 'no_plan';
use Lucy::Plan::Schema;
use Lucy::Plan::FullTextType;
use Lucy::Analysis::PolyAnalyzer;
use Lucy::Analysis::RegexTokenizer;
use Lucy::Index::Indexer;
use File::Spec::Functions qw(catdir);
use File::Path 'remove_tree';

my $CLASS;
BEGIN {
    $CLASS = 'PGXN::API::Searcher';
    use_ok $CLASS or die;
}

can_ok $CLASS => qw(
    new
    doc_root
    parsers
    search
);

# Build an index.
my $dir = catdir qw(t _index);
my %indexers;

INDEX: {
    if (!-e $dir) {
        require File::Path;
        File::Path::make_path($dir);
    }

    my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new(
        language => 'en',
    );

    my $fti = Lucy::Plan::FullTextType->new(
        analyzer      => $polyanalyzer,
        highlightable => 0,
    );

    my $ftih = Lucy::Plan::FullTextType->new(
        analyzer      => $polyanalyzer,
        highlightable => 1,
    );

    my $string = Lucy::Plan::StringType->new(
        indexed => 1,
        stored  => 1,
    );

    my $indexed = Lucy::Plan::StringType->new(
        indexed => 1,
        stored  => 0,
    );

    my $stored = Lucy::Plan::StringType->new(
        indexed => 0,
        stored  => 1,
    );

    my $list = Lucy::Plan::FullTextType->new(
        indexed       => 1,
        stored        => 1,
        highlightable => 1,
        analyzer      => Lucy::Analysis::RegexTokenizer->new(
            pattern => '[^\003]+'
        ),
    );

    for my $spec (
        [ docs => [
            [ key         => $indexed ],
            [ title       => $fti     ],
            [ abstract    => $fti     ],
            [ body        => $ftih    ],
            [ dist        => $fti     ],
            [ version     => $stored  ],
            [ docpath     => $stored  ],
            [ date        => $stored  ],
            [ user        => $string  ],
            [ user_name   => $fti     ],
        ]],
        [ dists => [
            [ key         => $indexed ],
            [ dist        => $fti     ],
            [ abstract    => $fti     ],
            [ description => $fti     ],
            [ readme      => $ftih    ],
            [ tags        => $list    ],
            [ version     => $stored  ],
            [ date        => $stored  ],
            [ user        => $string  ],
            [ user_name   => $fti     ],
        ]],
        [ extensions => [
            [ key         => $indexed ],
            [ extension   => $fti     ],
            [ abstract    => $ftih    ],
            [ docpath     => $stored  ],
            [ dist        => $stored  ],
            [ version     => $stored  ],
            [ date        => $stored  ],
            [ user        => $string  ],
            [ user_name   => $fti     ],
        ]],
        [ users => [
            [ key         => $indexed ],
            [ user        => $fti     ],
            [ name        => $fti     ],
            [ email       => $string  ],
            [ uri         => $string  ],
            [ details     => $ftih    ],
        ]],
        [ tags => [
            [ key         => $indexed ],
            [ tag         => $fti     ],
        ]],
    ) {
        my ($name, $fields) = @{ $spec };
        my $schema = Lucy::Plan::Schema->new;
        $schema->spec_field(name => $_->[0], type => $_->[1] )
            for @{ $fields };
        $indexers{$name} = Lucy::Index::Indexer->new(
            index    => catdir($dir, $name),
            schema   => $schema,
            create   => 1,
        );
    }
    END { remove_tree catdir $dir }
}

# Index some stuff.
for my $doc (
    # Distribution "pair"
    {
        type        => 'dists',
        abstract    => 'A key/value pair data type',
        date        => '2010-10-18T15:24:21Z',
        description => "This library contains a single PostgreSQL extension, a key/value pair data type called `pair`, along with a convenience function for constructing key/value pairs.",
        dist        => 'pair',
        key         => 'pair',
        user        => 'theory',
        readme      => 'This is the pair README file. Here you will find all thingds related to pair, including installation information',
        tags        => "ordered pair\003pair",
        user_name   => 'David E. Wheeler',
        version     => '0.1.0',
    },
    {
        type      => 'extensions',
        abstract  => 'A key/value pair data type',
        date      => '2010-10-18T15:24:21Z',
        dist      => 'pair',
        docpath   => 'doc/pair',
        extension => 'pair',
        key       => 'pair',
        user      => 'theory',
        user_name => 'David E. Wheeler',
        version   => '0.1.0',
    },
    {
        type     => 'users',
        details  => "theory David has a bio, yo. Perl and SQL and stuff",
        email    => 'david@example.com',
        key      => 'theory',
        name     => 'David E. Wheeler',
        user     => 'theory',
        uri      => 'http://justatheory.com/',
    },
    {
        type => 'tags',
        key  => 'pair',
        tag  => 'pair',
    },
    {
        type => 'tags',
        key  => 'key value',
        tag  => 'key value',
    },
    {
        type      => 'docs',
        abstract  => 'A key/value pair data type',
        body      => 'The ordered pair data type is nifty, I tell ya!',
        date      => '2010-10-18T15:24:21Z',
        dist      => 'pair',
        key       => 'pair/doc/pair',
        docpath   => 'doc/pair',
        title     => 'pair 0.1.0',
        user      => 'theory',
        user_name => 'David E. Wheeler',
        version   => '0.1.0',
    },

    # Distribution "semver".
    {
        type        => 'dists',
        abstract    => 'A semantic version data type',
        date        => '2010-10-18T15:24:21Z',
        description => 'Provides a data domain the enforces the Semantic Version format and includes support for operator-driven sort ordering.',
        dist        => 'semver',
        key         => 'semver',
        readme      => "README for the semver distribion. Installation instructions",
        tags        => "semver\003version\003semantic version",
        user        => 'roger',
        user_name   => 'Roger Davidson',
        version     => '2.1.3',
    },
    {
        type      => 'extensions',
        abstract  => 'A semantic version data type',
        date      => '2011-03-21T23:49:28Z',
        dist      => 'semver',
        docpath   => 'docs/semver',
        extension => 'semver',
        key       => 'semver',
        user      => 'roger',
        user_name => 'Roger Davidson',
        version   => '1.3.4',
    },
    {
        type      => 'extensions',
        abstract  => 'A less than semantic version data type (scary)',
        date      => '2011-03-21T23:49:28Z',
        dist      => 'semver',
        docpath   => 'docs/perver',
        extension => 'perver',
        key       => 'perver',
        user      => 'roger',
        user_name => 'Roger Davidson',
        version   => '1.3.4',
    },
    {
        type     => 'users',
        details  => "roger Roger is a Davidson. Har har.",
        email    => 'roger@example.com',
        key      => 'roger',
        name     => 'Roger Davidson',
        uri      => 'http://roger.example.com/',
        user     => 'roger',
    },
    {
        type => 'tags',
        key  => 'semver',
        tag  => 'semver',
    },
    {
        type => 'tags',
        key  => 'version',
        tag  => 'version',
    },
    {
        type => 'tags',
        key  => 'semantic version',
        tag  => 'semantic version',
    },
) {
    my $indexer = $indexers{delete $doc->{type}};
    $indexer->add_doc($doc);
}

$_->commit for values %indexers;

# Okay, do some searches!
my $search = new_ok $CLASS, ['t'], 'Instance';
is $search->doc_root, 't', 'Doc root should be set';
ok my $res = $search->search(query => 'ordered pair', in => 'dists'),
    'Search docs for "ordered pair"';
like delete $res->{hits}[0]{score}, qr/^\d+[.]\d+$/,
    'First hit score should look like a score';
like delete $res->{hits}[1]{score}, qr/^\d+[.]\d+$/,
    'Second hit score should look like a score';

TODO: {
    # Hack to work around bug in Lucy 0.2.2.
    local $TODO = 'Lucy 0.2.2 is broken' if Lucy->VERSION == 0.002002;

    is_deeply $res, {
        query  => "ordered pair",
        limit  => 50,
        offset => 0,
        count  => 2,
        hits   => [
            {
                abstract  => "A key/value pair data type",
                date      => "2010-10-18T15:24:21Z",
                dist      => "pair",
                excerpt   => "This is the <strong>pair</strong> README file. Here you will find all thingds related to <strong>pair</strong>, including installation information",
                user      => "theory",
                user_name => "David E. Wheeler",
                version   => "0.1.0",
            },
            {
                abstract  => "A semantic version data type",
                date      => "2010-10-18T15:24:21Z",
                dist      => "semver",
                excerpt   => "README for the semver distribion. Installation instructions",
                user      => "roger",
                user_name => "Roger Davidson",
                version   => "2.1.3",
            },
        ],
    }, 'Should have results for simple search';
}

# Test offset.
ok $res = $search->search(
    in     => 'dists',
    query  => 'ordered pair',
    offset => 1,
), 'Search with offset';
is $res->{count}, 2, 'Count should be 2';
is @{ $res->{hits} }, 1, 'Should have one hit';
is $res->{hits}[0]{dist}, 'semver', 'It should be the second record';

# Try limit.
ok $res = $search->search(
    in    => 'dists',
    query => 'ordered pair',
    limit => 1,
), 'Search with limit';
is $res->{count}, 2, 'Count should again be 2';
is @{ $res->{hits} }, 1, 'Should again have one hit';
is $res->{hits}[0]{dist}, 'pair', 'It should be the first record';

# Exceed the limit.
ok $res = $search->search(
    in    => 'dists',
    query => 'ordered pair',
    limit => 2048,
), 'Search with excessive limit';
is $res->{limit}, 50, 'Excessive limit should be ignored';

# Make sure : and = work.
for my $op (qw(: =)) {
    ok my $res = $search->search(query => 'dist:pair', in => 'dists'),
        qq{Search docs for "dist${op}pair"};
    like delete $res->{hits}[0]{score}, qr/^\d+[.]\d+$/,
        'The score should look like a score';
    is_deeply $res, {
        query  => "dist:pair",
        limit  => 50,
        offset => 0,
        count  => 1,
        hits   => [
            {
                abstract  => "A key/value pair data type",
                date      => "2010-10-18T15:24:21Z",
                dist      => "pair",
                excerpt   => "This is the pair README file. Here you will find all thingds related to pair, including installation information",
                user      => "theory",
                user_name => "David E. Wheeler",
                version   => "0.1.0",
            },
        ],
    }, qq{Should have single result for dist${op}pair search};
}

# Search for other stuff.
ok $res = $search->search( query => 'nifty' ),
    'Seach the docs';
like delete $res->{hits}[0]{score}, qr/^\d+[.]\d+$/,
    'The score should look like a score';
is_deeply $res, {
    query  => "nifty",
    limit  => 50,
    offset => 0,
    count  => 1,
    hits   => [
        {
            abstract => "A key/value pair data type",
            date      => "2010-10-18T15:24:21Z",
            dist      => "pair",
            excerpt   => "The ordered pair data type is <strong>nifty</strong>, I tell ya!",
            docpath   => "doc/pair",
            title     => "pair 0.1.0",
            user      => "theory",
            user_name => "David E. Wheeler",
            version   => "0.1.0",
        },
    ],
}, 'Should have expected structure for implicit docs search';

ok $res = $search->search( query => 'nifty', in => 'docs' ),
    'Seach the docs';
like delete $res->{hits}[0]{score}, qr/^\d+[.]\d+$/,
    'The score should look like a score';
is_deeply $res, {
    query  => "nifty",
    limit  => 50,
    offset => 0,
    count  => 1,
    hits   => [
        {
            abstract => "A key/value pair data type",
            date      => "2010-10-18T15:24:21Z",
            dist      => "pair",
            excerpt   => "The ordered pair data type is <strong>nifty</strong>, I tell ya!",
            docpath   => "doc/pair",
            title     => "pair 0.1.0",
            user      => "theory",
            user_name => "David E. Wheeler",
            version   => "0.1.0",
        },
    ],
}, 'Should have expected structure for docs';

ok $res = $search->search( query => 'semantic', in => 'extensions' ),
    'Seach extensions';
like delete $res->{hits}[0]{score}, qr/^\d+[.]\d+$/,
    'First hit score should look like a score';
like delete $res->{hits}[1]{score}, qr/^\d+[.]\d+$/,
    'Second hit score should look like a score';
is_deeply $res, {
    query  => "semantic",
    limit  => 50,
    offset => 0,
    count  => 2,
    hits   => [
        {
            abstract  => "A semantic version data type",
            date      => "2011-03-21T23:49:28Z",
            dist      => "semver",
            docpath   => 'docs/semver',
            excerpt   => "A <strong>semantic</strong> version data type",
            extension => "semver",
            user      => "roger",
            user_name => "Roger Davidson",
            version   => "1.3.4",
        },
        {
            abstract  => "A less than semantic version data type (scary)",
            date      => "2011-03-21T23:49:28Z",
            dist      => "semver",
            docpath   => 'docs/perver',
            excerpt   => "A less than <strong>semantic</strong> version data type (scary)",
            extension => "perver",
            user      => "roger",
            user_name => "Roger Davidson",
            version   => "1.3.4",
        },
    ],
}, 'Should have expected structure for extensions';


ok $res = $search->search( query => 'Davidson', in => 'users' ), 'Seach users';
like delete $res->{hits}[0]{score}, qr/^\d+[.]\d+$/,
    'The score should look like a score';
is_deeply $res, {
    query  => "Davidson",
    limit  => 50,
    offset => 0,
    count  => 1,
    hits   => [
        {
            excerpt => "roger Roger is a <strong>Davidson</strong>. Har har.",
            name    => "Roger Davidson",
            uri     => 'http://roger.example.com/',
            user    => "roger",
        },
    ],
}, 'Should have expected structure for users';

