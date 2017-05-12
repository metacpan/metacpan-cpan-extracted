#!/usr/bin/perl

use warnings;
use strict;

use String::Defer;
use t::Utils;
use Scalar::Util qw/refaddr/;

my $targ    = "foo";
my $defer   = eval { String::Defer->new(\$targ) };
my ($other, $targ2, $copy); # these needs to be declared before setup()

ok defined $defer,          "new accepts a scalar ref";
is_defer $defer,            "new returns a String::Defer"
    or BAIL_OUT "can't even create an object!";

try_forcing $defer, "foo",  "new object";
is_defer $defer,            "forcing doesn't affect the object";

$targ = "bar";
is $defer->force, "bar",    "forcing is deferred";
is "$defer", "bar",         "stringify is deferred";

sub setup {
    ($targ, my $want) = @_;
    $targ2 = uc $targ;
    $want =~ s/%/$targ/g;
    $want =~ s/#/$targ2/g;
    $want;
}

sub check {
    my ($what, $pat, $eval) = @_;

    my $want = setup "foo", $pat;
    my $str  = $eval->();

    unless (ok defined $str,    "$what succeeds") {
        diag "\$\@: $@";
        return;
    }
    is_defer $str,              "$what returns an object"
        or return;

    try_forcing $str, $want,    $what;

    $want = setup "bar", $pat;
    try_forcing $str, $want,    "deferred $what";
}

sub check_expr {
    my ($what) = @_;

    check @_, sub { eval $what };

    $targ = "baz";
    is "$defer", "baz",         "$what doesn't affect the original";
}

check_expr @$_ for (
    ['$defer->concat("B")',                 "%B"    ],
    ['$defer->concat("A", 1)',              "A%"    ],
    ['$defer->concat("B")->concat("A", 1)', "A%B"   ],

    ['$defer . "B"',                        "%B"    ],
    ['"A" . $defer',                        "A%"    ],
    ['"A" . $defer . "B"',                  "A%B"   ],

    ['"$defer B"',                          "% B"   ],
    ['"A $defer"',                          "A %"   ],
    ['"A $defer B"',                        "A % B" ],
);

$other = String::Defer->new(\$targ2);

check_expr @$_ for (
    ['$defer->concat($other)',                 "%#"        ],
    ['$defer->concat($other, 1)',              "#%"        ],
    ['$defer->concat("A")->concat($other)',    "%A#"       ],

    ['$defer . $other',                        "%#"        ],
    ['$defer . "A" . $other',                  "%A#"       ],
    ['"A" . $defer . $other',                  "A%#"       ],
    ['$defer . $other . "A"',                  "%#A"       ],

    ['"${defer}$other"',                       "%#"        ],
    ['"$defer A $other"',                      "% A #"     ],
    ['"A ${defer}$other"',                     "A %#"      ],
    ['"${defer}$other A"',                     "%# A"      ],
    ['"A $defer B $other C"',                  "A % B # C" ],
);

for (
    ['"A"',             "%A"    ],
    ['"A" . "B"',       "%AB"   ],
    ['$other',          "%#"    ],
    ['$copy',           "%%"    ],
    ['$defer',          "%%"    ],
) {
    my ($what, $pat) = @$_;

    my $copy = $defer;
    my $addr = refaddr $defer;
    $what = "\$copy .= $what";

    check $what, $pat, sub { eval $what; $copy };

    is refaddr $defer, $addr,       "$what leaves original unchanged";
    isnt refaddr $copy, $addr,      "$what creates a new \$copy";

    $targ = "baz";
    is "$defer", "baz",             "$what leaves original unaffected";
}

done_testing;
