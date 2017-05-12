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

package SMB::v2::Commands;

use strict;
use warnings;

use SMB::v2::Header;

our $header_stamp = "\xfeSMB";

our @command_names = (
	'Negotiate',       # 0x00
	'SessionSetup',    # 0x01
	'SessionLogoff',   # 0x02
	'TreeConnect',     # 0x03
	'TreeDisconnect',  # 0x04
	'Create',          # 0x05
	'Close',           # 0x06
	'Flush',           # 0x07
	'Read',            # 0x08
	'Write',           # 0x09
	'Lock',            # 0x0A
	'Ioctl',           # 0x0B
	'Cancel',          # 0x0C
	'KeepAlive',       # 0x0D
	'QueryDirectory',  # 0x0E
	'ChangeNotify',    # 0x0F
	'QueryInfo',       # 0x10
	'SetInfo',         # 0x11
	'Break',           # 0x12
);

our %command_codes = map { $command_names[$_] => $_ } 0 .. $#command_names;

our %command_aliases = (
	'Echo'    => 'KeepAlive',
	'Find'    => 'QueryDirectory',
	'Notify'  => 'ChangeNotify',
	'GetInfo' => 'QueryInfo',
);

our @command_struct_sizes = (
	[ 36, 65 ],  # 0x00
	[ 25,  9 ],  # 0x01
	[  4,  4 ],  # 0x02
	[  9, 16 ],  # 0x03
	[  4,  4 ],  # 0x04
	[ 57, 89 ],  # 0x05
	[ 24, 60 ],  # 0x06
	[ 24,  4 ],  # 0x07
	[ 49, 17 ],  # 0x08
	[ 49, 17 ],  # 0x09
	[ 48,  4 ],  # 0x0A
	[ 57, 49 ],  # 0x0B
	[  4,  0 ],  # 0x0C
	[  4,  4 ],  # 0x0D
	[ 33,  9 ],  # 0x0E
	[ 32,  9 ],  # 0x0F
	[ 41,  9 ],  # 0x10
	[ 33,  2 ],  # 0x11
	[ 24, 24 ],  # 0x12  # or [ 36, 44 ]
);

our $MIN_MESSAGE_SIZE = 64;

sub parse ($$) {
	my $class = shift;
	my $parser = shift || die;

	if ($parser->size < $MIN_MESSAGE_SIZE) {
		warn sprintf "Too short message to parse (%d, should be at least %d)\n", $parser->size, $MIN_MESSAGE_SIZE;
		return;
	}

	# parse header following the SMB2 stamp "\xfeSMB"
	$parser->uint16;  # skip reserved
	my $credit_charge = $parser->uint16;
	my $status = $parser->uint32;
	my $code   = $parser->uint16;
	my $credits = $parser->uint16;
	my $flags  = $parser->uint32;
	my $offset = $parser->uint32;  # offset of the next chain command or 0
	my $mid = $parser->uint64;
	my $aid = 0;
	my $tid = 0;
	if ($flags & SMB::v2::Header::FLAGS_ASYNC_COMMAND) {
		$aid = $parser->uint64;
	} else {
		$parser->uint32;  # reserved (according to spec), not pid
		$tid = $parser->uint32;
	}
	my $uid = $parser->uint64;
	my $sign = $parser->bytes(16);
	my $struct_size = $parser->uint16;

	my $header = SMB::v2::Header->new(
		code      => $code,
		status    => $status,
		uid       => $uid,
		tid       => $tid,
		mid       => $mid,
		signature => $sign,
		flags     => $flags,
		aid       => $aid,
		credits   => $credits,
		credit_charge => $credit_charge,
		struct_size => $struct_size,
	);

	my $command_name = $command_names[$code];
	my $command;

	if ($command_name) {
		my $command_class = "SMB::v2::Command::$command_name";
		my $command_filename = "SMB/v2/Command/$command_name.pm";
		unless ($INC{$command_filename} || $::_INC{$command_filename}) {
			# auto-load or auto-create requested sub-class
			if (!eval { require $command_filename; 1; }) {
				no strict 'refs';
				@{"${command_class}::ISA"} = qw(SMB::v2::Command);
				$::_INC{$command_filename} = 1;
			}
		}

		$command = $command_class->new($header);
		return $command unless $command->is_success || $command->is('SessionSetup');

		$command = $command->parse($parser)
			or warn sprintf "Failed to parse SMB2 command 0x%x ($command_name)\n", $code;
	} else {
		warn sprintf "Got unexisting SMB2 command 0x%x\n", $code;
	}

	return $command;
}

