# The implementation of this module can be found in Libnfc.xs 
# it basically makes the nfc_device_t structure available to perl code
# note that this file holds only its documentation
=head1 NAME

RFID::Libnfc::Device

=head1 SYNOPSIS

    use RFID::Libnfc;

    $device = RFID::Libnfc::Device->new();

=head1 DESCRIPTION

  Provides a perl OO api to libnfc functionalities
  (actually implements only mifare-related functionalities)

=head2 METHODS

=over

=item * acName ( )

returns the printable name of the device

=item * nc ( )

returns an integer representing the chip type

possible values are :

 NC_PN531
 NC_PN532
 NC_PN533

these constants are defined in RFID::Libnfc::Constants

=item * nds ( )

returns a pointer to the device connection specification (nfc_device_spec_t)

=item * bActive ( )

returns a boolean which determines if the device is active or not

=item * bCrc ( [ $bool ] )

get/set the crc field which determines if crc must be used or not

=item * bPar ( [ $bool ] )

get/set the parity field which determines if parity must be used or not

=item * ui8TxBits ( [ $bits ] )

get/set the internal buffer holding the transmit bits

=back

=head1 SEE ALSO

RFID::Libnfc RFID::Libnfc::Device RFID::Libnfc::Target RFID::Libnfc::Constants

< check also documentation for libnfc c library [ http://www.libnfc.org/documentation/introduction ] >

=head1 AUTHOR

xant

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by xant <xant@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
