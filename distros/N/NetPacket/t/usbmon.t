use strict;
use warnings;

use Test::More tests => 103;

use NetPacket::USBMon qw/:ALL/;

my $frame;
my $usbmon;

# host -> device, GET DESCRIPTOR Request DEVICE
$frame = binarize( <<'END_DATAGRAM' );
40 21 9d fa 01 88 ff ff 53 02 80 0a 03 00 00 3c
48 e4 0c 52 00 00 00 00 2f d7 06 00 8d ff ff ff
28 00 00 00 00 00 00 00 80 06 00 01 00 00 28 00
00 00 00 00 00 00 00 00 00 02 00 00 00 00 00 00
END_DATAGRAM

$usbmon = NetPacket::USBMon->decode( $frame );

#is $usbmon->{id} => 0xffff8801fa9d2140;
is $usbmon->{type} => 'S';
is $usbmon->{xfer_type} => USB_XFER_TYPE_CONTROL;
is $usbmon->{ep}{num} => 0;
is $usbmon->{ep}{dir} => 'IN';
is $usbmon->{devnum} => 10;
is $usbmon->{busnum} => 3;
is $usbmon->{flag_setup} => USB_FLAG_SETUP_RELEVANT;
is $usbmon->{ts_sec} => 1376576584;
is $usbmon->{ts_usec} => 448303;
is $usbmon->{status} => -115;
is $usbmon->{length} => 40;
is $usbmon->{len_cap} => 0;
is $usbmon->{xfer_flags} => 0x200;
is $usbmon->{data} => '';

# device -> host, GET DESCRIPTOR Response DEVICE
$frame = binarize( <<'END_DATAGRAM' );
40 21 9d fa 01 88 ff ff 43 02 80 0a 03 00 2d 00
48 e4 0c 52 00 00 00 00 24 db 06 00 00 00 00 00
12 00 00 00 12 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 02 00 00 00 00 00 00
12 01 00 02 00 00 00 40 71 1b 02 30 00 01 03 04
02 01
END_DATAGRAM

$usbmon = NetPacket::USBMon->decode( $frame );
is $usbmon->{type} => 'C';
is $usbmon->{xfer_type} => USB_XFER_TYPE_CONTROL;
is $usbmon->{ep}{num} => 0;
is $usbmon->{ep}{dir} => 'IN';
is $usbmon->{devnum} => 10;
is $usbmon->{busnum} => 3;
is $usbmon->{flag_setup} => USB_FLAG_SETUP_IRRELEVANT;
is $usbmon->{ts_sec} => 1376576584;
is $usbmon->{ts_usec} => 449316;
is $usbmon->{status} => 0;
is $usbmon->{length} => 18;
is $usbmon->{len_cap} => 18;
is $usbmon->{xfer_flags} => 512;
is length $usbmon->{data} => $usbmon->{len_cap};

# host -> device, SET INTERFACE Request
$frame = binarize( <<'END_DATAGRAM' );
00 2b 9d fa 01 88 ff ff 53 02 00 0a 03 00 00 00
65 e4 0c 52 00 00 00 00 23 62 07 00 8d ff ff ff
00 00 00 00 00 00 00 00 40 0c 01 00 08 c0 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
END_DATAGRAM

$usbmon = NetPacket::USBMon->decode( $frame );
is $usbmon->{type} => 'S';
is $usbmon->{xfer_type} => USB_XFER_TYPE_CONTROL;
is $usbmon->{ep}{num} => 0;
is $usbmon->{ep}{dir} => 'OUT';
is $usbmon->{devnum} => 10;
is $usbmon->{busnum} => 3;
is $usbmon->{flag_setup} => USB_FLAG_SETUP_RELEVANT;
is $usbmon->{ts_sec} => 1376576613;
is $usbmon->{ts_usec} => 483875;
is $usbmon->{status} => -115;
is $usbmon->{length} => 0;
is $usbmon->{len_cap} => 0;
is $usbmon->{xfer_flags} => 0;
is $usbmon->{data} => '';
is $usbmon->{setup}{bmRequestType} => USB_TYPE_VENDOR;
is $usbmon->{setup}{bRequest} => 12;
is $usbmon->{setup}{wIndex} => 49160;
is $usbmon->{setup}{wLength} => 0;
is $usbmon->{setup}{wValue} => 1;

# device -> host, SET INTERFACE Response
$frame = binarize( <<'END_DATAGRAM' );
00 2b 9d fa 01 88 ff ff 43 02 00 0a 03 00 2d 3e
65 e4 0c 52 00 00 00 00 ae 61 07 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
END_DATAGRAM

