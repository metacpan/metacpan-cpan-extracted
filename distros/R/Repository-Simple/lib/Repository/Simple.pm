package Repository::Simple;

use strict;
use warnings;

our $VERSION = '0.06';

use Carp;
use Readonly;
use Repository::Simple::Engine qw( :exists_constants );
use Repository::Simple::Node;
use Repository::Simple::Permission;
use Repository::Simple::Util qw( basename dirname normalize_path );

our @CARP_NOT = qw( Repository::Simple::Util );

=head1 NAME

Repository::Simple - Simple heirarchical repository for Perl

=head1 SYNOPSIS

  use Repository::Simple;

  my $repository = Repository::Simple->attach(
      FileSystem => root => /home/foo
  );

=head1 DESCRIPTION

B<NOTICE:> This software is still in development and the interface WILL CHANGE.

This is the main module of a hierarchical repository system, which is loosely based upon the L<File::System> module I've written combined with ideas from the JSR 170, a.k.a. Content Repository API for the Java API Specification.

The goal of this package is to provide a content repository system with a similar feature set. I think it would be a good goal to aim for loose compatibility, but it is not my intent to adhere to the strict letter of that standard. See L</"DIFFERENCES FROM JSR 170"> for details of the major deviations.

=head1 TERMINOLOGY

This is a glossary of the terms used by this library. Many of these have been borrowed from the JSR 170 terminology.

=over

=item name

A name is given to every node and path in the tree. A name may contain any number of letters, numbers, underscores, dashes, and colons. No other letter is permitted in a name.

=item node

Data in the repository is associated with objects called nodes. Each node has a parent which roots it in the hierarchy. Each node has a name. A node may have zero or more properties associated with it. A node may have zero or more child nodes associated with it.

=item node type

The node type determines when/how a node may be changed and the acceptable names and types of child properties and nodes.

=item parent

Relative to a given node or property, the parent is the node that is one-level higher than the given node or property.

=item path

A path is a collection of names separated by slashes ("/") used to refer to given node or property. The name of a node or property will be the right-most element of the path (after the last slash). The parent of a node or property is refered to by the path with the last slash and last name stripped off.

=item property

A property is a field associated with a node object. Each field has a single parent node. Each field has a name. Each field has a value.

=item property type

A property type determines when/how a property may be changed and what values are acceptable, via a selected value type.

=item repository

The repository is the name for this storage API, specifically for the repository, node, property, and value classes.

=item storage engine

The storage engine is the back-end storage device a repository refers to. The storage engine is responsible for actually reading from and writing to the storage device. The repository can be used without direct knowledge of the storage device in use.

=item type

Type is the generic term referred to describe the permitted nature of an object in the system. There are three kinds of type: node type, property type, and value type.

=item value

A value is the data associated with a property.

=item value type

A value type restricts the kinds of values that can be associated with a property. It may define how a value is checked for correctness and may define methods for serializing and deserializing values of the given type.

=back

=head1 CONTENT REPOSITORY

This package provides the entry point to an API for implementing content repository engines, and for storing nodes, properties, and values into those engines. As of this writing a single engine is provided, which accesses a native file system repository. Other repositories are planned. 

The basic idea is that every content repository is comprised of objects. We call these objects "nodes". Nodes are arranged in a rooted hierarchy. At the top is a single node named "/". Each node may have zero or more child nodes under them.

In addition to nodes, there are fields associated with nodes, called "properties". Each property has a name and value.

A given content repository may only store items that follow a specific schema. Each node has an associated node type. Each property has an associated property type. Each value stored in a property has an associated value type. The node and property types determine what a valid hierarchy will look like for a repository. The value types determine how a value should be stored and how it should be represented after it is loaded.

The functionality available in a given repository is determined by the content repository engine which is used to run it. There is a back-end API for creating new kinds of storage engines. At this time, the following engines are implemented or planned:

=over

=item L<Repository::Simple::Engine::DBI>

Not yet implemented. This engine reads and stores hierarchies inside of SQL databases.

=item L<Repository::Simple::Engine::FileSystem>

This storage engine maps a hierarchy into the native file system.

=item L<Repository::Simple::Engine::Layered>

Not yet implemented. This storage engine allows one or more engines to be layered over top of each other.

=item L<Repository::Simple::Engine::Memory>

This storage engine reads and stores hierarchies in transient memory structures.

=item L<Repository::Simple::Engine::Passthrough>

Not yet implemented. This storage engine simply wraps another storage engine as a mechanism to simplify meta-engine extensions.

=item L<Repository::Simple::Engine::Table>

Not yet implemented. This storage engine allows for VFS-like mounting of one or more engines via a mount table.

=item L<Repository::Simple::Engine::XML>

Not yet implemented. This storage engine reads and stores data in an XML file.

=back

As of this writing, only read operations have been implemented. Write operations are planned, but haven't been designed or implemented yet.

=head2 REPOSITORY ENGINE

Repository engines are implemented via a bridge pattern. Rather than having each engine implement several packages covering nodes, properties, values, and other parts, each engine is a single package containing definitions for all the methods required to access the repository's storage.

