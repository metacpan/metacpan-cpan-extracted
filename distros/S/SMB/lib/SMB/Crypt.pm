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

package SMB::Crypt;

use strict;
use warnings;

use bytes;

use Exporter 'import';
our @EXPORT = qw(des_crypt56 md4 md5 hmac_md5);

# lazy probing
our $has_Crypt_DES = undef;
our $has_Digest_MD4 = undef;
our $has_Digest_MD5 = undef;

sub has_Crypt_DES () {
	return 1 if $has_Crypt_DES;
	return 0 if defined $has_Crypt_DES;

	return $has_Crypt_DES = eval "require 'Crypt/DES.pm'";
}

sub has_Digest_MD4 () {
	return 1 if $has_Digest_MD4;
	return 0 if defined $has_Digest_MD4;

	return $has_Digest_MD4 = eval "require 'Digest/MD4.pm'";
}

sub has_Digest_MD5 () {
	return 1 if $has_Digest_MD5;
	return 0 if defined $has_Digest_MD5;

	return $has_Digest_MD5 = eval "require 'Digest/MD5.pm'";
}

# DES parts for SMB authentication, ported from samba auth/smbdes.c
# perm1[56], perm2[48], perm3[64], perm4[48], perm5[32], perm6[64],
# sc[16], sbox[8][4][16]

