#!/usr/local/bin/perl -w

use Test::More tests => 16;

package My::SOAP::Data::ComplexType::Foo;
use strict;
use warnings;
use SOAP::Data::ComplexType;
use vars qw(@ISA);
@ISA = qw(SOAP::Data::ComplexType);

use constant OBJ_URI    => 'http://foo.bar.baz';
use constant OBJ_TYPE   => 'ns1:myFoo';
use constant OBJ_FIELDS => {
	field1              => ['string', undef, undef],
	field2              => ['int', undef, undef],
	field3              => ['xsd:dateTime', undef, undef]
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

my $request_obj = My::SOAP::Data::ComplexType::Foo->new({
	field1  => 'moretext',
	field2  => 12345,
	field3  => '2005-10-26T12:00:00.000Z'
});
isa_ok($request_obj, 'SOAP::Data::ComplexType');

my @data = $request_obj->as_soap_data;
cmp_ok(scalar @data, '==', 3, 'Check that expected fields are present');
isa_ok ($_, 'SOAP::Data') foreach @data;

my $dhref = $request_obj->as_soap_data_instance(name => 'myObject');
isa_ok($dhref, 'SOAP::Data');
cmp_ok($dhref->name, 'eq', 'myObject', 'Check object instance name');
cmp_ok($dhref->type, 'eq', &My::SOAP::Data::ComplexType::Foo::OBJ_TYPE, 'Check object instance type');
cmp_ok($dhref->uri, 'eq', &My::SOAP::Data::ComplexType::Foo::OBJ_URI, 'Check object instance uri');
cmp_ok(scalar @{[${$dhref->value()}->value()]}, '==', 3, 'Check that expected object instance fields are present');
cmp_ok($request_obj->field1, 'eq', 'moretext', 'Check autoload accessor method');
cmp_ok($request_obj->get('field1'), 'eq', 'moretext', 'Check get accessor method');

my $data = $request_obj->as_raw_data;
cmp_ok(scalar keys %{$data}, '==', 3, 'Check that raw data expected fields are present');
cmp_ok($data->{field2}, '==', 12345, 'Check that raw data is valid');

$request_obj->set('field1', 'text1');
cmp_ok($request_obj->field1, 'eq', 'text1', 'Check that set method worked');

$request_obj->field1('text2');
cmp_ok($request_obj->field1, 'eq', 'text2', 'Check that autoload accessor set method worked');
