#!/usr/bin/perl

use warnings;
use strict;

use t::Utils;
use String::Defer;

my $defer = String::Defer->new(\my $targ);
my @defer = ($defer);

sub overload_ok {
    my ($what, $want) = @_;

    my $got = eval $what;

    unless (ok defined $got,    "$what succeeds") {
        diag "\$\@: $@";
        return;
    }
    is $got, $want,             "$what is correct";
    is_plain $got,              "$what is not an object";
}

sub overload_nok {
    my ($what, $want) = @_;

    my $got = eval $what;
    my $err = $@;

    ok !defined $got,           "$what fails"
        or diag "GOT: $got";
    like $err, $want,           "$what gives correct error"
        or diag "\$\@: $err";
}

$targ = 3;
overload_ok @$_ for (
    ['$defer + 4',      7           ],
    ['$defer - 5',      -2          ],
    ['$defer * 3',      9           ],
    ['$defer / 2',      1.5         ],
    ['$defer % 2',      1           ],
    ['$defer ** 3',     27          ],
    ['$defer << 2',     12          ],
    ['$defer >> 1',     1           ],
    ['$defer x 3',      333         ], # XXX this should defer
    # . is tested in defer.t

    ['$defer < 2',      ""          ],
    ['$defer <= 3',     1           ],
    ['$defer > 2',      1           ],
    ['$defer >= 4',     ""          ],
    ['$defer == 3',     1           ],
    ['$defer != 3',     ""          ],
    ['$defer <=> 4',    -1          ],

    ['$defer lt 29',    ""          ],
    ['$defer le 3',     1           ],
    ['$defer gt 20',    1           ],
    ['$defer ge 4',     ""          ],
    ['$defer eq "x"',   ""          ],
    ['$defer ne "x"',   1           ],
    ['$defer cmp 29',   1           ],

    ['$defer & 1',      "3" & 1     ],  # bitwise ops use string form
    ['$defer | 1',      "3" | 1     ],
    ['$defer ^ 1',      "3" ^ 1     ],

    ['-$defer',         -3          ],
    ['!$defer',         ""          ],
    ['~$defer',         ~"3"        ],

    ['atan2 $defer, 4', atan2(3,4)  ],
    ['atan2 4, $defer', atan2(4,3)  ],
    ['cos $defer',      cos(3)      ],
    ['sin $defer',      sin(3)      ],
    ['exp $defer',      exp(3)      ],
    ['log $defer',      log(3)      ],
    ['sqrt $defer',     sqrt(3)     ],
);

$targ = -2.6;
overload_ok @$_ for (
    ['abs $defer',      2.6     ],
    ['int $defer',      -2      ],
);

# "" is tested in defer.t

# this is a test for 0+
$targ = 3;
overload_ok '"x" x $defer',             "xxx";

$targ = 1;
overload_ok '$defer ? "ok" : "nok"',    "ok";
$targ = 0;
overload_ok '$defer ? "ok" : "nok"',    "nok";

$targ = "X*";
overload_ok '"XXX" =~ $defer',          1;
overload_ok '"AXXX" =~ /A$defer/',      1;
overload_ok '"xxx" =~ /$defer/i',       1;

$targ = "Build.PL";
overload_ok '-f $defer',                1;

$targ = "*uild.PL";
overload_ok '<$defer[0]>',              "Build.PL";

$targ = "DATA";
overload_nok @$_ for (
    ['<$defer>',        qr/Not a GLOB reference/            ],
    ['$$defer',         qr/Not a SCALAR reference/          ],
( $] >= 5.010 ? (
    ['%$defer',         qr/Not a HASH reference/            ],
) : (
    ['%$defer',         qr/Can't coerce array into hash/    ],
) ),
    ['$defer->()',      qr/Not a CODE reference/            ],
    ['*$defer',         qr/Not a GLOB reference/            ],
);

SKIP: {
    $] < 5.010 and skip "No smartmatch before 5.10", 1;
    $] == 5.010 and skip "Smartmatch broken in 5.10.0", 1;
    $targ = "XXX";
    overload_ok '$defer ~~ "XXX"', 1;
}

our $VALTODO;

sub mutate_ok {
    my ($what, $want) = @_;

    my $val = $defer;
    my $got = eval $what;

    unless (ok defined $got,        "$what succeeds") {
        diag "\$\@: $@";
        return;
    }
    TODO: {
        local $TODO = $VALTODO;
        is $val, $want,             "$what is correct";
    }
    is_plain $val,                  "$what gives plain value";
    is_defer $defer,                "$what leaves object alone";

    $got;
}

$targ = 4;
mutate_ok @$_ for (
    ['$val += 3',       7       ],
    ['$val -= 3',       1       ],
    ['$val *= 3',       12      ],
    ['$val /= 2',       2       ],
    ['$val %= 2',       0       ],
    ['$val **= 3',      64      ],
    ['$val <<= 3',      32      ],
    ['$val >>= 2',      1       ],
    ['$val x= 3',       444     ],  # XXX this should defer
    # .= is tested in defer.t
    
    ['$val &= 3',       "4" & 3 ],
    ['$val |= 3',       "4" | 3 ],
    ['$val ^= 3',       "4" | 3 ],
);

{
    local $VALTODO = "++ and -- act on refaddr??";

    for (
        ['++$val',          5       ],
        ['--$val',          3       ],
    ) {
        my ($what, $want) = @$_;

        my $got = mutate_ok $what, $want
            or next;
        TODO: {
            local $TODO = $VALTODO;
            is $got, $want, "$what returns new value";
        }
        is_plain $got,      "$what returns a plain value";
    }

    for (
        ['$val++',          5       ],
        ['$val--',          3       ],
    ) {
        my ($what, $want) = @$_;

        my $got = mutate_ok $what, $want
            or next;
        is $got, 4,         "$what returns original value";
        is_defer $got,      "$what returns an object";
    }
}

done_testing;

__DATA__
Data line 1