my $des_perm1 = [
	57, 49, 41, 33, 25, 17,  9,  1, 58, 50, 42, 34, 26, 18,
	10,  2, 59, 51, 43, 35, 27, 19, 11,  3, 60, 52, 44, 36,
	63, 55, 47, 39, 31, 23, 15,  7, 62, 54, 46, 38, 30, 22,
	14,  6, 61, 53, 45, 37, 29, 21, 13,  5, 28, 20, 12,  4,
];
my $des_perm2 = [
	14, 17, 11, 24,  1,  5,  3, 28, 15,  6, 21, 10,
	23, 19, 12,  4, 26,  8, 16,  7, 27, 20, 13,  2,
	41, 52, 31, 37, 47, 55, 30, 40, 51, 45, 33, 48,
	44, 49, 39, 56, 34, 53, 46, 42, 50, 36, 29, 32,
];
my $des_perm3 = [
	58, 50, 42, 34, 26, 18, 10,  2, 60, 52, 44, 36, 28, 20, 12,  4,
	62, 54, 46, 38, 30, 22, 14,  6, 64, 56, 48, 40, 32, 24, 16,  8,
	57, 49, 41, 33, 25, 17,  9,  1, 59, 51, 43, 35, 27, 19, 11,  3,
	61, 53, 45, 37, 29, 21, 13,  5, 63, 55, 47, 39, 31, 23, 15,  7,
];
my $des_perm4 = [
	32,  1,  2,  3,  4,  5,  4,  5,  6,  7,  8,  9,
	 8,  9, 10, 11, 12, 13, 12, 13, 14, 15, 16, 17,
   16, 17, 18, 19, 20, 21, 20, 21, 22, 23, 24, 25,
   24, 25, 26, 27, 28, 29, 28, 29, 30, 31, 32,  1,
];
my $des_perm5 = [
	16,  7, 20, 21, 29, 12, 28, 17,
	 1, 15, 23, 26,  5, 18, 31, 10,
	 2,  8, 24, 14, 32, 27,  3,  9,
	19, 13, 30,  6, 22, 11,  4, 25,
];
my $des_perm6 = [
	40,  8, 48, 16, 56, 24, 64, 32, 39,  7, 47, 15, 55, 23, 63, 31,
	38,  6, 46, 14, 54, 22, 62, 30, 37,  5, 45, 13, 53, 21, 61, 29,
	36,  4, 44, 12, 52, 20, 60, 28, 35,  3, 43, 11, 51, 19, 59, 27,
	34,  2, 42, 10, 50, 18, 58, 26, 33,  1, 41,  9, 49, 17, 57, 25,
];
my @des_sc = ( 1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1 );
my @des_sbox = (
	[
		[ 14,  4, 13,  1,  2, 15, 11,  8,  3, 10,  6, 12,  5,  9,  0,  7 ],
		[  0, 15,  7,  4, 14,  2, 13,  1, 10,  6, 12, 11,  9,  5,  3,  8 ],
		[  4,  1, 14,  8, 13,  6,  2, 11, 15, 12,  9,  7,  3, 10,  5,  0 ],
		[ 15, 12,  8,  2,  4,  9,  1,  7,  5, 11,  3, 14, 10,  0,  6, 13 ],
	],
	[
		[ 15,  1,  8, 14,  6, 11,  3,  4,  9,  7,  2, 13, 12,  0,  5, 10 ],
		[  3, 13,  4,  7, 15,  2,  8, 14, 12,  0,  1, 10,  6,  9, 11,  5 ],
		[  0, 14,  7, 11, 10,  4, 13,  1,  5,  8, 12,  6,  9,  3,  2, 15 ],
		[ 13,  8, 10,  1,  3, 15,  4,  2, 11,  6,  7, 12,  0,  5, 14,  9 ],
	],
	[
		[ 10,  0,  9, 14,  6,  3, 15,  5,  1, 13, 12,  7, 11,  4,  2,  8 ],
		[ 13,  7,  0,  9,  3,  4,  6, 10,  2,  8,  5, 14, 12, 11, 15,  1 ],
		[ 13,  6,  4,  9,  8, 15,  3,  0, 11,  1,  2, 12,  5, 10, 14,  7 ],
		[  1, 10, 13,  0,  6,  9,  8,  7,  4, 15, 14,  3, 11,  5,  2, 12 ],
	],
	[
		[  7, 13, 14,  3,  0,  6,  9, 10,  1,  2,  8,  5, 11, 12,  4, 15 ],
		[ 13,  8, 11,  5,  6, 15,  0,  3,  4,  7,  2, 12,  1, 10, 14,  9 ],
		[ 10,  6,  9,  0, 12, 11,  7, 13, 15,  1,  3, 14,  5,  2,  8,  4 ],
		[  3, 15,  0,  6, 10,  1, 13,  8,  9,  4,  5, 11, 12,  7,  2, 14 ],
	],
	[
		[  2, 12,  4,  1,  7, 10, 11,  6,  8,  5,  3, 15, 13,  0, 14,  9 ],
		[ 14, 11,  2, 12,  4,  7, 13,  1,  5,  0, 15, 10,  3,  9,  8,  6 ],
		[  4,  2,  1, 11, 10, 13,  7,  8, 15,  9, 12,  5,  6,  3,  0, 14 ],
		[ 11,  8, 12,  7,  1, 14,  2, 13,  6, 15,  0,  9, 10,  4,  5,  3 ],
	],
	[
		[ 12,  1, 10, 15,  9,  2,  6,  8,  0, 13,  3,  4, 14,  7,  5, 11 ],
		[ 10, 15,  4,  2,  7, 12,  9,  5,  6,  1, 13, 14,  0, 11,  3,  8 ],
		[  9, 14, 15,  5,  2,  8, 12,  3,  7,  0,  4, 10,  1, 13, 11,  6 ],
		[  4,  3,  2, 12,  9,  5, 15, 10, 11, 14,  1,  7,  6,  0,  8, 13 ],
	],
	[
		[  4, 11,  2, 14, 15,  0,  8, 13,  3, 12,  9,  7,  5, 10,  6,  1 ],
		[ 13,  0, 11,  7,  4,  9,  1, 10, 14,  3,  5, 12,  2, 15,  8,  6 ],
		[  1,  4, 11, 13, 12,  3,  7, 14, 10, 15,  6,  8,  0,  5,  9,  2 ],
		[  6, 11, 13,  8,  1,  4, 10,  7,  9,  5,  0, 15, 14,  2,  3, 12 ],
	],
	[
		[ 13,  2,  8,  4,  6, 15, 11,  1, 10,  9,  3, 14,  5,  0, 12,  7 ],
		[  1, 15, 13,  8, 10,  3,  7,  4, 12,  5,  6, 11,  0, 14,  9,  2 ],
		[  7, 11,  4,  1,  9, 12, 14,  2,  0,  6, 10, 13, 15,  3,  5,  8 ],
		[  2,  1, 14,  7,  4, 10,  8, 13, 15, 12,  9,  0,  3,  5,  6, 11 ],
	]
);

