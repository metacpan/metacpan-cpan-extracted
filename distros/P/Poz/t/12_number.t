use strict;
use utf8;
use Test::More;
use Test::Exception;
use Poz qw/z/;

my $numberSchema = z->number;
is($numberSchema->parse(1), 1, "number: 1");
is($numberSchema->parse(1.1), 1.1, "number: 1.1");
is($numberSchema->parse(-1), -1, "number: -1");
is($numberSchema->parse(-1.1), -1.1, "number: -1.1");
is($numberSchema->parse("1"), 1, "number: '1'");
is($numberSchema->parse("1.1"), 1.1, "number: '1.1'");
is($numberSchema->parse("-1"), -1, "number: '-1'");
is($numberSchema->parse("-1.1"), -1.1, "number: '-1.1'");
is($numberSchema->parse(10), 10, "number: 10");
is(
    $numberSchema->parse(1_000_000_000_000_000_000),
    1_000_000_000_000_000_000,
    "number: 1_000_000_000_000_000_000"
); # 1e18
throws_ok { $numberSchema->parse("a") } qr/^Not a number/, "number: 'a'";
throws_ok { $numberSchema->parse("1a") } qr/^Not a number/, "number: '1a'";
throws_ok { $numberSchema->parse(undef)} qr/^required/, "number: undef";

my ($valid, $error) = $numberSchema->safe_parse(123);
is($valid, 123, 'number: 123');
is($error, undef, 'no error');

($valid, $error) = $numberSchema->safe_parse(undef);
is($valid, undef, 'undef is not a number');
is($error, 'required', 'required error');

my $numberSchemaRequiredError = z->number({required_error => "required number"});
is($numberSchemaRequiredError->parse(1), 1, "number: 1");
throws_ok { $numberSchemaRequiredError->parse(undef) } qr/^required number/, "number: undef";

my $numberSchemaInvalidTypeError = z->number({invalid_type_error => "Not a valid number"});
is($numberSchemaInvalidTypeError->parse(1), 1, "number: 1");
throws_ok { $numberSchemaInvalidTypeError->parse("a") } qr/^Not a valid number/, "number: 'a'";

my $numberSchemaDefault = z->number->default(100);
is($numberSchemaDefault->parse(1), 1, "number: 1");
is($numberSchemaDefault->parse(undef), 100, "number: undef");
throws_ok { $numberSchemaDefault->parse("a") } qr/^Not a number/, "number: 'a'";

my $numberSchemaDefaultSub = z->number->default(sub { 100 });
is($numberSchemaDefaultSub->parse(1), 1, "number: 1");
is($numberSchemaDefaultSub->parse(undef), 100, "number: undef");
throws_ok { $numberSchemaDefaultSub->parse("a") } qr/^Not a number/, "number: 'a'";

my $numberSchemaNullable = z->number->nullable;
is($numberSchemaNullable->parse(1), 1, "number: 1");
is($numberSchemaNullable->parse(undef), undef, "number: undef");
throws_ok { $numberSchemaNullable->parse("a") } qr/^Not a number/, "number: 'a'";

my $numberSchemaOptional = z->number->optional;
is($numberSchemaOptional->parse(1), 1, "number: 1");
is($numberSchemaOptional->parse(undef), undef, "number: undef");
throws_ok { $numberSchemaOptional->parse("a") } qr/^Not a number/, "number: 'a'";

my $numberSchemaCoerce = z->coerce->number;
is($numberSchemaCoerce->parse(1), 1, "number: 1");
is($numberSchemaCoerce->parse("1"), 1, "number: '1'");
is($numberSchemaCoerce->parse("1.1"), 1.1, "number: '1.1'");
is($numberSchemaCoerce->parse(-1), -1, "number: -1");
throws_ok { $numberSchemaCoerce->parse("a") } qr/^Not a number/, "number: 'a'";

