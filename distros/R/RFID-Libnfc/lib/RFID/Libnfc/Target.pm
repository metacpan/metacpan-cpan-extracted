# The implementation of this module can be found in Libnfc.xs 
# it basically makes the nfc_target_t structure available to perl code
# note that this file holds only its documentation
=head1 NAME

RFID::Libnfc::Target

=head1 SYNOPSIS

    use RFID::Libnfc;

    $target = RFID::Libnfc::Target->new();

=head1 DESCRIPTION

  Provides a perl OO api to libnfc functionalities
  (actually implements only mifare-related functionalities)

=head2 METHODS

=over

=item * nti ( )

returns the internal RFID::Libnfc::TargetInfo object

=item * nm ( )

returns the internal RFID::Libnfc::Modulation object

=back

=head1 SEE ALSO

RFID::Libnfc RFID::Libnfc::Device RFID::Libnfc::TargetInfo RFID::Libnfc::Modulation

< check also documentation for libnfc c library [ http://www.libnfc.org/documentation/introduction ] >

=head1 AUTHOR

xant

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by xant <xant@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
