package OpenTracing::Implementation::DataDog::Utils;

=head1 NAME

OpenTracing::Implementation::DataDog::Utils - DataDog Utilities

=cut

our $VERSION = 'v0.45.0';

;

use Exporter qw/import/;

our @EXPORT_OK = qw/random_64bit_int nano_seconds/;

=head1 EXPORTS OK

The following subroutines can be imported into your namespance:

=cut



=head2 random_64bit_int

Generates a 64bit integers (or actually a 63bit, or signed 64bit)

=cut

sub random_64bit_int { int(rand( 2**63 )) }



=head2 nano_seconds

To turn floatingpoint times into number of nano seconds

=cut

sub nano_seconds { int( $_[0] * 1_000_000_000 ) }



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