$usbmon = NetPacket::USBMon->decode( $frame );
is $usbmon->{type} => 'C';
is $usbmon->{xfer_type} => USB_XFER_TYPE_CONTROL;
is $usbmon->{ep}{num} => 0;
is $usbmon->{ep}{dir} => 'OUT';
is $usbmon->{devnum} => 10;
is $usbmon->{busnum} => 3;
is $usbmon->{flag_setup} => USB_FLAG_SETUP_IRRELEVANT;
is $usbmon->{ts_sec} => 1376576613;
is $usbmon->{ts_usec} => 483758;
is $usbmon->{status} => 0;
is $usbmon->{length} => 0;
is $usbmon->{len_cap} => 0;
is $usbmon->{xfer_flags} => 0;
is $usbmon->{data} => '';

# host -> device, URB_CONTROL out
$frame = binarize( <<'END_DATAGRAM' );
00 2b 9d fa 01 88 ff ff 53 02 00 0a 03 00 00 00
65 e4 0c 52 00 00 00 00 23 62 07 00 8d ff ff ff
00 00 00 00 00 00 00 00 40 0c 01 00 08 c0 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
END_DATAGRAM

$usbmon = NetPacket::USBMon->decode( $frame );
is $usbmon->{type} => 'S';
is $usbmon->{xfer_type} => USB_XFER_TYPE_CONTROL;
is $usbmon->{ep}{num} => 0;
is $usbmon->{ep}{dir} => 'OUT';
is $usbmon->{devnum} => 10;
is $usbmon->{busnum} => 3;
is $usbmon->{flag_setup} => USB_FLAG_SETUP_RELEVANT;
is $usbmon->{ts_sec} => 1376576613;
is $usbmon->{ts_usec} => 483875;
is $usbmon->{status} => -115;
is $usbmon->{length} => 0;
is $usbmon->{len_cap} => 0;
is $usbmon->{xfer_flags} => 0;
is $usbmon->{data} => '';

# device -> host, URB_CONTROL out
$frame = binarize( <<'END_DATAGRAM' );
00 2b 9d fa 01 88 ff ff 43 02 00 0a 03 00 2d 3e
65 e4 0c 52 00 00 00 00 1e 64 07 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
END_DATAGRAM

$usbmon = NetPacket::USBMon->decode( $frame );
is $usbmon->{type} => 'C';
is $usbmon->{xfer_type} => USB_XFER_TYPE_CONTROL;
is $usbmon->{ep}{num} => 0;
is $usbmon->{ep}{dir} => 'OUT';
is $usbmon->{devnum} => 10;
is $usbmon->{busnum} => 3;
is $usbmon->{flag_setup} => USB_FLAG_SETUP_IRRELEVANT;
is $usbmon->{ts_sec} => 1376576613;
is $usbmon->{ts_usec} => 484382;
is $usbmon->{status} => 0;
is $usbmon->{length} => 0;
is $usbmon->{len_cap} => 0;
is $usbmon->{xfer_flags} => 0;
is $usbmon->{data} => '';

# host -> device, URB_ISOCHRONOUS in
$frame = binarize( <<'END_DATAGRAM' );
00 ce 6b 19 01 88 ff ff 53 00 81 0a 03 00 2d 3c
65 e4 0c 52 00 00 00 00 be 16 08 00 8d ff ff ff
00 60 00 00 80 00 00 00 00 00 00 00 08 00 00 00
01 00 00 00 00 00 00 00 02 02 00 00 08 00 00 00
ee ff ff ff 00 00 00 00 00 0c 00 00 00 00 00 00
ee ff ff ff 00 0c 00 00 00 0c 00 00 00 00 00 00
ee ff ff ff 00 18 00 00 00 0c 00 00 00 00 00 00
ee ff ff ff 00 24 00 00 00 0c 00 00 00 00 00 00
ee ff ff ff 00 30 00 00 00 0c 00 00 00 00 00 00
ee ff ff ff 00 3c 00 00 00 0c 00 00 00 00 00 00
ee ff ff ff 00 48 00 00 00 0c 00 00 00 00 00 00
ee ff ff ff 00 54 00 00 00 0c 00 00 00 00 00 00
END_DATAGRAM

$usbmon = NetPacket::USBMon->decode( $frame );
is $usbmon->{type} => 'S';
is $usbmon->{xfer_type} => USB_XFER_TYPE_ISO;
is $usbmon->{ep}{num} => 1;
is $usbmon->{ep}{dir} => 'IN';
is $usbmon->{devnum} => 10;
is $usbmon->{busnum} => 3;
is $usbmon->{flag_setup} => USB_FLAG_SETUP_IRRELEVANT;
is $usbmon->{ts_sec} => 1376576613;
is $usbmon->{ts_usec} => 530110;
is $usbmon->{status} => -115;
is $usbmon->{length} => 24576;
is $usbmon->{len_cap} => 128;
is $usbmon->{xfer_flags} => 514;
is length $usbmon->{data} => $usbmon->{len_cap};

# Copied from t/tcp.t, uglified.
sub binarize { return join '' => map { chr hex } split ' ', shift; }
