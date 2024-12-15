use strict;
use utf8;
use Test::More;
use Test::Exception;
use Poz qw/z/;

my $numbersSchema = z->array(z->number);
is_deeply(
    $numbersSchema->parse([1, 2, 3, 4, 5]),
    [1, 2, 3, 4, 5],
    "Array of numbers"
);

throws_ok(sub {
    $numbersSchema->parse([1, 2, 3, 4, "five"]);
}, qr/^Not a number on key `4`/, "Array of numbers with invalid data");

my $datesSchema = z->array(z->date)->as("My::Dates");
my $dates = $datesSchema->parse(["2020-01-01", "2020-01-02", "2020-01-03"]);
is_deeply(
    $dates,
    bless(["2020-01-01", "2020-01-02", "2020-01-03"], 'My::Dates'),
    "Array of dates"
);

my ($valid, $errors) = $datesSchema->safe_parse(["2020-01-01", "2020-01-02", "2020-01-03"]);
is_deeply(
    $valid,
    bless(["2020-01-01", "2020-01-02", "2020-01-03"], 'My::Dates'),
    "Array of dates"
);
is($errors, undef, "No errors");

($valid, $errors) = $datesSchema->safe_parse(["2020-01-01", "2020-01-02", "2020-01-0i"]);
is($valid, undef, "Invalid data");
is_deeply(
    $errors,
    [{key => 2, error => "Not a date"}],
    "Invalid data"
);

my $numbersSchemaNonEmpty = z->array(z->number)->nonempty;
is_deeply(
    $numbersSchemaNonEmpty->parse([1, 2, 3, 4, 5]),
    [1, 2, 3, 4, 5],
    "Array of numbers"
);
throws_ok(sub {
    $numbersSchemaNonEmpty->parse([]);
}, qr/^Array is empty/, "Array of numbers with empty data");

my $numbersSchemaMax = z->array(z->number)->max(3);
is_deeply(
    $numbersSchemaMax->parse([1, 2, 3]),
    [1, 2, 3],
    "Array of numbers"
);
throws_ok(sub {
    $numbersSchemaMax->parse([1, 2, 3, 4]);
}, qr/^Array is too long/, "Array of numbers with invalid data");

my $numbersSchemaMin = z->array(z->number)->min(3);
is_deeply(
    $numbersSchemaMin->parse([1, 2, 3]),
    [1, 2, 3],
    "Array of numbers"
);
throws_ok(sub {
    $numbersSchemaMin->parse([1, 2]),
}, qr/^Array is too short/, "Array of numbers with invalid data");

my $numbersSchemaLength = z->array(z->number)->length(3);
is_deeply(
    $numbersSchemaLength->parse([1, 2, 3]),
    [1, 2, 3],
    "Array of numbers"
);
throws_ok(sub {
    $numbersSchemaLength->parse([1, 2, 3, 4]);
}, qr/^Array is not of length 3/, "Array of numbers with invalid data");

subtest 'isa' => sub {
    my $array = z->array(z->number);
    isa_ok $array, 'Poz::Types', 'Poz::Types::array';
};

subtest 'safe_parse must handle error' => sub {
    my $array = z->array(z->number);
    throws_ok(sub { $array->safe_parse([]) }, qr/^Must handle error/, 'Must handle error');
};

done_testing;
