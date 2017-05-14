package MooseX::DataModel {
  use Moose;
  use Moose::Exporter;
  use Moose::Util::TypeConstraints qw/find_type_constraint register_type_constraint coerce subtype from via/;
  our $VERSION = "1.00";

  Moose::Exporter->setup_import_methods(
    with_meta => [ qw/ key array object / ],
    also => [ 'Moose', 'Moose::Util::TypeConstraints' ],
  );

  sub key {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an object declaration" if (not defined $properties{isa});

    $properties{ is } = 'ro';

    my $location = delete $properties{ location };
    $properties{ init_arg } = $location if ($location);

    my $type = $properties{isa};

    if (my $constraint = find_type_constraint($type)) {
      if ($constraint->isa('Moose::Meta::TypeConstraint::Class') and 
          (not $constraint->has_coercion or
           not $constraint->coercion->has_coercion_for_type('HashRef'))
         ){
        coerce $type, from 'HashRef', via {
          $type->new(%$_) 
        }
      }

      if ($constraint->has_coercion){
        $properties{ coerce } = 1
      }
    } else {
      die "FATAL: Didn't find a type constraint for $key_name";
    }

    $meta->add_attribute($key_name, \%properties);
  }

  sub _alias_for_paramtype {
    my $name = shift;
    $name =~ s/\[(.*)]$/Of$1/;
    return $name;
  }

  sub object {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an object declaration" if (not defined $properties{isa});

    my $location = delete $properties{ location };
    $properties{ init_arg } = $location if ($location);

    my ($inner_type, $type, $type_alias);

    if (ref($properties{isa})) {
      $type = find_type_constraint($properties{isa});
      die "FATAL: Didn't find a type constraint for $key_name" if (not defined $type);

      $type_alias = _alias_for_paramtype('HashRef[' . $properties{isa}->name . ']');
      $type = Moose::Meta::TypeConstraint::Parameterized->new(
        name   => $type_alias,
        parent => find_type_constraint('HashRef'),
        type_parameter => $properties{isa}
      );
      register_type_constraint($type);

      $inner_type = $properties{isa}->name;
    } else {
      $inner_type = $properties{isa};
      $type_alias = _alias_for_paramtype("HashRef[$inner_type]");

      $type = find_type_constraint("HashRef[$inner_type]");

      if (not defined $type) {
        subtype $type_alias, { as => "HashRef[$inner_type]" };
      }
    }

    my $key_isa = delete $properties{key_isa};

    my $type_constraint = find_type_constraint($inner_type);
    if (defined $type_constraint and not $type_constraint->has_coercion) {
      coerce $inner_type, from 'HashRef', via {
        return $inner_type->new(%$_);
      }
    }

    if (not find_type_constraint($type_alias)->has_coercion) {
      coerce $type_alias, from 'HashRef', via {
        my $uncoerced = $_;
        my $coerce_routine = $type_constraint;
        return { map { ($_ => $coerce_routine->coerce($uncoerced->{$_}, $_[1])) } keys %$uncoerced }
      };
    }

    $properties{ coerce } = 1;
    $properties{ isa } = $type_alias;
    $properties{ is } = 'ro'; 

    $meta->add_attribute($key_name, \%properties);
  }

  sub array {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an array declaration" if (not defined $properties{isa});

    my $location = delete $properties{ location };
    $properties{ init_arg } = $location if ($location);

    my ($inner_type, $type, $type_alias);

    if (ref($properties{isa})) {
      $type = find_type_constraint($properties{isa});
      die "FATAL: Didn't find a type constraint for $key_name" if (not defined $type);

      $type_alias = _alias_for_paramtype('ArrayRef[' . $properties{isa}->name . ']');
      $type = Moose::Meta::TypeConstraint::Parameterized->new(
        name   => $type_alias,
        parent => find_type_constraint('ArrayRef'),
        type_parameter => $properties{isa}
      );
      register_type_constraint($type);

      $inner_type = $properties{isa}->name;
      $properties{ isa } = $type;
    } else {
      $inner_type = $properties{isa};
      $type_alias = _alias_for_paramtype("ArrayRef[$inner_type]");

      $type = find_type_constraint($type_alias);

      if (not defined $type) {
        subtype $type_alias, { as => "ArrayRef[$inner_type]" };
      }
      $properties{ isa } = $type_alias;
    }

    my $type_constraint = find_type_constraint($inner_type);
    if (defined $type_constraint and not $type_constraint->has_coercion) {
      coerce $inner_type, from 'HashRef', via {
        return $inner_type->new(%$_);
      }
    }

    if (not find_type_constraint($type_alias)->has_coercion) {
      coerce $type_alias, from 'ArrayRef', via {
        my $type_c = find_type_constraint($inner_type);
        my $parent = $_[1];
        if ($type_c->has_coercion) {
          return [ map { $type_c->coerce($_) } @$_ ]
        } else {
          return [ map { $_ } @$_ ]
        }
      };
    }

    $properties{ coerce } = 1;
    $properties{ is } = 'ro'; 
    $meta->add_attribute($key_name, \%properties);
  }

  sub new_from_json {
    my ($class, $json) = @_;
    require JSON;
    return $class->new(JSON::decode_json($json));
  }

}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

MooseX::DataModel - Create object models from datastructures

