package Repository::Simple::Engine::Memory;

use strict;
use warnings;

our $VERSION = '0.05';

use Carp;
use IO::Scalar;
use Repository::Simple::Engine qw( :exists_constants );
use Repository::Simple::Type::Node;
use Repository::Simple::Type::Property;
use Repository::Simple::Type::Value::Scalar;

use base 'Repository::Simple::Engine';

=head1 NAME

Repository::Simple::Engine::Memory - Transient repository storage in memory

=head1 SYNOPSIS

  use Repository::Simple;
  my $mem = Repository::Simple->attach('Memory');

=head1 DESCRIPTION

This repository uses a transient memory store to store all nodes and properties. This is very simple and cnfigurable.

=head1 OPTIONS

You may create this repository with no options to accept all defaults. This will give you an empty repository (i.e., containing only a root node, with no properties). Until writes are implemented, this isn't at all useful, so you will probably want to issue a "root" option to at least specify a structure for the repository.

If you do specify options, you may specify any of the following:

=over

=item namespaces

This option accepts a hash of namespace prefixes to namespace URIs. This allows you to customize the namespaces used by the storage engine. By default, this contains a single entry "mem".

=item node_types

This option allows you to create an arbitrary set of node types for storing information in the repository. This should be an array of hashes. Each hash will be passed to the constructor of L<Repository::Simple::Type::Node> (with the "engine" argument added to refer to the newly created engine).

By default, a single node type, "mem:generic-node" is created, which provides very few constraints.

=item property_types

This option allows you to create an arbitrary set of property types for storing information in the repository. This should be an array of hashes. Each hash will be passed to the constructor of L<Repository::Simple::Type::Property> (with the "engine" argument added to refer to the newly created engine).

By default, a single node type, "mem:generic-property" is created, which provides very few constraints.

=item root

This option establishes what nodes are initially in the repository. If this option is not included, the repository will be empty, except for the root. If you specify a custom set of node types and do not include "mem:generic-node", you must define this option as the default setting will attempt to create a node with that node type.

The option should be set to a hash reference representing the root node. It must have the "node_type" key set to the name of the node type the root node should have. It may, optionally, also have a "nodes" and a "properties" key. 

The "nodes" key, if present, should point to a hash reference where each key is the name of each child node and each hash will have the same form as the root value. Thus, this structure is recursive, each node will be represented by a hash containing a "node_type" key and optionally "nodes" and "properties" keys.

The "properties" key, if present, should point to a hash reference where each eky is the name of each child property. Each hash should contain a "property_type" pointing to the name of the property_type for that value. It may also have a "value" key pointing to the properties value, stored as a scalar value or reference.

For example, 

  my %settings = (
      root => {
          node_type => 'mem:generic',
          properties => {
              'foo' => {
                  property_type => 'mem:generic-property',
                  value => 1,
              },
              'bar' => {
                  property_type => 'mem:generic-property',
                  value => 2,
              },
          },
          nodes => {
              'baz' => {
                  node_type => 'mem:generic',
                  nodes => {
                      'qux' => {
                          node_type => 'mem:generic',
                          properties => {
                              quux => {
                                  property_type => 'mem:generic-property',
                                  value => 3,
                              },
                          },
                      },
                  },
              },
          },
      },
  );
  my $repository = Repository::Simple->attach(Memory => %settings);

=back

=cut

my %default_settings = (
    namespaces => {
        mem => 'http://contentment.org/Repository/Simple/Engine/Memory',
    },
    node_types => [
        {
            name => 'mem:generic-node',
            property_types => {
                '*' => [ 'mem:generic-property' ],
            },
            node_types => {
                '*' => [ 'mem:generic-node' ],
            },
            auto_created => 0,
            updatable => 1,
            removable => 1,
        },
    ],
    property_types => [
        {
            name => 'mem:generic-property',
            auto_created => 0,
            updatable => 1,
            removable => 1,
            value_type => Repository::Simple::Type::Value::Scalar->new,
        },
    ],
    root => {
        node_type => 'mem:generic',
    },
);

