#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 62;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib";

{
    package Test::MouseX::TypeLibrary::TypeDecorator;
    
    use Mouse;
    use MouseX::Types::Mouse qw(
        Int Str ArrayRef HashRef Object
    );
    use DecoratorLibrary qw(
        MyArrayRefBase MyArrayRefInt01 MyArrayRefInt02 StrOrArrayRef
        AtLeastOneInt Jobs SubOfMyArrayRefInt01 WierdIntergersArrayRef1
        WierdIntergersArrayRef2
    );
    
    has 'arrayrefbase' => (is=>'rw', isa=>MyArrayRefBase, coerce=>1);
    has 'arrayrefint01' => (is=>'rw', isa=>MyArrayRefInt01, coerce=>1);
    has 'arrayrefint02' => (is=>'rw', isa=>MyArrayRefInt02, coerce=>1);
    has 'arrayrefint03' => (is=>'rw', isa=>MyArrayRefBase[Int]);
    has 'StrOrArrayRef' => (is=>'rw', isa=>StrOrArrayRef);
    has 'AtLeastOneInt' => (is=>'rw', isa=>AtLeastOneInt);
    has 'pipeoverloading' => (is=>'rw', isa=>Int|Str);   
    has 'deep' => (is=>'rw', isa=>ArrayRef[ArrayRef[HashRef[Int]]] );
    has 'deep2' => (is=>'rw', isa=>ArrayRef[Int|ArrayRef[HashRef[Int|Object]]] );
    has 'enum' => (is=>'rw', isa=>Jobs);
    has 'SubOfMyArrayRefInt01_attr' => (is=>'rw', isa=>SubOfMyArrayRefInt01);
    has 'WierdIntergersArrayRef1_attr' => (is=>'rw', isa=>WierdIntergersArrayRef1);
    has 'WierdIntergersArrayRef2_attr' => (is=>'rw', isa=>WierdIntergersArrayRef2);   
}

## Make sure we have a 'create object sanity check'

ok my $type = Test::MouseX::TypeLibrary::TypeDecorator->new(),
 => 'Created some sort of object';
 
isa_ok $type, 'Test::MouseX::TypeLibrary::TypeDecorator'
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
 
