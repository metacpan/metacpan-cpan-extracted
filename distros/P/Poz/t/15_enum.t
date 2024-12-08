use strict;
use utf8;
use Test::More;
use Test::Exception;
use Poz qw/z/;

my $enumSchema = z->enum(["egg", "bean", "mackerel"]);
is($enumSchema->parse("egg"), "egg", "Enum of values");
throws_ok(sub {
    $enumSchema->parse("tofu");
}, qr/^Invalid data of enum/, "Invalid data of enum");

my $extractedEnumSchema = $enumSchema->extract(["egg", "mackerel"]);
is($extractedEnumSchema->parse("egg"), "egg", "Extracted enum of values");
throws_ok(sub {
    $extractedEnumSchema->parse("bean");
}, qr/^Invalid data of enum/, "Invalid data of enum");

my $excludedEnumSchema = $enumSchema->exclude(["bean"]);
is($excludedEnumSchema->parse("egg"), "egg", "Excluded enum of values");
throws_ok(sub {
    $excludedEnumSchema->parse("bean");
}, qr/^Invalid data of enum/, "Invalid data of enum");

done_testing;