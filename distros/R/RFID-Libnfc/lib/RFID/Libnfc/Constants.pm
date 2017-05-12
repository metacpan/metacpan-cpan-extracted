package RFID::Libnfc::Constants;

use Exporter;
our @ISA = qw( Exporter );
our $VERSION = '0.13';

BEGIN {    # must be defined at compile time
        %constants = (

            NDO => {    # export tag
                NDO_HANDLE_CRC             => 0x00,
                NDO_HANDLE_PARITY          => 0x01,
                NDO_ACTIVATE_FIELD         => 0x10,
                NDO_ACTIVATE_CRYPTO1       => 0x11,
                NDO_INFINITE_SELECT        => 0x20,
                NDO_ACCEPT_INVALID_FRAMES  => 0x30,
                NDO_ACCEPT_MULTIPLE_FRAMES => 0x31,
                NDO_AUTO_ISO14443_4        => 0x40,
                NDO_EASY_FRAMING           => 0x41,
                NDO_FORCE_ISO14443_A       => 0x42,
            },
            IM => {
                IM_ISO14443A_106  => 0x00,
                IM_FELICA_212     => 0x01,
                IM_FELICA_424     => 0x02,
                IM_ISO14443B_106  => 0x03,
                IM_JEWEL_106      => 0x04
            },
            MC => {
                MC_AUTH_A         => 0x60,
                MC_AUTH_B         => 0x61,
                MC_READ           => 0x30,
                MC_WRITE          => 0xA0,
                MC_TRANSFER       => 0xB0,
                MC_DECREMENT      => 0xC0,
                MC_INCREMENT      => 0xC1,
                MC_STORE          => 0xC2
            },
            MU => {
                MU_REQA           => 0x26,
                MU_WUPA           => 0x52,
                MU_SELECT1        => 0x93,
                MU_SELECT2        => 0x95,
                MU_READ           => 0x30,
                MU_WRITE          => 0xA2,
                MU_CWRITE         => 0xA0,
                MU_HALT           => 0x50
            },
            NMT => {
                NMT_ISO14443A     => 0,
                NMT_ISO14443B     => 1,
                NMT_FELICA        => 2,
                NMT_JEWEL         => 3,
                NMT_DEP           => 4
            },
            NBR => {
                NBR_UNDEFINED     => 0,
                NBR_106           => 1,
                NBR_212           => 2,
                NBR_424           => 3,
                NBR_847           => 4
            },
            NC => {
                NC_PN531          => 0x10,
                NC_PN532          => 0x20,
                NC_PN533          => 0x30
            }
        );
}

# define the exports
our %EXPORT_TAGS
     = ( 'all' => [map { keys %$_ } values %constants], map { $_ => [ keys %{ $constants{$_} } ] } keys %constants );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# exporting all constants by default ... there are just a few right now, so it's not a big problem
our @EXPORT = @EXPORT_OK;

use constant + { map { %$_ } values %constants }; 

1;

__END__

=head1 NAME

RFID::Libnfc::Constants

=head1 SYNOPSIS

    use RFID::Libnfc::Constants;
    
    or

    use RFID::Libnfc::Constants qw(<category>);

    where <category> can be any of :
    - NDO
    - IM
    - MC
    - MU
    - NC
    - NMT
    - NBR
    

=head1 DESCRIPTION

    Constants used within RFID::Libnfc

=head2 CATEGORIES

=over

