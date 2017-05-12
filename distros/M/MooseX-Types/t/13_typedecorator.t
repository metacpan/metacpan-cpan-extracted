use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use lib 't/lib';

{
    package Test::MooseX::TypeLibrary::TypeDecorator;

    use Moose;
    use MooseX::Types::Moose qw(
        Int Str ArrayRef HashRef Object
    );
    use DecoratorLibrary qw(
        MyArrayRefBase MyArrayRefInt01 MyArrayRefInt02 StrOrArrayRef
        AtLeastOneInt Jobs SubOfMyArrayRefInt01 WierdIntegersArrayRef1
        WierdIntegersArrayRef2
    );

    has 'arrayrefbase' => (is=>'rw', isa=>MyArrayRefBase, coerce=>1);
    has 'arrayrefint01' => (is=>'rw', isa=>MyArrayRefInt01, coerce=>1);
    has 'arrayrefint02' => (is=>'rw', isa=>MyArrayRefInt02, coerce=>1);
    has 'arrayrefint03' => (is=>'rw', isa=>MyArrayRefBase[Int]);
    has 'StrOrArrayRef_attr' => (is=>'rw', isa=>StrOrArrayRef);
    has 'AtLeastOneInt_attr' => (is=>'rw', isa=>AtLeastOneInt);
    has 'pipeoverloading' => (is=>'rw', isa=>Int|Str);
    has 'deep' => (is=>'rw', isa=>ArrayRef[ArrayRef[HashRef[Int]]] );
    has 'deep2' => (is=>'rw', isa=>ArrayRef[Int|ArrayRef[HashRef[Int|Object]]] );
    has 'enum' => (is=>'rw', isa=>Jobs);
    has 'SubOfMyArrayRefInt01_attr' => (is=>'rw', isa=>SubOfMyArrayRefInt01);
    has 'WierdIntegersArrayRef1_attr' => (is=>'rw', isa=>WierdIntegersArrayRef1);
    has 'WierdIntegersArrayRef2_attr' => (is=>'rw', isa=>WierdIntegersArrayRef2);
}

## Make sure we have a 'create object sanity check'

ok my $type = Test::MooseX::TypeLibrary::TypeDecorator->new(),
 => 'Created some sort of object';

isa_ok $type, 'Test::MooseX::TypeLibrary::TypeDecorator'
 => "Yes, it's the correct kind of object";

## test arrayrefbase normal and coercion

ok $type->arrayrefbase([qw(a b c d e)])
 => 'Assigned arrayrefbase qw(a b c d e)';

is_deeply $type->arrayrefbase, [qw(a b c d e)],
 => 'Assignment is correct';

ok $type->arrayrefbase('d,e,f')
 => 'Assignment arrayrefbase d,e,f to test coercion';

is_deeply $type->arrayrefbase, [qw(d e f)],
 => 'Assignment and coercion is correct';

## test arrayrefint01 normal and coercion

ok $type->arrayrefint01([qw(1 2 3)])
 => 'Assignment arrayrefint01 qw(1 2 3)';

is_deeply $type->arrayrefint01, [qw(1 2 3)],
 => 'Assignment is correct';

ok $type->arrayrefint01('4.5.6')
 => 'Assigned arrayrefint01 4.5.6 to test coercion from Str';

is_deeply $type->arrayrefint01, [qw(4 5 6)],
 => 'Assignment and coercion is correct';

ok $type->arrayrefint01({a=>7,b=>8})
 => 'Assigned arrayrefint01 {a=>7,b=>8} to test coercion from HashRef';

is_deeply $type->arrayrefint01, [qw(7 8)],
 => 'Assignment and coercion is correct';

like exception {
    $type->arrayrefint01([qw(a b c)])
}, qr/Attribute \(arrayrefint01\) does not pass the type constraint/ => 'Dies when values are strings';

## test arrayrefint02 normal and coercion

ok $type->arrayrefint02([qw(1 2 3)])
 => 'Assigned arrayrefint02 qw(1 2 3)';

