#############
# Created By: setitesuk@gmail.com
# Created On: 2009-11-03
# Last Updated: 2009-11-09

package MooseX::AttributeCloner;
use Moose::Role;
use Carp qw{carp cluck croak confess};
use English qw{-no_match_vars};
use Readonly;

use JSON;

our $VERSION = 0.27;

Readonly::Scalar our $ATTRIBUTE_METACLASS_TO_SKIP => q[MooseX::Getopt::Meta::Attribute::NoGetopt];

=head1 NAME

MooseX::AttributeCloner

=head1 VERSION

0.27

=head1 SYNOPSIS

  package My::Class;
  use Moose;
  with qw{MooseX::AttributeCloner};

  my $NewClassObject = $self->new_with_cloned_attributes(q{New::Class}, {});
  1;

=head1 DESCRIPTION

The purpose of this Role is to take all the attributes which have values in the current class,
and populate them directly into a new class object. The purpose of which is that if you have data
inputted on the command line that needs to propagate through to later class objects, you shouldn't
need to do the following

  my $oNewClass = New::Class->new({
    attr1 => $self->attr1,
    attr2 => $self->attr2,
    ...
  });

Which is going to get, quite frankly, tedious in the extreme. Particularly when you have more 2 class
objects in your chain.

=head1 SUBROUTINES/METHODS

=head2 new_with_cloned_attributes

This takes a package name as the first argument, plus an optional additional $arg_refs hash. It will
return a class object of the package populated with any matching attribute data from the current object,
plus anything in the $arg_refs hash.

=cut

sub new_with_cloned_attributes {
  my ($self, $package, $arg_refs) = @_;
  $arg_refs ||= {};

  if (!ref$self && ref$package) {
    my $temp = $self;
    $self = $package;
    $package = $temp;
  }

  eval {
    my $package_file_name = $package;
    $package_file_name =~ s{::}{/}gxms;
    if ($package_file_name !~ /[.]pm\z/xms) {
      $package_file_name .= q{.pm};
    }
    require $package_file_name;
  } or do {
    confess $EVAL_ERROR;
  };
  $self->_hash_of_attribute_values($arg_refs);
  return $package->new($arg_refs);
}

=head2 attributes_as_command_options

returns all the built attributes that are not objects as a string of command_line options
only the first level of references will be passed through, multi-dimensional data structures
should use the json serialisation option and deserialise it on object construction or script
running

  my $command_line_string = $class->attributes_as_command_options();
  --attr1 val1 --attr2 val2

By default, it returns the options with a double dash, space separated, and not quoted (as above). These can be switched by submitting a hash_ref as follows

  my $command_line_string = $class->attributes_as_command_options({
    equal => 1,
    quotes => 1,
    single_dash => 1,
  });

Although, if you are passing a hash_ref, this will always be space separated attr val.

You may exclude some values if you wish. To do this, use the example below

  my $command_line_string = $class->attributes_as_command_options({
    excluded_attributes => [ qw( init_arg1 init_arg2 init_arg3 ) ],
  });

Note here you are using the init_arg, rather than any reader/accessor method names to exclude the option, as it is the init_arg which will be used in the command_line string generated

Sometimes you may have floating attributes for argv and ARGV (we have discovered this with MooseX::Getopt). As such, these are being treated as 'special', and these will be excluded by default. You can request them to be included as follows.

  my $command_line_string = $class->attributes_as_command_options({
    included_argv_attributes => [ qw( argv ARGV ) ],
  });

No additional command_line params can be pushed into this, it only deals with the attributes already set in the current object

Note, it is your responsibility to know where you may need any of these to be on or off, unless they have no init_arg (init_arg => undef)

From v0.25, any attributes with a metaclass of NoGetopt will not be translated to a command line as they would cause a failure to any new_with_options with MooseX::Getopt. You can override this by passing an additional argument 'include_no_getopt'

  my $command_line_string = $class->attributes_as_command_options({
    included_argv_attributes => [ qw( argv ARGV ) ],
    include_no_getopt => 1,
  });

=cut

