use Test::More;
use strict;
use warnings;

use Moose::Util::TypeConstraints;

subtype 'C', as 'ArrayRef';
coerce 'C', from 'Str', via { [ $_ ] };

no Moose::Util::TypeConstraints;

package TestRole;
use Moose::Role;
use MooseX::Attribute::LazyInflator;


has attr => ( is => 'rw', coerce => 1, isa => 'C', traits => ['LazyInflator'] );

package Test;
use Moose;
use MooseX::Attribute::LazyInflator;
with 'TestRole';

package main;

for ( 1 .. 2 ) {

    my $foo = Test->new( attr => "foo" );
    is_deeply(Test->meta->get_attribute('attr')->get_raw_value($foo), ["foo"], 'raw value is arrayref');
    is_deeply( $foo->attr, ["foo"], 'attribute has been coerced' );
    ok( Test->meta->get_attribute('attr')->is_inflated($foo) );

    $foo = Test->new( attr => ['foo'] );
    is_deeply(Test->meta->get_attribute('attr')->get_raw_value($foo), ["foo"], 'raw value is arrayref');
    is_deeply( $foo->attr, ["foo"], 'attribute has been coerced' );
    ok( Test->meta->get_attribute('attr')->is_inflated($foo) );
    Test->meta->make_immutable;

}

done_testing;