sub xor_inplace ($$) {
	my $a1 = shift;
	my $a2 = shift;

	for my $i (0 .. @$a1 - 1) {
		$a1->[$i] ^= $a2->[$i];
	}
}

sub des_str_to_key {
	my @str = map { ord($_) } split('', $_[0]);

	my @key = (
		0                       | ($str[0] >> 1),
		(($str[0] & 0x01) << 6) | ($str[1] >> 2),
		(($str[1] & 0x03) << 5) | ($str[2] >> 3),
		(($str[2] & 0x07) << 4) | ($str[3] >> 4),
		(($str[3] & 0x0F) << 3) | ($str[4] >> 5),
		(($str[4] & 0x1F) << 2) | ($str[5] >> 6),
		(($str[5] & 0x3F) << 1) | ($str[6] >> 7),
		(($str[6] & 0x7F) << 0) | 0,
	);
	$_ <<= 1 for @key;

	return join('', map { chr($_) } @key);
}

sub permute ($$) {
	my $a = shift;
	my $p = shift;

	return [ map { $a->[$_ - 1] } @$p ];
}

sub lshift ($$) {
	my $a = shift;
	my $count = shift() % @$a;

	@$a = ( @{$a}[$count .. @$a - 1], @{$a}[0 .. $count - 1] );
}

sub des_dohash ($$$) {
	my $arr = shift;
	my $key = shift;
	my $forw = shift;

	my $c = permute($key, $des_perm1);
	my $d = [ splice(@$c, 28) ];

	my @ki;
	for my $i (0 .. 15) {
		lshift($c, $des_sc[$i]);
		lshift($d, $des_sc[$i]);

		$ki[$i] = permute([ @$c, @$d ], $des_perm2);
	}

	my $l = permute($arr, $des_perm3);
	my $r = [ splice(@$l, 32) ];

	for my $i (0 .. 15) {
		my $er = permute($r, $des_perm4);

		xor_inplace($er, $ki[$forw ? $i : 15 - $i]);

		my @b;
		for my $j (0 .. 7) {
			$b[$j] = [];
			for my $k (0 .. 5) {
				$b[$j][$k] = $er->[$j * 6 + $k];
			}
		}

		for my $j (0 .. 7) {
			my $m = ($b[$j][0] << 1) | ($b[$j][5] << 0);
			my $n = ($b[$j][1] << 3) | ($b[$j][2] << 2) | ($b[$j][3] << 1) | ($b[$j][4] << 0);

			for my $k (0 .. 3) {
				$b[$j][$k] = $des_sbox[$j][$m][$n] & (1 << (3 - $k)) ? 1 : 0;
			}
		}

		my @cb;
		for my $j (0 .. 7) {
			for my $k (0 .. 3) {
				$cb[$j * 4 + $k] = $b[$j][$k];
			}
		}

		my $pcb = permute(\@cb, $des_perm5);

		xor_inplace($l, $pcb);

		($l, $r) = ($r, $l);
	}

	return permute([ @$r, @$l ], $des_perm6 );
}