=head1 SYNOPSIS

  package MyModel {
    use MooseX::DataModel;

    version => (isa => 'Int');
    description => (isa => 'Str', required => 1);

    sub do_something {
      my $self = shift;
      if(shift->version == 3) ... 
    }
    # Moose is imported for your convenience 
    has foo => (...);
  }

  my $obj = MyModel->MooseX::DataModel::new_from_json('{"version":3,"description":"a json document"}');
  # $obj is just a plain old Moose object
  print $obj->version;

  my $obj = MyModel->new({ version => 6, description => 'A description' });
  $obj->do_something;

=head1 DESCRIPTION

Working with "plain datastructures" (nested hashrefs, arrayrefs and scalars) that come from other 
systems can be a pain.

Normally those datastructures are not arbitrary: they have some structure to them: most of them 
come to express "object like" things. MooseX::DataModel tries to make converting these datastructures
into objects in an easy, declarative fashion.

Lots of times

MooseX::DataModel also helps you validate the datastructures. If you get an object back, it conforms
to your object model. So if you declare a required key, and the passed datastructure doesn't contain 
it: you will get an exception. If the type of the key passed is different from the one declared: you
get an exception. The advantage over using a JSON validator, is that after validation you still have
your original datastructure. With MooseX::DataModel you get full-blown objects, to which you can
attach logic.

=head1 USAGE

Just use MooseX::DataModel in a class. It will import three keywords C<key>, C<array>, C<object>.
With these keywords we can specify attributes in our class

=head2 key attribute => (isa => $type, [required => 1, location => $location])

Declares an attribute named "attribute" that is of type $type. $type can be a string with a
Moose type constraint (Str, Int), or any user defined subtype (MyPositiveInt). Also it can 
be the name of a class. If it's a class, MooseX::DataModel will coerce a HashRef to the 
specified class (using the HashRef as the objects' constructor parameters).

  package VersionObject {
    use MooseX::DataModel;
    key major => (isa => 'Int');
    key minor => (isa => 'Int');
  }
  package MyObject {
    use MooseX::DataModel;
    key version => (isa => 'VersionObject');
  }

  my $o = MyObject->MooseX::DataModel::new_from_json('{"version":{"major":3,"minor":5}}');
  # $o->version->isa('VersionObject') == true
  print $o->version->major;
  # prints 3
  print $o->version->minor;
  # prints 5

required => 1: declare that this attribute is obliged to be set in the passed datastructure

  package MyObject {
    use MooseX::DataModel;
    key version => (isa => 'Int', required => 1);
  }
  my $o = MyObject->MooseX::DataModel::new_from_json('{"document_version":3}');
  # exception, since "version" doesn't exist
  
  my $o = MyObject->MooseX::DataModel::new_from_json('{"version":3}');
  print $o->version;
  # prints 3

location => $location: $location is a string that specifies in what key of the datastructure to 
find the attributes' value:

  package MyObject {
    use MooseX::DataModel;
    key Version => (isa => 'Int', location => 'document_version');
  }
  my $o = MyObject->MooseX::DataModel::new_from_json('{"document_version":3}');
  print $o->Version;
  # prints 3

=head2 array attribute => (isa => $type, [required => 1, location => $location])

Declares an attribute that holds an array whose elements are of a certain type.

$type, required and location work as in "key"

  package MyObject {
    use MooseX::DataModel;
    key name => (isa => 'Str', required => 1);
    array likes => (isa => 'Str', required => 1, location => 'his_tastes');
  }
  my $o = MyObject->MooseX::DataModel::new_from_json('{"name":"pplu":"his_tastes":["cars","ice cream"]}");
  print $o->likes->[0];
  # prints 'cars'

=head2 object attribute => (isa => $type, [required => 1, location => $location])

Declares an attribute that holds an hash ("JS object") whose elements are of a certain type. This
is useful when in the datastructure you have a hash with arbitrary keys (for known keys you would
describe an object with the "key" keyword.

$type, required and location work as in "key"

  package MyObject {
    use MooseX::DataModel;
    key name => (isa => 'Str', required => 1);
    object likes => (isa => 'Int', required => 1, location => 'his_tastes');
  }
  my $o = MyObject->MooseX::DataModel::new_from_json('{"name":"pplu":"his_tastes":{"cars":9,"ice cream":6}}");
  print $o->likes->{ cars };
  # prints 9

=head1 METHODS

=head2 new

Your class gets the default Moose constructor. You can pass it a hashref with the datastructure

  my $o = MyObject->new({ name => 'pplu', his_tastes => { cars => 9, 'ice cream' => 6 }});

=head2 MooseX::DataModel::from_json

There is a convenience constructor for parsing a JSON (so you don't have to do it from the outside)

  my $o = MyObject->MooseX::DataModel::from_json("JSON STRING");

=head1 INNER WORKINGS

All this can be done with plain Moose, using subtypes, coercions and declaring the 
appropiate attributes (that's what really happens on the inside, although it's not guaranteed
to stay that way forever). MooseX::DataModel just wants to help you write less code :)

=head1 BUGS and SOURCE

The source code is located here: https://github.com/pplu/moosex-datamodel

Please report bugs to:

=head1 COPYRIGHT and LICENSE

    Copyright (c) 2015 by CAPSiDE

    This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.

=cut