sub new {
    my $class = shift;
    my %settings = (%default_settings, @_);

    my $self = $class->SUPER::new(%settings);

    # This crazy thing turns the array into a hash and converts each element
    # into a Repository::Simple::Type::Node
    $self->{node_types} 
        = { map 
            { 
                ($_->{name} 
                    => Repository::Simple::Type::Node->new(
                        %$_, engine => $self
                    )
                ) 
            } @{ $self->{node_types} } };

    # This crazy thing turns the array into a hash and converts each element
    # into a Repository::Simple::Type::Property
    $self->{property_types}
        = { map 
            { 
                ($_->{name} 
                    => Repository::Simple::Type::Property->new(
                        %$_, engine => $self
                    ) 
                )
            } @{ $self->{property_types} } };

    return $self;
}

sub node_type_named {
    my ($self, $name) = @_;
    return $self->{node_types}{$name};
}

sub property_type_named {
    my ($self, $name) = @_;
    return $self->{property_types}{$name};
}

sub lookup {
    my ($self, $path) = @_;
    my @names = split '/', $path;
    shift @names; # Get rid of the first ''

    my $item = $self->{root};
    for my $name (@names) {
#        use Data::Dumper;
#        print STDERR Dumper($name, $item);
        last unless defined $item;

        $item = $item->{nodes}{$name} || $item->{properties}{$name};
    }

    return $item;
}


sub path_exists {
    my ($self, $path) = @_;
    
    my $item = $self->lookup($path);

    return !defined $item                  ? $NOT_EXISTS
         :  defined $item->{node_type}     ? $NODE_EXISTS
         :  defined $item->{property_type} ? $PROPERTY_EXISTS
         :  croak qq(invalid item at path "$path");
}

sub check_lookup {
    my ($self, $type, $path) = @_;

    my $item = $self->lookup($path);

    croak qq(no $type found at "$path") unless defined $item;
    croak qq(item at path "$path" is not a $type) 
        unless defined $item->{"${type}_type"};

    return $item;
}

sub node_type_of {
    my ($self, $path) = @_;

    my $item = $self->check_lookup('node', $path);
    
    return $self->node_type_named($item->{node_type});
}

sub property_type_of {
    my ($self, $path) = @_;

    my $item = $self->check_lookup('property', $path);

    return $self->property_type_named($item->{property_type});
}

sub nodes_in {
    my ($self, $path) = @_;

    my $item = $self->check_lookup('node', $path);

    return keys %{ $item->{nodes} };
}

sub properties_in {
    my ($self, $path) = @_;

    my $item = $self->check_lookup('node', $path);

    return keys %{ $item->{properties} };
}

sub get_scalar {
    my ($self, $path) = @_;

    my $item = $self->check_lookup('property', $path);

    return $item->{value};
}

sub get_handle {
    my ($self, $path, $mode) = @_;

    my $item = $self->check_lookup('property', $path);

    # Make the scalar into a file handle
    my $fh = IO::Scalar->new(\$item->{value});

    $mode ||= '<';

    # If we're in read or overwrite mode, set the position to the start
    if ($mode eq '>') {
        $item->{value} = '';
    }

    elsif ($mode eq '+>') {
        die 'read/overwrite mode for file handles is not supported';
    }

    return $fh;
}

sub namespaces {
    my $self = shift;

    return $self->{namespaces};
}

sub has_permission { 1 }

sub set_scalar {
    my ($self, $path, $scalar) = @_;

    my $item = $self->check_lookup('property', $path);

    $item->{value} = $scalar;
}

sub set_handle {
    my ($self, $path, $handle) = @_;

    my $item = $self->check_lookup('property', $path);

    $item->{value} = join '', readline($handle);
}

sub save_property {
    my ($self, $path) = @_;

    my $item = $self->check_lookup('property', $path);
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
