#!perl -Tw

use strict;

use Test::More tests => 12;

use PICA::Record;
use PICA::Field;

my $field = PICA::Field->new("028A","d" => "Given1", "d" => "Given2", "a" => "Surname", "x" => "Stuff");
isa_ok( $field, 'PICA::Field');

my $s = $field->subfield("d");
ok( $s , 'scalar context' );

my @s = $field->subfield("d");
is( scalar @s, 2 , 'array context' );

my $record = PICA::Record->new();
$record->append($field);

$s = $record->subfield("028A", "d");
ok( $s , 'scalar context' );

@s = $record->subfield("028A", "d");
is( scalar @s, 2 , 'array context' );

$s = $record->subfield('028A$d');
ok( $s , 'field$subfield' );

@s = $record->subfield("028A", "da");
is( scalar @s, 3 , 'multiple subfields' );

@s = $record->values('028A$a', '028A$z', '028A$d' );
is( scalar @s, 3 , 'multiple subfields with values()' );

@s = $record->subfield(1, "028A", "da");
is( scalar @s, 1 , 'multiple subfields with limit' );

@s = $record->subfield(0, '028A', 'azd' );
is( scalar @s, 3 , 'multiple subfields with limit 0' );

@s = $record->subfield(99, '028A', 'azd' );
is( scalar @s, 3, 'multiple subfields with limit high' );

@s = $record->subfield(2, '028A$azd' );
is( scalar @s, 2, 'multiple subfields with limit' );