sub des_crypt56 ($$;$) {
	my $data = shift // die "No 8-byte data to crypt";
	my $str  = shift // die "No 7-byte key to crypt";
	my $forw = shift // 1;

	if (has_Crypt_DES()) {
		return Crypt::DES->new(des_str_to_key($str))->encrypt($data);
	}

	my $arr = [ map { ord($_) } split '', $data ];
	my $key = [ map { ord($_) } split '', des_str_to_key($str) ];

	my $arrb = [];
	my $keyb = [];
	for my $i (0 .. 63) {
		$arrb->[$i] = $arr->[$i / 8] & (1 << (7 - $i % 8)) ? 1 : 0;
		$keyb->[$i] = $key->[$i / 8] & (1 << (7 - $i % 8)) ? 1 : 0;
	}

	my $outb = des_dohash($arrb, $keyb, $forw);

	my $out = [ (0) x 8 ];
	for my $i (0 .. 63) {
		$out->[$i / 8] |= 1 << (7 - $i % 8)
			if $outb->[$i];
	}

	return join('', map { chr($_) } @$out);
}

# MD4 parts for SMB authentication, ported from samba crypto/md4.c

our @md4_state;

sub md4_F { my ($x, $y, $z) = @_; return ($x & $y) | ((~$x) & $z); }
sub md4_G { my ($x, $y, $z) = @_; return ($x & $y) | ($x & $z) | ($y & $z); }
sub md4_H { my ($x, $y, $z) = @_; return $x ^ $y ^ $z; }

# uint32 arithmetic in perl, hopefully works on all platforms
sub add32 (@) {
	my @sum = (0, 0);
	for (@_) {
		$sum[0] += $_ & 0xFFFF;
		$sum[1] += ($_ >> 16) & 0xFFFF;
	}
	$sum[1] += $sum[0] >> 16;
	$sum[0] &= 0xFFFF;
	$sum[1] &= 0xFFFF;

	return ($sum[1] << 16) + $sum[0];
}

sub lshift32 ($$) {
	my ($num, $count) = @_;

	return (($num << $count) & 0xFFFFFFFF) | ($num >> (32 - $count));
}

sub md4_ROUND1 {
	my ($a, $b, $c, $d, $X, $s) = @_;

	$md4_state[$a] = lshift32(add32($md4_state[$a], md4_F(@md4_state[$b, $c, $d]), $X, 0x00000000), $s);
}

sub md4_ROUND2 {
	my ($a, $b, $c, $d, $X, $s) = @_;

	$md4_state[$a] = lshift32(add32($md4_state[$a], md4_G(@md4_state[$b, $c, $d]), $X, 0x5A827999), $s);
}

sub md4_ROUND3 {
	my ($a, $b, $c, $d, $X, $s) = @_;

	$md4_state[$a] = lshift32(add32($md4_state[$a], md4_H(@md4_state[$b, $c, $d]), $X, 0x6ED9EBA1), $s);
}

