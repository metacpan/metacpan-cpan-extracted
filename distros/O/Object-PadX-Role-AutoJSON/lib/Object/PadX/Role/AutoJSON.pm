package Object::PadX::Role::AutoJSON;

use v5.26;

use strict;
use warnings;

use Object::Pad ':experimental(custom_field_attr mop)';
use Object::Pad::MOP::FieldAttr;
use Object::Pad::MOP::Field;
use Object::Pad::MOP::Class;

# TODO replace these with the real thing as part of the func flags when Object::Pad finally exposes them
my $_require_value = sub {
  my ($field_meta, $value) = @_;

  die "Missing required attribute value" unless defined $value;
  return $value;
};

my $_disallow_value = sub {
  my ($field_meta, $value) = @_;

  die "Missing required attribute value" if defined $value;
};

Object::Pad::MOP::FieldAttr->register( "JSONExclude", permit_hintkey => 'Object::PadX::Role::AutoJSON', apply => $_disallow_value );
# Set a new name when going to JSON
Object::Pad::MOP::FieldAttr->register( "JSONKey", permit_hintkey => 'Object::PadX::Role::AutoJSON', apply => $_require_value );
# Allow this to get sent as null, rather than leaving it off
Object::Pad::MOP::FieldAttr->register( "JSONNull", permit_hintkey => 'Object::PadX::Role::AutoJSON', apply => $_disallow_value );
# Force boolean or num or str
Object::Pad::MOP::FieldAttr->register( "JSONBool", permit_hintkey => 'Object::PadX::Role::AutoJSON', apply => $_disallow_value );
Object::Pad::MOP::FieldAttr->register( "JSONNum", permit_hintkey => 'Object::PadX::Role::AutoJSON', apply => $_disallow_value );
Object::Pad::MOP::FieldAttr->register( "JSONStr", permit_hintkey => 'Object::PadX::Role::AutoJSON', apply => $_disallow_value );

Object::Pad::MOP::FieldAttr->register( "JSONList", permit_hintkey => 'Object::PadX::Role::AutoJSON', apply => $_require_value );

# ABSTRACT: Role for Object::Pad that dynamically handles a TO_JSON serialization based on the MOP
our $VERSION = '1.2';

sub import {
  my @imports = @_;
  $^H{'Object::PadX::Role::AutoJSON'}=1;

  if (grep {$_ eq '-toplevel'} @imports) {
    eval "use Object::Pad; use Object::PadX::Role::AutoJSON; role AutoJSON :does(Object::PadX::Role::AutoJSON) {};";
    die $@ if $@;
  }
}

sub unimport { 
  delete $^H{'Object::PadX::Role::AutoJSON'};

  # Don't try to undo -toplevel, madness may ensue 
}

role Object::PadX::Role::AutoJSON {
  use feature 'signatures';

  my $_to_str = sub ($x) {
    return "".$x;
  };

  my $_to_num = sub ($x) {
    return 0+$x;
  };

  my $_to_bool = sub ($x) {
    return !!$x ? \1 : \0;
  };

  my $_to_list = sub ($ref, $type) {
    my $sub = $type eq 'JSONNum' ? $_to_num :
              $type eq 'JSONStr' ? $_to_str :
              $type eq 'JSONBool' ? $_to_bool :
                                    sub {die "Wrong type $type in json conversion"};
    return [map {$sub->($_)} $ref->@*]
  };

  method TO_JSON() {
    my $class = __CLASS__;
    my $classmeta = Object::Pad::MOP::Class->for_class($class);
    my @metafields = $classmeta->fields;

    my %json_out = ();

    for my $metafield (@metafields) {
      my $field_name = $metafield->name;
      my $sigil = $metafield->sigil;

      my $has_exclude = $metafield->has_attribute("JSONExclude");

      next if $has_exclude;

      next if $sigil ne '$';  # Don't try to handle anything but scalars

      my $has_null = $metafield->has_attribute("JSONNull");

      my $value = $metafield->value($self);
      next unless (defined $value || $has_null);

      my $key = $field_name =~ s/^\$//r;
      $key = $metafield->get_attribute_value("JSONKey") if $metafield->has_attribute("JSONKey");

      if ($metafield->has_attribute('JSONBool')) {
        $value = $_to_bool->($value);
      } elsif ($metafield->has_attribute('JSONNum')) {
        # Force numification
        $value = $_to_num->($value);
      } elsif ($metafield->has_attribute('JSONStr')) {
        # Force stringification
        $value = $_to_str->($value);
      } elsif ($metafield->has_attribute('JSONList')) {
        my $type = $metafield->get_attribute_value('JSONList');
        $value = $_to_list->($value, $type);
      }

      $json_out{$key} = $value;
    }

    return \%json_out;
  }
}

