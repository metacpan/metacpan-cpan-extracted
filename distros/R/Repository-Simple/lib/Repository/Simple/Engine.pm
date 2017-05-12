package Repository::Simple::Engine;

use strict;
use warnings;

our $VERSION = '0.06';

use Readonly;
use Repository::Simple::Util;

our @CARP_NOT = qw( Repository::Simple::Util );

require Exporter;

our @ISA = qw( Exporter );

our @EXPORT_OK = qw( $NODE_EXISTS $PROPERTY_EXISTS $NOT_EXISTS );
our %EXPORT_TAGS = ( exists_constants => \@EXPORT_OK );

# Return values for path_exists()
Readonly our $NODE_EXISTS     => 1;
Readonly our $PROPERTY_EXISTS => 2;
Readonly our $NOT_EXISTS      => 0;

=head1 NAME

Repository::Simple::Engine - Abstract base class for storage engines

=head1 DESCRIPTION

This documentation is meant for developers wishing to implement a content repository engine. If you just want to know how to use the repository API, L<Repository::Simple> is where you'll want to go.

A developer may extend this class to provide a new storage engine. Each engine is simply an implementation of the bridge API specified here and requires only a single package. 

To implement a content repository engine, create a subclass of L<Repository::Simple::Engine> that implements all the methods described in this documentation.

  package Repository::Simple::Engine::MyCustom;

  use strict;
  use warnings;

  use base qw( Repository::Simple::Engine );

  sub new { ... }
  sub node_type_named { ... }
  sub property_type_named { ... }
  sub path_exists { ... }
  sub node_type_of { ... }
  sub property_type_of { ... }
  sub nodes_in { ... }
  sub properties_in { ... }
  sub get_scalar { ... }
  sub set_scalar { ... }
  sub get_handle { ... }
  sub set_handle { ... }
  sub namespaces { ... }
  sub has_permission { ... }

=head1 METHODS

Every storage engine must implement the following methods:

=over

=item $engine = Repository::Simple::Engine-E<gt>new(@args)

This method constructs an instance of the engine. The arguments can be anything you want. The C<attach()> method of L<Repository::Simple> will pass the arguments directly to the new method upon creation. I.e.,

  my $repository = Repository::Simple->attach(
      MyEngine => qw( a b c )
  );

would effectively call:

  Repository::Simple::Engine::MyEngine->new('a', 'b', 'c');

This interface doesn't define anything specific regarding these arguments.

This method must return an instance of the storage engine upon which all the other methods may be called.

A basic default implementation is provided that simply treats all arguments given as a hash and blesses that hash into the class. Therefore, you can use the built-in implementation like this:

  sub new {
      my ($class, $some_arg) = @_;
      
      # Do some manipulations on $some_arg...

      my $self = $class->SUPER::new( some_arg => $some_arg );

      # Do some manipulations on $self
      
      return $self;
  }

=cut

sub new {
    my $class = shift;

    return bless { @_ }, $class;
}

=item $exists = $engine-E<gt>path_exists($path)

Returns information regarding whether a given path refers to a node, a property, or nothing. The method must return one of the following values:

=over

=item C<$NOT_EXISTS>

There is no node or property at the given path, C<$path>.

=item C<$NODE_EXISTS>

There is a node at the given path, C<$path>.

=item C<$PROPERTY_EXISTS>

There is a property at the given path, C<$path>.

=back

These can be imported from the L<Repository::Simple::Engine> package:

  use Repository::Simple::Engine qw( 
      $NOT_EXISTS $NODE_EXISTS $PROPERTY_EXISTS 
  );

  # OR
  use Repository::Simple::Engine qw( :exists_constants );

This method must be implemented by subclasses. No implementation is provided.

=cut

sub path_exists {
    die 'path_exists() must be implemented in subclass';
}

=item $node_type = $engine-E<gt>node_type_named($name)

Given a node type name, this method returns an instance of L<Repository::Simple::Type::Node> for the matching node type or C<undef> if no node type by the given name exists.

This method must be implemented by subclasses. No implementation is provided.

=cut

sub node_type_named {
    die "node_type_named() must be implemented by subclass";
}

=item $property_type = $engine-E<gt>property_type_named($name)

Given a property type name, this method returns an instance of L<Repository::Simple::Type::Property> for the matching property type or C<undef> if no property type by the given name exists.

This method must be implemented by subclasses. No implementation is provided.

=cut

sub property_type_named {
    die "property_type_named() must be implemented by subclass";
}

=item @names = $engine-E<gt>nodes_in($path)

Given a path, this method should return all the child nodes of that path or an empty list if the node found has no children. If the given path itself does not exist, the method must die.

The nodes should be returned as names relative to the given path.

This method must be implemented by subclasses. No implementation is provided.