sub md4_64 (@) {
	my @old_state = @md4_state;

	md4_ROUND1(0, 1, 2, 3, $_[ 0],  3); md4_ROUND1(3, 0, 1, 2, $_[ 1],  7);
	md4_ROUND1(2, 3, 0, 1, $_[ 2], 11); md4_ROUND1(1, 2, 3, 0, $_[ 3], 19);
	md4_ROUND1(0, 1, 2, 3, $_[ 4],  3); md4_ROUND1(3, 0, 1, 2, $_[ 5],  7);
	md4_ROUND1(2, 3, 0, 1, $_[ 6], 11); md4_ROUND1(1, 2, 3, 0, $_[ 7], 19);
	md4_ROUND1(0, 1, 2, 3, $_[ 8],  3); md4_ROUND1(3, 0, 1, 2, $_[ 9],  7);
	md4_ROUND1(2, 3, 0, 1, $_[10], 11); md4_ROUND1(1, 2, 3, 0, $_[11], 19);
	md4_ROUND1(0, 1, 2, 3, $_[12],  3); md4_ROUND1(3, 0, 1, 2, $_[13],  7);
	md4_ROUND1(2, 3, 0, 1, $_[14], 11); md4_ROUND1(1, 2, 3, 0, $_[15], 19);

	md4_ROUND2(0, 1, 2, 3, $_[ 0],  3); md4_ROUND2(3, 0, 1, 2, $_[ 4],  5);
	md4_ROUND2(2, 3, 0, 1, $_[ 8],  9); md4_ROUND2(1, 2, 3, 0, $_[12], 13);
	md4_ROUND2(0, 1, 2, 3, $_[ 1],  3); md4_ROUND2(3, 0, 1, 2, $_[ 5],  5);
	md4_ROUND2(2, 3, 0, 1, $_[ 9],  9); md4_ROUND2(1, 2, 3, 0, $_[13], 13);
	md4_ROUND2(0, 1, 2, 3, $_[ 2],  3); md4_ROUND2(3, 0, 1, 2, $_[ 6],  5);
	md4_ROUND2(2, 3, 0, 1, $_[10],  9); md4_ROUND2(1, 2, 3, 0, $_[14], 13);
	md4_ROUND2(0, 1, 2, 3, $_[ 3],  3); md4_ROUND2(3, 0, 1, 2, $_[ 7],  5);
	md4_ROUND2(2, 3, 0, 1, $_[11],  9); md4_ROUND2(1, 2, 3, 0, $_[15], 13);

	md4_ROUND3(0, 1, 2, 3, $_[ 0],  3); md4_ROUND3(3, 0, 1, 2, $_[ 8],  9);
	md4_ROUND3(2, 3, 0, 1, $_[ 4], 11); md4_ROUND3(1, 2, 3, 0, $_[12], 15);
	md4_ROUND3(0, 1, 2, 3, $_[ 2],  3); md4_ROUND3(3, 0, 1, 2, $_[10],  9);
	md4_ROUND3(2, 3, 0, 1, $_[ 6], 11); md4_ROUND3(1, 2, 3, 0, $_[14], 15);
	md4_ROUND3(0, 1, 2, 3, $_[ 1],  3); md4_ROUND3(3, 0, 1, 2, $_[ 9],  9);
	md4_ROUND3(2, 3, 0, 1, $_[ 5], 11); md4_ROUND3(1, 2, 3, 0, $_[13], 15);
	md4_ROUND3(0, 1, 2, 3, $_[ 3],  3); md4_ROUND3(3, 0, 1, 2, $_[11],  9);
	md4_ROUND3(2, 3, 0, 1, $_[ 7], 11); md4_ROUND3(1, 2, 3, 0, $_[15], 15);

	$md4_state[$_] = add32($md4_state[$_], $old_state[$_]) for 0 .. 3;
}

sub md4_copy64 (@) {
	return map {
		($_[$_ * 4 + 3] << 24) |
		($_[$_ * 4 + 2] << 16) |
		($_[$_ * 4 + 1] <<  8) |
		($_[$_ * 4 + 0] <<  0)
	} 0 .. 15;
}

sub md4_copy4 ($) {
	my ($x) = @_;

	return (
		($x >>  0) & 0xFF,
		($x >>  8) & 0xFF,
		($x >> 16) & 0xFF,
		($x >> 24) & 0xFF,
	);
}

sub md4 ($) {
	if (has_Digest_MD4()) {
		return Digest::MD4::md4($_[0]);
	}

	my @in = map { ord($_) } split('', $_[0]);
	my $b = (@in * 8) & 0xFFFFFFFF;

	@md4_state = ( 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 );

	while (@in > 64) {
		md4_64(md4_copy64(splice(@in, 0, 64)));
	}

	my @buf = (@in, 0x80, (0) x (126 - @in));

	if (@in <= 55) {
		@buf[56 .. 59] = md4_copy4($b);
		md4_64(md4_copy64(@buf));
	} else {
		@buf[120 .. 123] = md4_copy4($b);
		md4_64(md4_copy64(splice(@buf, 0, 64)));
		md4_64(md4_copy64(@buf));
	}

	return join('', map { chr($_) } map { md4_copy4($_) } @md4_state)
}

