use strict;
use warnings;
use Test::More;
use Switch::Declare;

# `case ref(TYPE)` lowers to ref($topic) eq "TYPE"; bare `case ref` is "any
# reference". Pure ops, never warns. Runs under `use warnings` with a global
# handler asserting zero warnings at the end.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

sub kind {
    my $x = shift;
    return switch ($x) {
        case ref(ARRAY)  { "array"  }
        case ref(HASH)   { "hash"   }
        case ref(CODE)   { "code"   }
        case ref(SCALAR) { "scalar" }
        case ref(Regexp) { "regex"  }
        case ref         { "other-ref" }
        default          { "plain"  }
    };
}

is( kind([1,2,3]),   "array",     "ref(ARRAY)" );
is( kind({a=>1}),    "hash",      "ref(HASH)" );
is( kind(sub { 1 }), "code",      "ref(CODE)" );
is( kind(\my $s),    "scalar",    "ref(SCALAR)" );
is( kind(qr/x/),     "regex",     "ref(Regexp)" );
is( kind("hello"),   "plain",     "non-ref falls to default" );
is( kind(0),         "plain",     "number is not a ref" );

# bare `case ref` matches any reference the specific arms didn't
{
    my $glob = \*STDOUT;
    is( (switch ($glob) { case ref(ARRAY) { "a" } case ref { "R" } default { "p" } }),
        "R", "bare ref matches a non-listed reference type (GLOB)" );
}

# specific-before-general ordering: ref(ARRAY) wins over bare ref
is( (switch ([1]) { case ref(ARRAY) { "A" } case ref { "R" } default { "p" } }),
    "A", "specific ref(ARRAY) is chosen before bare ref" );

# package-qualified class dispatch: ref($obj) eq "Class"
{
    package Widget;       sub new { bless {}, shift }
    package Widget::Sub;  our @ISA = ('Widget'); sub new { bless {}, shift }
    package main;
    is( (switch (Widget->new) { case ref(Widget) { "w" } default { "?" } }),
        "w", "ref(Class) matches an object of exactly that class" );
    # ref() is exact, so a subclass instance is NOT ref(Widget)
    is( (switch (Widget::Sub->new) { case ref(Widget) { "w" } case ref { "sub" } default { "?" } }),
        "sub", "ref(Class) is exact: a subclass is not the parent class" );
}

# an undef topic never matches a ref pattern and never warns
my $undef;
is( (switch ($undef) { case ref(ARRAY) { "a" } case ref { "r" } default { "D" } }),
    "D", "undef topic -> default for ref patterns" );

# quoted type name is accepted too
is( (switch ([1]) { case ref("ARRAY") { "a" } default { "no" } }), "a",
    "quoted type name ref(\"ARRAY\")" );

is_deeply( \@warnings, [], "ref patterns produced no warnings" )
    or diag("unexpected warnings:\n", @warnings);

done_testing;
