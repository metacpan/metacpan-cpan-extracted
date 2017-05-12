#!/usr/local/bin/perl -w

use Test::More tests => 5;

package My::SOAP::Data::ComplexType::SomeItem;

use strict;
use warnings;
use SOAP::Data::ComplexType;
use vars qw(@ISA);
@ISA = qw(SOAP::Data::ComplexType);

use constant OBJ_URI 	=> undef;
use constant OBJ_TYPE	=> 'SOAP-ENC:SomeItem';
use constant OBJ_FIELDS	=> {
	item1	=> ['int'],
	item2	=> ['float'],
	item3	=> ['string'],
};

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $data = shift;
	my $obj_fields = shift;
	$obj_fields = defined $obj_fields && ref($obj_fields) eq 'HASH' ? {%{+OBJ_FIELDS}, %{$obj_fields}} : OBJ_FIELDS;
	my $self = $class->SUPER::new($data, $obj_fields);
	return bless($self, $class);
}

package My::SOAP::Data::ComplexType::ArrayOfSomeItem;

use strict;
use warnings;
use SOAP::Data::ComplexType::Array;
use vars qw(@ISA);
@ISA = qw(SOAP::Data::ComplexType::Array);

use constant OBJ_URI 		=> undef;
use constant OBJ_TYPE		=> SOAP::Data::ComplexType::Array::OBJ_TYPE;
use constant OBJ_ARRAY_TYPE	=> My::SOAP::Data::ComplexType::SomeItem::OBJ_TYPE;
use constant OBJ_FIELDS		=> {
	someItem	=> [
		[My::SOAP::Data::ComplexType::SomeItem::OBJ_TYPE, My::SOAP::Data::ComplexType::SomeItem::OBJ_FIELDS], 
		My::SOAP::Data::ComplexType::SomeItem::OBJ_URI
	],
};

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $data = shift;
	my $obj_fields = shift;
	$obj_fields = defined $obj_fields && ref($obj_fields) eq 'HASH' ? {%{+OBJ_FIELDS}, %{$obj_fields}} : OBJ_FIELDS;
	my $self = $class->SUPER::new($data, $obj_fields);
	return bless($self, $class);
}


package My::SOAP::Data::ComplexType::Baz;

use strict;
use warnings;
use SOAP::Data::ComplexType 0.032;
use vars qw(@ISA);
@ISA = qw(SOAP::Data::ComplexType);

use constant OBJ_URI 	=> undef;
use constant OBJ_TYPE	=> 'SOAP-ENC:Baz';
use constant OBJ_FIELDS	=> {
	simpleField	=> ['string'],
	arrayField	=> [
		[My::SOAP::Data::ComplexType::ArrayOfSomeItem::OBJ_TYPE, My::SOAP::Data::ComplexType::ArrayOfSomeItem::OBJ_FIELDS],
		My::SOAP::Data::ComplexType::ArrayOfSomeItem::OBJ_URI,
		{ 'SOAP-ENC:arrayType' => My::SOAP::Data::ComplexType::ArrayOfSomeItem::OBJ_ARRAY_TYPE },
	],
};

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $data = shift;
	my $obj_fields = shift;
	$obj_fields = defined $obj_fields && ref($obj_fields) eq 'HASH' ? {%{+OBJ_FIELDS}, %{$obj_fields}} : OBJ_FIELDS;
	my $self = $class->SUPER::new($data, $obj_fields);
	return bless($self, $class);
}

package main;

my $request_obj = My::SOAP::Data::ComplexType::Baz->new({
	simpleField	=> 'sometext',
	arrayField	=> [
		{
			item1	=> 12345,
			item2	=> 12345.6789,
			item3	=> 'asdf'
		},
		{
			item1	=> 54321,
			item2	=> 98765.4321,
			item3	=> 'fdsa'
		}
	]
});
isa_ok($request_obj, 'SOAP::Data::ComplexType');

my @data = $request_obj->as_soap_data;
cmp_ok(scalar @data, '==', 2, 'Check that expected fields are present');
isa_ok ($_, 'SOAP::Data') foreach @data;
cmp_ok(scalar @{([$request_obj->arrayField])}, '==', 2, 'Check that complex array is correct size');
