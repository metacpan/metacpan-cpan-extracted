package Oryx::Value;

use base qw(Class::Data::Inheritable);

use Module::Pluggable(
    search_path => 'Oryx::Value',
    sub_name    => 'types',
    require     => 1,
);

=head1 NAME

Value - base class for value types for the Oryx object persistence tool

=head1 SYNOPSIS

 # constructor - this is what you should do
 tie $obj->{some_field}, 'Oryx::Value::SomeType', ($meta, $owner);
  
 # this is if you really must call these methods on the tied object
 # although normally these are called by the tied object on $self
 tied($obj->{some_field})->deflate($value);
 tied($obj->{some_field})->inflate($value);
 tied($obj->{some_field})->check($value);
 tied($obj->{some_field})->check_required($value);
 tied($obj->{some_field})->check_type($value);
 tied($obj->{some_field})->check_size($value);
 tied($obj->{some_field})->meta;
 tied($obj->{some_field})->owner;

=head1 DESCRIPTION

This module is considered abstract and should be sublcassed to create the
actual Value types.

The purpose of these Value types is to validate input and to prepare
field values for storage in the database via the C<deflate> method and
to prepare the values for consumption after retrieval via the C<inflate>
method.

The tie constructor is passed the associated L<Oryx::Attribute> instance which
can be accessed via C<meta>, along with the L<Oryx::Class> instance to which
the Attribute - and therefore the value - belongs. The L<Oryx::Class> instance
can be accessed with the C<owner> accessor.

=head1 SUBCLASSING

The C<tie> related methods: C<TIESCALAR>, C<STORE> and C<FETCH>, as well as
C<VALUE> should not be overridden when subclassing - they are documented here
for the sake of completeness.

The C<inflate>, C<deflate>, C<check_thing>, and C<primitive> methods are usually overloaded when subclassing.

=head1 METHODS

=over

=item TIESCALAR( $meta, $owner )

takes two arguments: C<$meta> and C<$owner> - C<$meta> is the L<Oryx::Attribute>
instance with which this value is associated, and C<$owner> is the L<Oryx::Class>
instance (or persistent object).

This method should not be called directly, instead use

 my $attr_name = $attrib->name;
 tie $object->{$attr_name}, 'Oryx::Value::String', $attrib, $object;
 
=cut

sub TIESCALAR {
    my $class = shift;
    my ($meta, $owner) = @_;
    my $self = bless {
	meta  => $meta,  # Oryx::Attribute instance
	owner => $owner, # Oryx::Class instance
    }, $class;

    $self->STORE($self->owner->{$self->meta->name});
    return $self;
}

=item FETCH

automatically called by Perl when the field to which this Value is tied
is retrieved. You should not normally need to call this directly.

=cut

sub FETCH {
    my $self = shift;
    unless (defined $self->VALUE) {
	my $value = $self->owner->{$self->meta->name};
	$self->VALUE($self->inflate($value));
    }
    return $self->VALUE;
}

=item STORE( $value )

automatically called by Perl when the field to which this Value is tied
is set via assignment. You should not normally need to call this directly.

=cut

sub STORE {
    my ($self, $value) = @_;
    if ($self->check($value)) {
	$self->VALUE($value);
    } else {
	$self->_croak('check failed ['.$value.'] MESSAGE: '.$self->errstr);
    }
}

=item VALUE

mutator to the internal raw value held in this tied object instance

=cut

sub VALUE {
    my $self = shift;
    $self->{VALUE} = shift if @_;
    return $self->{VALUE};
}

=item deflate( $value )

hook to modify the value before it is stored in the db. C<$value> is the
raw value associated with the attribute as it is in the live object. This
is not neccessarily the same as its representation in the database. Take
L<Oryx::Value::Complex> for example. Complex serializes its value using
L<YAML> before it saves it to the database. C<deflate> does the serialization
in this case. It is passed the value in the live object which could be
a hash ref or array ref (or anything else that could be serialized using
YAML) and returns the serialized YAML string representation of that value.

=cut

sub deflate {
    my ($self, $value) = @_;
    return $value
}

=item inflate( $value )

hook to modify the value as it is loaded from the db. This is the complement
to C<deflate> in that it takes the value loaded from the database and cooks
it before it is associated with the attribute of the live C<Oryx::Class> object.

In the case of L<Oryx::Value::Complex> C<$value> is a YAML string which is
deserialized using YAML and the result returned.

=cut

sub inflate {
    my ($self, $value) = @_;
    return $value;
}

=item check( $value )

hook for checking the value before it is set. You should consider carefully
if you need to override this method as this one calls the other C<check_thing>
methods and sets C<< $self->errstr >> if any of them fail.

=cut

sub check {
    my ($self, $value) = @_;
    unless ($self->check_required($value)) {
	$self->errstr('value required');
	return 0;
    }
    if (defined $value) {
	unless ($self->check_type($value)) {
	    $self->errstr('type mismatch');
	    return 0;
	}
	unless ($self->check_size($value)) {
	    $self->errstr('size mismatch');
	    return 0;
	}
    }
    return 1;
}

=item check_type( $value )

hook for doing type checking on the passed C<$value>. Should return
1 if successful and 0 if not.

=cut

sub check_type {
    my ($self, $value) = @_;
    return 1;
}

=item check_size( $value )

hook for doing size checking on the passed C<$value>. Should return
1 if successful and 0 if not.

=cut

sub check_size {
    my ($self, $value) = @_;
    return 1;
}

=item check_required( $value )

hook for checking if the passed C<$value> is required. Should return
1 if the value is required and defined and 0 if required and not defined.
If the value is not required, return 1.

=cut

sub check_required {
    my ($self, $value) = @_;
    if ($self->meta->required) {
	return defined $value;
    } else {
	return 1;
    }
}

=item errstr

returns the error string if input checks failed.

=cut

sub errstr {
    my $self = shift;
    $self->{errstr} = shift if @_;
    return $self->{errstr};
}

=item meta

simple accessor to meta data for this value type, in this case,
a reference to the L<Oryx::Attribute> with which this Value instance
is associated.

=cut

sub meta  { $_[0]->{meta}  }

=item owner

returns the L<Oryx::Class> which owns the L<Oryx::Attribute> instance
with which this Value instance is associated.

=cut

sub owner { $_[0]->{owner} }

=item primitive

Returns a string representing the underlying primitive type. This is used by the storage driver to determine how to pick the data type to use to store the value. The possible values include:

=over

=item Integer

=item String

=item Text

=item Binary

=item Float

=item Boolean

=item DateTime

=back

There is an additional internal type called "Oid", but it should not be used.

=cut

sub primitive { $_[0]->_croak('abstract') }

sub _croak {
    my ($self, $msg) = @_;
    $self->{owner}->_croak("<".$self->{meta}->name."> $msg");
}

sub _carp {
    my ($self, $msg) = @_;
    $self->{owner}->_carp("<".$self->{meta}->name."> $msg");
}

1;

=back

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENCE

This library is free software and may be used under the same terms as Perl itself.

=cut