sub pack ($$$%) {
	my $class = shift;
	my $packer = shift;
	my $command = shift;
	my %options = @_;

	my $header = $command->header;
	my $status = $command->status;

	my $is_response = $command->is_response;
	my $struct_size = $options{struct_size} // $command_struct_sizes[$header->code][$is_response] // $header->struct_size;
	my $is_chained  = $options{is_chained};
	my $is_first    = $options{is_first};
	my $is_last     = $options{is_last};

	my $flags = $header->flags;
	if ($is_response) {
		$flags |=  SMB::v2::Header::FLAGS_RESPONSE;
	} else {
		$flags &= ~SMB::v2::Header::FLAGS_RESPONSE;
	}
	if ($is_chained && !$is_first) {
		$flags |=  SMB::v2::Header::FLAGS_CHAINED;
	} else {
		$flags &= ~SMB::v2::Header::FLAGS_CHAINED;
	}

	# skip NetBIOS header (length will be filled later)
	if (!$is_chained || $is_first) {
		$packer->mark('netbios-header');
		$packer->skip(4);
	}

	# pack SMB2 header
	$packer->mark('smb-header');
	$packer->bytes($header_stamp);  # SMB2 magic signature
	$packer->uint16(64);            # header size
	$packer->uint16($header->credit_charge);
	$packer->mark('status');
	$packer->uint32($is_response ? $status : 0);
	$packer->uint16($header->code);
	$packer->uint16($header->credits || 1);
	$packer->uint32($flags);
	$packer->mark('next-command');
	$packer->uint32(0);
	$packer->uint64($header->mid);
	# aid or pid + tid
	if ($flags & SMB::v2::Header::FLAGS_ASYNC_COMMAND) {
		$packer->uint64($header->aid);
	} else {
		$packer->uint32(0);  # no pid in SMB2 spec
		$packer->uint32($header->tid);
	}
	$packer->uint64($header->uid);
	$packer->bytes("\0" x 16);      # no message signing for now

	$packer->mark('header-end');
	$packer->uint16($command->is_success ? $struct_size : 9);
	$packer->mark('command-start');

	$command->pack($packer) if $command->is_success || $command->is('SessionSetup');
	$packer->zero(6 + 1) if $command->is_error && !$command->is('SessionSetup');

	my $payload_allowed = $struct_size % 2;
	$payload_allowed = 1 if $command->is('Negotiate') && !$is_response;
	my $size = $packer->diff('header-end');
	my $size0 = $struct_size & ~1;
	die "SMB2 command $command->{name} pack produced size $size, expected $size0\n"
		if $size > $size0 && !$payload_allowed;
	$packer->zero($size0 - $size) if $size0 > $size;

	$packer->mark('end');
	if ($is_chained && !$is_last) {
		my $command_size = $packer->diff('header');
		my $command_size_padded = ($command_size + 7) & ~7;
		$packer->zero($command_size_padded - $command_size);
		$packer->mark('end');
		$packer->jump('next-command');
		$packer->uint32($command_size_padded);
	}
	if (!$is_chained || $is_last) {
		$packer->jump('netbios-header');
		$packer->uint32_be(-$packer->diff('end') - 4);
	}
	$packer->jump('end');
}

1;
