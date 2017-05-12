# SMB-Perl library, Copyright (C) 2014 Mikhael Goikhman, migo@cpan.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package SMB::v1::Commands;

use strict;
use warnings;

use SMB::v1::Header;

our $header_stamp = "\xffSMB";

our @command_names = (
	'CreateDirectory',        # 0x00
	'DeleteDirectory',        # 0x01
	'Open',                   # 0x02
	'Create',                 # 0x03
	'Close',                  # 0x04
	'Flush',                  # 0x05
	'Delete',                 # 0x06
	'Rename',                 # 0x07
	'QueryInformation',       # 0x08
	'SetInformation',         # 0x09
	'Read',                   # 0x0A
	'Write',                  # 0x0B
	'LockByteRange',          # 0x0C
	'UnlockByteRange',        # 0x0D
	'CreateTemporary',        # 0x0E
	'CreateNew',              # 0x0F
	'CheckDirectory',         # 0x10
	'ProcessExit',            # 0x11
	'Seek',                   # 0x12
	'LockAndRead',            # 0x13
	'WriteAndUnlock',         # 0x14
	'',                       # 0x15
	'',                       # 0x16
	'',                       # 0x17
	'',                       # 0x18
	'',                       # 0x19
	'ReadRaw',                # 0x1A
	'ReadMpx',                # 0x1B
	'ReadMpx2Secondary',      # 0x1C
	'WriteRaw',               # 0x1D
	'WriteMpx',               # 0x1E
	'WriteMpxSecondary',      # 0X1F
	'WriteComplete',          # 0x20
	'QueryServer',            # 0x21
	'SetInformation2',        # 0x22
	'QueryInformation2',      # 0x23
	'LockingAndX',            # 0x24
	'Transaction',            # 0x25
	'TransactionSecondary',   # 0x26
	'Ioctl',                  # 0x27
	'IoctlSecondary',         # 0x28
	'Copy',                   # 0x29
	'Move',                   # 0x2A
	'Echo',                   # 0x2B
	'WriteAndClose',          # 0x2C
	'OpenAndX',               # 0x2D
	'ReadAndX',               # 0x2E
	'WriteAndX',              # 0x2F
	'NewFileSize',            # 0x30
	'CloseAndTreeDisc',       # 0x31
	'Transaction2',           # 0x32
	'Transaction2Secondary',  # 0x33
	'FindClose2',             # 0x34
	'FindNotifyClose',        # 0x35
	'',                       # 0x36
	'',                       # 0x37
	'',                       # 0x38
	'',                       # 0x39
	'',                       # 0x3A
	'',                       # 0x3B
	'',                       # 0x3C
	'',                       # 0x3D
	'',                       # 0x3E
	'',                       # 0x3F
	'',                       # 0x40
	'',                       # 0x41
	'',                       # 0x42
	'',                       # 0x43
	'',                       # 0x44
	'',                       # 0x45
	'',                       # 0x46
	'',                       # 0x47
	'',                       # 0x48
	'',                       # 0x49
	'',                       # 0x4A
	'',                       # 0x4B
	'',                       # 0x4C
	'',                       # 0x4D
	'',                       # 0x4E
	'',                       # 0x4F
	'',                       # 0x50
	'',                       # 0x51
	'',                       # 0x52
	'',                       # 0x53
	'',                       # 0x54
	'',                       # 0x55
	'',                       # 0x56
	'',                       # 0x57
	'',                       # 0x58
	'',                       # 0x59
	'',                       # 0x5A
	'',                       # 0x5B
	'',                       # 0x5C
	'',                       # 0x5D
	'',                       # 0x5E
	'',                       # 0x5F
	'',                       # 0x60
	'',                       # 0x61
	'',                       # 0x62
	'',                       # 0x63
	'',                       # 0x64
	'',                       # 0x65
	'',                       # 0x66
	'',                       # 0x67
	'',                       # 0x68
	'',                       # 0x69
	'',                       # 0x6A
	'',                       # 0x6B
	'',                       # 0x6C
	'',                       # 0x6D
	'',                       # 0x6E
	'',                       # 0x6F
	'TreeConnect',            # 0x70
	'TreeDisconnect',         # 0x71
	'Negotiate',              # 0x72
	'SessionSetupAndX',       # 0x73
	'LogoffAndX',             # 0x74
	'TreeConnectAndX',        # 0x75
	'',                       # 0x76
	'',                       # 0x77
	'',                       # 0x78
	'',                       # 0x79
	'',                       # 0x7A
	'',                       # 0x7B
	'',                       # 0x7C
	'',                       # 0x7D
	'SecurityPackageAndX',    # 0x7E
	'',                       # 0x7F
	'QueryInformationDisk',   # 0x80
	'Search',                 # 0x81
	'Find',                   # 0x82
	'FindUnique',             # 0x83
	'FindClose',              # 0x84
	'',                       # 0x85
	'',                       # 0x86
	'',                       # 0x87
	'',                       # 0x88
	'',                       # 0x89
	'',                       # 0x8A
	'',                       # 0x8B
	'',                       # 0x8C
	'',                       # 0x8D
	'',                       # 0x8E
	'',                       # 0x8F
	'',                       # 0x90
	'',                       # 0x91
	'',                       # 0x92
	'',                       # 0x93
	'',                       # 0x94
	'',                       # 0x95
	'',                       # 0x96
	'',                       # 0x97
	'',                       # 0x98
	'',                       # 0x99
	'',                       # 0x9A
	'',                       # 0x9B
	'',                       # 0x9C
	'',                       # 0x9D
	'',                       # 0x9E
	'',                       # 0x9F
	'NtTransact',             # 0xA0
	'NtTransactSecondary',    # 0xA1
	'NtCreateAndX',           # 0xA2
	'',                       # 0xA3
	'NtCancel',               # 0xA4
	'NtRename',               # 0xA5
	'',                       # 0xA6
	'',                       # 0xA7
	'',                       # 0xA8
	'',                       # 0xA9
	'',                       # 0xAA
	'',                       # 0xAB
	'',                       # 0xAC
	'',                       # 0xAD
	'',                       # 0xAE
	'',                       # 0xAF
	'',                       # 0xB0
	'',                       # 0xB1
	'',                       # 0xB2
	'',                       # 0xB3
	'',                       # 0xB4
	'',                       # 0xB5
	'',                       # 0xB6
	'',                       # 0xB7
	'',                       # 0xB8
	'',                       # 0xB9
	'',                       # 0xBA
	'',                       # 0xBB
	'',                       # 0xBC
	'',                       # 0xBD
	'',                       # 0xBE
	'',                       # 0xBF
	'OpenPrintFile',          # 0xC0
	'WritePrintFile',         # 0xC1
	'ClosePrintFile',         # 0xC2
	'GetPrintQueue',          # 0xC3
	'',                       # 0xC4
	'',                       # 0xC5
	'',                       # 0xC6
	'',                       # 0xC7
	'',                       # 0xC8
	'',                       # 0xC9
	'',                       # 0xCA
	'',                       # 0xCB
	'',                       # 0xCC
	'',                       # 0xCD
	'',                       # 0xCE
	'',                       # 0xCF
	'',                       # 0xD0
	'',                       # 0xD1
	'',                       # 0xD2
	'',                       # 0xD3
	'',                       # 0xD4
	'',                       # 0xD5
	'',                       # 0xD6
	'',                       # 0xD7
	'ReadBulk',               # 0xD8
	'WriteBulk',              # 0xD9
	'WriteBulkData',          # 0xDA
	'',                       # 0xDB
	'',                       # 0xDC
	'',                       # 0xDD
	'',                       # 0xDE
	'',                       # 0xDF
	'',                       # 0xE0
	'',                       # 0xE1
	'',                       # 0xE2
	'',                       # 0xE3
	'',                       # 0xE4
	'',                       # 0xE5
	'',                       # 0xE6
	'',                       # 0xE7
	'',                       # 0xE8
	'',                       # 0xE9
	'',                       # 0xEA
	'',                       # 0xEB
	'',                       # 0xEC
	'',                       # 0xED
	'',                       # 0xEE
	'',                       # 0xEF
	'',                       # 0xF0
	'',                       # 0xF1
	'',                       # 0xF2
	'',                       # 0xF3
	'',                       # 0xF4
	'',                       # 0xF5
	'',                       # 0xF6
	'',                       # 0xF7
	'',                       # 0xF8
	'',                       # 0xF9
	'',                       # 0xFA
	'',                       # 0xFB
	'',                       # 0xFC
	'',                       # 0xFD
	'',                       # 0xFE
	'',                       # 0xFF
);

