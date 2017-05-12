#!/usr/bin/perl

use strict;
use warnings;

use String::Defer;
use t::Utils;

import_ok "String::Defer", ["djoin"],   "djoin import succeeds";
is_import "djoin", "String::Defer",     "djoin imports correctly"
    or die "can't import djoin";

new_import_pkg;

import_ok "String::Defer", [],          "empty import list succeeds";
cant_ok "djoin",                        "djoin not exported by default";

String::Defer->import("djoin");

my @targ        = map \my $x, 0..2;
my @defer       = map String::Defer->new($targ[$_]), 0..2;
my @subclass    = map t::Subclass->new($targ[$_]), 0..2;

sub settarg { ${$targ[$_]} = $_[$_] for 0..$#_ }

for (
    [sub { String::Defer->join(@_) },   "String::Defer",
        "->join"],

    [sub { t::Subclass->join(@_) },     "t::Subclass",
        "subclass->join"],
    
    [sub { djoin(@_) },                 "String::Defer",
        "djoin"],
) {
    my ($joiner, $class, $jtype) = @$_;

    for (
        [[":", @defer],         
            "foo:bar:baz",  "one:two:three",
            "$jtype"],

        [[@defer],
            "barfoobaz",    "twoonethree",          
            "$jtype on deferred"],

        [[":", $defer[0], "A", $defer[1], "B"],
            "foo:A:bar:B",  "one:A:two:B",
            "mixed $jtype"],

        [[$defer[0], qw/A B C/],
            "AfooBfooC",    "AoneBoneC",
            "$jtype of plain on deferred"],

        [[$defer[0], "A", $defer[1], "B"],
            "AfoobarfooB",  "AonetwooneB",
            "mixed $jtype on deferred"],

        # XXX this should probably not defer the result
        [[qw/: A B C/],
            "A:B:C",        "A:B:C",
            "$jtype of all plain strings"],

        [[":", @subclass],
            "foo:bar:baz",  "one:two:three",
            "$jtype of subclass"],

        [[@subclass],
            "barfoobaz",    "twoonethree",
            "$jtype on subclass"],

        [[$subclass[0], @defer],
            "foofoobarfoobaz",  "oneonetwoonethree",
            "$jtype of superclass on subclass"],

        [[":", @subclass, @defer],
            "foo:bar:baz:foo:bar:baz",  "one:two:three:one:two:three",
            "mixed $jtype of sub- and superclass"],
    ) {
        my ($args, $fbb, $ott, $name) = @$_;

        settarg qw/foo bar baz/;
        my $join = eval { $joiner->(@$args) };

        ok defined $join,               "$name succeeds";
        is_defer $join,                 "$name isa String::Defer";
        is blessed $join, $class,       "$name is really a $class";

        is "$join", $fbb,               "$name forces correctly";

        settarg qw/one two three/;
        is "$join", $ott,               "$name defers correctly";
    }

    settarg qw/foo/;
    my $hex = "\\(0x[[:xdigit:]]+\\)";

    for (
        [SCALAR         => \1                                           ],
        [REF            => \\1, ($] >= 5.008 ? "REF$hex" : "SCALAR$hex")],
    ($] >= 5.010 ? (
        [VSTRING        => \v1                                          ],
        [REGEXP         => ${qr/x/},    
                            ($] >= 5.012 ? quotemeta(qr/x/) : "")       ],
    ) : () ),
        [LVALUE         => \substr(my $x = "x", 0, 1)                   ],
        [ARRAY          => []                                           ],
        [HASH           => {}                                           ],
        [CODE           => sub { 1 }                                    ],
        [GLOB           => \*STDOUT,                                    ],
        [IO             => *STDOUT{IO},         
                ($] > 5.011 ? "IO::File=IO$hex" : "IO::Handle=IO$hex")  ],
    ($] >= 5.008 ? (
        [FORMAT         => *Format{FORMAT}                              ],
    ) : () ),
        ["plain object" => PlainObject->new,    "PlainObject=ARRAY$hex" ],
    ) {
        my ($rtype, $ref, $pat) = @$_;

        defined $pat or $pat = "$rtype$hex";
        my $join = eval { $joiner->(":", $defer[0], $ref) };

        ok defined $join,           "$jtype of $rtype ref succeeds";
        like "$join", qr/^foo:$pat$/,
                                    "$jtype stringifies $rtype refs";
    }

    {
        settarg qw/foo/;
        my $obj = StrOverload->new("bar");
        my $join = $joiner->(":", $defer[0], $obj);
        is "$join", "foo:bar",      "$jtype with \"\"-overloaded object";

        settarg qw/one/;
        $obj->[0] = "two";
        is "$join", "one:bar",      "\"\"-object isn't deferred by $jtype";
        is "$obj", "two",           "\"\"-object is unaffected by $jtype";
    }
}

done_testing;
