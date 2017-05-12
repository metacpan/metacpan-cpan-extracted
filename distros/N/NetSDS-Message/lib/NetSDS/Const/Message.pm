#===============================================================================
#
#         FILE:  Message.pm
#
#  DESCRIPTION:  Common messaging constants
#
#        NOTES:  ---
#       AUTHOR:  Grigory Milev (Weekend), <week@altlinux.org>
#      COMPANY:  Net.Style
#      CREATED:  25.07.2008 01:06:46 EEST
#===============================================================================

=head1 NAME

NetSDS::Const::Message - common constants for messaging

=head1 SYNOPSIS

	use NetSDS::Const::Message;

=head1 DESCRIPTION

C<NetSDS::Const::Message> module contains based constants

=cut

package NetSDS::Const::Message;

use 5.8.0;
use strict;
use warnings 'all';

use Exporter;
our @ISA = qw(
  Exporter
);

use version; our $VERSION = '0.021';

our @EXPORT = qw(
  COD_7BIT
  COD_GSM0338
  COD_8BIT
  COD_BINARY
  COD_UNICODE
  COD_UCS2

  ENC_7BIT
  ENC_8BIT
  ENC_BINARY
  ENC_UNICODE

  DLR_DELIVERED
  DLR_EXPIRED
  DLR_DELETED
  DLR_UNDELIVERABLE
  DLR_ACCEPTED
  DLR_UNKNOWN
  DLR_REJECTED

  TRANSPORT_ANY
  TRANSPORT_KANNEL
  TRANSPORT_CPA2
  TRANSPORT_UMC

  DCS_EMS
  DCS_NOKIA
  DCS_SIEMENS

  IEC_SPLIT8
  IEC_SPLIT16
  IEC_TEXTFMT
  IEC_SOUND
  IEC_MELODY
  IEC_SMILES
  IEC_ANIM16
  IEC_ANIM8
  IEC_ICON32
  IEC_ICON16
  IEC_PICTURE
  IEC_UPI

  PORT_LOGO
  PORT_CLI
  PORT_RINGTONE
  PORT_VCARD
  PORT_VCALENDAR
  PORT_ITEMS
  PORT_PUSHWAP

  SMS_SIZE

  SEO_VER
  SEO_FILL
  SEO_LEN
);

our @EXPORT_OK = qw(
);

#-- SMS encoding
use constant COD_7BIT    => '0';             # GSM 03.38 default charset
use constant COD_GSM0338 => COD_7BIT();
use constant COD_8BIT    => '1';             # Binary encoded message
use constant COD_BINARY  => COD_8BIT();
use constant COD_UNICODE => '2';             # UCS-2BE Unicode message
use constant COD_UCS2    => COD_UNICODE();

#-- Charset encodings
use constant ENC_7BIT    => 'ISO-8859-1';
use constant ENC_8BIT    => '8-BIT';
use constant ENC_BINARY  => ENC_8BIT();
use constant ENC_UNICODE => 'UTF-16BE';

#-- Delivery status
use constant DLR_DELIVERED     => 'DELIVRD';    # Message is delivered to destination
use constant DLR_EXPIRED       => 'EXPIRED';    # Message validity period has expired.
use constant DLR_DELETED       => 'DELETED';    # Message has been deleted.
use constant DLR_UNDELIVERABLE => 'UNDELIV';    # Message is undeliverable
use constant DLR_ACCEPTED      => 'ACCEPTD';    # Message is in accepted state (i.e. has been manually read on behalf of the subscriber by customer service)
use constant DLR_UNKNOWN       => 'UNKNOWN';    # Message is in invalid state
use constant DLR_REJECTED      => 'REJECTD';    # Message is in a rejected state

#-- Transports
use constant TRANSPORT_ANY    => '';
use constant TRANSPORT_KANNEL => 'kannel';
use constant TRANSPORT_CPA2   => 'cpa2';
use constant TRANSPORT_UMC    => 'umc';

#-- Data Coding Schemes
use constant DCS_EMS     => '64:245';
use constant DCS_NOKIA   => '64:245';
use constant DCS_SIEMENS => '0:245';