# MD5 parts for SMB authentication, ported from samba crypto/md5.c

our @md5_state;

sub md5_F1 { $_[2] ^ ($_[0] & ($_[1] ^ $_[2])) }
sub md5_F2 { $_[1] ^ ($_[2] & ($_[0] ^ $_[1])) }
sub md5_F3 { $_[0] ^ $_[1] ^ $_[2] }
sub md5_F4 { $_[1] ^ ($_[0] | ~$_[2]) }

sub md5_pad64 {
	my $data = shift() . "\x80";

	my $len = length $data;
	$data .= "\0" x (($len % 64 <= 56 ? 56 : 120) - $len % 64);
	my $num_bits = ($len - 1) * 8;

	return $data . pack 'VV', $num_bits & 0xFFFFFFFF, $num_bits >> 32;
}

sub md5_STEP ($$$$$$$$) {
	my ($func, $a, $b, $c, $d, $X, $Y, $s) = @_;

	$md5_state[$a] = lshift32(add32($md5_state[$a], $func->($md5_state[$b], $md5_state[$c], $md5_state[$d]), $X, $Y), $s);
	$md5_state[$a] = add32($md5_state[$a], $md5_state[$b]);
}

sub md5_ROUND (@) {
	my @old_state = @md5_state;

	md5_STEP(\&md5_F1, 0, 1, 2, 3, $_[ 0], 0xd76aa478,  7);
	md5_STEP(\&md5_F1, 3, 0, 1, 2, $_[ 1], 0xe8c7b756, 12);
	md5_STEP(\&md5_F1, 2, 3, 0, 1, $_[ 2], 0x242070db, 17);
	md5_STEP(\&md5_F1, 1, 2, 3, 0, $_[ 3], 0xc1bdceee, 22);
	md5_STEP(\&md5_F1, 0, 1, 2, 3, $_[ 4], 0xf57c0faf,  7);
	md5_STEP(\&md5_F1, 3, 0, 1, 2, $_[ 5], 0x4787c62a, 12);
	md5_STEP(\&md5_F1, 2, 3, 0, 1, $_[ 6], 0xa8304613, 17);
	md5_STEP(\&md5_F1, 1, 2, 3, 0, $_[ 7], 0xfd469501, 22);
	md5_STEP(\&md5_F1, 0, 1, 2, 3, $_[ 8], 0x698098d8,  7);
	md5_STEP(\&md5_F1, 3, 0, 1, 2, $_[ 9], 0x8b44f7af, 12);
	md5_STEP(\&md5_F1, 2, 3, 0, 1, $_[10], 0xffff5bb1, 17);
	md5_STEP(\&md5_F1, 1, 2, 3, 0, $_[11], 0x895cd7be, 22);
	md5_STEP(\&md5_F1, 0, 1, 2, 3, $_[12], 0x6b901122,  7);
	md5_STEP(\&md5_F1, 3, 0, 1, 2, $_[13], 0xfd987193, 12);
	md5_STEP(\&md5_F1, 2, 3, 0, 1, $_[14], 0xa679438e, 17);
	md5_STEP(\&md5_F1, 1, 2, 3, 0, $_[15], 0x49b40821, 22);

	md5_STEP(\&md5_F2, 0, 1, 2, 3, $_[ 1], 0xf61e2562,  5);
	md5_STEP(\&md5_F2, 3, 0, 1, 2, $_[ 6], 0xc040b340,  9);
	md5_STEP(\&md5_F2, 2, 3, 0, 1, $_[11], 0x265e5a51, 14);
	md5_STEP(\&md5_F2, 1, 2, 3, 0, $_[ 0], 0xe9b6c7aa, 20);
	md5_STEP(\&md5_F2, 0, 1, 2, 3, $_[ 5], 0xd62f105d,  5);
	md5_STEP(\&md5_F2, 3, 0, 1, 2, $_[10], 0x02441453,  9);
	md5_STEP(\&md5_F2, 2, 3, 0, 1, $_[15], 0xd8a1e681, 14);
	md5_STEP(\&md5_F2, 1, 2, 3, 0, $_[ 4], 0xe7d3fbc8, 20);
	md5_STEP(\&md5_F2, 0, 1, 2, 3, $_[ 9], 0x21e1cde6,  5);
	md5_STEP(\&md5_F2, 3, 0, 1, 2, $_[14], 0xc33707d6,  9);
	md5_STEP(\&md5_F2, 2, 3, 0, 1, $_[ 3], 0xf4d50d87, 14);
	md5_STEP(\&md5_F2, 1, 2, 3, 0, $_[ 8], 0x455a14ed, 20);
	md5_STEP(\&md5_F2, 0, 1, 2, 3, $_[13], 0xa9e3e905,  5);
	md5_STEP(\&md5_F2, 3, 0, 1, 2, $_[ 2], 0xfcefa3f8,  9);
	md5_STEP(\&md5_F2, 2, 3, 0, 1, $_[ 7], 0x676f02d9, 14);
	md5_STEP(\&md5_F2, 1, 2, 3, 0, $_[12], 0x8d2a4c8a, 20);

	md5_STEP(\&md5_F3, 0, 1, 2, 3, $_[ 5], 0xfffa3942,  4);
	md5_STEP(\&md5_F3, 3, 0, 1, 2, $_[ 8], 0x8771f681, 11);
	md5_STEP(\&md5_F3, 2, 3, 0, 1, $_[11], 0x6d9d6122, 16);
	md5_STEP(\&md5_F3, 1, 2, 3, 0, $_[14], 0xfde5380c, 23);
	md5_STEP(\&md5_F3, 0, 1, 2, 3, $_[ 1], 0xa4beea44,  4);
	md5_STEP(\&md5_F3, 3, 0, 1, 2, $_[ 4], 0x4bdecfa9, 11);
	md5_STEP(\&md5_F3, 2, 3, 0, 1, $_[ 7], 0xf6bb4b60, 16);
	md5_STEP(\&md5_F3, 1, 2, 3, 0, $_[10], 0xbebfbc70, 23);
	md5_STEP(\&md5_F3, 0, 1, 2, 3, $_[13], 0x289b7ec6,  4);
	md5_STEP(\&md5_F3, 3, 0, 1, 2, $_[ 0], 0xeaa127fa, 11);
	md5_STEP(\&md5_F3, 2, 3, 0, 1, $_[ 3], 0xd4ef3085, 16);
	md5_STEP(\&md5_F3, 1, 2, 3, 0, $_[ 6], 0x04881d05, 23);
	md5_STEP(\&md5_F3, 0, 1, 2, 3, $_[ 9], 0xd9d4d039,  4);
	md5_STEP(\&md5_F3, 3, 0, 1, 2, $_[12], 0xe6db99e5, 11);
	md5_STEP(\&md5_F3, 2, 3, 0, 1, $_[15], 0x1fa27cf8, 16);
	md5_STEP(\&md5_F3, 1, 2, 3, 0, $_[ 2], 0xc4ac5665, 23);

	md5_STEP(\&md5_F4, 0, 1, 2, 3, $_[ 0], 0xf4292244,  6);
	md5_STEP(\&md5_F4, 3, 0, 1, 2, $_[ 7], 0x432aff97, 10);
	md5_STEP(\&md5_F4, 2, 3, 0, 1, $_[14], 0xab9423a7, 15);
	md5_STEP(\&md5_F4, 1, 2, 3, 0, $_[ 5], 0xfc93a039, 21);
	md5_STEP(\&md5_F4, 0, 1, 2, 3, $_[12], 0x655b59c3,  6);
	md5_STEP(\&md5_F4, 3, 0, 1, 2, $_[ 3], 0x8f0ccc92, 10);
	md5_STEP(\&md5_F4, 2, 3, 0, 1, $_[10], 0xffeff47d, 15);
	md5_STEP(\&md5_F4, 1, 2, 3, 0, $_[ 1], 0x85845dd1, 21);
	md5_STEP(\&md5_F4, 0, 1, 2, 3, $_[ 8], 0x6fa87e4f,  6);
	md5_STEP(\&md5_F4, 3, 0, 1, 2, $_[15], 0xfe2ce6e0, 10);
	md5_STEP(\&md5_F4, 2, 3, 0, 1, $_[ 6], 0xa3014314, 15);
	md5_STEP(\&md5_F4, 1, 2, 3, 0, $_[13], 0x4e0811a1, 21);
	md5_STEP(\&md5_F4, 0, 1, 2, 3, $_[ 4], 0xf7537e82,  6);
	md5_STEP(\&md5_F4, 3, 0, 1, 2, $_[11], 0xbd3af235, 10);
	md5_STEP(\&md5_F4, 2, 3, 0, 1, $_[ 2], 0x2ad7d2bb, 15);
	md5_STEP(\&md5_F4, 1, 2, 3, 0, $_[ 9], 0xeb86d391, 21);

	$md5_state[$_] = add32($md5_state[$_], $old_state[$_]) for 0 .. 3;
}

