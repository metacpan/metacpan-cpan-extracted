package MooseX::Attribute::Deflator;

# ABSTRACT: Deflate and inflate Moose attribute values

use strict;
use warnings;
use Moose::Exporter;
use MooseX::Attribute::Deflator::Registry;
use Moose::Util qw();

sub via (&)    { $_[0] }
sub inline_as (&) { $_[0] }

Moose::Exporter->setup_import_methods(
    as_is => [ qw( deflate inflate via inline_as ) ], );

my $REGISTRY = MooseX::Attribute::Deflator::Registry->new;

sub get_registry {$REGISTRY}

sub deflate {
    my $types = shift;
    $types = [$types] unless ( ref $types eq 'ARRAY' );
    $REGISTRY->add_deflator( $_, @_ ) for (@$types);
}

sub inflate {
    my $types = shift;
    $types = [$types] unless ( ref $types eq 'ARRAY' );
    $REGISTRY->add_inflator( $_, @_ ) for (@$types);
}

deflate 'Item', via {$_}, inline_as {'$value'};
inflate 'Item', via {$_}, inline_as {'$value'};

Moose::Util::_create_alias( 'Attribute', 'Deflator', 1,
    'MooseX::Attribute::Deflator::Meta::Role::Attribute' );

1;

__END__

=head1 SYNOPSIS

 package MySynopsis;

 use Moose;
 use DateTime;

 use MooseX::Attribute::Deflator;

 deflate 'DateTime',
    via { $_->epoch },
    inline_as { '$value->epoch' }; # optional
 inflate 'DateTime',
    via { DateTime->from_epoch( epoch => $_ ) },
    inline_as { 'DateTime->from_epoch( epoch => $value )' }; # optional

 no MooseX::Attribute::Deflator;

 # import default deflators and inflators for Moose types
 use MooseX::Attribute::Deflator::Moose;

 has now => ( is => 'rw', 
            isa => 'DateTime', 
            default => sub { DateTime->now }, 
            traits => ['Deflator'] );

 has hash => ( is => 'rw', 
               isa => 'HashRef', 
               default => sub { { foo => 'bar' } }, 
               traits => ['Deflator'] );

 package main;

 use Test::More;

 my $obj = MySynopsis->new;

 {
     my $attr = $obj->meta->get_attribute('now');
     my $deflated = $attr->deflate($obj);
     like($deflated, qr/^\d+$/);

     my $inflated = $attr->inflate($obj, $deflated);
     isa_ok($inflated, 'DateTime');
 }

 {
     my $attr = $obj->meta->get_attribute('hash');
     my $deflated = $attr->deflate($obj);
     is($deflated, '{"foo":"bar"}');

     my $inflated = $attr->inflate($obj, $deflated);
     is_deeply($inflated, {foo => 'bar'})
 }

 done_testing;

=head1 DESCRIPTION

This module consists of a a registry (L<MooseX::Attribute::Deflator::Registry>) an attribute trait L<MooseX::Attribute::Deflator::Meta::Role::Attribute> and predefined deflators and inflators
for Moose L<MooseX::Attribute::Deflator::Moose> and MooseX::Types::Strutured L<MooseX::Attribute::Deflator::Structured>.
This class is just sugar to set the inflators and deflators.

You can deflate to whatever data structure you want. Loading L<MooseX::Attribute::Deflator::Moose>
will cause HashRefs and ArrayRefs to be encoded as JSON strings. However, you can simply overwrite
those deflators (and inflators) to deflate to something different like L<Storable>.

Unlike C<coerce>, you don't need to create a deflator and inflator for every type. Instead this module
will bubble up the type hierarchy and use the first deflator or inflator it finds.

This comes at a cost: B<Union types are not supported>.

For extra speed, inflators and deflators can be inlined. All in/deflators that come with this
module have an inlined version as well. Whenever you implment custom type in/deflators, you
should consider writing the inlining code as well. The performance boost is immense. You
can check whether an deflator has been inlined by calling:

 $attr->is_deflator_inlined;

B<< Inlining works in Moose >= 1.9 only. >>

=head1 FUNCTIONS

=over 4

