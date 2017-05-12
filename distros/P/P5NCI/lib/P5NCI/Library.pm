package P5NCI::Library;

use strict;
use warnings;

use P5NCI;

use vars '$VERSION';
$VERSION = '0.31';

use Carp 'croak';

sub new
{
	my ($self, %args) = @_;

	P5NCI::add_path( $args{path} ) if $args{path};

	croak "No library given\n" unless $args{library};
	my $libpath = P5NCI::find_lib( $args{library} );

	croak "No library found\n" unless $libpath;

	my $library = P5NCI::load_lib( $libpath );
	bless { %args, lib => $library }, $self;
}

sub package
{
	my $self = shift;
	$self->{package} ||= 'main';
}

sub load_function
{
	my ($self, $function, $signature) = @_;

	croak "No function given\n"  unless $function;
	croak "No signature given\n" unless $signature;

	return P5NCI::load_func( $self->{lib}, $function, $signature );
}

sub install_function
{
	my ($self, $name, $sig) = @_;
	my $function            = $self->load_function( $name, $sig);
	my $package             = $self->package();

	no strict 'refs';
	*{ $package . '::' . $name } = $function;
	return $function;

}

1;
__END__

=head1 NAME

P5NCI::Library - an OO library to the Native Calling Interface for Perl 5

=head1 SYNOPSIS

	use P5NCI::Library;

	# load a shared library
	my $lib = P5NCI::Library->new( library => 'nci_test' );

	# fetch a reference to a function in a shared libarry
	my $double_double = $lib->load_function( 'double_double', 'dd' );
	my $two_point_oh  = $double_double->( 1.0 );

	# load a shared library and associate it with a namespace
	my $lib = P5NCI::Library->new( library => 'nci_test', package => 'NCI' );

	# install a function from the shared library into the namespace
	$lib->install_function( 'double_int', 'ii' );
	my $two = NCI::double_int( 1 );

	# or call it from that namespace
	package NCI;

	my $six = double_int( 3 );

=head1 DESCRIPTION

P5NCI::Library provides an object-oriented way of loading shared libraries and
their functions, including installing them in specified namespaces.  This makes
it easy to call C functions from Perl without writing any messy glue code
yourself -- or having to compile any XS!

=head1 METHODS

=over 4

=item C<new( library => $library_name, [ package => $package_name ] )>

Loads the library named in C<$library_name> if possible and returns a new
P5NCI::Library object.

This will throw an exception if you fail to provide a library name or if it
cannot find a library of the given name.  Note that C<$library_name> should
ideally be the cross-platform library name.  For example, use C<nci_test>
instead of F<libnci_test.so> on Unix, F<nci_test.dll> on Windows, or
F<libnci_test.dylib> on Mac OS X.

The optional C<package> parameter sets the name of the package to which the
library object can install loaded functions directly.  You don't have to do
this.  If you don't specify a package name, it will default to C<main>.

=item C<package()>

Returns the name of the package into which the object can install shared
library functions.

=item C<load_function( $function_name, $signature )>

Attempts to load the function named C<$function_name> with the signature
C<$signature> from the shared library this object represents.  Signatures are
simple strings representing the types of the arguments the function takes in
their simplest forms.  For example, a function that takes two ints and returns
an int would have a signature of C<iii>.  A function that takes two ints and
returns nothing (or void) has a signature of C<vii>.  The current working
signature items are:

=over

=item C<i>, an integer

=item C<f>, a float

=item C<d>, a double

=item C<s>, a short

=item C<t>, a string

=item C<v>, void (nothing)

=back

B<Note:> The signature list will definitely expand and may change in the
future.

This function returns a Perl subroutine reference to the library function.
Call it as you would any other subroutine reference.  Note that it will throw
an exeption if you pass the wrong number of values.  It will probably segfault
or do horrible things if you pass the wrong type of values.  That's what
happens when you play with C.

This function itself will throw an exception if you fail to provide both a
function name and its signature.  It will also throw an exception if it does
not understand the signature.  That might not be an error -- it doesn't
understand a lot of valid signatures yet.

=item C<install_function( $function_name, $function_signature )>

Loads the function with the given name and signature from the library the
object represents and installs it into the namespace associated with the
object.  This will throw the same exceptions as does C<load_function> under the same circumstances.

It also returns the same subroutine reference.

=back

=head1 AUTHOR

chromatic, E<lt>chromatic at wgz dot orgE<gt>

=head1 BUGS

No known bugs.  Several known limitations.

=head1 COPYRIGHT

Copyright (c) 2004, 2006 - 2007, chromatic.  All rights reserved.

This module is free software; you can use, redistribute, and modify it under
the same terms as Perl 5.8.x.