Normally, you will not interact with the repository engine directly after you instantiate it using the repository connection factory method, C<attach()>:

  my $repository = Repository::Simple->attach(...);

The returned repository object, C<$repository> in this example, is an instance of this class, L<Repository::Simple>, which holds an internal reference to the engine. Thus, you do not usually need to be aware of how the engine works after instantiation. 

If you are interested in building a repository engine, the details of repository engine design may be found in L<Repository::Simple::Engine>.

=head2 THIS CLASS

This class provides the entry point into the repository API. The typical way of getting a reference to an instance of this class is to use the L<attach()> method to connect to a repository. This method of returns an instance of L<Repository::Simple>, which encapsulates the requested repository engine connection.

As an alternative, you may also instantiate an engine directly:

  my $engine = MyProject::Content::Engine->new;
  my $repository = Repository::Simple->new($engine);

This shouldn't be necessary in most cases though, since this is the same as:

  my $repository 
      = Repository::Simple->attach('MyProject::Content::Engine');

=head1 METHODS

=over

=item $repository = Repository::Simple-E<gt>attach($engine, ...)

This will attach to a repository via the named engine, C<$engine>. The repository object representing that storage is returned.

If the C<$engine> does not contain any colons, then the package "C<Repository::Simple::Engine::$engine>" is loaded. Otherwise, the C<$engine> is loaded and its C<new> method is used.

Any additional arguments passed to this method are then passed to the C<new> method of the engine.

See L<Repository::Simple::Engine> if you are interested in the guts.

=cut

sub attach {
    my ($class, $engine) = @_;

    $engine =~ /[\w:]+/
        or croak "The given content repository engine, $engine, "
                .'does not appear to be a package name.';

    # XXX should this be configurable?
    $engine =~ /:/
        or $engine = "Repository::Simple::Engine::$engine";

    eval "use $engine";
    warn "Failed to load package for engine, $engine: $@" if $@;

    my $instance = eval { $engine->new(@_) };
    if ($@) {
        $@ =~ s/ at .*//s;
        croak $@ if $@;
    }

    return Repository::Simple->new($instance);
}

=item $repository = Repository::Simple-E<gt>new($engine)

Given an engine, this constructor wraps the engine with a repository object.

=cut

sub new {
    my ($class, $engine) = @_;
    return bless { engine => $engine }, $class;
}

=item $engine = $repository-E<gt>engine

Returns a reference to the engine this repository is using.

=cut

sub engine {
    my ($self) = @_;
    return $self->{engine};
}

=item $node_type = $repository-E<gt>node_type($name)

Returns the L<Repository::Simple::Type::Node> object for the given C<$name> or returns C<undef> if no such type exists in the repository.

=cut

sub node_type {
    my ($self, $type_name) = @_;

    if (!defined $type_name) {
        croak 'no type name given for lookup';
    }

    return $self->engine->node_type_named($type_name);
}

=item $property_type = $repository-E<gt>property_type($name)

Returns the L<Repository::Simple::Type::Property> object for the given C<$name> or returns C<undef> if no such type exists in the repository.

=cut

sub property_type {
    my ($self, $type_name) = @_;

    if (!defined $type_name) {
        croak 'no type name given for lookup';
    }

    return $self->engine->property_type_named($type_name);
}

=item $root_node = $repository-E<gt>root_node

Return the root node in the repository.

=cut

sub root_node {
    my $self = shift;

    $self->check_permission("/", $READ);

    return Repository::Simple::Node->new($self, "/");
}

=item $item = $repository-E<gt>get_item($path)

Return the node (L<Repository::Simple::Node>) or property (L<Repository::Simple::Property>) found at the given path. This method returns C<undef> if the given path points to nothing.

=cut

sub get_item {
    my ($self, $path) = @_;

    $path = normalize_path('/', $path);

    $self->check_permission($path, $READ);

    my $exists = $self->engine->path_exists($path);

    if ($exists == $NODE_EXISTS) {
        return Repository::Simple::Node->new($self, $path);
    }

    elsif ($exists == $PROPERTY_EXISTS) {
        my $property_name = basename($path);
        my $parent_path   = dirname($path);
        my $parent = Repository::Simple::Node->new($self, $parent_path);
        return Repository::Simple::Property->new($parent, $property_name);
    }

    else {
        return undef;
    }
}

=item %namespaces = $repository-E<gt>namespaces

Determine the meaning of the name prefixes used by the engine. This returns a hash of all namespace information currently used by the storage engine.

=cut

sub namespaces {
    my ($self) = @_;
    return %{ $self->engine->namespaces };
}

=item $repository->check_permission($path, $action)

This method will C<croak()> if the specified action, C<$action>, is not permitted on the given path, C<$path>, due to access restrictions by the current attached session. The C<$path> is an absolute path in the repository. 

The C<$action> must be one of the following constants:

=over

=item $ADD_NODE

Use this to see if the current session is permitted to create a node at C<$path>.

