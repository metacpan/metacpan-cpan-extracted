package SOAP::Data::ComplexType::Array;

$VERSION = 0.044;

use strict;
use warnings;
use vars qw(@ISA);
@ISA = qw(SOAP::Data::ComplexType);

use constant OBJ_URI 		=> undef;
use constant OBJ_TYPE		=> 'SOAP-ENC:Array';
use constant OBJ_ARRAY_TYPE	=> undef;
use constant OBJ_FIELDS		=> undef;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $data = shift;
	my $obj_fields = shift;
	$obj_fields = defined $obj_fields && ref($obj_fields) eq 'HASH' ? {%{+OBJ_FIELDS}, %{$obj_fields}} : OBJ_FIELDS;
	my $self = $class->SUPER::new($data, $obj_fields);
	return bless($self, $class);
}

1;

__END__
=pod

=head1 NAME

SOAP::Data::ComplexType::Array - Abstract class for native SOAP Array complex type

=head1 SYNOPSYS

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
		simpleArrayField	=> [
			'SOAP-ENC:Array', undef, undef
			{ 'SOAP-ENC:arrayType' => 'float' },
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
		],
		simpleArrayField => [
			1.5
			5.1
			1234.5678
		]
	});

=head1 DESCRIPTION

SOAP::Data::ComplexType::Array is an abstract class that represents
the native Array complex type in SOAP.  This allows users to define
complex types that extend the Array class

=head1 USAGE

=head2 Object Definition

In SOAP, you can either create an array of a simple or complex type.
Essentially, there are three critical steps:
    1. Defining your class that extends SOAP::Data::ComplexType::Array
    2. Specifying the OBJ_FIELDS definition for your implementing class
    3. Defining the arrayType attribute in your implementing class
	
Since SOAP::Data::ComplexType::Array is a subclass of SOAP::Data::ComplexType,
you must follow the usual L<SOAP::Data/IMPLEMENTATION>, with the following
additional compile-time constant:

	OBJ_ARRAY_TYPE: namespace and type of the complexType (formatted like 'myNamespace:myDataType')
	
For your subclass of SOAP::Data::ComplexType::Array, compile-time constant
OBJ_TYPE B<must> be explcitiy defined as 'ns:Array', as in:

	use constant OBJ_TYPE => 'SOAP-ENC:Array';
	
Then, in the complex type class that implements your complex array class,
you must define the arrayType attribute of your array field to the type
of your class, as in:

	{ 'SOAP-ENC:arrayType' => My::SOAP::Data::ComplexType::ArrayOfSomeItem::OBJ_ARRAY_TYPE }

See the L</SYNOPSYS> for a common example of complex array type usage.

=head2 Constructor input data structure

Perl raw data format to be passed to a complex array constructor might look something
like the following:

	myArray => [
		{
			item1	=> ...,
			item2	=> ...,
			...
		},
		{
			item1	=> ...,
			item2	=> ...,
			...
		},
		...
	]
	
where values within the array must be stored as separate, anonymous hashes.
	
The critical difference between this and what you might expect to use given the L<USAGE>
instructions is that the hashes stored within a perl-data structure array are anonymous,
whereas the XML complex type definition suggests that each element in that array has a key
name.  Perl must define raw data of this type as shown above, as perl hashes do not allow for
duplicate key names with different values in the same level of a hash. This is an important
distinction to be aware of, as it is as a very common element of confusion when dealing with
SOAP arrays in perl.

=head1 AUTHOR

Eric Rybski <rybskej@yahoo.com>.

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Eric Rybski, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<SOAP::Data::ComplexType>

=cut
