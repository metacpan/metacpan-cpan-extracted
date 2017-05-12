#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;
use Data::Dump qw(pp);

use Test::More tests => 42;

BEGIN {
    use_ok('Text::Search::SQL');
}

# GLOBAL VARIABLES
my ($sp);

# make sure we offer the expected methods in the interface
can_ok('Text::Search::SQL',
    qw[
        new
        set_search_term
        get_search_term
        set_search_fields
        get_search_fields
        set_search_type
        get_search_type
        set_chunks
        get_chunks
        set_sql_where
        get_sql_where
        parse

        _parse_chunks
    ]
);

# get a new instance of the object, name sure it's what we're expecting
$sp = Text::Search::SQL->new();
isa_ok($sp, q{Text::Search::SQL});

# calling with no argument means we should have default attributes
is( $sp->{search_term}, undef, q{undefined search_term} );

# create a new object with a search_term in the call to new
$sp = Text::Search::SQL->new(
    {
        search_term => 'one man'
    }
);
isa_ok($sp, q{Text::Search::SQL});

# calling with no argument means we should have default attributes
is( $sp->{search_term}, q{one man}, q{search_term is 'one man'} );

# using set_search_term() gives expected results
$sp->set_search_term('went to mow');
is( $sp->{search_term}, q{went to mow}, q{search_term is 'went to mow'} );

# data to loop through for _parse_chunks() and parse() tests
my @data = (
    {
        input   => q{isn't},
        parse  => [ q{isn't} ],

        search_fields   => [ qw/subject/ ],
        sql_where       => [
            subject => { '=' => [ q{isn't} ] },
        ],
    },
    {
        input   => q{went to mow},
        parse  => ['went', 'to', 'mow'],

        search_fields   => [ qw/subject/ ],
        sql_where       => [
            subject => { '=' => [ qw(went to mow) ] },
        ],
    },
    {
        input   => q{"went to" mow},
        parse  => ['went to', 'mow'],

        search_fields   => [ qw/subject/ ],
        sql_where       => [
            subject => { '=' => [ q{went to}, q{mow} ] },
        ],
    },
    {
        input   => q{'went to' mow},
        parse  => [ q{'went}, q{to'}, q{mow} ],
    },
    {
        input   => q{'went to' "mow a meadow"},
        parse  => [ q{'went}, q{mow a meadow}, q{to'}],
    },
    {
        input   => q{went to' mow a meadow"},
        parse  => [ q{a}, q{meadow"}, q{mow}, q{to'}, q{went} ],
    },
    {
        input   => q{went to' mow a "meadow"'},
        parse  => [ q{'}, q{a}, q{meadow}, q{mow}, q{to'}, q{went} ],
    },
    {
        input   => q{went to" mow a 'meadow'"},
        parse  => [ q{ mow a 'meadow'}, q{to}, q{went} ],
    },
    {
        input   => q{isn't it nice to be here?},
        parse  => [ q{isn't}, q{it}, q{nice}, q{to}, q{be}, q{here?} ],
    },
    {
        input   => q{"isn't it nice to be here?"},
        parse  => [ q{isn't it nice to be here?} ],
    },

    # some tests geared to the returned where data
    {
        input   => q{alpha beta},
        parse  => [ qw(alpha beta) ],

        search_fields   => [ qw(subject) ],
        sql_where       => [
            subject => { '=' => [ qw(alpha beta) ] },
        ],
    },
    {
        input   => q{alpha beta},
        parse  => [ qw(alpha beta) ],

        search_fields   => [ qw(subject message) ],
        sql_where       => [
            subject => { '=' => [ qw(alpha beta) ] },
            message => { '=' => [ qw(alpha beta) ] },
        ],
    },

    # search type tests
    {
        input   => q{haven't},
        chunks  => [ q{haven't} ],
        parse   => [ q{%haven't%} ],

        search_fields   => [ qw/subject/ ],
        search_type     => q{like},
        sql_where       => [
            subject => { 'like' => [ q{%haven't%} ] },
        ],
    },
    {
        input   => q{alpha beta gamma},
        parse   => [ qw(alpha beta gamma) ],

        search_fields   => [ qw(subject message) ],
        search_type     => q{like},
        sql_where       => [
            subject => { 'like' => [ qw(%alpha% %beta% %gamma%) ] },
            message => { 'like' => [ qw(%alpha% %beta% %gamma%) ] },
        ],
    },
);

# tests for _parse_chunks()
foreach my $data (@data) {
    # _parse_chunks()
    my $chunks = $sp->_parse_chunks( $data->{input} );
    my $expected = $data->{chunks} || $data->{parse};

    is_deeply(
        [ sort @{ $chunks } ],
        [ sort @{ $expected } ],
        qq{_parse_chunks: $data->{input}}
    );

    # check where clause meets our expectation
    if (defined $data->{search_fields}) {
        $sp->set_search_fields( $data->{search_fields} );
    }

    # parse()
    $sp->set_search_term( $data->{input} );
    # if we have a search_type, set it
    if (defined $data->{search_type}) {
        $sp->set_search_type( $data->{search_type} );
        is (
            $sp->get_search_type(),
            $data->{search_type},
            qq{search_type set correctly for $data->{input}}
        )
    };
    $sp->parse();
    # if we're not doing a like search, we should have matching chunks
    if( not defined $data->{search_type}
            or
        $data->{search_type} !~ m{\A(?:like|ilike)\z}xms
    ) {
        is_deeply(
            $sp->{chunks},
            $chunks,
            qq{\$sp->{chunks} matches _parse_chunks($data->{input})}
        );
    }

    # where clause
    if (defined $data->{sql_where}) {
        is_deeply(
            $sp->get_sql_where(),
            $data->{sql_where},
            qq{correct where data for $data->{input}},
        );
    }
}

