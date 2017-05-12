package Process::Serializable;

use 5.00503;
use strict;
use Process::Role::Serializable ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.30';
	@ISA     = 'Process::Role::Serializable';	
}

1;

__END__

=pod

=head1 NAME

Process::Serializable - Indicates that a Process can be frozen to a string

=head1 SYNOPSIS

  my $object = MyFreezer->new( foo => 'bar' );
  
  # Freeze to various things
  $object->serialize( 'filename.dat' );
  $object->serialize( \$string       );
  $object->serialize( \*FILEHANDLE   );
  $object->serialize( $io_handle     );
  
  # Thaw from various things
  $object = MyFreezer->deserialize( 'filename.dat' );
  $object = MyFreezer->deserialize( \$string       );
  $object = MyFreezer->deserialize( \*FILEHANDLE   );
  $object = MyFreezer->deserialize( $io_handle     );
  
  # Prepare and run as normal
  $object->prepare
  $object->run;

=head1 DESCRIPTION

C<Process::Serializable> provides a role (an additional interface and set
of rules) that allow for L<Process> objects to be converted to be "frozen"
to a string, moved around, and then be "thawed" back into an object again.

It does not dictate a specific serialization/deserialization mechanism
for you, only dictates that the new API rules be followed. For a good
default implementation that should work with almost any class see
L<Process::Storable>, which is an implementation using L<Storable>.

No default implementations of the two methods are provided for you.

=head2 When a Process can be Serialized

The C<Process::Serializable> API dictates 4 specific conditions at which
your object must be serializable. This means you shouldn't be connected
to any database, have no locked files, and so on. You should have cleaned
up any weird things and be self-contained again.

=over

=item Following a successful C<new>

When created successfully, your object must be serializable. This point
is the primary reason we have seperate C<new> and C<prepare> functions.

With this seperation available, the most common case in distributed
systems is to call C<new> to create the object, and then pass the
created object to some other interpreter for processing.

=item Following a failed C<prepare>

When an object fails a C<prepare> call, it is generally for a reason,
and often this reasons is saved in the object. This result needs to
be transported back to the requestor.

As such, your object must be serializable after C<prepare> in the case
that it fails. If you have partly set up before some error occurs, you
should ensure that any cleaning up is done before you return false.

=item Following a successful C<run>

When an object completes C<run>, it will often have data to send back
to the requestor. As a result your object must be serializable after
C<run> returns. Any cleaning up from the process should be done
B<before> you return.

=item Following a failed C<run>

As well as after a successful C<run>, and for similar reasons as after
a failed C<prepare>, you should ensure that your object is serializable
after a B<failed> C<run> call.

This means you should including some form of cleaning up even on error,
and that B<you> should be the one trapping exceptions in your C<run>,
so that this can be done. (but then you should be doing that anyway).

=back

=head1 METHODS

=head2 serialize

  $object->serialize( 'filename.dat' );
  $object->serialize( \$string       );
  $object->serialize( \*FILEHANDLE   );
  $object->serialize( $io_handle     );

The C<serialize> method converts your object to a string, and writes it
to a destination.

All implementations are required to accept three different param types,
a string that is to be seen as a filename, a C<SCALAR> reference to a
string, or a file handle (either a raw C<GLOB> reference, or any
L<IO::Handle> object).

All three should have identical information written to them, and in a
network-transparent order (if relevant for the serialization mechanism)

Should return true on success, or fail on failure.

=head2 deserialize

  $object = MyFreezer->deserialize( 'filename.dat' );
  $object = MyFreezer->deserialize( \$string       );
  $object = MyFreezer->deserialize( \*FILEHANDLE   );
  $object = MyFreezer->deserialize( $io_handle     );

The C<deserialize> method takes a filename, string or file handle
(C<GLOB> reference or L<IO::Handle> object) and creates a new object,
returning it. The same assumptions stated above apply for
deserialization.

Returns a new object of your class, or false on error.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Process>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
