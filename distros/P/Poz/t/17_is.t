use strict;
use Test::More;
use Test::Exception;
use Poz qw/z/;

my $isSchema = z->is('Some::Class');

my $obj = bless {}, 'Some::Class';
my $other_obj = bless {}, 'Some::Other::Class';

is($isSchema->parse($obj), $obj, "Some::Class");
throws_ok(sub {
    $isSchema->parse($other_obj);
}, qr/^Not a Some::Class/, "Not a Some::Class");

my $isSchemaOptional = z->is('Some::Class')->optional;

is($isSchemaOptional->parse($obj), $obj, "Some::Class");
is($isSchemaOptional->parse(undef), undef, "Optional");
throws_ok(sub {
    $isSchemaOptional->parse($other_obj);
}, qr/^Not a Some::Class/, "Not a Some::Class");

my $isSchemaDefault = z->is('Some::Class')->default($obj);

is($isSchemaDefault->parse($obj), $obj, "Some::Class");
is($isSchemaDefault->parse(undef), $obj, "Default");
throws_ok(sub {
    $isSchemaDefault->parse($other_obj);
}, qr/^Not a Some::Class/, "Not a Some::Class");

my $isSchemaOptionalDefault = z
    ->is('Some::Class')
    ->optional
    ->default($obj);

is($isSchemaOptionalDefault->parse($obj), $obj, "Some::Class");
is($isSchemaOptionalDefault->parse(undef), $obj, "Default");
throws_ok(sub {
    $isSchemaOptionalDefault->parse($other_obj);
}, qr/^Not a Some::Class/, "Not a Some::Class");

my $schemaSchema = z->is('Poz::Types');
is($schemaSchema->parse($isSchema), $isSchema, "Poz::Types");

done_testing;