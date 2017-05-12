
package POCSAG::Encode;

=head1 NAME

POCSAG::Encode - A perl module for encoding messages in the POCSAG binary protocol.

=head1 ABSTRACT

This module encodes text messages in the POCSAG protocol. It returns
a binary string which can be fed synchronously to an FSK transmitter
at 512 bit/s per second.

=head1 DESCRIPTION

The module's generate function generates a single complete binary
POCSAG transmission, which consists of:

=over

=item *

A preamble consisting of Synchronisation Codewords (CWs)

=item *

One or more messages consisting of an Address Codeword and one or more
Message Codewords

=item *

Synchronisation Codewords at regular intervals between the codeword batches,
to keep the receivers in sync with the ongoing transmission

=item *

Idle Codewords before, between and after the messages, for mandatory padding to
correctly place the Address Codewords in the correct frame boundaries.

=back

Because the preamble is long, it makes sense to send a large amount of messages in
a batch to minimize transmitter key-down time and save RF channel time. Also, having
a larger number of messages to transmit in a single transmission
makes it possible to reduce the amount of Idle Codewords
in the transmission by optimizing the order in which the messages are sent.

This module currently has a very simple optimizer, which does not do a deeper search
for the most optimal transmit order, but instead only considers the next message to
be transmitted based on the minimum amount of Idle Codewords needed before the
address frame for the next message can be sent.

Unless a debugging mode is enabled, all errors and warnings are reported
through the API (as opposed to printing on STDERR or STDOUT), so that
they can be reported nicely on the user interface of an application.

=head1 FUNCTIONS

=cut

use strict;
use warnings;

use Data::Dumper;

our $VERSION = '1.00';

#
# Configuration
#

my $debug = 0;

#
# Constants
#

# The POCSAG transmission starts with 576 bit reversals (101010...).
# That's 576/8 == 72 bytes of 0xAA.
my $POCSAG_PREAMBLE = pack('H*', 'AA') x (576/8);

# The Frame Synchronisation (FS) code is 32 bits:
# 01111100 11010010 00010101 11011000
my $POCSAG_FS_CW = pack('H*', '7CD215D8');

# The Idle Codeword:
# 01111010 10001001 11000001 10010111
my $POCSAG_IDLE_CW = pack('H*', '7A89C197');

#_debug("preamble is: " . hex_dump($POCSAG_PREAMBLE));
#_debug("preamble length is " . length($POCSAG_PREAMBLE) . " bytes");
#_debug("POCSAG_FS_CW is " . hex_dump($POCSAG_FS_CW));
#_debug("POCSAG_IDLE_CW is " . hex_dump($POCSAG_IDLE_CW));

#_debug("integer in hex, network byte order: " . hex_dump(pack('N', 152151251)));

#
#	Converts a binary string to a hex dump - slow but good for debug logging
#

sub _hex_dump($)
{
	my($s) = @_;
	
	my $out = '';
	
	my $l = length($s);
	
	my $bytes_in_a_chunk = 4;
	my $bytes_in_a_row = $bytes_in_a_chunk * 8;
	
	# this is a bit slow, but it's only used for debugging
	for (my $i = 0; $i < $l; $i += 1) {
		if ($i % $bytes_in_a_row == 0 && $i != 0) {
			$out .= "\n";
		} elsif ($i % $bytes_in_a_chunk == 0 && $i != 0) {
			$out .= ' ';
		}
		$out .= sprintf('%02x', ord(substr($s, $i, 1)));
	}
	$out .= "\n";
	
	return $out;
}

#
#	Returns an integer as a hex string
#

sub _hex_int($)
{
	my($i) = @_;
	
	return unpack('H*', pack('N', $i));
}

#
#	Debug logging warn
#

sub _debug($)
{
	return if (!$debug);
	
	warn "Pocsag::Encode DEBUG: @_\n";
}

#
#	Calculate binary checksum and parity for a codeword
#

sub _calculate_bch_and_parity($)
{
	my($cw) = @_;
	
	# make sure the 11 LSB are 0.
	$cw &= 0xFFFFF800;
	
	my $local_cw = 0;
	my $parity = 0;
	
	# calculate bch
	$local_cw = $cw;
	for (my $bit = 1; $bit <= 21; $bit++) {
		$cw ^= 0xED200000 if ($cw & 0x80000000);
		$cw = $cw << 1;
	}
	$local_cw |= ($cw >> 21);
	# at this point $local_cw has codeword with bch
	
	# calculate parity
	$cw = $local_cw;
	for (my $bit = 1; $bit <= 32; $bit++) {
		$parity++ if ($cw & 0x80000000);
		$cw = $cw << 1;
	}
	
	# turn last bit to 1 depending on parity
	my $cw_with_parity = ($parity % 2) ? $local_cw + 1 : $local_cw;
	
	_debug("  bch_and_parity returning " . _hex_int($cw_with_parity));
	return $cw_with_parity;
}

#
#	Given the numeric destination address and function, generate an address codeword.
#

