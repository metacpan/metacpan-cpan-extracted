package PkgForge::YAMLStorage; # -*-perl-*-
use strict;
use warnings;

# $Id: Job.pm.in 15923 2011-02-18 13:41:43Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15923 $
# $HeadURL: https://svn.lcfg.org/svn/source/trunk/PkgForge/lib/PkgForge/Job.pm.in $
# $Date: 2011-02-18 13:41:43 +0000 (Fri, 18 Feb 2011) $

our $VERSION = '1.4.8';

use Carp ();
use Try::Tiny;
use YAML::Syck ();

use Moose::Role;

use PkgForge::Meta::Attribute::Trait::Serialise;

has 'yamlfile' => (
  is  => 'rw',
  isa => 'Maybe[Str]',
  documentation => 'The configuration file for this job',
);

sub new_from_yamlfile {
  my ( $class, @args ) = @_;

  # Permit the passing of a filename, hash or hashref

  my %args;
  if ( scalar @args == 1 && defined $args[0] ) {
    if ( !ref $args[0] ) {
      $args{yamlfile} = $args[0];
    } elsif ( ref $args[0] eq 'HASH' ) {
      %args = %{ $args[0] };
    } else {
      Carp::croak('Single parameters to new_from_yamlfile() must be either a filename or a HASH ref');
    }
  } elsif ( scalar @args % 2 == 0 ) {
    %args = @args;
  } else {
    Carp::croak('Parameters to new_from_yamlfile() must be either a filename, HASH ref or hash');
  }

  # Hunt around for the yaml file name if none has been explicitly specified.

  my $file = $args{yamlfile};
  if ( !defined $file ) {
    my $attr = $class->meta->find_attribute_by_name('yamlfile');
    if ( $attr->has_default ) {
      $file = $attr->default;
    }
  }

  # Handle an attribute 'default' being a code-ref

  if ( ref $file eq 'CODE' ) {
    $file = $file->($class);
  }

  $class->load_data_from_yamlfile( $file, \%args );

  return $class->new(%args);
}

sub load_data_from_yamlfile {
  my ( $class, $file, $results ) = @_;

  if ( !defined $file || !length $file ) {
    Carp::croak('Error: You must specify the meta-data file name');
  } elsif ( !-f $file ) {
    Carp::croak("Error: Cannot find meta-data file '$file'");
  }

  my $data = try {
    YAML::Syck::LoadFile($file);
  } catch {
    Carp::croak("An error occurred whilst loading '$file': $_");
  };

  if ( !defined $data ) {
    Carp::croak("No data found whilst loading '$file'");
  } elsif ( ref $data ne 'HASH' ) {
    Carp::Croak("Cannot load data in '$file', must be a HASH ref");
  }

  for my $attr ( $class->meta->get_all_attributes ) {
    my $name  = $attr->name;
    my $value = $data->{$name};

    # An override value was passed-in. No need to check (or unpack)
    # anything for this attribute.

    if ( defined $results->{$name} ) {
      next;
    }

    if ( $attr->does('PkgForge::Meta::Attribute::Trait::Serialise') ) {
      if ( $attr->has_unpack_method ) {
        my $method = $attr->unpack;
        if ( ref $method eq 'CODE') {
	  $value = $method->($value);
	} elsif ( $class->can($method) ) {
          $value = $class->$method($value);
        } else {
          Carp::croak("Could not find '$method' data unpack method");
        }
      }

      $results->{$name} = $value if defined $value;
    }

  }

  return;
}

sub store_in_yamlfile {
  my ( $self, $file ) = @_;

  $file ||= $self->yamlfile;

  if ( !defined $file || !length $file ) {
    Carp::croak('Error: You need to specify the metadata file name');
  }

  my %dump;
  for my $attr ( $self->meta->get_all_attributes ) {
    my $name  = $attr->name;
    my $value = $attr->get_value($self);

    if ( $attr->does('PkgForge::Meta::Attribute::Trait::Serialise') ) {
      if ( $attr->has_pack_method ) {
        my $method = $attr->pack;
        if ( ref $method eq 'CODE') {
	  $value = $method->($value);
	} elsif ( $self->can($method) ) {
          $value = $self->$method($value);
        } else {
          Carp::croak("Could not find '$method' data pack method");
        }
      }

      $dump{$name} = $value;
    }

  }

  try {
    local $YAML::Syck::SortKeys = 1;
    YAML::Syck::DumpFile( $file, \%dump );
  } catch {
    Carp::croak("Failed to dump to '$file': $_");
  };

  return;
}

no Moose::Role;
1;
__END__

=head1 NAME

PkgForge::YAMLStorage - A Moose role for serialising objects into YAML

