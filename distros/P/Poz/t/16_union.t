use strict;
use utf8;
use Test::More;
use Test::Exception;
use Poz qw/z/;

my $unionSchema = z->union(z->number, z->string);

is($unionSchema->parse(42), 42, "Number");
is($unionSchema->parse("tofu"), "tofu", "String");
throws_ok(sub {
    $unionSchema->parse(undef);
}, qr/^Required for union value/, "Required for union value");
throws_ok(sub {
    $unionSchema->parse([]);
}, qr/^Not a number, Not a string for union value/, "Not a number, Not a string for union value");

my $unionSchemaOptional = z->union(z->number, z->string)->optional;

is($unionSchemaOptional->parse(42), 42, "Number");
is($unionSchemaOptional->parse("tofu"), "tofu", "String");
is($unionSchemaOptional->parse(undef), undef, "Optional");
throws_ok(sub {
    $unionSchemaOptional->parse([]);
}, qr/^Not a number, Not a string for union value/, "Not a number, Not a string for union value");

my $unionSchemaDefault = z->union(z->number, z->string)->default("tofu");
is($unionSchemaDefault->parse(42), 42, "Number");
is($unionSchemaDefault->parse("tofu"), "tofu", "String");
is($unionSchemaDefault->parse(undef), "tofu", "Default");
throws_ok(sub {
    $unionSchemaDefault->parse([]);
}, qr/^Not a number, Not a string for union value/, "Not a number, Not a string for union value");

my $unionSchemaOptionalDefault = z->union(z->number, z->string)->optional->default("tofu");
is($unionSchemaOptionalDefault->parse(42), 42, "Number");
is($unionSchemaOptionalDefault->parse("tofu"), "tofu", "String");
is($unionSchemaOptionalDefault->parse(undef), "tofu", "Default");
throws_ok(sub {
    $unionSchemaOptionalDefault->parse([]);
}, qr/^Not a number, Not a string for union value/, "Not a number, Not a string for union value");

my $unionNabeatzSchema = z->union(
    z->number->multipleOf(3), 
    z->number->multipleOf(5)
);
is($unionNabeatzSchema->parse(15), 15, "Multiple of 3 and 5");
is($unionNabeatzSchema->parse(9), 9, "Multiple of 3");
is($unionNabeatzSchema->parse(10), 10, "Multiple of 5");
throws_ok(sub {
    $unionNabeatzSchema->parse(8);
}, qr/^Not a multiple of 3, Not a multiple of 5 for union value/, "Not a multiple of 3, Not a multiple of 5 for union value");

done_testing;