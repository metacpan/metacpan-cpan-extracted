# The implementation of this module can be found in Libnfc.xs 
# it basically makes the nfc_modulation_t structure available to perl code
# note that this file holds only its documentation
=head1 NAME

RFID::Libnfc::Modulation

=head1 SYNOPSIS

    use RFID::Libnfc;

    $modulation = RFID::Libnfc::Modulation->new();

    or 

    $target = RFID::Libnfc::Target->new();
    $modulation = $target->nm();

=head1 DESCRIPTION

  Provides a perl OO api to libnfc functionalities
  (actually implements only mifare-related functionalities)

=head2 METHODS

=over

=item nmt ( [ $modulation_type ] )
  
returns the configured modulation type.
The returned value is an integer as defined in NMT constants :
  NMT_ISO14443A
  NMT_ISO14443B
  NMT_FELICA
  NMT_JEWEL
  NMT_DEP

check  RFID::Libnfc::Constants for more details

If $modulation_type is defined the new value will be set before returning the old value

=item nbr ( [ $baud_rate ] )

returns the configured baud rate.
The returned value is an integer as defined in NBR constants :
  NBR_UNDEFINED
  NBR_106
  NBR_212
  NBR_424
  NBR_847

check  RFID::Libnfc::Constants for more details

If $baud_rate is defined the new value will be set before returning the old value

=back

=head1 SEE ALSO

RFID::Libnfc RFID::Libnfc::Device RFID::Libnfc::TargetInfo RFID::Libnfc::Constants

< check also documentation for libnfc c library [ http://www.libnfc.org/documentation/introduction ] >

=head1 AUTHOR

xant

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by xant <xant@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