throws_ok sub {
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
 
throws_ok sub {
    $type->arrayrefint03([qw(a b c)])
}, qr/Attribute \(arrayrefint03\) does not pass the type constraint/ => 'Dies when values are strings';

# TEST StrOrArrayRef

ok $type->StrOrArrayRef('string')
 => 'String part of union is good';

ok $type->StrOrArrayRef([1,2,3])
 => 'arrayref part of union is good';
 
throws_ok sub {
    $type->StrOrArrayRef({a=>111});
}, qr/Attribute \(StrOrArrayRef\) does not pass the type constraint/ => 'Correctly failed to use a hashref';

# Test AtLeastOneInt

ok $type->AtLeastOneInt([1,2]),
 => 'Good assignment';

is_deeply $type->AtLeastOneInt, [1,2]
 => "Got expected values.";
 
throws_ok sub {
    $type->AtLeastOneInt([]);
}, qr/Attribute \(AtLeastOneInt\) does not pass the type constraint/ => 'properly fails to assign as []';

throws_ok sub {
    $type->AtLeastOneInt(['a','b']);
}, qr/Attribute \(AtLeastOneInt\) does not pass the type constraint/ => 'properly fails arrayref of strings';

## Test pipeoverloading

ok $type->pipeoverloading(1)
 => 'Integer for union test accepted';
 
ok $type->pipeoverloading('a')
 => 'String for union test accepted';

throws_ok sub {
    $type->pipeoverloading({a=>1,b=>2});
}, qr/Validation failed for 'Int|Str'/ => 'Union test corrected fails a HashRef';

## test deep (ArrayRef[ArrayRef[HashRef[Int]]])

ok $type->deep([[{a=>1,b=>2},{c=>3,d=>4}],[{e=>5}]])
 => 'Assigned deep to [[{a=>1,b=>2},{c=>3,d=>4}],[{e=>5}]]';

is_deeply $type->deep, [[{a=>1,b=>2},{c=>3,d=>4}],[{e=>5}]],
 => 'Assignment is correct';
 
throws_ok sub {
    $type->deep({a=>1,b=>2});
}, qr/Attribute \(deep\) does not pass the type constraint/ => 'Deep Constraints properly fail';

# test deep2 (ArrayRef[Int|ArrayRef[HashRef[Int|Object]]])

ok $type->deep2([[{a=>1,b=>2},{c=>3,d=>4}],[{e=>5}]])
 => 'Assigned deep2 to [[{a=>1,b=>2},{c=>3,d=>4}],[{e=>5}]]';

is_deeply $type->deep2, [[{a=>1,b=>2},{c=>3,d=>4}],[{e=>5}]],
 => 'Assignment is correct';
 
throws_ok sub {
    $type->deep2({a=>1,b=>2});
}, qr/Attribute \(deep2\) does not pass the type constraint/ => 'Deep Constraints properly fail';

throws_ok sub {
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


throws_ok sub {
    $type->enum('ddddd');
}, qr/Attribute \(enum\) does not pass the type constraint/ => 'Enum properly fails';

## Test SubOfMyArrayRefInt01_attr

ok $type->SubOfMyArrayRefInt01_attr([15,20,25])
 => 'Assigned SubOfMyArrayRefInt01_attr to [15,20,25]';

is_deeply $type->SubOfMyArrayRefInt01_attr, [15,20,25],
 => 'Assignment is correct';
 
throws_ok sub {
    $type->SubOfMyArrayRefInt01_attr([15,5,20]);
}, qr/Attribute \(SubOfMyArrayRefInt01_attr\) does not pass the type constraint/
 => 'SubOfMyArrayRefInt01 Constraints properly fail';

## test WierdIntergersArrayRef1 

ok $type->WierdIntergersArrayRef1_attr([5,10,1000])
 => 'Assigned deep2 to [5,10,1000]';

is_deeply $type->WierdIntergersArrayRef1_attr, [5,10,1000],
 => 'Assignment is correct';
 
throws_ok sub {
    $type->WierdIntergersArrayRef1_attr({a=>1,b=>2});
}, qr/Attribute \(WierdIntergersArrayRef1_attr\) does not pass the type constraint/
 => 'Constraints properly fail';

throws_ok sub {
    $type->WierdIntergersArrayRef1_attr([5,10,1]);
}, qr/Attribute \(WierdIntergersArrayRef1_attr\) does not pass the type constraint/
 => 'Constraints properly fail';

throws_ok sub {
    $type->WierdIntergersArrayRef1_attr([1]);
}, qr/Attribute \(WierdIntergersArrayRef1_attr\) does not pass the type constraint/
 => 'Constraints properly fail';

## test WierdIntergersArrayRef2 

ok $type->WierdIntergersArrayRef2_attr([5,10,$type])
 => 'Assigned deep2 to [5,10,$type]';

is_deeply $type->WierdIntergersArrayRef2_attr, [5,10,$type],
 => 'Assignment is correct';
 
throws_ok sub {
    $type->WierdIntergersArrayRef2_attr({a=>1,b=>2});
}, qr/Attribute \(WierdIntergersArrayRef2_attr\) does not pass the type constraint/
 => 'Constraints properly fail';

throws_ok sub {
    $type->WierdIntergersArrayRef2_attr([5,10,1]);
}, qr/Attribute \(WierdIntergersArrayRef2_attr\) does not pass the type constraint/
 => 'Constraints properly fail';

throws_ok sub {
    $type->WierdIntergersArrayRef2_attr([1]);
}, qr/Attribute \(WierdIntergersArrayRef2_attr\) does not pass the type constraint/
 => 'Constraints properly fail';