is_deeply $type->arrayrefint02, [qw(1 2 3)],
 => 'Assignment is correct';

ok $type->arrayrefint02('4:5:6')
 => 'Assigned arrayrefint02 4:5:6 to test coercion from Str';

is_deeply $type->arrayrefint02, [qw(4 5 6)],
 => 'Assignment and coercion is correct';

ok $type->arrayrefint02({a=>7,b=>8})
 => 'Assigned arrayrefint02 {a=>7,b=>8} to test coercion from HashRef';

is_deeply $type->arrayrefint02, [qw(7 8)],
 => 'Assignment and coercion is correct';

ok $type->arrayrefint02({a=>'AA',b=>'BBB', c=>'CCCCCCC'})
 => "Assigned arrayrefint02 {a=>'AA',b=>'BBB', c=>'CCCCCCC'} to test coercion from HashRef";

is_deeply $type->arrayrefint02, [qw(2 3 7)],
 => 'Assignment and coercion is correct';

ok $type->arrayrefint02({a=>[1,2],b=>[3,4]})
 => "Assigned arrayrefint02 {a=>[1,2],b=>[3,4]} to test coercion from HashRef";

is_deeply $type->arrayrefint02, [qw(1 2 3 4)],
 => 'Assignment and coercion is correct';

# test arrayrefint03

ok $type->arrayrefint03([qw(11 12 13)])
 => 'Assigned arrayrefint01 qw(11 12 13)';

is_deeply $type->arrayrefint03, [qw(11 12 13)],
 => 'Assignment is correct';

like exception {
    $type->arrayrefint03([qw(a b c)])
}, qr/Attribute \(arrayrefint03\) does not pass the type constraint/ => 'Dies when values are strings';

# TEST StrOrArrayRef

ok $type->StrOrArrayRef_attr('string')
 => 'String part of union is good';

ok $type->StrOrArrayRef_attr([1,2,3])
 => 'arrayref part of union is good';

like exception {
    $type->StrOrArrayRef_attr({a=>111});
}, qr/Attribute \(StrOrArrayRef_attr\) does not pass the type constraint/ => 'Correctly failed to use a hashref';

# Test AtLeastOneInt

ok $type->AtLeastOneInt_attr([1,2]),
 => 'Good assignment';

is_deeply $type->AtLeastOneInt_attr, [1,2]
 => "Got expected values.";

like exception {
    $type->AtLeastOneInt_attr([]);
}, qr/Attribute \(AtLeastOneInt_attr\) does not pass the type constraint/ => 'properly fails to assign as []';

like exception {
    $type->AtLeastOneInt_attr(['a','b']);
}, qr/Attribute \(AtLeastOneInt_attr\) does not pass the type constraint/ => 'properly fails arrayref of strings';

## Test pipeoverloading

ok $type->pipeoverloading(1)
 => 'Integer for union test accepted';

ok $type->pipeoverloading('a')
 => 'String for union test accepted';

like exception {
    $type->pipeoverloading({a=>1,b=>2});
}, qr/Validation failed for 'Int|Str'/ => 'Union test corrected fails a HashRef';

## test deep (ArrayRef[ArrayRef[HashRef[Int]]])

ok $type->deep([[{a=>1,b=>2},{c=>3,d=>4}],[{e=>5}]])
 => 'Assigned deep to [[{a=>1,b=>2},{c=>3,d=>4}],[{e=>5}]]';

is_deeply $type->deep, [[{a=>1,b=>2},{c=>3,d=>4}],[{e=>5}]],
 => 'Assignment is correct';

like exception {
    $type->deep({a=>1,b=>2});
}, qr/Attribute \(deep\) does not pass the type constraint/ => 'Deep Constraints properly fail';

# test deep2 (ArrayRef[Int|ArrayRef[HashRef[Int|Object]]])

ok $type->deep2([[{a=>1,b=>2},{c=>3,d=>4}],[{e=>5}]])
 => 'Assigned deep2 to [[{a=>1,b=>2},{c=>3,d=>4}],[{e=>5}]]';