=head1 VERSION

This documentation refers to PkgForge::YAMLStorage version 1.4.8

=head1 SYNOPSIS

    package My::App;
    use Moose;

    with 'PkgForge::YAMLStorage';

    has 'foobar' => (
      is     => 'ro',
      isa    => 'Str',
      traits => ['PkgForge::Serialise'],
    );

    # ... rest of the class here

    my $obj = My::App->new();

    $obj->store_in_yamlfile('/tmp/store.yml');

    my $obj2 = My::App->new_from_yamlfile('/tmp/store.yml');

=head1 DESCRIPTION

This is a Moose role for serialising objects into YAML files. This
module is designed to only serialise specific attributes. It is
intended to be simple and lightweight and deliberately only supports a
single format. For much more comprehensive support there are already
more heavy-weight solutions available, such as L<MooseX::Storage>. In
general, YAML can cope very well with serialising most data but this
role also provides support for attributes having their own specialist
methods for packing and unpacking of data.

Only attributes in a class which have the C<PkgForge::Serialise> trait
will be serialised to a YAML file or loaded from a YAML file. In
general YAML can be used to serialise pretty much any data
structure. However, where necessary, any attribute which has the
C<PkgForge::Serialise> trait can specify that it has specialist
C<pack> and/or C<unpack> helper methods. These helper methods can be
used to mangle the attribute data before serialisation or after
deserialisation but prior to the data being loaded as part of the new
object.

=head1 ATTRIBUTES

There is one attribute which is gained by any Moose class which
implements this role.

=over

=item yamlfile

This is a simple string which holds the path to the YAML file. When a
filename is passed into the C<new_from_yamlfile> method the value is
automatically set for this attribute. If no filename is passed into
the C<store_in_yamlfile> method then the value of this attribute will
be used. There is no default value for this attribute and it does not
have to be specified. A class implementing this role may override the
attribute to have a default value if necessary.

=back

=head1 SUBROUTINES/METHODS

=over

=item new_from_yamlfile([$filename|$hashref|%hash])

This method creates a new object for the class with the values of
certain attributes being taken from the YAML file. The method takes
either a single string as a file name, a hash or a reference to a hash
of attributes and their values. If passing a hash or hashref the YAML
file name should be specified using the C<yamlfile> hash key. If no
file name is given then the method will look for a default value for
the C<yamlfile> attribute.

Once the path to the YAML file has been found the data is loaded from
the file using the C<load_data_from_yamlfile> method. Any data passed
in as a hash or reference to a hash will be passed into that method.
The final results hash populated by that method will be passed to the
standard C<new> method for the class and the generated object is
returned.

=item load_data_from_yamlfile( $filename, $results )

This is a class method which takes the name of the YAML file from
which the data should be loaded and a reference to a hash into which
the values of the required attributes should be inserted.

The YAML file must exist and the data in the YAML file must be
loadable as a reference to a hash. Only attributes which have the
C<PkgForge::Serialise> trait will have their values loaded from the
YAML file. Any attribute which already has a value in the results hash
will be ignored. It will not be checked and no data will be unpacked.

Any attribute with the C<PkgForge::Serialise> trait can specify that a
specialist C<unpack> helper method should be used to handle the
unpacking of the data. The unpacking method will be passed a scalar
variable which is either the data or a reference to the data found for
the attribute in the YAML file. The data can be mangled in anyway
required as long as the method returns a single scalar variable (which
may, of course, be a reference to another object or a complex data
structure).

=item store_in_yamlfile($file)

If no file name is specified then the value of the C<yamlfile>
attribute will be used. If no file name is found then an exception
will be thrown.

This method will serialise, into the specified YAML file, a hash of
the attributes, and their values, for the object which have the
C<PkgForge::Serialise> trait. The hash keys will be sorted before
serialisation so that the content of the generated files should always
be reproducible and comparable with a simple text diff tool.

Any attribute with the C<PkgForge::Serialise> trait can specify that a
specialist C<pack> helper method should be used to handle the packing
of the data. The packing method will be passed the value of the
attribute. The data can be mangled in anyway required as long as the
method returns a single scalar variable (which may, of course, be a
reference to a complex data structure).

=head1 DEPENDENCIES

This module is powered by Moose. It also requires L<YAML::Syck> for
reading and writing YAML files and L<Try::Tiny> for exception
handling. It also works fine with L<YAML::XS> but the output files
generated are slightly different. This breaks some expectations in
other parts of the PkgForge code and test-suite so that module,
although better, is being avoided for now.

=head1 SEE ALSO

L<Moose>, L<MooseX::Storage>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

    ScientificLinux5, Fedora13

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2011 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