=item B<< deflate >>

=item B<< inflate >>

 deflate 'DateTime',
    via { $_->epoch },
    inline_as { '$value->epoch' }; # optional

 inflate 'DateTime',
    via { DateTime->from_epoch( epoch => $_ ) },
    inline_as { 'DateTime->from_epoch( epoch => $value )' }; # optional
    
Defines a deflator or inflator for a given type constraint. This can also be
a type constraint defined via L<MooseX::Types> and parameterized types.

The function supplied to C<via> is called with C<$_> set to the attribute's value
and with the following arguments:

=over 8

=item C<$attr>

The attribute on which this deflator/inflator has been called

=item C<$constraint>

The type constraint attached to the attribute

=item C<< $deflate/$inflate >>

A code reference to the deflate or inflate function. E.g. this is handy if you want
to call the type's parent's parent inflate or deflate method:

 deflate 'MySubSubType', via {
    my ($attr, $constraint, $deflate) = @_;
    return $deflate->($_, $constraint->parent->parent);
 };

=item C<$instance>

The object instance on which this deflator/inflator has been called.

=item C<@_>

Any other arguments added to L<MooseX::Attribute::Deflator::Meta::Role::Attribute/inflate>
or L<MooseX::Attribute::Deflator::Meta::Role::Attribute/deflate>.

=back

For C<inline>, the parameters are handled a bit differently. The code generating subroutine
is called with the following parameters:

=over 8

=item C<$constraint>

The type constraint attached to the attribute.

=item C<$attr>

The attribute on which this deflator/inflator has been called.

=item C<$registry>

 my $parent = $registry->($constraint->parent);
 my $code = $parent->($constraint->parent, $attr, $registry, @_);

To get the code generator of a type constraint, call this function.

=back

The C<inline> function is expected to return a string. The generated code
has access to a number of variables:

=over 8

=item C<$value>

Most important, the value that should be de- or inflated is stored in C<$value>.

=item C<$type_constraint>

=back

For some more advanced examples, have a look at the source of
L<MooseX::Attribute::Deflator::Moose> and L<MooseX::Attribute::Deflator::Structured>.

=back

=head1 DEFLATE AN OBJECT INSTANCE

Usually, you want to deflate certain attributes of a class, but this module only
works on a per attribute basis. In order to deflate an instance with all of its
attributes, you can use the following code:

 sub deflate {
    my $self = shift;
    
    # you probably want to deflate only those that are required or have a value
    my @attributes = grep { $_->has_value($self) || $_->is_required }
                     $self->meta->get_all_attributes;
    
    # works only if all attributes have the 'Deflator' trait applied
    return { map { $_->name => $_->deflate($self) } @attributes };
 }

If you are using L<MooseX::Attribute::LazyInflator>,
throw in a call to L<MooseX::Attribute::LazyInflator::Meta::Role::Attribute/is_inflated>
to make sure that you don't deflate an already deflated attribute. Instead, you can just
use L<Moose::Meta::Attribute/get_raw_value> to get the deflated value.

=head1 PERFORMANCE

The overhead for having custom deflators or inflators per attribute is minimal.
The file C<benchmark.pl> tests three ways of deflating the value of a HashRef attribute
to a json encoded string (using L<JSON>).

 my $obj     = MyBenchmark->new( hashref => { foo => 'bar' } );
 my $attr    = MyBenchmark->meta->get_attribute('hashref');

=over

=item deflate

 $attr->deflate($obj); 

Using the deflate attribute method, supplied by this module.

=item accessor

 JSON::encode_json($obj->hashref);

If the attribute comes with an accessor, you can use this
method, to deflate its value. However, you need to know the
name of the accessor in order to use this method.

=item get_value

 JSON::encode_json($attr->get_value($obj, 'hashref'));

This solves the mentioned problem with not knowing the
accessor name.

=back

The results clearly states that using the C<deflate> method
adds only minimal overhead to deflating the attribute
value manually.

               Rate get_value   deflate  accessor
 get_value  69832/s        --      -87%      -88%
 deflate   543478/s      678%        --       -4%
 accessor  564972/s      709%        4%        --
