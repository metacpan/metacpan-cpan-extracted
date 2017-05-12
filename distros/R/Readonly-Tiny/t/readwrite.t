#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use t::Util;

use Readonly::Tiny qw/readonly readwrite/;

use File::Spec::Functions   qw/devnull/;

sub ro_rw { readonly $_[0], {peek=>1}; readwrite @_ }

{
    my $x = 1;
    ro_rw \$x;

    is $x, 1,                       "readwrite doesn't affect scalar value";
    ok !SvRO(\$x),                  "readwrite makes scalars SvRW";
    lives_ok { $x = 2 }             "readwrite makes scalars readwrite";
    lives_ok { undef $x }           "readwrite scalar can't be undefined";
}

{
    my $x = 1;
    my $y = \$x;
    ro_rw \$y;

    is $y, \$x,                     "readwrite doesn't affect REF value";
    ok !SvRO(\$y),                  "readwrite makes REF SvRW";
    lives_ok { $y = 2 }             "readwrite makes REF readwrite";
    lives_ok { undef $y }           "readwrite REF can't be undefined";
}

{
    my @x = (1, 2);
    ro_rw \@x;

    is_deeply \@x, [1, 2],          "readwrite doesn't affect array value";
    ok !SvRO(\@x),                  "readwrite makes array SvRW";
    ok !SvRO(\$x[0]),               "readwrite makes array elem SvRW";

    lives_ok { $x[0] = 2 }    "readwrite array elem can't be changed";
    lives_ok { push @x, 3 }   "readwrite array can't be extended";
    lives_ok { pop @x }       "readwrite array can't be shortened";
    lives_ok { @x = () }      "readwrite array can't be cleared";
    lives_ok { undef @x }     "readwrite array can't be undefined";
}

{
    my %x = (foo => 1);
    ro_rw \%x;

    is_deeply \%x, {foo => 1},      "readwrite doesn't affect hash value";
    ok !SvRO(\%x),                  "readwrite makes hashes SvRW";
    ok !SvRO(\$x{foo}),             "readwrite makes hash elem SvRW";

    lives_ok { $x{foo} = 2 }      "readwrite hash elem can't be changed";
    lives_ok { $x{bar} = 1 }      "readwrite hash can't be extended";
    lives_ok { delete $x{foo} }   "readwrite hash can't be shortened";
    lives_ok { %x = () }          "readwrite hash can't be cleared";
    lives_ok { undef %x }         "readwrite hash can't be undefined";
}

{
    no warnings "redefine";

    my $x = 1;              *x = \$x;
    my @x = (1, 2);         *x = \@x;
    my %x = (foo => 1);     *x = \%x;
    my $c = sub {1};        *x = $c;
    open *x, "<", devnull;  my $i = *x{IO};
    ro_rw \*x;

    is *x{SCALAR}, \$x,             "readwrite doesn't affect glob SCALAR slot";
    is *x{ARRAY}, \@x,              "readwrite doesn't affect glob ARRAY slot";
    is *x{HASH}, \%x,               "readwrite doesn't affect glob HASH slot";
    is *x{CODE}, $c,                "readwrite doesn't affect glob CODE slot";
    is *x{IO}, $i,                  "readwrite doesn't affect glob IO slot";

    ok !SvRO(\*x),                   "readwrite makes glob SvRW";
    ok !SvRO(*x{SCALAR}),            "readwrite makes glob SCALAR SvRW";
    ok !SvRO(*x{ARRAY}),             "readwrite makes glob ARRAY SvRW";
    ok !SvRO(*x{HASH}),              "readwrite makes glob HASH SvRW";

    lives_ok { *x = \1 }      "readwrite SCALAR slot can't be changed";
    lives_ok { *x = [] }      "readwrite ARRAY slot can't be changed";
    lives_ok { *x = {} }      "readwrite HASH slot can't be changed";
    lives_ok { *x = sub {2} }  "readwrite CODE slot can't be changed";
    lives_ok { *x = *STDOUT{IO} } 
                                    "readwrite IO slot can't be changed";
}

{
    my $x = bless [];
    ro_rw $x;

    ok SvRO($x),                    "readwrite doesn't affect object";
}
{
    my $x = bless [];
    ro_rw $x, {peek=>1};

    ok !SvRO($x),                   "readwrite w/peek affects objects";
}

for (
    ["undef",   \undef  ], 
    ["yes",     \!0     ], 
    ["no",      \!1     ],
) {
    my ($n, $r) = @$_;
    readwrite $r;

    ok SvRO($r),                    "readwrite doesn't affect PL_sv_$n";
}

done_testing;
