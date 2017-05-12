package Perl::Signature;

=pod

=head1 NAME

Perl::Signature - Generate functional signatures for Perl source code

=head2 DESCRIPTION

In early beta, L<PPI> introduced the concept of "Document Normalization"
into the core. It had previously only been implemented "behind the scenes"
as part of L<Perl::Compare>.

Unfortunately, there isn't a whole lot of things you can do with a
L<PPI::Document::Normalized> object. It's a giant twisty mass of objects
and perl structure, and not very practical for long term storage.

L<Perl::Signature> implements the idea of a "functional signature" for
Perl documents, implemented in a similar way to L<Object::Signature>.

The normalized document is serialized to a string with L<Storable>, then
this string is converted into a MD5 hash, producing a single short string
which represents the functionality of the Perl document.

This signature can then be stored and transfered easily, and at any later
point the signature can be regenerated for the file to ensure that it has
not changed (functionally).

=head2 Not Stable Across Upgrades

Perl::Signature is relatively sensitive to change.

Primarily, this is because L<PPI::Normal> is biased towards false
negative comparison. (Avoiding false "these are the same" by accepting a
number of false "these are not the same" results).

In addition, the serialization of L<Storable> is not assured to use
identical file formats across versions.

In short, you should assume that a signature is valid at best for only
as long as the PPI and Storable versions are the same, and at worst only
for the current process.

=head1 METHODS

PPI::Signature provides two sets of methods. A set of 

=cut

use 5.005;
use strict;
use PPI           ();
use PPI::Util     '_Document';
use Storable      ();
use Digest::MD5   ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.09';
}





#####################################################################
# Static Methods

=pod

=head2 file_signature $filename

The C<file_signature> static method takes a filename and produces a
signature for the file.

Returns a 32 character hexidecimal MD5 signature, or C<undef> on error.

=cut

sub file_signature {
	my $class    = ref $_[0] ? ref shift : shift;
	my $filename = -f $_[0]  ? shift : return undef;
	my $Document = PPI::Document->new( $filename ) or return undef;
	$class->document_signature( $Document );
}

=pod

=head2 source_signature $content | \$content

The C<source_signature> static method generates a signature for any
arbitrary Perl source code, which can be passed as either a raw string,
or a reference to a SCALAR containing the code.

Returns a 32 character hexidecimal MD5 signature, or C<undef> on error.

=cut

sub source_signature {
	my $class  = ref $_[0] ? ref shift : shift;
	my $source = defined $_[0] ? shift : return undef;
	$source    = $$source if ref $source;

	# Build the PPI::Document
	my $Document = PPI::Document->new( \$source ) or return undef;
	$class->document_signature( $Document );
}

=pod

=head2 document_signature $Document

The C<document_signature> method takes a L<PPI::Document> object and
generates a signature for it.

Returns a 32 character hexidecimal MD5 signature, or C<undef> on error.

=cut

sub document_signature {
	my $class    = ref $_[0] ? ref shift : shift;
	my $Document = _Document(shift) or return undef;

	# Normalize the PPI::Document
	my $Normalized = $Document->normalized or return undef;

	# Freeze the normalized document
	my $string = Storable::freeze $Normalized;
	return undef unless defined $string;

	# Last step, hash the string
	Digest::MD5::md5_hex( $string ) or undef;
}





#####################################################################
# Object Methods

=pod

=head2 new $file

As well as static methods for generatic signatures, L<Perl::Signature>
also provides a simple way to create signature objects for a particular
file.

This makes it relatively easy to see if a file has changed

The C<new> constructor takes as argument the name of a file, and creates
an object that remembers current signature of the file.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my $file  = -f $_[0] ? shift : return undef;

	# Get the current signature for the file
	my $signature = $class->file_signature( $file ) or return undef;

	# Create the object
	my $self = bless {
		file      => $file,
		signature => $signature,
		}, $class;

	$self;
}

=pod

=head2 file

The C<file> accessor returns the name of the file that a Perl::Signature
object is set to.

=cut

sub file { $_[0]->{file} }

=pod

=head2 current

The C<current> method returns the current signature for the file.

Returns a 32 character hexidecimal MD5 signature, or C<undef> on error.

=cut

sub current {
	my $self = shift;
	-f $self->file or return undef;
	$self->file_signature( $self->file );
}

=pod

=head2 original

The C<original> accessor returns the original signature at the time of
the creation of the object.

=cut

sub original { $_[0]->{signature} }

=pod

=head2 changed

The C<changed> method checks to see if the signature has changed since
the object was created.

Returns true if the file has been (functionally) changed, false if not,
or C<undef> on error.

=cut

sub changed {
	my $self    = shift;
	my $current = $self->current or return undef;
	$current ne $self->original;	
}

=pod

=head2 unchanged

The C<unchanged> method checks to ensure that the signature has not
changed since the object was created.

Returns true if the file is (functionally) unchanged, false if it has
changed, or C<undef> on error.

=cut

sub unchanged {
	my $self    = shift;
	my $current = $self->current or return undef;
	$current eq $self->original;
}

1;

=pod

=head1 SUPPORT

All bugs should be filed via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Signature>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<PPI>

=head1 COPYRIGHT

Copyright 2004 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
