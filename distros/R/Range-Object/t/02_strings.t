use strict;
use warnings;

use Test::More tests => 101;

BEGIN { use_ok 'Range::Object::String' };

my $tests = eval do { local $/; <DATA>; };
die "Data eval error: $@" if $@;

die "Nothing to test!" unless $tests;

require 't/tests.pl';

run_tests( $tests );

__DATA__
[
    'Range::Object::String' => [
        # Custom code
        undef,

        # No invalid values for Range::Object::String
        [],

        # Valid input
        [ qw(foo bar baz qux), 'blarg10-blarg15' ],

        # Valid in() items
        [ qw(foo bar baz qux blarg10-blarg15) ],

        # Not in() input
        [ qw(quux fooo baar bazz blarg09 blarg11.5 blarg16) ],

        # Not in() output
        [ qw(baar bazz blarg09 blarg11.5 blarg16 fooo quux) ],

        # List context range() output
        [ qw(bar baz blarg10-blarg15 foo qux) ],

        # Scalar context range() output
        "bar\nbaz\nblarg10-blarg15\nfoo\nqux",

        # List context collapsed() output
        [ 'bar', 'baz', 'blarg10-blarg15', 'foo', 'qux' ],

        # Scalar context collapsed() output
        "bar\nbaz\nblarg10-blarg15\nfoo\nqux",

        # Initital range size()
        5,

        # add() input
        [ 'splurge', 'mymse' ],

        # Valid in() items after add()
        [ qw(bar baz blarg10-blarg15 foo mymse qux splurge) ],

        # Not in() input after add()
        [ qw(quux fooo baar bazz blarg09 blarg11.5 blarg16) ],

        # Not in() output
        [ qw(quux fooo baar bazz blarg09 blarg11.5 blarg16) ],

        # List context range() output after add()
        [ qw(bar baz blarg10-blarg15 foo mymse qux splurge) ],

        # Scalar context range() output after add()
        "bar\nbaz\nblarg10-blarg15\nfoo\nmymse\nqux\nsplurge",

        # List context collapsed() output after add()
        [ qw(bar baz blarg10-blarg15 foo mymse qux splurge) ],

        # Scalar context collapsed() output after add()
        "bar\nbaz\nblarg10-blarg15\nfoo\nmymse\nqux\nsplurge",

        # Size after add()
        7,

        # remove() input
        [ qw(baz blarg10-blarg15 foo mymse) ],

        # Valid in() items after remove()
        [ qw(bar qux splurge) ],

        # Not in() input after remove()
        [ qw(quux fooo baar bazz blarg09 blarg11.5 blarg16 baz foo
             blarg10-blarg15 mymse) ],

        # Not in() output
        [ qw(quux fooo baar bazz blarg09 blarg11.5 blarg16 baz foo
             blarg10-blarg15 mymse) ],

        # List context range() output after remove()
        [ qw(bar qux splurge) ],

        # Scalar context range() output after remove()
        "bar\nqux\nsplurge",

        # List context collapsed() output after remove()
        [ qw(bar qux splurge) ],

        # Scalar context collapsed() output after remove()
        "bar\nqux\nsplurge",

        # size() after remove()
        3,
    ],
]
