package Object::Signature::Portable;

# ABSTRACT: generate portable fingerprints of objects

use v5.10;

use strict;
use warnings;

use Carp;
use Crypt::Digest;
use Exporter 5.57 qw/ import /;
use JSON::MaybeXS;

our $VERSION = 'v1.1.1';

our @EXPORT    = qw/ signature /;
our @EXPORT_OK = @EXPORT;


sub signature {
    my %args;

    if ( scalar(@_) <= 1 ) {
        $args{data} = $_[0];
    } else {
        %args = @_;
    }

    $args{digest} //= 'MD5';

    $args{format} //= 'hexdigest';
    unless ( $args{format} =~ m/^(?:hex|b64u?)digest$/ ) {
        croak sprintf( 'Invalid digest format: %s', $args{format} );
    }

    $args{serializer} //= sub {
        return JSON->new->canonical(1)->allow_nonref(1)->utf8(1)->pretty(0)
            ->indent(0)->space_before(0)->space_after(0)->allow_blessed(1)
            ->convert_blessed(1)->encode( $_[0] );
    };

    my $digest = Crypt::Digest->new( $args{digest} );
    $digest->add( &{ $args{serializer} }( $args{data} ) );

    if ( my $method = $digest->can( $args{format} ) ) {
        my $prefix = $args{prefix} ? ( $args{digest} . ':' ) : '';
        return $prefix . $digest->$method;
    } else {
        croak sprintf( 'Unexpected error with digest format: %s',
            $args{format} );
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Object::Signature::Portable - generate portable fingerprints of objects

=head1 VERSION

version v1.1.1

=head1 SYNOPSIS

    use Object::Signature::Portable;

    my $sig = signature( $object ); # MD5 hex of object signature

    my $sig = signature(
      digest => 'SHA1',             # SHA-1 digest
      format => 'b64udigest',       # as URL-safe base-64
      data   => $object,
    );

=head1 DESCRIPTION

This module provides a simple function for generating I<portable>
digital fingerprints (a.k.a. signatures, not to be confiused with
public key signatures.) of Perl data structures.

The object is serialized into a canonical JSON structure, and then
hashed using the MD5 algorithm.

Any two machines running different versions of Perl on different
architectures should produce identical signatures.

Note that this module is useful in cases where the consistency of
signatures between machine is more important than the speed of
signature generation.

However, the serialization method, hash algorithm and signature format
can be customized, as needed.

=for readme stop

=head1 EXPORTS

=head2 C<signature>

  my $sig = signature( $data );

  my $sig = signature(
    data       => $data,
    digest     => 'MD5',         # default
    format     => 'hexdigest',   # default
    serializer => sub { ... },
  );

Generate a digital fingerprint of the C<$data>.

The following options are supported:

=over 4

=item C<digest>

The cryptographic digest algorithm, as supported by L<Crypt::Digest>.

=item C<format>

The L<Crypt::Digest> formatting method for the signature, which can be
one of:

=over 4

=item C<digest>

The raw bytes of the digest.

=item C<hexdigest>

The digest as a string of hexidecimal numbers.

=item C<b64digest>

The digest as a MIME base-64 string.

=item C<b64udigest>

The digest as a URL-friendly base-64 string.

=back

=item C<prefix>

If set to a true value, the digest is prefixed by the name of the
digest algorithm.

This is useful when you may want to change the digest algorithm used
by an application in the future, but do not want to regenerate
signatures for existing objects in a data store.

=item C<serializer>

The serialization method, which is a subroutine that takes the data as
a single argument, and returns the serialized data to be hashed.

It is recommended that you use a serializer that produces canonical
(normalized) output, and preferably one that produces consistent
output across all of the platforms that you are using.  (L<YAML>,
L<Data::Dumper> or L<Sereal::Encoder> should be acceptable
alternatives, provided that you enable canonical encoding, and in the
case of Sereal, explicitly specify a protocol version.)

By default, it uses L<JSON::MaybeXS>. The choice for using JSON is
based on the following considerations:

=over

=item *

JSON is a simple, text-based format. The output is not likely to
change between module versions.

=item *

Consistent encoding of integers are strings.

=item *

Classes can be extended with hooks for JSON serialization.

=item *

Speed is not a factor.

=back

However, see L</LIMITATIONS> below.

=back

=head1 LIMITATIONS

=head2 Encoding

The default JSON serializer will use UTF-8 encoding by default, which
generally removes an issue with L<Storable> when identical strings
have different encodings.

Numeric values may be inconsistently represented if they are not
numified, e.g. C<"123"> vs C<123> may not produce the same JSON. (This too
is an issue with C<Storable>.)

=head2 Signatures for Arbitrary Objects

By default, this module uses L<JSON::MaybeXS> to serialize Perl objects.

This requires the objects to have a C<TO_JSON> method in order to be
serialized.  Unfortunately, this is not suitable for many objects
(particularly those generated by modules that are not under your
control, e.g. many CPAN modules) without monkey-patching or
subclassesing them.

One solution is to use a different serializer that can handle the
object.

Alternatively, you can write a wrapper function that translates an
object into a hash reference that can then be passed to the
C<signature> function, e.g.

    package Foo;

    use Object::Signature::Portable ();

    sub signature {
        my $self = shift;
        return Object::Signature::Portable::signature(
          data => $self->_serialize
        );
    }

    sub _serialize { # returns a hash reference of the object
       my $self = shift;
       ...
    }

=head2 Portability

The portability of signatures across different versions of
L<JSON::MaybeXS> is, of course, dependent upon whether those versions
will produce consistent output.

If you are concerned about this, then write our own serializer, or
avoid upgrading L<JSON::MaybeXS> until you are sure that the it will
produce consistent signatures.

=head2 Security

This module is intended for generating signatures of Perl data
structures, as a simple means of determining whether two structures
are different.

For that purpose, the MD5 algorithm is probably good enough.  However,
if you are hashing that in part comes from untrusted sources, or the
consequences of two different data structures having the same
signature are significant, then you should consider using a different
algorithm.

This module is I<not> intended for hashing passwords.

=for readme continue

=head1 SEE ALSO

=head2 Similar Modules

=over

=item L<Object::Signature>

This uses L<Storable> to serialise objects and generate a MD5
hexidecimal string as a signature.

This has the drawback that machines with different architectures,
different versions of Perl, or different versions L<Storable>, or in
some cases different encodings of the same scalar, may not
produce the same signature for the same data. (This does not mean that
L<Storable> is unable to de-serialize data produced by different
versions; it only means that the serialized data is not identical
across different versions.)

=for readme stop

L<Object::Signature> does not allow for customizing the hash algorithm
or signature format.

L<Object::Signature::Portable> module can replicate the signatures
generated by L<Object::Signature>, using the following:

  use Storable 2.11;

  my $sig = signature(
    data       => $data,
    serializer => sub {
      local $Storable::canonical = 1;
      return Storable::nfreeze($_[0]);
    },
  );

As noted above, using L<Storable> will not produce portable
signatures.

=for readme continue

=back

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Object-Signature-Portable>
and may be cloned from L<git://github.com/robrwo/Object-Signature-Portable.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Object-Signature-Portable/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head2 Acknowledgements

Thanks to various people at YAPC::EU 2014 for suggestions about
L<Sereal::Encoder>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013-2014, 2019-2022 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
