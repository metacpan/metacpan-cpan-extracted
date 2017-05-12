package SOAP::Data::Builder;
use strict;

=head1 NAME

  SOAP::Data::Builder - A wrapper simplifying SOAP::Data and SOAP::Serialiser

=head1 DESCRIPTION

  This Module provides a quick and easy way to build complex SOAP data
  and header structures for use with SOAP::Lite.

  It primarily provides a wrapper around SOAP::Serializer and SOAP::Data
  (or SOAP::Header) enabling you to generate complex XML within your SOAP
  request or response.

=head1 VERSION

1.0

=head1 SYNOPSIS

  use SOAP::Lite ( +trace => 'all', maptype => {} );

  use SOAP::Data::Builder;

  # create new Builder object
  my $soap_data_builder = SOAP::Data::Builder->new();

  #<eb:MessageHeader eb:version="2.0" SOAP:mustUnderstand="1">
  $soap_data_builder->add_elem(name => 'eb:MessageHeader',
                             header=>1,
                               attributes => {"eb:version"=>"2.0", "SOAP::mustUnderstand"=>"1"});

  #   <eb:From>
  #        <eb:PartyId>uri:example.com</eb:PartyId>
  #        <eb:Role>http://rosettanet.org/roles/Buyer</eb:Role>
  #   </eb:From>
  my $from = $soap_data_builder->add_elem(name=>'eb:From',
                               parent=>$soap_data_builder->get_elem('eb:MessageHeader'));

  $soap_data_builder->add_elem(name=>'eb:PartyId',
                               parent=>$from,
                               value=>'uri:example.com');

  $from->add_elem(name=>'eb:Role', value=>'http://path.to/roles/foo');

  #   <eb:DuplicateElimination/>
  $soap_data_builder->add_elem(name=>'eb:DuplicateElimination', parent=>$soap_data_builder->get_elem('eb:MessageHeader'));


  # fetch Data
  my $data =  SOAP::Data->name('SOAP:ENV' =>
                             \SOAP::Data->value( $soap_data_builder->to_soap_data )
                              );

  # serialise Data using SOAP::Serializer
  my $serialized_xml = SOAP::Serializer->autotype(0)->serialize( $data );

  # serialise Data using wrapper
  my $wrapper_serialised_xml = $soap_data_builder->serialise();

  # make SOAP request with data

  my $foo  = SOAP::Lite
      -> uri('http://www.liverez.com/SoapDemo')
      -> proxy('http://www.liverez.com/soap.pl')
      -> getTest( $soap_data_builder->to_soap_data )
      -> result;

=cut

use SOAP::Data::Builder::Element;
use SOAP::Lite ( maptype => {} );
use Carp qw(carp cluck croak confess);
use Data::Dumper;

our $VERSION = 1.0;

=head1 METHODS

=head2 new(autotype=>0)

Constructor method for this class, it instantiates and returns the Builder object,
taking named options as parameters

my $builder = SOAP::Data::Builder->new( autotype=>0 ); # new object with no autotyping

supported options are :

* autotype which switches on/off SOAP::Serializers autotype setting

* readable which switches on/off SOAP::Serialixer readable setting

=cut

sub new {
    my ($class,%args) = @_;

    my $self = { elements => [], };
    bless ($self,ref $class || $class);
    foreach my $key (keys %args) {
      $self->{options}{$key} = $args{$key};
    }

    return $self;
}

=head2 serialise()

Wrapper for SOAP::Serializer (sic), serialises the contents of the Builder object
and returns the XML as a string

# serialise Data using wrapper
my $wrapper_serialised_xml = $soap_data_builder->serialise();

This method does not accept any arguments

NOTE: serialise is spelt properly using the King's English

=cut

sub serialise {
  my $self = shift;
  my $data =  SOAP::Data->name('SOAP:ENV' =>
			       \SOAP::Data->value( $self->to_soap_data )
			      );
  my $serialized = SOAP::Serializer->autotype($self->autotype)->readable($self->readable)->serialize( $data );
}

=head2 autotype()

returns whether the object currently uses autotype when serialising

=cut

sub autotype {
  return shift->{options}{autotype} || 0;
}

=head2 readable()

returns whether the object currently uses readable when serialising

=cut

sub readable {
 return shift->{options}{readable} || 0;
}

