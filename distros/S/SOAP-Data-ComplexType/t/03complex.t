#!/usr/local/bin/perl -w

use Test::More tests => 6;

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

package My::SOAP::Data::ComplexType::Bar;
use strict;
use warnings;
use SOAP::Data::ComplexType;
use vars qw(@ISA);
@ISA = qw(SOAP::Data::ComplexType);

use constant OBJ_URI    => 'http://bar.baz.uri';
use constant OBJ_TYPE   => 'ns1:myBar';
use constant OBJ_FIELDS => {
	val1                => ['string', undef, undef],
	val2                => [
		[
			My::SOAP::Data::ComplexType::Foo::OBJ_TYPE,
			My::SOAP::Data::ComplexType::Foo::OBJ_FIELDS
		],
		My::SOAP::Data::ComplexType::Foo::OBJ_URI, undef
	]
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

my $request_obj = My::SOAP::Data::ComplexType::Bar->new({
	val1    => 'sometext',
	val2    => {
		field1  => 'moretext',
		field2  => 12345,
		field3  => '2005-10-26T12:00:00.000Z'
	}
});
isa_ok($request_obj, 'SOAP::Data::ComplexType');

my @data = $request_obj->as_soap_data;
cmp_ok(scalar @data, '==', 2, 'Check that expected fields are present');
isa_ok ($_, 'SOAP::Data') foreach @data;
cmp_ok($request_obj->get_elem('val2')->field1, 'eq', 'moretext', 'Check that nested element is correctly defined');
cmp_ok($request_obj->get_elem('val2')->field2, 'eq', '12345', 'Check that nested element is correctly defined');
