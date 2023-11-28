package Object::PadX::Role::AutoMarshal;

use v5.36;

use Object::Pad ':experimental(custom_field_attr mop)';
use Object::Pad::MOP::FieldAttr;
use Object::Pad::MOP::Field;
use Object::Pad::MOP::Class;
use Syntax::Operator::Equ qw/is_strequ/;

# ABSTRACT: Automated nested object creation with Object::Pad

our $VERSION = '1.1';

# TODO replace these with the real thing as part of the func flags when Object::Pad finally exposes them
my $_require_value = sub {
  my ($field_meta, $value) = @_;

  die "Missing required attribute value" unless defined $value;
  return $value;
};

Object::Pad::MOP::FieldAttr->register( "MarshalTo", permit_hintkey => 'Object::PadX::Role::AutoMarshal', apply => $_require_value );

sub import {
  my @imports = @_;
  $^H{'Object::PadX::Role::AutoMarshal'}=1;

  if (grep {$_ eq '-toplevel'} @imports) {
    eval "use Object::Pad; use Object::PadX::Role::AutoMarshal; role AutoMarshal :does(Object::PadX::Role::AutoMarshal) {};";
    die $@ if $@;
  }
}
sub unimport { delete $^H{'Object::PadX::Role::AutoMarshal'};}

role Object::PadX::Role::AutoMarshal {
  use Carp qw/croak/;
  use experimental 'for_list';

  ADJUST {
    my $class = __CLASS__;

    my $classmeta = Object::Pad::MOP::Class->for_class($class);
    my @metafields = $classmeta->fields;

    for my $metafield (@metafields) {
      my $field_name = $metafield->name;
      my $sigil = $metafield->sigil;

      my $has_attr = $metafield->has_attribute("MarshalTo");

      # one of ours!
      if ($metafield->has_attribute("MarshalTo")) {
        my $value = $metafield->value($self);
        my $newvalue;

        my $newclass = $metafield->get_attribute_value("MarshalTo");

        if (is_strequ($sigil, '$')) {
          # TODO more advanced parser?
          # :KeyValidator?
          if ($newclass =~ /^\[(.*?)\]$/) {
            $newclass = $1;

            my @list = map {$newclass->new($_->%*)} $value->@*;

            $newvalue = \@list; 

            $metafield->value($self) = $newvalue;
          } elsif ($newclass =~ /^\{(.*?)\}$/) {
            $newclass = $1;

            my %hash = ();
            for my ($k, $v) ($value->%*) {
              $hash{$k} = $newclass->new($v->%*);
            }
            my $newvalue = \%hash; 

            $metafield->value($self) = $newvalue;
          } else {
            $newvalue = $newclass->new($value->%*);

            $metafield->value($self) = $newvalue;
          }
        } elsif (is_strequ($sigil, '%')) {
          my %hash = ();
          for my ($k, $v) ($value->%*) {
            $hash{$k} = $newclass->new($v->%*);
          }
          my $newvalue = \%hash; 

          $metafield->value($self) = $newvalue;
        } elsif (is_strequ($sigil,'@')) {
          $newclass = $1;

          my @list = map {$newclass->new($_->%*)} $value->@*;
          my $newvalue = \@list; 

          $metafield->value($self) = $newvalue;
        } else {
          croak "Unable to handle field $class"."->$sigil$field_name";
        }
      }
    }
  }
}

=pod

=head1 NAME

Object::PadX::Role::AutoMarshal - Object::Pad role that tries to automatically create sub-objects during instantiation.

=head1 WARNING

This module is using the currently experimental Object::Pad::MOP family of packages.  They are subject to change due to the MOP being unfinished, and
thus this module may fail to work at some point in the future due to an update.  This is currently tested with Object::Pad 0.806 released on 2023-11-14

