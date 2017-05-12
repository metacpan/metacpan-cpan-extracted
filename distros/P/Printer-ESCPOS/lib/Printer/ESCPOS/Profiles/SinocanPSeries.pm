use strict;
use warnings;

package Printer::ESCPOS::Profiles::SinocanPSeries;

# PODNAME: Printer::ESCPOS::Profiles::SinocanPSeries
# ABSTRACT: Sinocan P Series Profile for Printers for L<Printer::ESCPOS>.
#
# This file is part of Printer-ESCPOS
#
# This software is copyright (c) 2017 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '1.006'; # VERSION

# Dependencies
use 5.010;
use Moo;
extends 'Printer::ESCPOS::Profiles::Generic';
with 'Printer::ESCPOS::Roles::Profile';

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Printer::ESCPOS::Profiles::SinocanPSeries - Sinocan P Series Profile for Printers for L<Printer::ESCPOS>.

=head1 VERSION

version 1.006

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org> L<https://www.shantanubhadoria.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
