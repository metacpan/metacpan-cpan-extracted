#!/usr/bin/perl

use strict;
use warnings;

use String::Defer;
use t::Utils;

sub check {
    my ($targ, $setup, $name) = @_;

    my $defer;
    lives_ok { $defer = String::Defer->new($targ) }
                                "->new($name) succeeds"
        or return;
    is_defer $defer,            "->new($name) gives a String::Defer"
        or return;

    my $want = $setup->();
    try_forcing $defer, $want,  "->new($name)";
}

{
    my $targ;
    for (
        'undef',                    # SCALAR
        '"string"',                 # SCALAR
        'v1',                       # VSTRING
        '\\1',                      # REF
        '${qr/x/}',                 # REGEXP
        '*STDOUT',                  # GLOB
        'PlainObject->new',
        'StrOverload->new',
    ) {
        $targ = eval $_;
        check \$targ, sub { $targ = "foo"; "foo" }, "\\(\$x = $_)";
    }
}

{   # CODE
    my ($i, $j) = (0, 999);
    check sub { $i++; "foo" }, sub { $j = $i; "foo" }, 'sub {}';

    is $j, 0,                   "sub not called before forcing";
    is $i, 2,                   "sub called once per forcing";
}

{   # LVALUE
    my $targ = "blurb";
    check \substr($targ, 1, 3), sub { $targ = "XfooX"; "foo" },
        "\\substr()";

    my $want = do {
        my $targ = "X";
        my $ref = \substr($targ, 1, 3);
        $targ = "XXXXX";
        "$$ref";
    };

    $targ = "X";
    check \substr($targ, 1, 3), sub { $targ = "XXXXX"; $want },
        "\\substr(<outside>)";
}

for (
    ["ARRAY ref",                   []                          ],
    ["HASH ref",                    {}                          ],
    ["IO ref",                      *STDOUT{IO}                 ],
    ["FORMAT ref",                  *Format{FORMAT}             ],
    ["plain object",                PlainObject->new            ],
    ["object based on scalar ref",  PlainObject->new(\my $targ) ],
    ["object based on code ref",    PlainObject->new(sub { 1 }) ],
    ["object with \"\"",            StrOverload->new            ],
    # XXX these should perhaps be allowed
    ["object with \${}",            ScalarOverload->new         ],
    ["object with &{}",             CodeOverload->new           ],
) {
    my ($type, $ref) = @$_;
    throws_ok { String::Defer->new($ref) }
        qr/^I need a SCALAR or CODE ref/,   "$type not allowed";
}

done_testing;