sub _address_codeword($$)
{
	my($in_addr, $function) = @_;
	
	# POCSAG recommendation 1.3.2
	# The three least significant bits are not transmitted but
	# serve to define the frame in which the address codeword
	# must be transmitted.
	# So we take them away.
	my $addr_frame_bits = $in_addr & 0x3;
	
	# shift address to right by two bits to remove the least significant
	# bits
	my $addr = $in_addr >> 3;
	
	# truncate address to 18 bits
	$addr &= 0x3FFFF;
	
	# truncate function to 2 bits
	$function &= 0x3;
	
	# codeword without parity
	my $codeword = ($addr << 13) | ($function << 11);
	
	_debug("  generated address codeword for $in_addr function $function: " . _hex_int($codeword));
	
	return _calculate_bch_and_parity($codeword);
}

#
#	Append a message content codeword to the message, calculating bch+parity for it
#

sub _append_message_codeword($$)
{
	my($posref, $word) = @_;
	
	$$posref++;
	
	return pack('N', _calculate_bch_and_parity($word | (1 << 31)));
}

#
#	Reverse the bits in a byte. Used to encode characters in a text message,
#	since the opposite order is used when transmitting POCSAG text.
#

sub _reverse_bits($)
{
	my($in) = @_;
	
	my $out = 0;
	
	for (my $i = 0; $i < 7; $i++) {
		$out |= (($in >> $i) & 1) << 6-$i;
	}
	
	return $out;
}

#
#	Append text message content to the transmission blob.
#

sub _append_content_text($)
{
	my($content) = @_;
	
	my $out = '';
	_debug("append_content_text: $content");
	
	my $l = length($content);
	my $bitpos = 0;
	my $word = 0;
	my $leftbits = 0;
	my $leftval = 0;
	my $pos = 0;
	
	# walk through characters in message
	for (my $i = 0; $i < $l; $i++) {
		# make sure it's 7 bits
		my $char = ord(substr($content, $i, 1)) & 0x7f;
		
		_debug("  char $i: $char");
		
		$char = _reverse_bits($char);
		
		# if the bits won't fit:
		if ($bitpos+7 > 20) {
			my $space = 20 - $bitpos;
			# leftbits least significant bits of $char are left over in the next word
			$leftbits = 7 - $space;
			$leftval = $char;
			_debug("  bits of char won't fit since bitpos is $bitpos, got $space bits free, leaving $leftbits bits in next word");
		}
		
		$word |= $char << (31 - 7 - $bitpos);
		$bitpos += 7;
		
		if ($bitpos >= 20) {
			_debug("   appending word: " . _hex_int($word));
			$out .= _append_message_codeword(\$pos, $word);
			$word = 0;
			$bitpos = 0;
		}
		
		if ($leftbits) {
			$word |= $char << (31 - $leftbits);
			$bitpos = $leftbits;
			$leftbits = 0;
		}
	}
	
	if ($bitpos) {
		_debug("  got $bitpos bits in word at end of text, word: " . _hex_int($word));
		my $step = 0;
		#_debug("  filling the word");
		while ($bitpos < 20) {
			#_debug("    bitpos $bitpos step $step");
			if ($step == 2) {
				#_debug("      setting to 1");
				$word |= 1 << (30 - $bitpos);
			}
			$bitpos++;
			$step++;
			$step = 0 if ($step == 7)
		}
		$out .= _append_message_codeword(\$pos, $word);
	}
	
	return ($pos, $out);
}

#
#	Append content to a message
#

sub _append_content($$)
{
	my($type, $content) = @_;
	
	if ($type eq 'a') {
		# alphanumeric
		return _append_content_text($content);
	} elsif ($type eq 'n') {
		# TODO: numeric message: unsupported
		return (0, '');
	}
}

#
#	Append a single message to the end of the transmission blob.
#

sub _append_message($$)
{
	my($startpos, $msg) = @_;
	
	# expand the parameters of the message
	my($addr, $function, $type, $content) = @{ $msg };
	
	_debug("append_message: addr $addr function $function type $type content $content");
	
	# the starting frame is selected based on the three least
	# significant bits
	my $frame_addr = $addr & 7;
	my $frame_addr_cw = $frame_addr * 2;
	
	_debug("  frame_addr is $frame_addr, current position $startpos");
	
	# append idle codewords, until we're in the right frame for this
	# address
	my $tx = '';
	my $pos = 0;
	while (($startpos + $pos) % 16 != $frame_addr_cw) {
		_debug("   inserting IDLE codewords in position " . ($startpos+$pos) . " (" . (($startpos + $pos) % 16) . ")");
		$tx .= $POCSAG_IDLE_CW;
		$pos++;
	}
	
	# Then, append the address codeword, containing the function and the address
	# (sans 3 least significant bits, which are indicated by the starting frame,
	# which the receiver is waiting for)
	$tx .= pack('N', _address_codeword($addr, $function));
	$pos++;
	
	# Next, append the message contents
	my($content_enc_len, $content_enc) = _append_content($type, $content);
	$tx .= $content_enc;
	$pos += $content_enc_len;
	
	# Return the current frame position and the binary string to be appended
	return ($pos, $tx);
}