=cut

sub nodes_in {
    die 'nodes_in() must be implemented by subclass';
}

=item @names = $engine-E<gt>properties_in($path)

Given a path, this method should return all the child properties of the node at the given path or an empty list if the node found has no children. If the given path itself does not exist or does not refer to a node, the method must die.

Properties must be returned as names relative to the given path.

This method must be implemented by subclasses. No implementation is provided.

=cut

sub properties_in {
    die 'properties_in() must be implemented by subclass';
}

=item $node_type = $engine-E<gt>node_type_of($path)

Given a path, this method should return the L<Repository::Simple::Type::Node> object for the node at that path. If there is no node at that path, then the method must die.

This method must be implemented by subclasses. No implementation is provided.

=cut

sub node_type_of {
    die 'node_type_of() must be implemented by subclass';
}

=item $property_type = $engine-E<gt>property_type_of($path)

Return the property type of the given class via a L<Repository::Simple::Type::Property> instance. If there is no property at that path, then the method must die.

This method must be implemented by subclasses. No implementation is provided.

=cut

sub property_type_of {
    die 'property_type_of() must be implemented by subclass';
}

=item $scalar = $engine-E<gt>get_scalar($path)

Return the value of the property at the given path as a scalar value.

This method must be implemented by subclasses. No implementation is provided.

=cut

sub get_scalar {
    die 'get_scalar() must be implemented by subclass';
}

=item $engine-E<gt>set_scalar($path, $value)

Set the value stored the property at C<$path> to the scalar value C<$scalar>.

This method is optional. If your engine does not support writes, then it does
not need to define this method.

See C<save_property()> for information on how these changes are actually committed.

=cut

sub set_scalar {
    die 'set_scalar() is not supported.';
}

=item $handle = $engine-E<gt>get_handle($path, $mode)

Return the value of the property at the given path as an IO handle, with the given mode, C<$mode>. The C<$mode> must be one of:

=over

=item * 

"<"

=item * 

">"

=item *

">>"

=item *

"+<"

=item *

"+>"

=item *

"+>>"

=back

These have the same meaning as the Perl C<open()> built-in (i.e., read, write, append, read-write, write-read, append-read).

This method must be implemented by subclasses. No implementation is provided.

An implementation must support reading properties by handle for all properties, but is not required to implement write or append handles. If writes or appends are not available, the method must throw an exception when an unsupported file handle type is requested.

The user is required B<not> to call C<close> on any file handle returned via this method, but might do so anyway. The result of such behavior is undefined. It is suggested that the engine should make sure any returned file handles are closed when the appropriate save handle is called.

Whether or not writes/appends are supported does not affect whether or not C<set_handle()> is supported.

See C<save_property()> for information on how these changes are actually committed.

=cut

sub get_handle {
    die 'get_handle() must be implemented by subclass';
}

=item $engine-E<gt>set_handle($path, $handle)

This method allows the user to set a value using a custom file handle. This
file handle must be a read-handle ready to read immediately using the C<readline> or C<read>. This specification recommends the use of L<File::Temp> or L<IO::Scalar> for creating these file handles.

This operation is optional and does not need to be implemented if the engine does not handle write operations. Whether this method is implemented does not affect whether or not C<get_handle()> supports writes/appends.

See C<save_property()> for information on how these changes are actually committed.

=cut

sub set_handle {
    die 'set_handle() is not supported';
}

=item $namespaces = $engine-E<gt>namespaces

This method returns a reference to a hash of all the namespaces the storage engine currently supports. The keys are the prefixes and the values are URLs.

=cut

sub namespaces {
    die 'namespaces() must be implemented by subclass';
}

=item $test = $engine-E<gt>has_permission($path, $action)

Tests to see if the current engine session has permission to perform the given action, C<$action>, on path, C<$path>. This method should return a true value if permissions would allow the action to proceed. Return false if the action would fail. The repository will attempt to guarantee that this method will not be called when it is not applicable.

The C<$action> is one of the constants described under C<check_permission()> in the documentation for L<Repository::Simple>.

=cut

sub has_permission {
    die 'has_permission() must be implemented by subclass';
}

=item $engine-E<gt>save_property($path)

This method is responsible for committing changes made by C<set_scalar()>, C<get_handle()> (using a write or append file handle), and C<set_handle()>. If any of these methods are implemented, this method must also be implemented.

Changes made by one of the mutator methods must be set on the property given path, C<$path>, by the time C<save_property()> returns. However, the changes may be committed sooner. 

The implementation of this method is optional, but required if any of C<set_scalar()>, writes/appends via C<get_handle()>, or C<set_handle()> are implemented.

=cut

sub save_property {
    die 'save_property() is not supported'
}

=back

=head1 SEE ALSO

L<Repository::Simple>

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