sub md5 ($;$) {
	if (has_Digest_MD5()) {
		return Digest::MD5::md5(join '', @_);
	}

	my $data = md5_pad64(join '', @_);

	@md5_state = ( 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 );

	for my $i (0 .. length($data) / 64 - 1) {
		md5_ROUND(unpack 'V16', substr $data, $i * 64, 64);
	}

	pack 'V4', @md5_state;
}

sub hmac_md5 ($$) {
	my ($data, $key) = @_;

	$key = md5($key) if length($key) > 64;

	my $ipad = $key ^ ("\x36" x 64);
	my $opad = $key ^ ("\x5c" x 64);

	return md5($opad, md5($ipad, $data));
}

1;

__END__
# ----------------------------------------------------------------------------

=head1 NAME

SMB::Crypt - Fallback implementations of cryptography algorithms for SMB

=head1 SYNOPSIS

	use SMB::Crypt qw(md4 md5);

	my $digest1 = md4($data);

	my $digest2 = md5($data);

=head1 ABSTRACT

This module provides fallback implementations for DES, MD4 and MD5 in
pure perl to reduce dependence on non-standard perl modules.

However it is recommended to install L<Crypt::DES>, L<Digest::MD4> and
L<Digest::MD5> modules to get improved performance.

=head1 EXPORTED FUNCTIONS

By default, functions B<des_crypt56>, B<md4>, B<md5> and B<hmac_md5> are exported using the standard L<Exporter> mechanism.

=over 4

=item des_crypt56 EIGHT_BYTE_INPUT SEVEN_BYTE_KEY_STR [FORWARD=1]

Returns output of eight bytes that is a permutation of the input according to a key.

If L<Crypt::DES> is found, it is used, otherwise pure perl fallback implemenation is used.

=item md4 DATA

Returns digest of 16 bytes, similar to Digest::MD4::md4.

If L<Digest::MD4> is found, it is used, otherwise pure perl fallback implemenation is used.

=item md5 DATA ...

Returns digest of 16 bytes, similar to Digest::MD5::md5.

If L<Digest::MD5> is found, it is used, otherwise pure perl fallback implemenation is used.

=item hmac_md5 DATA KEY

Returns digest of 16 bytes, similar to Digest::HMAC_MD5::hmac_md5. Uses B<md5> internally.

=back

=head1 AUTHOR

Mikhael Goikhman <migo@cpan.org>

=head1 ACKNOWLEGDEMENTS

Ported from samba project.