sub attributes_as_command_options {
  my ($self,$arg_refs) = @_;
  $arg_refs ||= {};

  my $attributes = $self->_hash_of_attribute_values({command_options => 1});

  # exclude any specified init_args
  $self->_exclude_args($attributes, $arg_refs);

  # remove any objects from the hash
  $self->_traverse_hash($attributes);

  my @command_line_options;

  # version 0.21 - force this to be in a sorted order, so that results can be consistent should operating systems return keys in a different order
  foreach my $key (sort keys %{$attributes}) {

    if (! ref $attributes->{$key}
          &&
        ( (ref( $self->meta()->get_attribute($key) ) ne $ATTRIBUTE_METACLASS_TO_SKIP ) || $arg_refs->{include_no_getopt} ) ) {
      my $string = $self->_create_string($key, $attributes->{$key}, $arg_refs);
      push @command_line_options, $string;
      next;
    }

    if (ref $attributes->{$key} eq q{HASH}) {

      foreach my $h_key (sort {$a cmp $b} keys %{$attributes->{$key}}) {

        if (defined $attributes->{$key}->{$h_key} && ! ref $attributes->{$key}->{$h_key}) { # don't pass through empty strings or references
          my $string = $self->_create_string($key, qq{$h_key=$attributes->{$key}->{$h_key}}, $arg_refs, 1);
          push @command_line_options, $string;
        }

      }

    }

    if (ref $attributes->{$key} eq q{ARRAY}) {

      foreach my $value (@{$attributes->{$key}}) {

        if (defined $value && ! ref $value) { # don't pass through empty strings or references
          my $string = $self->_create_string($key, $value, $arg_refs);
          push @command_line_options, $string;
        }

      }

    }

  }

  my $clo_string;
  if ($arg_refs->{single_dash}) {
    $clo_string = join q{ -}, @command_line_options;
    $clo_string = q{-} . $clo_string;
  } else {
    $clo_string = join q{ --}, @command_line_options;
    $clo_string = q{--} . $clo_string;
  }
  return $clo_string;
}

=head2 attributes_as_json

returns all the built attributes that are not objects as a JSON string

  my $sAttributesAsJSON = $class->attributes_as_json();

=head2 attributes_as_escaped_json

as attributes_as_json, except it is an escaped JSON string, so that this could be used on a command line

  my $sAttributesAsEscapedJSON = $class->attributes_as_escaped_json();

This uses JSON to generate the string, removing any objects before stringifying, and then parses it through a regex to generate a string with escaped characters
Note, because objects are removed, arrays will remain the correct length, but have null in them
=cut

sub attributes_as_escaped_json {
  my ($self) = @_;
  my $json = $self->attributes_as_json();
  $json =~ s{([^\w\d-])}{\\$1}gmxs;
  return $json;
}

sub attributes_as_json {
  my ($self) = @_;

  my $attributes = $self->_hash_of_attribute_values();
  # remove any objects from the hash
  $self->_traverse_hash($attributes);
  my $json = to_json($attributes);
  return $json;
}

=head2 attributes_as_hashref

Returns a hashref of the attributes this object has built,
optionally excluding any specified attributes.
Includes objects which may have been built.

  my $hAttributesAsHashref = $class->attributes_as_hashref({
    excluded_attributes => [ qw( init_arg1 init_arg2 init_arg3 ) ],
  });

Note here you are using the init_arg, rather than any reader/accessor method names to exclude the option

=cut

sub attributes_as_hashref {
  my ( $self, $arg_refs ) = @_;
  $arg_refs ||= {};
  my $attributes = $self->_hash_of_attribute_values();

  # exclude any specified init_args
  $self->_exclude_args($attributes, $arg_refs);
  return $attributes;
}

###############
# private methods


