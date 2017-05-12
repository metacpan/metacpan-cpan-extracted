package P5NCI;

use strict;
use warnings;

use vars '$VERSION';
$VERSION = 0.31;

use Carp 'croak';

use DynaLoader ();
DynaLoader::bootstrap( 'P5NCI', $VERSION );

my $nci_lib = $DynaLoader::dl_librefs[-1];

sub dl_load_flags { 0x01 }

sub add_path
{
	my $path = shift;
	unshift @DynaLoader::dl_library_path, $path;
}

sub load_func
{
	my ($lib, $name, $signature) = @_;
	my $thunk_name               = "nci_$signature";
	my $func                     = DynaLoader::dl_find_symbol( $lib, $name );
	my $xs_thunk_name            = "XS_P5NCI_$thunk_name";
	my $thunk_pointer            = DynaLoader::dl_find_symbol( $nci_lib,
	                                                           $xs_thunk_name );

	croak( "Don't understand NCI signature '$signature'\n" )
		unless $thunk_pointer;

	DynaLoader::dl_install_xsub( $thunk_name, $thunk_pointer )
		unless defined &$thunk_name;

	my $thunk_func = __PACKAGE__->can( $thunk_name );
	return build_thunk( $thunk_func, $func ) if $thunk_func;
}

sub build_thunk
{
	my ($thunk, $func) = @_;
	return sub { return $thunk->( $func, @_ ); };
}

BEGIN
{
	*find_lib = \&DynaLoader::dl_findfile;
	*load_lib = \&DynaLoader::dl_load_file;
}

1;
__END__

=head1 NAME

P5NCI - Perl extension for loading shared libraries and their functions

=head1 SYNOPSIS

  use P5NCI;

  # find and load a shared library in a cross-platform fashion
  my $library_path = P5NCI::find_lib( 'nci_test' );
  my $library      = P5NCI::load_lib( $library_path );

  # load a function from the shared library
  my $double_func  = P5NCI::load_func( $library, 'double_double', 'dd' );

  # now use it
  my $two_dot_oh   = $double_func->( 1.0 );

=head1 DESCRIPTION

P5NCI provides a bare-bones, stripped down, procedural interface to shared
libraries installed on your system.  It allows you to call functions in them
without writing or compiling any glue code.

I recommend using L<P5NCI::Library> as it has a nicer interface, but you can do
everything through here if you really want.

=head1 FUNCTIONS

=over

=item find_lib( $library_name )

Finds and returns the full path to a library on your particular platform given
its short name.  For example, on Unix, passing a C<$library_name> of
C<nci_test> will give you the full path to F<libnci_test.so>, if it's
installed.  On Windows and Mac OS X this should do the right thing as well.

=item load_lib( $library_full_path )

Given the full path to a library (as returned from C<find_lib()> or specified
on your own if you really don't care about cross-platform coding), loads the
library, if possible, and returns it in an opaque scalar that you really
oughtn't examine.

=item load_func( $library, $function_name, $signature )

Given an opaque library from C<load_lib()> in C<$library>, the name of a
function within that library in C<$function_name>, and the signature of that
function in C<$signature>, loads and returns a subroutine reference that allows
you to pass values to and return values from the function.

This function itself will throw an exception if you fail to provide both a
function name and its signature.  It will also throw an exception if it does
not understand the signature.  That might not be an error -- it doesn't
understand a lot of valid signatures yet.

Signatures are simple strings representing the types of the arguments the
function takes in their simplest forms.  For example, a function that takes two
ints and returns an int would have a signature of C<iii>.  A function that
takes two ints and returns nothing (or void) has a signature of C<vii>.  The
currently working signature items are:

=over

=item C<d>, a double

=item C<f>, a float

=item C<i>, an integer

=item C<p>, a pointer (read-only for now, so be careful)

=item C<s>, a short

=item C<t>, a string

=item C<v>, void (nothing), valid only as an output type, not an input type

=back

B<Note:> The signature list will definitely expand and may change in the
future.

=back

=head1 SEE ALSO

L<DynaLoader>, L<Inline::C>, L<perlxs>.

=head1 AUTHOR

chromatic, E<lt>chromatic at wgz dot orgE<gt>.

Based on Parrot's NCI by Dan Sugalski, Leo Toetsch, and a host of other people
including me (a little bit, here and there).

Thanks to Bill Ricker for documentation fixes and other suggestions.

Thanks to Norman Nunley for pair programming to help fix the generation code.

=head1 BUGS

No known bugs, though the signature list is currently pretty small in what it
supports and what it I<can> support.  Right now, you can only bind to C
functions that take zero to four arguments.  The XS code takes a long time to
compile as it is.

Hopefully this approach uses much less memory than the naive implementation,
though it depends on how well your platform manages shared libraries.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004, 2006 - 2007, chromatic.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl 5.8.x.

=cut