=item * NDO

 NDO_HANDLE_CRC => 0x00,
     Let the PN53X chip handle the CRC bytes. This means that the chip appends
     the CRC bytes to the frames that are transmitted. It will parse the last
     bytes from received frames as incoming CRC bytes. They will be verified
     against the used modulation and protocol. If an frame is expected with
     incorrect CRC bytes this option should be disabled. Example frames where
     this is useful are the ATQA and UID+BCC that are transmitted without CRC
     bytes during the anti-collision phase of the ISO14443-A protocol. 

 NDO_HANDLE_PARITY => 0x01,
     Parity bits in the network layer of ISO14443-A are by default generated and
     validated in the PN53X chip. This is a very convenient feature. On certain
     times though it is useful to get full control of the transmitted data. The
     proprietary MIFARE Classic protocol uses for example custom (encrypted)
     parity bits. For interoperability it is required to be completely
     compatible, including the arbitrary parity bits. When this option is
     disabled, the functions to communicating bits should be used. 

 NDO_ACTIVATE_FIELD => 0x10,
     This option can be used to enable or disable the electronic field of the
     NFC device. 

 NDO_ACTIVATE_CRYPTO1 => 0x11,
     The internal CRYPTO1 co-processor can be used to transmit messages
     encrypted. This option is automatically activated after a successful MIFARE
     Classic authentication. 

 NDO_INFINITE_SELECT => 0x20,
     The default configuration defines that the PN53X chip will try indefinitely
     to invite a tag in the field to respond. This could be desired when it is
     certain a tag will enter the field. On the other hand, when this is
     uncertain, it will block the application. This option could best be compared
     to the (NON)BLOCKING option used by (socket)network programming. 

 NDO_ACCEPT_INVALID_FRAMES => 0x30,
     If this option is enabled, frames that carry less than 4 bits are allowed.
     According to the standards these frames should normally be handles as
     invalid frames. 

 NDO_ACCEPT_MULTIPLE_FRAMES => 0x31,
     If the NFC device should only listen to frames, it could be useful to let
     it gather multiple frames in a sequence. They will be stored in the internal
     FIFO of the PN53X chip. This could be retrieved by using the receive data
     functions. Note that if the chip runs out of bytes (FIFO => 64 bytes long),
     it will overwrite the first received frames, so quick retrieving of the
     received data is desirable. 

 NDO_AUTO_ISO14443_4 => 0x40,
     This option can be used to enable or disable the auto-switching mode to
     ISO14443-4 is device is compliant.
     In initiator mode, it means that NFC chip will send RATS automatically when
     select and it will automatically poll for ISO14443-4 card when ISO14443A is
     requested.
     In target mode, with a NFC chip compiliant (ie. PN532), the chip will
     emulate a 14443-4 PICC using hardware capability 

 NDO_EASY_FRAMING => 0x41,
     Use automatic frames encapsulation and chaining. 

 NDO_FORCE_ISO14443_A => 0x42,
     Force the chip to switch in ISO14443-A 

=item * IM

 IM_ISO14443A_106  => 0x00,
     Mifare Classic (both 1K and 4K) and ULTRA tags conform to IM_ISO14443A_106.
     At the moment these are the only implemented tag types.
 IM_FELICA_212     => 0x01,
    * UNIMPLEMENTED *
 IM_FELICA_424     => 0x02,
    * UNIMPLEMENTED *
 IM_ISO14443B_106  => 0x03,
    * UNIMPLEMENTED *
 IM_JEWEL_106      => 0x04
    * UNIMPLEMENTED *

=item * MC

 MC_AUTH_A         => 0x60,
    Select the A key
 MC_AUTH_B         => 0x61,
    Select the B key
 MC_READ           => 0x30,
    Perform a read operation
 MC_WRITE          => 0xA0,
    Perform a write operation
 MC_TRANSFER       => 0xB0,
 
 MC_DECREMENT      => 0xC0,
    Increment the value of a byte
 MC_INCREMENT      => 0xC1,
    Increment the value of a byte
 MC_STORE          => 0xC2


=item * MU

 MU_REQA           => 0x26,
 MU_WUPA           => 0x52,
 MU_SELECT1        => 0x93,
 MU_SELECT2        => 0x95,
 MU_READ           => 0x30,
 MU_WRITE          => 0xA2,
 MU_CWRITE         => 0xA0,
 MU_HALT           => 0x50

=item * NMT

 NMT_ISO14443A     => 0,
     Mifare Classic (both 1K and 4K) and ULTRA tags conform to IM_ISO14443A_106.
     At the moment these are the only implemented tag types.
 NMT_ISO14443B     => 1,
     * UNIMPLEMENTED *
 NMT_FELICA        => 2,
     * UNIMPLEMENTED *
 NMT_JEWEL         => 3,
     * UNIMPLEMENTED *
 NMT_DEP           => 4
     * UNIMPLEMENTED *

=item * NBR

 NBR_UNDEFINED     => 0,
 NBR_106           => 1,
 NBR_212           => 2,
 NBR_424           => 3,
 NBR_847           => 4

=item * NC

 NC_UNDEFINED      => 0xff,
    * Undefined reader type *
    This will be returned also when an error condition occurs
 NC_PN531          => 0x10
 NC_PN532          => 0x20
 NC_PN533          => 0x30



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