# a hash_ref of attribute values from $self, where built
# either acts on a provided hash_ref, or will return a new one
sub _hash_of_attribute_values {
  my ($self, $arg_refs) = @_;
  $arg_refs ||= {};

  my $command_options = $arg_refs->{command_options};
  delete$arg_refs->{command_options};

  my @attributes = $self->meta->get_all_attributes();
  foreach my $attr (@attributes) {
    my $reader   = $attr->reader()   || $attr->accessor();
    my $init_arg = $attr->init_arg();

    # if there is no reader/accessor method, then we can't read the attribute value, so skip
    next if (!$reader);

    # if the reader/accessor are private, then we don't want to pass it around
    next if ($reader =~ /\A_/xms);

    # if lazy_build, then will only propagate data if it is built, saving any expensive build routines.
    # obviously, this has the effect that you may need to do it twice, or force a build before the cloning of data
    # NOTE: this doesn't account for those which are lazy, and have a builder, but no predicate (generated by lazy_build flag only)
    if ($attr->{predicate}) {
      my $pred = $attr->{predicate};
      next if !$self->$pred();
    }

    if ($init_arg && !exists$arg_refs->{$init_arg} && defined $self->$reader()) {
      next if ( $attr->type_constraint() eq q{Bool} && $command_options && ! $self->$reader );
      $arg_refs->{$init_arg} = $attr->type_constraint() eq q{Bool} && $command_options ? q{} : $self->$reader();
    }
  }

  return $arg_refs;
}

# remove any objects from a hash
sub _traverse_hash {
  my ($self, $hash) = @_;
  my @keys_to_delete;
  foreach my $key (keys %{$hash}) {
    next if (!ref $hash->{$key});
    if (ref$hash->{$key} eq q{HASH}) {
      $self->_traverse_hash($hash->{$key});
      next;
    }
    if (ref$hash->{$key} eq q{ARRAY}) {
      $hash->{$key} = $self->_traverse_array($hash->{$key});
      next;
    }
    push @keys_to_delete, $key;
  }
  foreach my $key (@keys_to_delete) {
    delete $hash->{$key};
  }
  return $hash;
}

# remove any objects from an array
sub _traverse_array {
  my ($self, $array) = @_;
  my @wanted_items;
  foreach my $item (@{$array}) {
    if (!ref $item) {
      push @wanted_items, $item;
      next;
    }
    if (ref$item eq q{HASH}) {
      $self->_traverse_hash($item);
      push @wanted_items, $item;
      next;
    }
    if (ref$item eq q{ARRAY}) {
      $item = $self->_traverse_array($item);
      push @wanted_items, $item;
      next;
    }
    push @wanted_items, undef;
  }
  return \@wanted_items;
}

############
# remove any unwanted options by the init_arg they would have

sub _exclude_args {
  my ($self, $attributes, $arg_refs) = @_;
  my $excluded_attributes = $arg_refs->{excluded_attributes} || [];
  delete $arg_refs->{excluded_attributes};
  my $included_argv_attributes = $arg_refs->{included_argv_attributes} || [];
  delete $arg_refs->{included_argv_attributes};
  if (!$excluded_attributes && !$included_argv_attributes) {
    return 1;
  }

  if ( ! ref$excluded_attributes || ref$excluded_attributes ne q{ARRAY} ) {
    croak qq{Your excluded_attributes are not in an arrayref - $excluded_attributes};
  }

  if ( ! ref$included_argv_attributes || ref$included_argv_attributes ne q{ARRAY} ) {
    croak qq{Your included_argv_attributes are not in an arrayref - $included_argv_attributes};
  }

  foreach my $exclusion (@{$excluded_attributes}) {
    delete $attributes->{$exclusion};
  }

  my $wanted_argv = {};
  foreach my $inclusion (@{$included_argv_attributes}) {
    $wanted_argv->{$inclusion}++;
  }

  foreach my $argv ( qw{ argv ARGV }) {
    if (!$wanted_argv->{$argv}) {
      delete $attributes->{$argv};
    }
  }

  return 1;
}

# create a command line string

sub _create_string {
  my ($self, $attr, $value, $arg_refs, $hash) = @_;
  my $string = $attr;

  if ($value ne q{} && !$hash && $arg_refs->{equal}) {
    $string .= q{=};
  } else {
    $string .= q{ }; # default attr value separator
  }

  if ($value ne q{} && $arg_refs->{quotes}) {
    $string .= qq{"$value"};
  } else {
    $string .= qq{$value}; # default no quote of value
  }
  return $string;
}

1;
__END__

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Carp

=item English -no_match_vars

=item Readonly

=item JSON

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

This is more than likely to have bugs in it. Please contact me with any you find (or submit to RT)
and any patches.

=head1 AUTHOR

setitesuk

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 Andy Brown (setitesuk@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
