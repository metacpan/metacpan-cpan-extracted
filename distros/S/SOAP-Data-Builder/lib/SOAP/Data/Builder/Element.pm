package SOAP::Data::Builder::Element;
use strict;

=head1 NAME

  SOAP::Data::Builder::Element - A simple wrapper SOAP::Data Elements

=head1 DESCRIPTION

  This Module provides a quick and easy way to build complex SOAP data
  and header structures for use with SOAP::Lite, managed by SOAP::Data::Builder.

=cut

use Data::Dumper;

=head1 METHODS

=head2 new(autotype=>0)

Constructor method for this class, it instantiates and returns the element object,
taking value and attributes as named parameters

my $element = SOAP::Data::Builder::Element->new( name=> 'anExample', VALUE=> 'foo', attributes => { 'ns1:foo' => 'bar'});

optional parameters are : value, attributes, header, isMethod

parent should be an element fetched using get_elem

value should be a string, to add child nodes use add_elem(parent=>get_elem('name/of/parent'), .. )

attributes should be a hashref : { 'ns:foo'=> bar, .. }

header should be 1 or 0 specifying whether the element should be built using SOAP::Data or SOAP::Header

=cut

sub new {
    my ($class,%args) = @_;
    my $self = {};
    bless ($self,ref $class || $class);
    foreach my $key (keys %args) {
      $self->{$key} = $args{$key} || 0;
    }
    if ($args{parent}) {
	$self->{fullname} = (ref $args{parent}) ? $args{parent}->{fullname}: "$args{parent}/$args{name}";
    }
    $self->{fullname} ||= $args{name};
    $self->{VALUE} = [ $args{value} ];
    return $self;
}

=head2 value()

the value() method sets/gets the VALUE of the element 

=cut

sub value {
    my $self = shift;
    my $value = shift;
    if ($value) {
	if (ref $value) {
	    $self->{VALUE} = $value;
	} else {
	    $self->{VALUE} = [$value];
	}
    } else {
	$value = $self->{VALUE};
    }
    return $value;
}

=head2 name()

the name() method gets/sets the name of the element

=cut

sub name {
    my $self = shift;
    my $value = shift;
    if ($value) {
	$self->{name} = $value;
    } else {
	$value = $self->{name};
    }
    return $value;
}

=head2 fullname()

the fullname() method returns the full '/' delimited name of the element

'eb:foo/eb:name' would return the inner element on <eb:foo><eb:name ..> .. </eb:name></eb:foo>

=cut

sub fullname {
    my $self = shift;
    return $self->{fullname} || $self->{name};
}

=head2 attributes()

returns a hashref of the elements attributes

=cut

sub attributes {
    my $self = shift;
    return $self->{attributes} || {};
}

=head2 remove_attribute($name)

removes a named attribute - returns 1 if it existed , 0 if not 

=cut

sub remove_attribute {
    my ($self, $attribute) = @_;
    my $success = 0;
    if ($self->{attributes}{$attribute}) {
	delete $self->{attributes}{$attribute};
	$success++;
    }
    return $success;
}

=head2 set_attribute($name,$value)

sets a named attribute

=cut

sub set_attribute {
    my ($self, $attribute, $value) = @_;
    $self->{attributes}{$attribute} = $value;
    return 1;
}

=head2 get_attribute($name)

gets a named attribute

=cut

sub get_attribute {
    my ($self, $attribute) = @_;
    return $self->{attributes}{$attribute};
}

=head2 add_elem($elem)

This method adds an element as a child to another element.

Accepts either a SOAP::Data::Builder::Element object or a hash of arguments to create the object

Returns the added element

my $child = $parent->add_elem(name=>'foo',..);

or

$parent->add_elem($child);

=cut

sub add_elem {
    my $self = shift;
    my $elem;
    if (ref $_[0] eq 'SOAP::Data::Builder::Element') {
	$elem = $_[0];
	push(@{$self->{VALUE}},$elem);
    } else {
	$elem = {};
	bless ($elem,ref $self);
	my %args = @_;
	foreach my $key (keys %args) {
	    $elem->{$key} = $args{$key} || 0;
	}
	$elem->{fullname} = $self->{fullname}."/$args{name}";
	$elem->{VALUE} = [ $args{value} ];
	push(@{$self->{VALUE}},$elem);
    }
    return $elem;
}

=head2 get_children()

returns a list of the child nodes of an element

=cut

sub get_children {
    my $self = shift;
    my @children = shift;
    foreach my $value (@{$self->value}) {
	push (@children, $value ) if ref $value;
    }
    if (wantarray) {
	return @children;
    } else {
	return \@children;
    }
}

=head2 remove_elem($name)

removes the named node from the element, returns 1 if existed, 0 if not

=cut

sub remove_elem {
    my ($self,$childname) = @_;
    my @tmp_values = ();
    my $success = 0;
    foreach my $value (@{$self->value}) {
	if (ref $value) {
	    push (@tmp_values, $value) unless ($value->fullname eq $childname);
	    $success++;
	} else {
	    push (@tmp_values, $value);
	}
    }
    $self->{VALUE} = [ @tmp_values ];
    return $success;
}

# soap data method

=head2 get_as_data()

    returns the element and its sub-nodes in SOAP::Data objects.

=cut

sub get_as_data {
  my $self = shift;
  my @values;
  foreach my $value ( @{$self->{VALUE}} ) {
    if (ref $value) {
      push(@values,$value->get_as_data())
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

  if ($self->{header}) {
    $data[0] = SOAP::Header->name($self->{name} => $data[0])->attr($self->{attributes});
  } else {
    if ($self->{isMethod}) {
      @data = ( SOAP::Data->name($self->{name} )->attr($self->{attributes}) => SOAP::Data->value( @values ) );
    } else {
      $data[0] = SOAP::Data->name($self->{name} => $data[0])->attr($self->{attributes});
    }
  }

  return @data;
}


1;