=pod

=head1 NAME

Object::PadX::Role::AutoJSON - Object::Pad role that creates an automatic TO_JSON() method that serializes properly with JSON::XS or Cpanel::JSON::XS

=head1 WARNING

This module is using the currently experimental Object::Pad::MOP family of packages.  They are subject to change due to the MOP being unfinished, and
thus this module may fail to work at some point in the future due to an update.  This is currently tested with Object::Pad 0.806 released on 2023-11-14

=head1 SYNOPSIS

  use Object::Pad;
  use Object::PadX::Role::AutoJSON;
  use Cpanel::JSON::XS;

  class Person :does(Object::PadX::Role::AutoJSON) {
    field $internal_uuid :param :JSONStr :JSONKey(uuid);

    field $first_name :param;
    field $middle_name :param :JSONNull = undef;
    field $last_name :param;
    field $age :param :JSONNum;

    field $is_alive :param :JSONBool;

    field $private_information :param :JSONExclude = undef;
  }

  my $person = Person->new(
    internal_uuid => "defe205e-833f-11ee-b962-0242ac120002",
    first_name => "Phillip",
    last_name  => "Fry",
    age => 3049,
    is_alive => 1,
    private_information => {"pin number": "1077"}
  );

  my $json = Cpanel::JSON::XS->new->convert_blessed(1);

  my $output = $json->encode($person);

  $output eq '{
    "uuid": "defe205e-833f-11ee-b962-0242ac120002",
    "first_name": "Phillip",
    "middle_name": null,
    "last_name": "Fry",
    "age": 3049,
    "is_alive": true,
  }'

=head1 DESCRIPTION

This module creates an automatic serialization function named C<TO_JSON> on your Object::Pad classes.  The purpose
of which is to automatically look up all fields in the object and give them out to be serialized by a JSON module.
It also provides a series of attributes, C<:JSONExclude> and such, to allow you to do some basic customization of
how the fields will be output, without affecting how the fields themselves work.

=head2 IMPORTS

  use Object::PadX::Role::AutoJSON '-toplevel';

  class Foo :does(AutoJSON) {
    ...
  }

This is the only import right now, it creates a top level namespace role AutoJSON for lazy people (like me).
This is a bad idea, don't do it it pollutes this globally since there is no such thing as lexical role imports.

=head2 ATTRIBUTES

=over 4

=item * :JSONExclude

This attribute on a field tells the serializier to ignore the field and never output it.  This is useful for internal
fields or fields to other objects that shouldn't be kept as part of the object when serializing, such as a database handle
or private information.

=item * :JSONKey(name)

This attribute lets you change the name that is output when serializing, so that you can use a more descriptive name on the class
but give a shorter one when serializing, or to help multiple classes look the same when output as JSON even if they're different internally.

=item * :JSONNull

Normally fields that have no value will be excluded from output, to prevent accidental nulls being given and breaking other expectations.  
This attribute lets you force those fields to be output when appropriate.

=item * :JSONBool

This attribute forces the value to be re-interpreted as a boolean value, regardless of how perl sees it.  This way you can get a proper 'true' and 'false'
in the resulting JSON without having to massage the value yourself through other means.

=item * :JSONNum

This attribute forces the value to be re-interpreted as a numeric value, regardless of how perl sees it.  This will help handle dual-vars or places where a number
came as a string and perl wouldn't care but JSON does.

=item * :JSONStr

This attribute forces the value to be re-interpreted as a string value, regardless of how perl sees it.  That way numbers, or other value types that were present will
be properly stringified, such as nested objects that override stringification.

=item * :JSONList(type)

This attribute forces the list in the field to have all of it's elements processed as C<type>.  Where C<type> is one of C<JSONNum>, C<JSONStr>, or C<JSONBool>.  See above for any
notes about each type, they match the attributes

=back

=head1 BUGS

No known bugs at this time, if any are found contact simcop2387 on IRC, or email simcop2387 at simcop2387.info

=head1 LICENSE

This module is available under the Artistic 2.0 License

=head1 SEE ALSO

L<Object::Pad>, L<Cpanel::JSON::XS>

=head1 AUTHOR

Ryan Voots, L<simcop@cpan.org>, aka simcop2387

=cut