=head2 to_soap_data()

  returns the contents of the object as a list of SOAP::Data and/or SOAP::Header objects

  NOTE: make sure you call this in array context!

=cut

sub to_soap_data {
    my $self = shift;
    my @data = ();
    foreach my $elem ( $self->elems ) {
	push(@data,$self->get_as_data($elem,1));
    }
    return @data;
}

sub elems {
  my $self = shift;
  my @elems = @{$self->{elements}};
  return @elems;
}

=head1 add_elem

This method adds an element to the structure, either to the root list
or a specified element.

optional parameters are : parent, value, attributes, header, isMethod

parent should be an element 'add_elem(parent=>$parent_element, .. );'

or the full name of an element 'add_elem(parent=>'name/of/parent', .. );'

value should be a string,

attributes should be a hashref : { 'ns:foo'=> bar, .. }

header should be 1 or 0 specifying whether the element should be built using SOAP::Data or SOAP::Header

returns the added element

my $bar_elem = $builder->add_elem(name=>'bar', value=>$foo->{bar}, parent=>$foo);

would produce SOAP::Data representing an XML fragment like '<foo><bar>..</bar></foo>'

=cut

sub add_elem {
  my ($self,%args) = @_;
  my $elem = SOAP::Data::Builder::Element->new(%args);
  if ( $args{parent} ) {
      my $parent = $args{parent};
      unless (ref $parent eq 'SOAP::Data::Builder::Element') {
	  $parent = $self->get_elem($args{parent});
      }
      $parent->add_elem($elem);
  } else {
      push(@{$self->{elements}},$elem);
  }
  return $elem;
}

=head2 get_elem('ns:elementName')

returns an element (which is an internal data structure rather than an object)

returns the first element with the name passed as an argument,
sub elements can be referred to as 'grandparent/parent/element'

This structure is passed to other object methods and may change in behaviour, 
type or structure without warning as the class is developed

=cut

sub get_elem {
    my ($self,$name) = (@_,'');
    my ($a,$b);
    my @keys = split (/\//,$name);
    foreach my $elem ( $self->elems) {
	if ($elem->name eq $keys[0]) {
	    $a = $elem;
	    $b = shift(@keys);
	    last;
	}
    }

    my $elem = $a;
    $b = shift(@keys);
    if ($b) {
	$elem = $self->find_elem($elem,$b,@keys);
    }

    return $elem;
}

# internal method

sub find_elem {
    my ($self,$parent,$key,@keys) = @_;

    croak 'parent not defined' unless $parent;

    my ($a,$b);
    foreach my $elem ( $parent->get_children()) {
	next unless ref $elem;
	if ($elem->{name} eq $key) {
	    $a = $elem;
	    $b = $key;
	    last;
	}
    }

    my $elem = $a;
    undef($b);
    while ($b = shift(@keys) ) {
	$elem = $self->find_elem($elem,$b,@keys);
    }
    return $elem;
}


# internal method

sub get_as_data {
  my ($self,$elem) = @_;
  my @values;
  foreach my $value ( @{$elem->value} ) {
    next unless ($value);
    if (ref $value) {
      push(@values,$self->get_as_data($value))
    } else {
      push(@values,$value);
    }
  }
  my @data = ();

  if (ref $values[0]) {
    $data[0] = \SOAP::Data->value( @values );
  } else {
    @data = @values;
  }
  if ($elem->{header}) {
    $data[0] = SOAP::Header->name($elem->{name} => $data[0])->attr($elem->attributes());
  } else {
      if ($elem->{isMethod}) {
	  @data = ( SOAP::Data->name($elem->{name} )->attr($elem->attributes()) => SOAP::Data->value( @values ) );
      } elsif ($elem->{type}) {
	  $data[0] = SOAP::Data->name($elem->{name} => $data[0])->attr($elem->attributes())->type($elem->{type});
      } else {
	  $data[0] = SOAP::Data->name($elem->{name} => $data[0])->attr($elem->attributes());
      }
  }
  return @data;
}

=head2 EXPORT

None.

=head1 SEE ALSO

L<perl>

L<SOAP::Lite>

=head1 AUTHOR

Aaron Trevena, E<lt>teejay@droogs.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004,2005 by Aaron Trevena

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself,

=cut


#############################################################################
#############################################################################

1;