our %command_codes = map { $command_names[$_] => $_ } 0 .. $#command_names;

our $MIN_MESSAGE_SIZE = 33;

sub parse ($$) {
	my $class = shift;
	my $parser = shift || die;

	if ($parser->size < $MIN_MESSAGE_SIZE) {
		warn sprintf "Too short message to parse (%d, should be at least %d)\n", $parser->size, $MIN_MESSAGE_SIZE;
		return;
	}

	# parse header following the SMB1 stamp "\xffSMB"
	my $code   = $parser->uint8;
	my $status = $parser->uint32;
	my $flags  = $parser->uint8;
	my $flags2 = $parser->uint16;
	my $pid_h  = $parser->uint16;
	my $sign   = $parser->bytes(8);
	my $tid    = $parser->uint16;
	my $pid_l  = $parser->uint16;
	my $uid    = $parser->uint16;
	my $mid    = $parser->uint16;

	my $header = SMB::v1::Header->new(
		code      => $code,
		status    => $status,
		uid       => $uid,
		tid       => $tid,
		mid       => $mid,
		signature => $sign,
		pid       => $pid_h << 16 + $pid_l,
		flags     => $flags,
		flags2    => $flags2,
	);

	my $command_name = $command_names[$code];
	my $command;

	if ($command_name) {
		my $command_class = "SMB::v1::Command::$command_name";
		my $command_filename = "SMB/v1/Command/$command_name.pm";
		require $command_filename unless $INC{$command_filename};

		$command = $command_class->new($header)->parse($parser)
			or warn sprintf "Failed to parse SMB1 command 0x%x ($command_name)\n", $code;
	} else {
		warn sprintf "Got unexisting SMB1 command 0x%x\n", $code;
	}

	return $command;
}

1;
