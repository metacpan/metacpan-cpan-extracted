package OpenTracing::Implementation::DataDog::Utils;

=head1 NAME

OpenTracing::Implementation::DataDog::Utils - DataDog Utilities

=cut

our $VERSION = 'v0.46.2';

;

use Exporter qw/import/;

our @EXPORT_OK = qw/nano_seconds random_bigint/;

=head1 EXPORTS OK

The following subroutines can be imported into your namespance:

=cut



=head2 nano_seconds

To turn floatingpoint times into number of nano seconds

=cut

sub nano_seconds { int( $_[0] * 1_000_000_000 ) }



=head2 random_bigint

Returns a random 63 bits L<Math::BigInt>. Some architectures do not support
native 64 bit integers, but that is what DataDog expects.

NOTE: special care needs to be taken when rendering to JSON, as the GO language
is not forgiving for double qouted values when using big numbers.
Use C<<JSON->allow_bignum>>.

=cut

use Math::BigInt::Random::OO;
#
# $random
#
# our internal BigInt::Random generator, we only instantiate once
#
my $RANDOM = Math::BigInt::Random::OO->new( length_bin => 63 );

sub random_bigint { $RANDOM->generate() }



=head1 SEE ALSO

=over

=item L<OpenTracing::Implementation::DataDog>

Sending traces to DataDog using Agent.

=back



=head1 AUTHOR

Theo van Hoesel <tvanhoesel@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'OpenTracing::Implementation::DataDog'
is Copyright (C) 2019 .. 2021, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.


=cut

1;