#
#	Given a binary message string, insert Synchronisation Codeword
#	before every 8 POCSAG frames (frame is SC+ 64 bytes of address
#	and message codewords)
#

sub _insert_scs($)
{
	my($tx) = @_;
	
	my $out = '';
	_debug("insert_scs");
	
	# each batch is SC + 8 frames, each frame is 2 codewords,
	# each codeword is 32 bits, so we must insert an SC
	# every (8*2*32) bits == 64 bytes
	my $tx_len = length($tx);
	for (my $i = 0; $i < $tx_len; $i += 64) {
		# put in the CW and 64 the next 64 bytes
		$out .= $POCSAG_FS_CW . substr($tx, $i, 64);
	}
	
	return $out;
}

#
#	Select the optimal next message to be appended, trying to
#	minimize the amount of idle codewords transmitted
#

sub _select_msg($$)
{
	my($pos, $msglistref) = @_;
	
	my $current_pick;
	my $current_dist;
	my $pos_frame = int($pos/2) % 8;
	
	_debug("select_msg pos $pos: $pos_frame");
	
	my $i;
	for ($i = 0; $i <= $#{ $msglistref }; $i++) {
		my $addr = $msglistref->[$i]->[0];
		my $frame_addr = $addr & 7;
		my $distance = $frame_addr - $pos_frame;
		$distance += 8 if ($distance < 0);
		
		_debug("  considering list item $i: $addr - frame addr $frame_addr distance $distance");
		
		if ($frame_addr == $pos_frame) {
			_debug("  exact match $i: $addr - frame addr $frame_addr");
			return $i;
		}
		
		
		if (!defined $current_pick) {
			_debug("  first option $i: $addr - frame addr $frame_addr distance $distance");
			$current_pick = $i;
			$current_dist = $distance;
			next;
		}
		
		if ($distance < $current_dist) {
			_debug("  better option $i: $addr - frame addr $frame_addr distance $distance");
			$current_pick = $i;
			$current_dist = $distance;
		}
	}
	
	return $current_pick;
}

=over

=item generate()

Generates a transmission binary string.

 # list of messages to send
 my @msgs = (
    # address, function, type, message
    [ '12345', 0, 'a', 'Hello, world!' ]
 );

my($encoded, @left) = POCSAG::Encode::generate($piss_max_len, @msgs);

The function returns the binary string to be keyed over the air in FSK, and
any messages which did not fit in the transmission, given the maximum
transmission length (in bytes) given in the first parameter. They can be passed
in the next generate() call and sent in the next brrraaaap.

=back

=cut

sub generate($@)
{
	my $tx_without_scs = '';
	my $scs_len = length($POCSAG_PREAMBLE);
	
	my $maxlen = shift;
	my @msgs = @_;
	
	_debug("generate_transmission, maxlen: $maxlen");
	
	my($pos) = 0; # number of codewords appended currently
	while (@msgs) {
		# figure out an optimal next message to minimize the amount of required idle codewords
		# TODO: do a deeper search, considering the length of the message and a possible
		# optimal next recipient
		my $optimal_next_msg = _select_msg($pos, \@msgs);
		my $msg = splice(@msgs, $optimal_next_msg, 1);
		my($append_len, $append) = _append_message($pos, $msg);
		
		my $next_len = $pos + $append_len + 2; # two extra idle codewords in end
		# initial sync codeword + one for every 16 codewords
		$next_len += 1 + int(($next_len-1)/16);
		my $next_len_bytes = $next_len * 4;
		_debug("after this message of $append_len codewords, burst will be $next_len codewords and $next_len_bytes bytes long");
		
		if ($next_len_bytes > $maxlen) {
			if ($pos == 0) {
				_debug("burst would become too large ($next_len_bytes > $maxlen) with first message alone - discarding!");
			} else {
				_debug("burst would become too large ($next_len_bytes > $maxlen) - returning msg in queue");
				unshift @msgs, $msg;
				last;
			}
		} else {
			$tx_without_scs .= $append;
			$pos += $append_len;
		}
	}
	
	# if the burst is empty, return it as completely empty
	if ($pos == 0) {
		return ('', @msgs);
	}
	
	# append a couple of IDLE codewords, otherwise many pagers will
	# happily decode the junk in the end and show it to the recipient
	$tx_without_scs .= $POCSAG_IDLE_CW x 2;
	
	my $burst_len = length($tx_without_scs);
	_debug("transmission without SCs: $burst_len bytes, " . int($burst_len/4) . " codewords\n" . _hex_dump($tx_without_scs));
	
	# put SC every 8 frames
	my $burst = _insert_scs($tx_without_scs);
	
	$burst_len = length($burst);
	_debug("transmission with SCs: $burst_len bytes, " . int($burst_len/4) . " codewords\n" . _hex_dump($burst));
	
	return ($burst, @msgs);
}

=over

=item set_debug($enable)

Enables or disables debug printout in the module. Debug output goes to the standard error.

=back

=cut

sub set_debug($)
{
	$debug = ($_[0]);
}

1;