my $numberSchemaGt = z->number->gt(10);
is($numberSchemaGt->parse(11), 11, "number: 11");
throws_ok { $numberSchemaGt->parse(10) } qr/^Too small/, "number: 10";
throws_ok { $numberSchemaGt->parse(9) } qr/^Too small/, "number: 9";

my $numberSchemaGte = z->number->gte(10);
is($numberSchemaGte->parse(11), 11, "number: 11");
is($numberSchemaGte->parse(10), 10, "number: 10");
throws_ok { $numberSchemaGte->parse(9) } qr/^Too small/, "number: 9";

my $numberSchemaLt = z->number->lt(10);
is($numberSchemaLt->parse(9), 9, "number: 9");
throws_ok { $numberSchemaLt->parse(10) } qr/^Too large/, "number: 10";
throws_ok { $numberSchemaLt->parse(11) } qr/^Too large/, "number: 11";

my $numberSchemaLte = z->number->lte(10);
is($numberSchemaLte->parse(9), 9, "number: 9");
is($numberSchemaLte->parse(10), 10, "number: 10");
throws_ok { $numberSchemaLte->parse(11) } qr/^Too large/, "number: 11";

my $numberSchemaInt = z->number->int;
is($numberSchemaInt->parse(1), 1, "number: 1");
is($numberSchemaInt->parse(-1), -1, "number: -1");
throws_ok { $numberSchemaInt->parse(1.1) } qr/^Not an integer/, "number: 1.1";
throws_ok { $numberSchemaInt->parse(-1.1) } qr/^Not an integer/, "number: -1.1";

my $numberSchemaIntError = z->number->int({message => "Not an integer number"});
is($numberSchemaIntError->parse(1), 1, "number: 1");
throws_ok { $numberSchemaIntError->parse(1.1) } qr/^Not an integer number/, "number: 1.1";

my $numberSchemaPositive = z->number->positive;
is($numberSchemaPositive->parse(1), 1, "number: 1");
throws_ok { $numberSchemaPositive->parse(0) } qr/^Not a positive number/, "number: 0";

my $numberSchemaNegative = z->number->negative;
is($numberSchemaNegative->parse(-1), -1, "number: -1");
throws_ok { $numberSchemaNegative->parse(0) } qr/^Not a negative number/, "number: 0";

my $numberSchemaNonPositive = z->number->nonpositive;
is($numberSchemaNonPositive->parse(0), 0, "number: 0");
is($numberSchemaNonPositive->parse(-1), -1, "number: -1");
throws_ok { $numberSchemaNonPositive->parse(1) } qr/^Not a non-positive number/, "number: 1";

my $numberSchemaNonNegative = z->number->nonnegative;
is($numberSchemaNonNegative->parse(0), 0, "number: 0");
is($numberSchemaNonNegative->parse(1), 1, "number: 1");
throws_ok { $numberSchemaNonNegative->parse(-1) } qr/^Not a non-negative number/, "number: -1";

my $numberSchemaMultipleOf = z->number->multipleOf(3);
is($numberSchemaMultipleOf->parse(3), 3, "number: 3");
is($numberSchemaMultipleOf->parse(6), 6, "number: 6");
throws_ok { $numberSchemaMultipleOf->parse(5) } qr/^Not a multiple of 3/, "number: 5";

my $numberSchemaStep = z->number->step(4);
is($numberSchemaStep->parse(4), 4, "number: 4");
is($numberSchemaStep->parse(8), 8, "number: 8");
throws_ok { $numberSchemaStep->parse(5) } qr/^Not a multiple of 4/, "number: 5";

subtest 'isa' => sub {
    my $num = z->number;
    isa_ok $num, 'Poz::Types', 'Poz::Types::scalar';
};

subtest 'safe_parse must handle error' => sub {
    my $num = z->number;
    throws_ok(sub { $num->safe_parse([]) }, qr/^Must handle error/, 'Must handle error');
};

done_testing;