=head1 SYNOPSIS

  use Object::Pad;
  use Object::PadX::Role::AutoMarshal;
  use Cpanel::JSON::XS;

  class Pet {
    field $name :param;
    field $species :param = "Dog";
  }

  class Person :does(Object::PadX::Role::AutoMarshal) {
    field $internal_uuid :param;

    field $first_name :param;
    field $middle_name :param = undef;
    field $last_name :param;
    field $age :param;

    field $is_alive :param;

    field $pets :param :MarshalTo([Pet]) = undef;
  }

  my $person = Person->new(
    internal_uuid => "defe205e-833f-11ee-b962-0242ac120002",
    first_name => "Phillip",
    last_name  => "Fry",
    age => 3049,
    is_alive => 1,
    pets => [
      {
        name => "Spot",
        species => "Dalmation",
      },
      {
        name => "Belle",
        species => "Bloodhound",
      }
    ],
  );

  # Now pets is a set of Pet objects

=head1 DESCRIPTION

This role adds an ADJUST sub that reads the MarshalTo attributes to try to instantiate new objects with the listed class.  
It doesn't require that the subobjects to be made with Object::Pad but it does require the constructor to be expecting all
parameters as a hash, not a hashref or positional arguments.

=head2 CAVEATS

=over 4

=item * This module is VERY opinionated.  All constructors of sub-objects must be expecting a hash as their only input.

=item * It only handles fields at object creation time.  Assignment later does not get considered, so you can overwrite the field with a different type/class.

=item * IT DOES NOT CHECK TYPES.  Do not use this module if you are expecting type checking.

=item * It relies on experimental APIs and will likely break.

=back

=head2 IMPORTS

  use Object::PadX::Role::AutoMarshal '-toplevel';

  class Foo :does(AutoMarshal) {
    ...
  }

This is the only import right now, it creates a top level namespace role AutoJSON for lazy people (like me).
This is a bad idea, don't do it it pollutes this globally since there is no such thing as lexical role imports.

=head2 ATTRIBUTES

=over 4

=item * :MarshalTo(ClassName)

Set the type of object to be instantiated during object creation.  It'll get called as C<< ClassName->new($field_value->%*) >>, expecting the field to have been
set with a hashref on the original ->new call to your class.

=item * :MarshalTo([ClassName])

Create this as an array ref of ClassName objects.  It'll iterate through the field value as an array ref and call C<< ClassName->new($element->%*) >>.
All elements of the array are expected to be hash-refs that will be dereferenced for creating the subobjects. 

=item * :MarshalTo({ClassName})

Create this as a hash ref of ClassName objects.  It'll iterate through the field value as an hash setting each C<$key> and call C<< ClassName->new($value->%*) >> for each value.
All elements of the top level hash-ref are expected to be hash-refs that will be dereferenced for creating the subobjects.

=back

=head1 TRICKS

Since this doesn't actually require the sub-objects to be an Object::Pad class, you can pull some tricks by using a package that just "looks right" to handle more esoteric cases.

    use Object::PadX::Role::AutoMarshal;

    class Thing::Vehicle::Car {
      field $name :param;
      ...
    }

    class Thing::Vehicle::Truck {
      field $name :param;
      ...
    }

    package Thing::VehicleFactory {
      sub new {
        my ($class, %params) = @_;

        my $type = delete $params{type};

        if ($type eq "car") {
          return Thing::Vehicle::Car->new(%params);
        } elsif ($type eq "truck") {
          return Thing::Vehicle::Truck->new(%params);
        } else {
          die "Unhandled vehicle $type";
        }
      }
    }

    class Person :does(Object::PadX::Role::AutoMarshal) {
      field $name :param;
      field $vehicles :param :MarshalTo([Thing::VehicleFactory]) = undef;
    }

    my $peoples = Person->new(
      name => "Phillip J Fry",
      vehicles => [
        {
          type => "car",
          name => "Something meaningful here",
        },
        {
          type => "truck",
          name => "Fry doesn't own a truck!",
        }
      ]
    );

Now when you create a Person object and give it a bunch of vehicles, the Thing::VehicleFactory class will take care of creating the correct object types based on the contents of each element.

=head1 BUGS

No known bugs at this time, if any are found contact simcop2387 on IRC, or email simcop2387 at simcop2387.info

=head1 LICENSE

This module is available under the Artistic 2.0 License

=head1 SEE ALSO

L<Object::Pad>, L<Cpanel::JSON::XS>

=head1 AUTHOR

Ryan Voots, L<simcop@cpan.org>, aka simcop2387

=cut

