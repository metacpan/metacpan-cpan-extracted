#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use t::Util;

use Readonly::Tiny;

use File::Spec::Functions   qw/devnull/;

{
    my $x = 1;
    readonly \$x;

    is $x, 1,                       "readonly doesn't affect scalar value";
    ok SvRO(\$x),                   "readonly makes scalars SvRO";
    throws_ok { $x = 2 } $mod,      "readonly makes scalars readonly";
    throws_ok { undef $x } $mod,    "readonly scalar can't be undefined";
}

{
    my $x = 1;
    my $y = \$x;
    readonly \$y;

    is $y, \$x,                     "readonly doesn't affect REF value";
    ok SvRO(\$y),                   "readonly makes REF SvRO";
    throws_ok { $y = 2 } $mod,      "readonly makes REF readonly";
    throws_ok { undef $y } $mod,    "readonly REF can't be undefined";
}

{
    my @x = (1, 2);
    readonly \@x;

    is_deeply \@x, [1, 2],          "readonly doesn't affect array value";
    ok SvRO(\@x),                   "readonly makes array SvRO";
    ok SvRO(\$x[0]),                "readonly makes array elem SvRO";

    throws_ok { $x[0] = 2 } $mod,   "readonly array elem can't be changed";
    throws_ok { push @x, 3 } $mod,  "readonly array can't be extended";
    throws_ok { pop @x } $mod,      "readonly array can't be shortened";
    throws_ok { @x = () } $mod,     "readonly array can't be cleared";
    throws_ok { undef @x } $mod,    "readonly array can't be undefined";
}

{
    my %x = (foo => 1);
    readonly \%x;

    is_deeply \%x, {foo => 1},      "readonly doesn't affect hash value";
    ok SvRO(\%x),                   "readonly makes hashes SvRO";
    ok SvRO(\$x{foo}),              "readonly makes hash elem SvRO";

    throws_ok { $x{foo} = 2 } $mod,     "readonly hash elem can't be changed";
    throws_ok { $x{bar} = 1 } $mod,     "readonly hash can't be extended";
    throws_ok { delete $x{foo} } $mod,  "readonly hash can't be shortened";
    throws_ok { %x = () } $mod,         "readonly hash can't be cleared";
    throws_ok { undef %x } $mod,        "readonly hash can't be undefined";
}

{
    my $x = 1;              *x = \$x;
    my @x = (1, 2);         *x = \@x;
    my %x = (foo => 1);     *x = \%x;
    my $c = sub {1};        *x = $c;
    open *x, "<", devnull;  my $i = *x{IO};
    readonly \*x;

    is *x{SCALAR}, \$x,             "readonly doesn't affect glob SCALAR slot";
    is *x{ARRAY}, \@x,              "readonly doesn't affect glob ARRAY slot";
    is *x{HASH}, \%x,               "readonly doesn't affect glob HASH slot";
    is *x{CODE}, $c,                "readonly doesn't affect glob CODE slot";
    is *x{IO}, $i,                  "readonly doesn't affect glob IO slot";

    ok SvRO(\*x),                   "readonly makes glob SvRO";
    ok SvRO(*x{SCALAR}),            "readonly makes glob SCALAR SvRO";
    ok SvRO(*x{ARRAY}),             "readonly makes glob ARRAY SvRO";
    ok SvRO(*x{HASH}),              "readonly makes glob HASH SvRO";

    ok !SvRO(*x{CODE}),             "readonly doesn't make CODE slot SvRO";
    ok !SvRO(*x{IO}),               "readonly doesn't make IO slot SvRO";

    throws_ok { *x = \1 } $mod,     "readonly SCALAR slot can't be changed";
    throws_ok { *x = [] } $mod,     "readonly ARRAY slot can't be changed";
    throws_ok { *x = {} } $mod,     "readonly HASH slot can't be changed";
    throws_ok { *x = sub {2} } $mod, "readonly CODE slot can't be changed";
    throws_ok { *x = *STDOUT{IO} } $mod,
                                    "readonly IO slot can't be changed";
}

{
    my $x = bless [];
    readonly $x;

    ok !SvRO($x),                   "readonly doesn't affect object";
}
{
    my $x = bless [];
    readonly $x, {peek=>1};

    ok SvRO($x),                    "readonly w/peek affects objects";
}

sub foo { }
readonly \&foo;
ok !SvRO(\&foo),                    "readonly doesn't affect subref";

readonly *STDOUT{IO};
ok !SvRO(*STDOUT{IO}),              "readonly doesn't affect ioref";

{
    my $x = qr/x/;
    readonly $x, {peek => 1};

    ok !SvRO($x),                       "readonly doesn't affect qr//";
}

done_testing;