#-- EMS Constants
use constant IEC_SPLIT8  => "\x00";    # Messages chain, 8-bit reference
use constant IEC_SPLIT16 => "\x08";    # Messages chain, 16-bit reference
use constant IEC_TEXTFMT => "\x0A";    # Text formatting
use constant IEC_SOUND   => "\x0B";    # Predefined sound
use constant IEC_MELODY  => "\x0C";    # User Defined iMelody
use constant IEC_SMILES  => "\x0D";    # Predefined animation
use constant IEC_ANIM16  => "\x0E";    # User Defined 16x16x4 animation
use constant IEC_ANIM8   => "\x0F";    # User Defined 8x8x4 animation
use constant IEC_ICON32  => "\x10";    # User Defined 32x32 icon
use constant IEC_ICON16  => "\x11";    # User Defined 16x16 icon
use constant IEC_PICTURE => "\x12";    # User Defined variable size picture
use constant IEC_UPI     => "\x13";    # User Prompt Indicator

#-- Nokia SmartMessaging ports
use constant PORT_RINGTONE  => "\x15\x81";    # Ringtone
use constant PORT_LOGO      => "\x15\x82";    # Operator Logo
use constant PORT_CLI       => "\x15\x83";    # CLI Icon
use constant PORT_ITEMS     => "\x15\x8A";    # Picture Message
use constant PORT_VCARD     => "\x23\xF4";    # VCard
use constant PORT_VCALENDAR => "\x23\xF5";    # Operator Logo
use constant PORT_PUSHWAP   => "\x0B\x84";    # Wap push

#-- Siemens OTA constants
use constant SMS_SIZE => 140;                 # Maximum SMS size in bytes
use constant SEO_VER  => 1;                   # SEO version 1
use constant SEO_FILL => "\0";                # SEO Chunk padding character
use constant SEO_LEN  => 22;                  # SEO Header length in bytes w/o strings

#***********************************************************************

1;

__END__

=head1 NAME

NetSDS::Messaging::Const - основные константы для сообщений

=head1 SYNOPSIS

Нужны только константы:

	use NetSDS::Messaging::Const;


Потрібні додатково і деякі процедури:

	use NetSDS::Messaging::Const qw(
		ncMessage
		ncIsError
		...
	);

=head1 DESCRIPTION

Пакунок C<NetSDS::Messaging::Const> містить загальні константи для SMS повідомлень та процедури роботи із ними.

Ідею злизано із L<HTTP::Status>

=head1 CONSTANTS

=over

=item B<COD_7BIT> - ...

=item B<COD_8BIT> - ...

=item B<COD_BINARY> - ...

=item B<COD_UNICODE> - ...

=item B<ENC_7BIT> - ...

=item B<ENC_8BIT> - ...

=item B<ENC_BINARY> - ...

=item B<ENC_UNICODE> - ...

=item B<DLR_DELIVERED> - ...

=item B<DLR_EXPIRED> - ...

=item B<DLR_DELETED> - ...

=item B<DLR_UNDELIVERABLE> - ...

=item B<DLR_ACCEPTED> - ...

=item B<DLR_UNKNOWN> - ...

=item B<DLR_REJECTED> - ...

=item B<TRANSPORT_ANY> - ...

=item B<TRANSPORT_KANNEL> - ...

=item B<TRANSPORT_CPA2> - ...

=item B<TRANSPORT_UMC> - ...

=item B<DCS_EMS> - ...

=item B<DCS_NOKIA> - ...

=item B<DCS_SIEMENS> - ...

=item B<IEC_SPLIT8> - ...

=item B<IEC_SPLIT16> - ...

=item B<IEC_TEXTFMT> - ...

=item B<IEC_SOUND> - ...

=item B<IEC_MELODY> - ...

=item B<IEC_SMILES> - ...

=item B<IEC_ANIM16> - ...

=item B<IEC_ANIM8> - ...

=item B<IEC_ICON32> - ...

=item B<IEC_ICON16> - ...

=item B<IEC_PICTURE> - ...

=item B<IEC_UPI> - ...

=item B<PORT_LOGO> - ...

=item B<PORT_CLI> - ...

=item B<PORT_RINGTONE> - ...

=item B<PORT_VCARD> - ...

=item B<PORT_VCALENDAR> - ...

=item B<PORT_ITEMS> - ...

=item B<SMS_SIZE> - ...

=item B<SEO_VER> - ...

=item B<SEO_FILL> - ...

=item B<SEO_LEN> - ...

=back

=head1 EXPORTS

Empty

=head1 EXAMPLES

Empty

=head1 BUGS

Unknown

=head1 SEE ALSO

Empty

=head1 TODO

Empty

=head1 AUTHOR

Valentyn Solomko <pere@pere.org.ua>

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008 Michael Bochkaryov

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
