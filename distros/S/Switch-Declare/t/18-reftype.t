use strict;
use warnings;
use Test::More;
use Switch::Declare;

# `case reftype(TYPE)` matches the *underlying* reference type, seeing through
# blessing - the key difference from ref(). Bare `case reftype` is "any ref".

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# unblessed refs behave like ref()
is( (switch ([1,2]) { case reftype(ARRAY) { "a" } default { "no" } }), "a", "reftype(ARRAY), unblessed" );
is( (switch ({a=>1}) { case reftype(HASH) { "h" } default { "no" } }), "h", "reftype(HASH), unblessed" );
is( (switch (sub{}) { case reftype(CODE) { "c" } default { "no" } }), "c", "reftype(CODE), unblessed" );

# the distinguishing case: a blessed reference
{
    my $arr_obj  = bless [1,2,3], "My::ArrayObj";
    my $hash_obj = bless {x=>1},  "My::HashObj";

    # ref() reports the class, so ref(ARRAY) does NOT match...
    is( (switch ($arr_obj) { case ref(ARRAY) { "a" } default { "D" } }), "D",
        "ref(ARRAY) does not match a blessed arrayref" );
    # ...but reftype() sees the underlying ARRAY
    is( (switch ($arr_obj) { case reftype(ARRAY) { "a" } default { "D" } }), "a",
        "reftype(ARRAY) matches a blessed arrayref" );
    is( (switch ($hash_obj) { case reftype(HASH) { "h" } default { "D" } }), "h",
        "reftype(HASH) matches a blessed hashref" );
    is( (switch ($hash_obj) { case reftype(ARRAY) { "a" } default { "D" } }), "D",
        "reftype(ARRAY) does not match a blessed hashref" );
}

# bare reftype = any reference
is( (switch ([1]) { case reftype { "ref" } default { "no" } }), "ref", "bare reftype matches a ref" );
is( (switch ("x") { case reftype { "ref" } default { "no" } }), "no",  "bare reftype: non-ref -> default" );

# non-ref / undef topics never match and never warn
is( (switch (42)    { case reftype(ARRAY) { "a" } default { "D" } }), "D", "number -> default" );
my $undef;
is( (switch ($undef) { case reftype(HASH) { "h" } case reftype { "r" } default { "D" } }), "D",
    "undef topic -> default for reftype patterns" );

is_deeply( \@warnings, [], "reftype patterns produced no warnings" )
    or diag("unexpected warnings:\n", @warnings);

done_testing;
