#!/usr/local/bin/perl -w

use Test::More tests => 10;

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

package My::SOAP::Data::ComplexType::AnotherItem;

use strict;
use warnings;
use vars qw(@ISA);
@ISA = qw(My::SOAP::Data::ComplexType::SomeItem);

use constant OBJ_URI 	=> undef;
use constant OBJ_TYPE	=> 'SOAP-ENC:SomeItem';
use constant OBJ_FIELDS	=> {
	item1	=> ['string'],
	item4	=> ['int'],
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

########################################################################
package main;

my $request_obj = My::SOAP::Data::ComplexType::AnotherItem->new({
	item1  => 'asdf',
	item2  => 12345.6789,
	item3  => 'text',
	item4  => 54321,
});
isa_ok($request_obj, 'SOAP::Data::ComplexType');
isa_ok($request_obj, 'My::SOAP::Data::ComplexType::SomeItem');

my @data = $request_obj->as_soap_data;
cmp_ok(scalar @data, '==', 4, 'Check that expected fields are present');
isa_ok ($_, 'SOAP::Data') foreach @data;
cmp_ok($request_obj->get_elem('item1')->{type}, 'eq', 'string', 'Check that child class field type is used');
cmp_ok($request_obj->item3, 'eq', 'text', 'Check that parent class field is defined');
cmp_ok($request_obj->item4, '==', 54321, 'Check that extra child class field is defined');
