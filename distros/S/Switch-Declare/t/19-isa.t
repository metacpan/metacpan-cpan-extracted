use strict;
use warnings;
use Test::More;
use Switch::Declare;

# `case isa(Class)` matches a blessed object derived from Class - a fast @ISA
# check (C-level sv_derived_from). It does not invoke an overridden isa()/DOES,
# does not match plain class-name strings, and never dies on a non-object.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
    package Animal;  sub new { bless {}, shift }
    package Cat;     our @ISA = ('Animal'); sub new { bless {}, shift }
    package Dog;     our @ISA = ('Animal'); sub new { bless {}, shift }
    package main;
}

my $cat = Cat->new;

is( (switch ($cat) { case isa(Cat)    { "cat" }    default { "no" } }), "cat",
    "isa matches the object's own class" );
is( (switch ($cat) { case isa(Animal) { "animal" } default { "no" } }), "animal",
    "isa matches a parent class" );
is( (switch ($cat) { case isa(Dog)    { "dog" }    default { "no" } }), "no",
    "isa does not match an unrelated class" );

# ordering: most-specific first
is( (switch ($cat) {
        case isa(Cat)    { "cat" }
        case isa(Animal) { "animal" }
        default          { "no" }
    }), "cat", "first matching isa arm wins" );

# class dispatch table style
sub describe {
    my $o = shift;
    return switch ($o) {
        case isa(Cat) { "meow" }
        case isa(Dog) { "woof" }
        default       { "???"  }
    };
}
is( describe(Cat->new), "meow", "isa dispatch: cat" );
is( describe(Dog->new), "woof", "isa dispatch: dog" );

# non-matching / non-object topics: no match, no die, no warning
is( (switch ("Animal") { case isa(Animal) { "a" } default { "no" } }), "no",
    "a plain class-name string is not an object -> no match" );
is( (switch ([1,2]) { case isa(Animal) { "a" } default { "no" } }), "no",
    "an unblessed ref -> no match" );
is( (switch (42) { case isa(Animal) { "a" } default { "no" } }), "no",
    "a number -> no match" );
my $undef;
is( (switch ($undef) { case isa(Animal) { "a" } default { "no" } }), "no",
    "undef -> no match, no die" );

# quoted class name accepted
is( (switch ($cat) { case isa("Animal") { "a" } default { "no" } }), "a",
    "quoted class name isa(\"Animal\")" );

is_deeply( \@warnings, [], "isa patterns produced no warnings" )
    or diag("unexpected warnings:\n", @warnings);

done_testing;