=item $SET_PROPERTY

Use this to see if the current session is permitted to modify the property at C<$path>.

=item $REMOVE

Use this to see if the current session is permitted to remove the node or property at C<$path>.

=item $READ

Use this to see if the current session is permitted to read the data at the node or property at C<$path>.

=back

The constants may be imported from this package individually or as a group using the ":permission_constants" tag:

  use Repository::Simple qw( $READ $ADD_NODE );

  # OR
  
  use Repository::Simple qw( :permission_constants );

=cut

sub check_permission {
    my ($self, $path, $action) = @_;
    my $engine = $self->engine;

    # Sanity checks
    croak "No path given" unless defined $path;
    croak "No action given" unless defined $action;
    croak qq(Invalid action "$action" given)
        unless $action =~ /^(?:$READ|$SET_PROPERTY|$REMOVE|$ADD_NODE)$/;

    # Normalize path
    $path = normalize_path('/', $path);

    # What is it?
    my $exists = $engine->path_exists($path);

    # Make sure this is a valid node action
    if ($exists == $NODE_EXISTS) {
        my $node_type = $engine->node_type_of($path);

        if ($action eq $ADD_NODE) {
            croak qq(Error: cannot create node "$path": it already exists);
        }

        elsif ($action eq $SET_PROPERTY) {
            croak qq(Error: cannot set property "$path": a node exists at ),
                   q(that path);
        }

        elsif ($action eq $REMOVE) {
            if (!$node_type->removable) {
                croak qq(Error: cannot remove node "$path": it is not ),
                       q(removable);
            }
        }
    }

    # Make sure this is a valid property action
    elsif ($exists == $PROPERTY_EXISTS) {
        my $property_type = $engine->property_type_of($path);

        if ($action eq $ADD_NODE) {
            croak qq(Error: cannot create node "$path": a property exists at ),
                   q(that path);
        }

        elsif ($action eq $SET_PROPERTY) {
            if (!$property_type->updatable) {
                croak qq(Error: cannot update property "$path": it is not ),
                       q(updatable);
            }
        }

        elsif ($action eq $REMOVE) {
            if (!$property_type->removable) {
                croak qq(Error: cannot remove property "$path": it is not ),
                       q(removable);
            }
        }
    }

    # Doesn't exists, make sure it's a sane thing to say
    else {
        # Check for parent
        my $parent_path = dirname($path);
        my $parent_exists = $engine->path_exists($parent_path);

        if ($parent_exists == $PROPERTY_EXISTS) {
            if ($action eq $ADD_NODE) {
                croak qq(Error: cannot create node "$path": the parent path ),
                      qq("$parent_path" is a property);
            }

            elsif ($action eq $SET_PROPERTY) {
                croak qq(Error: cannot set property "$path": the parent path ),
                      qq("$parent_path" is a property);
            }
        }

        elsif ($parent_exists == $NOT_EXISTS) {
            if ($action eq $ADD_NODE) {
                croak qq(Error: cannot create node "$path": the parent path ),
                      qq("$parent_path" does not exist);
            }
        }

        if ($action eq $REMOVE) {
            croak qq(Error: cannot remove item "$path": the path does not ),
                   q(exist);
        }

        elsif ($action eq $READ) {
            croak qq(Error: cannot read item "$path": the path does not exist);
        }
    }

    # Finally, actually check the permissions
    if (!$self->engine->has_permission($path, $action)) {
        croak qq(Access denied: current session does not have "$action" ),
              qq(permission on "$path".);
    }
}

=back

=head1 DIFFERENCES FROM JSR 170

Here are some specific differences between this implementation and the JSR 170 specification.

B<Flexible typing.> This implementation doesn't attempt to define any specifics when it comes to node types, property types, or value types. The way these are used is up to the storage engines.

In particular, it is possible to create value types that are in nearly any data format, rather than being restricted to strings, binary streams, longs, doubles, booleans, dates, names, paths, and references. For example, you could store arbitrarily complex Perl types if you defined a type extension to use YAML to store data into files.

B<API Differences.> This library doesn't implement most of the classes required by a JCR implementation.

=head1 TO DO

There are a number of tasks remaining to do on this project. Here are a few of the big tasks:

=over

=item *

Add better support for naming and namespaces.

=item *

Design and implement the storage API so repositories can write as well as read data. Then, update all existing implementations to handle it.

=item *

Implement several more data types including rs:string, rs:binary, rs:long, rs:double, rs:datetime, rs:boolean, rs:name, rs:path, and rs:reference.

=item *

Add support for creating node references and performing lookups on nodes by reference for repositories that support such operations.

=item *

Add support for indexing and search.

=item *

Add support for globbing, XPath, and SQL selection as indexers and search methods.

=item *

Observation.

=item *

Version control.

=item *

Implement the DBI repository engine.

=item *

Implement the layered repository engine.

=item *

Implement the memory repository engine.

=item *

Implement the passthrough repository engine.

=item *

Implement the table repository engine.

=item *

Implement the XML repository engine.

=back

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2005 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