is_deeply $type->deep2, [[{a=>1,b=>2},{c=>3,d=>4}],[{e=>5}]],
 => 'Assignment is correct';

like exception {
    $type->deep2({a=>1,b=>2});
}, qr/Attribute \(deep2\) does not pass the type constraint/ => 'Deep Constraints properly fail';

like exception {
    $type->deep2([[{a=>1,b=>2},{c=>3,d=>'noway'}],[{e=>5}]]);
}, qr/Attribute \(deep2\) does not pass the type constraint/ => 'Deep Constraints properly fail';


ok $type->deep2([[{a=>1,b=>2},{c=>3,d=>$type}],[{e=>5}]])
 => 'Assigned deep2 to [[{a=>1,b=>2},{c=>3,d=>$type}],[{e=>5}]]';


is_deeply $type->deep2, [[{a=>1,b=>2},{c=>3,d=>$type}],[{e=>5}]],
 => 'Assignment is correct';

ok $type->deep2([1,2,3])
 => 'Assigned deep2 to [1,2,3]';


is_deeply $type->deep2, [1,2,3],
 => 'Assignment is correct';

## Test jobs

ok $type->enum('Programming')
 => 'Good Assignment of Programming to Enum';


like exception {
    $type->enum('ddddd');
}, qr/Attribute \(enum\) does not pass the type constraint/ => 'Enum properly fails';

## Test SubOfMyArrayRefInt01_attr

ok $type->SubOfMyArrayRefInt01_attr([15,20,25])
 => 'Assigned SubOfMyArrayRefInt01_attr to [15,20,25]';

is_deeply $type->SubOfMyArrayRefInt01_attr, [15,20,25],
 => 'Assignment is correct';

like exception {
    $type->SubOfMyArrayRefInt01_attr([15,5,20]);
}, qr/Attribute \(SubOfMyArrayRefInt01_attr\) does not pass the type constraint/
 => 'SubOfMyArrayRefInt01 Constraints properly fail';

## test WierdIntegersArrayRef1

ok $type->WierdIntegersArrayRef1_attr([5,10,1000])
 => 'Assigned deep2 to [5,10,1000]';

is_deeply $type->WierdIntegersArrayRef1_attr, [5,10,1000],
 => 'Assignment is correct';

like exception {
    $type->WierdIntegersArrayRef1_attr({a=>1,b=>2});
}, qr/Attribute \(WierdIntegersArrayRef1_attr\) does not pass the type constraint/
 => 'Constraints properly fail';

like exception {
    $type->WierdIntegersArrayRef1_attr([5,10,1]);
}, qr/Attribute \(WierdIntegersArrayRef1_attr\) does not pass the type constraint/
 => 'Constraints properly fail';

like exception {
    $type->WierdIntegersArrayRef1_attr([1]);
}, qr/Attribute \(WierdIntegersArrayRef1_attr\) does not pass the type constraint/
 => 'Constraints properly fail';

## test WierdIntegersArrayRef2

ok $type->WierdIntegersArrayRef2_attr([5,10,$type])
 => 'Assigned deep2 to [5,10,$type]';

is_deeply $type->WierdIntegersArrayRef2_attr, [5,10,$type],
 => 'Assignment is correct';

like exception {
    $type->WierdIntegersArrayRef2_attr({a=>1,b=>2});
}, qr/Attribute \(WierdIntegersArrayRef2_attr\) does not pass the type constraint/
 => 'Constraints properly fail';

like exception {
    $type->WierdIntegersArrayRef2_attr([5,10,1]);
}, qr/Attribute \(WierdIntegersArrayRef2_attr\) does not pass the type constraint/
 => 'Constraints properly fail';

like exception {
    $type->WierdIntegersArrayRef2_attr([1]);
}, qr/Attribute \(WierdIntegersArrayRef2_attr\) does not pass the type constraint/
 => 'Constraints properly fail';

done_testing();
