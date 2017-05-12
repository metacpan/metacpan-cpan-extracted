package Net::IP::Lite;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed);

use base 'Exporter';

our @EXPORT = qw(
	ip2bin ip_validate ip_is_ipv4 ip_is_ipv6 ip_is_ipv6ipv4
	ip_transform ip_equal ip_equal_v4 ip_equal_v6 ip_in_range
);

use constant IPV6IPV4HEAD => '0' x 80 . '1' x 16;

our $VERSION = '0.03';

sub _wrong_ip {
	my $addr = shift;
	$addr = 'UNDEFINED' unless defined $addr;
	return "Wrong IP address: '$addr'";
}

sub _wrong_ipv6ipv4 {
	my $addr = shift;
	$addr = 'UNDEFINED' unless defined $addr;
	return "Failed to convert IPv6 address '$addr' to IPv4 address";
}

sub _wrong_net {
	my $net = shift;
	$net = 'UNDEFINED' unless defined $net;
	return "Wrong network definition: '$net'";
}

sub ip2bin {
	my $addr = shift;
	return '' unless defined $addr;

	my $bin = '';

	if ($addr =~ /:/) {
		# IPv6 address

		return '0' x 128 if $addr eq '::';

		return '' if $addr =~ s/^:// && $addr !~ /^:/;
		return '' if $addr =~ s/:$// && $addr !~ /:$/;

		my @words = split(/:/, $addr, -1);
		my $words_amount = scalar @words;

		# IPv4 representation
		$words_amount++ if $addr =~ /\./;

		my $reduct = 0;
		my $i = 0;
		for my $word (@words) {
			$i++;
			if ($word =~ /\./) {
				# IPv4 representation
				return '' if $i != scalar @words || $bin ne IPV6IPV4HEAD;
				my @octets = split(/\./, $word);
				return '' if scalar @octets != 4;
				for my $octet (@octets) {
					return '' if $octet !~ /^\d+$/ || $octet > 255;
					$bin .= unpack('B8', pack('C', $octet));
				}
				return $bin;
			} elsif (!length $word) {
				return '' if $reduct;
				$reduct = 1;
				my $len = (9 - $words_amount) << 4;
				return '' unless $len;
				$bin .= '0' x ((9 - $words_amount) << 4);
			} elsif ($word =~ /^[0-9a-f]+$/i) {
				$word =~ s/^0+//i;
				return '' if length($word) > 4;
				my $int = hex($word);
				$bin .= unpack('B16', pack('n', $int));
			} else {
				return '';
			}
			return '' if length($bin) > 128;
		}
		return '' if length($bin) < 128;
	} elsif ($addr =~ /\./) {
		# IPv4
		my @octets = split(/\./, $addr, -1);
		return '' if scalar @octets > 4;
		my $i = 0;
		for my $octet (@octets) {
			$i++;
			my $dec;
			if ($octet =~ /^0[0-7]+$/) {
				# Octal octet
				$octet =~ s/^0+//;
				return '' if length($octet) > 3;
				$dec = oct($octet);
			} elsif ($octet =~ /^\d+$/) {
				# Decimal octet
				return '' if length($octet) > 3;
				$dec = $octet;
			} elsif ($octet =~ /^0x[0-9a-f]+$/i) {
				# Hexadecimal octet
				$octet =~ s/^0x0*//i;
				return '' if length($octet) > 2;
				$dec = hex($octet);
			} else {
				return '';
			}
			return '' if $dec > 255;
			if ($i == scalar @octets && $i < 4) {
				# add missed octets
				$bin .= '0' x ((4 - $i) << 3);
			}
			$bin .= unpack('B8', pack('C', $dec));
		}
	} elsif ($addr =~ /^0[0-7]+$/) {
		# Octal IPv4 address
		$addr =~ s/^0+//i;
		return '' if $addr > 37777777777;
		my $int = oct($addr);
		$bin = unpack('B32', pack('N', $int));
	} elsif ($addr =~ /^\d+$/) {
		# Decimal IPv4 address
		return '' if $addr > 4294967295;
		$bin = unpack('B32', pack('N', $addr));
	} elsif ($addr =~ /^0x[0-9a-f]+$/i) {
		# Hexadecimal IPv4 addres
		$addr =~ s/^0x0*//i;
		return '' if length($addr) > 8;
		my $int = hex($addr);
		$bin = unpack('B32', pack('N', $int));
	}
	return $bin;
}

sub _ip_validate {
	return length(shift) > 0;
}

sub ip_validate {
	return _ip_validate(ip2bin(shift)) > 0;
}

sub _ip_is_ipv4 {
	return length(shift) eq 32;
}

sub ip_is_ipv4 {
	return _ip_is_ipv4(ip2bin(shift));
}

sub _ip_type_equal {
	return length(shift) == length(shift);
}

sub _ip_is_ipv6 {
	return length(shift) eq 128;
}

sub ip_is_ipv6 {
	return _ip_is_ipv6(ip2bin(shift));
}

sub _ip_is_ipv6ipv4 {
	return substr(shift, 0, 96) eq IPV6IPV4HEAD;
}

sub ip_is_ipv6ipv4 {
	return _ip_is_ipv6ipv4(ip2bin(shift));
}

sub _bin2ipv6 {
	my ($bin, $lead_zeros, $short) = @_;
	my $result = '';
	my @chunks = $bin =~ m/[0..1]{16}/g;

	my $short_len = 0;
	if ($short) {
		my @zero_chunks;
		my $i = 0;
		for my $chunk (@chunks) {
			if ($chunk !~ /1/) {
				$zero_chunks[$i]++;
			} else {
				$i++ if defined $zero_chunks[$i];
			}
		}
		@zero_chunks = sort @zero_chunks;
		$short_len = pop @zero_chunks if scalar @zero_chunks;
	}
	for my $chunk (@chunks) {
		my $word = unpack('H4', pack('B16', $chunk)) . ':';
		$word =~ s/^0{1,3}// unless $lead_zeros;
		$result .= $word;
	}

	$result =~ s/(^|:)(0{1,4}:){$short_len}/::/ if $short_len > 1;
	$result =~ s/:$// if $result !~ /::$/;
	return $result;
}

sub _bin2ipv4 {
	my ($bin, $format, $lead_zeros, $short) = @_;

	$format ||= '';
	my @chunks = $bin =~ m/[0..1]{8}/g;

	if ($format =~ /^(D|O|X)$/) {
		my $result = 0;
		my $i = 0;
		for my $chunk (reverse @chunks) {
			$result += unpack('C', pack('B8', $chunk)) << $i;
			$i +=8;
		}

		return sprintf("%#1o", $result) if $format eq 'O';
		return sprintf("0x%.8x", $result) if $format eq 'X' && $lead_zeros;
		return sprintf("0x%x", $result) if $format eq 'X';
		return $result;
	} else {
		my $result = '';
		my $f = '';
		if ($format eq 'o') {
			$f = '%#.1o';
		} elsif ($format eq 'x') {
			$f = $lead_zeros ? '0x%.2x' : '0x%x' ;
		}

		my $i = 4;
		for my $chunk (reverse @chunks) {
			$i--;
			my $octet = unpack('C', pack('B8', $chunk));
			if ($short) {
				next if (!$octet && $i && $i < 3 );
				$short = 0 if $i == 2;
			}
			if ($format eq 'o') {
				$octet = sprintf($f, $octet);
			} elsif ($format eq 'x') {
				$octet = sprintf($f, $octet);
			}
			$result = "$octet.$result";
		}
		$result =~ s/\.$//;
		return $result;
	} 
}

sub _reverse {
	my $bin = shift;
	my $len = _ip_is_ipv4($bin) ? 8 : 16;
	my @chunks = $bin =~ m/[0..1]{$len}/g;
	return join('', reverse @chunks);
}

sub _ip_transform {
	my ($bin, $opts) = @_;

	my $format = $opts->{format_ipv4} || '';
	my $convert_to = $opts->{convert_to} || '';

	my $ipv6;
	my $ipv4;

	if ($convert_to eq 'ipv4' && _ip_is_ipv6ipv4($bin)) {
		# convert ipv6ipv4 to ipv4
		$bin = substr($bin, 96, 32);
	}

	if (($convert_to eq 'ipv6' || $convert_to eq 'ipv6ipv4') && _ip_is_ipv4($bin)) {
		# convert ipv4 to ipv6
		$bin = IPV6IPV4HEAD . $bin;
	}

	if ($convert_to eq 'ipv6ipv4' && _ip_is_ipv6ipv4($bin)) {
		# convert ipv4 to ipv6ipv4
		$ipv4 = substr($bin, 96, 32);
		$ipv4 = _reverse($ipv4) if $opts->{reverse};
		$bin = IPV6IPV4HEAD;
	} else {
		$bin = _reverse($bin) if $opts->{reverse};
	}

	my $result = '';
	if (length($bin) > 32) {
		# IPv6
		$result = _bin2ipv6($bin, $opts->{lead_zeros}, $opts->{short_ipv6});
		if ($ipv4) {
			$bin = $ipv4;
			$ipv6 = $result;
		}
	}

	if (length($bin) == 32) {
		# IPv4
		if ($ipv6) {
			$result = "$ipv6:" . _bin2ipv4($bin);
		} else {
			$result = _bin2ipv4($bin, $format, $opts->{lead_zeros}, $opts->{short_ipv4});
		}
	}

	return $result;
}

sub ip_transform {
	my ($addr, $opts) = @_;

	$opts ||= {};
	croak 'Options must be a hash' unless ref($opts) eq 'HASH';

	my $bin = ip2bin($addr);
	croak _wrong_ip($addr) unless _ip_validate($bin);
	return _ip_transform($bin, $opts);
}

sub _ip_equal {
	my ($bin1, $bin2) = @_;
	return $bin1 eq $bin2;
}

sub ip_equal {
	my ($addr1, $addr2) = @_;
	my $bin1 = ip2bin($addr1);
	my $bin2 = ip2bin($addr2);

	croak _wrong_ip($addr1) unless _ip_validate($bin1);
	croak _wrong_ip($addr2) unless _ip_validate($bin2);

	return $bin1 eq $bin2;
}

sub _ip_equal_v4 {
	my ($bin1, $bin2) = @_;
	$bin1 = substr($bin1, 96, 32) if _ip_is_ipv6ipv4($bin1);
	$bin2 = substr($bin2, 96, 32) if _ip_is_ipv6ipv4($bin2);
	return _ip_equal($bin1, $bin2);
}

sub ip_equal_v4 {
	my ($addr1, $addr2) = @_;
	my $bin1 = ip2bin($addr1);
	my $bin2 = ip2bin($addr2);

	croak _wrong_ip($addr1) unless _ip_validate($bin1);
	croak _wrong_ip($addr2) unless _ip_validate($bin2);

	if ((_ip_is_ipv6($bin1) && ! _ip_is_ipv6ipv4($bin1))) {
		croak _wrong_ipv6ipv4($addr1);
	}

	if ((_ip_is_ipv6($bin2) && ! _ip_is_ipv6ipv4($bin2))) {
		croak _wrong_ipv6ipv4($addr2);
	}

	return _ip_equal_v4($bin1, $bin2);
}

sub _ip_equal_v6 {
	my ($bin1, $bin2) = @_;
	$bin1 = IPV6IPV4HEAD . $bin1 if _ip_is_ipv4($bin1);
	$bin2 = IPV6IPV4HEAD . $bin2 if _ip_is_ipv4($bin2);
	return _ip_equal($bin1, $bin2);
}

sub ip_equal_v6 {
	my ($addr1, $addr2) = @_;
	my $bin1 = ip2bin($addr1);
	my $bin2 = ip2bin($addr2);

	croak _wrong_ip($addr1) unless _ip_validate($bin1);
	croak _wrong_ip($addr2) unless _ip_validate($bin2);

	return _ip_equal_v6($bin1, $bin2);
}

sub __ip_in_range {
	my ($bin_addr, $bin_net, $bin_mask) = @_;

	my @addr_bits = split(//, $bin_addr);
	my @mask_bits = split(//, $bin_mask);
	my $result = '';

	my $i = 0;
	for my $bit (@addr_bits) {
		$result	.= $bit & $mask_bits[$i];
		$i++;
	}

	return _ip_equal($bin_net, $result);
}

sub _ip_in_range {
	my ($bin_addr, $net, $addr) = @_;

	my $bin_net;
	my $bin_mask;

	if ($net =~ /^(.+)\/(\d+)$/) {
		my $mask = $2;
		$bin_net = ip2bin($1);
		croak _wrong_net($net) unless _ip_validate($bin_net);

		my $mask_len = _ip_is_ipv4($bin_net) ? 32 : 128;
		croak _wrong_net($net) if $mask > $mask_len;

		$bin_mask = '1' x $mask . '0' x ($mask_len - $mask);
	} elsif ($net =~ /^(\S+)\s+(\S+)$/) {
		$bin_net = ip2bin($1);
		$bin_mask = ip2bin($2);
	} else {
		$bin_net = ip2bin($net);
		$bin_mask = '1' x (_ip_is_ipv4($bin_net) ? 32 : 128);
	}

	unless (_ip_validate($bin_net) && _ip_validate($bin_mask) && _ip_type_equal($bin_net, $bin_mask)) {
		croak _wrong_net($net);
	}

	return 0 unless _ip_type_equal($bin_addr, $bin_net);

	return __ip_in_range($bin_addr, $bin_net, $bin_mask);
}

sub ip_in_range {
	my ($addr, $range) = @_;

	croak _wrong_net($range) unless defined $range;

	if (ref($range) eq 'ARRAY') {
		for my $net (@$range) {
			return 1 if ip_in_range($addr, $net);
		}
		return 0;
	} 

	my $bin_addr = ip2bin($addr);
	croak _wrong_ip($addr) unless _ip_validate($bin_addr);

	return _ip_in_range($bin_addr, $range, $addr);
}

sub new {
	my ($class, $addr) = @_;

	my $bin = ip2bin($addr);
	return 0 unless _ip_validate($bin);

	my $self = { 
		bin => $bin,
		addr => $addr
	};

	bless $self, $class;
	return $self;
}

sub _set_binary {
	my ($self, $bin) = @_;
	$self->{bin} = $bin;
	$self->{addr} = $self->transform();
}

sub address {
	my $self = shift;
	return $self->{addr};
}

sub binary {
	my $self = shift;
	return $self->{bin};
}

sub is_ipv4 {
	my $self = shift;
	return _ip_is_ipv4($self->binary);
}

sub is_ipv6 {
	my $self = shift;
	return _ip_is_ipv6($self->binary);
}

sub is_ipv6ipv4 {
	my $self = shift;
	return _ip_is_ipv6ipv4($self->binary);
}

sub transform {
	my ($self, $opts) = @_;
	$opts ||= {};
	croak 'Options must be a hash' unless ref($opts) eq 'HASH';
	return _ip_transform($self->binary, $opts);
}

sub equal {
	my ($self, $addr) = @_;

	if (blessed($addr) && $addr->isa('Net::IP::Lite')) {
		return _ip_equal($self->binary, $addr->binary);
	}

	my $bin2 = ip2bin($addr);
	croak _wrong_ip($addr) unless _ip_validate($bin2);

	return _ip_equal($self->binary, $bin2);
}

sub equal_v4 {
	my ($self, $addr) = @_;

	my $bin2 = (blessed($addr) && $addr->isa('Net::IP::Lite')) ? $addr->binary : ip2bin($addr);
	croak _wrong_ip($addr) unless _ip_validate($bin2);

	if (($self->is_ipv6() && ! $self->is_ipv6ipv4())) {
		croak _wrong_ipv6ipv4($self->address);
	}

	if ((_ip_is_ipv6($bin2) && ! _ip_is_ipv6ipv4($bin2))) {
		croak _wrong_ipv6ipv4($addr);
	}

	return _ip_equal_v4($self->binary, $bin2);
}

sub equal_v6 {
	my ($self, $addr) = @_;

	my $bin2 = (blessed($addr) && $addr->isa('Net::IP::Lite')) ? $addr->binary : ip2bin($addr);

	croak _wrong_ip($addr) unless _ip_validate($bin2);

	return _ip_equal_v6($self->binary, $bin2);
}

sub in_range {
	my ($self, $range) = @_;

	croak _wrong_net($range) unless defined $range;

	if (ref($range) eq 'ARRAY') {
		for my $net (@$range) {
			return 1 if $self->in_range($net);
		}
		return 0;
	} 

	if (blessed($range) && $range->isa('Net::IP::Lite::Net')) {
		return $range->contains($self);
	}

	return _ip_in_range($self->binary, $range, $self->address);
}

package Net::IP::Lite::Net;
use Carp qw(croak);
use Scalar::Util qw(blessed);

use base qw(Net::IP::Lite);

sub new {
	my ($class, $net) = @_;

	return 0 unless defined $net;

	my $self = {};
	my $bin_mask;

	if ($net =~ /^(.+)\/(\d+)$/) {
		my $mask = $2;
		$self = $class->SUPER::new($1);

		my $mask_len = $self->is_ipv4() ? 32 : 128;
		return 0 if $mask > $mask_len;

		$bin_mask = '1' x $mask . '0' x ($mask_len - $mask);
	} elsif ($net =~ /^(\S+)\s+(\S+)$/) {
		$self = $class->SUPER::new($1);
		return 0 unless $self;
		$self->{mask} = Net::IP::Lite->new($2);
	} else {
		$self = $class->SUPER::new($net);
		return 0 unless $self;
		$bin_mask = '1' x ($self->is_ipv4 ? 32 : 128);
	}

	if ($bin_mask) {
		if (length($bin_mask) == 32) {
			$self->{mask} = Net::IP::Lite->new(Net::IP::Lite::_bin2ipv4($bin_mask));
		} else {
			$self->{mask} = Net::IP::Lite->new(Net::IP::Lite::_bin2ipv6($bin_mask));
		}
	}

	return 0 unless $self->{mask};

	my $ipv4_mask = $self->{mask}->is_ipv4;
	return 0 unless (($self->is_ipv4 && $ipv4_mask) || ($self->is_ipv6 && ! $ipv4_mask));

	$self->{net} = $net;
	return $self;
}

sub mask {
	my ($self) = @_;
	return $self->{mask};
}

sub network {
	my ($self) = @_;
	return $self->{net};
}

sub contains {
	my ($self, $addr) = @_;

	if (blessed($addr) && $addr->isa('Net::IP::Lite')) {
		return 0 unless Net::IP::Lite::_ip_type_equal($self->binary, $addr->binary);
		return Net::IP::Lite::__ip_in_range($addr->binary, $self->binary, $self->mask->binary);
	} else {
		my $bin_addr = Net::IP::Lite::ip2bin($addr);
		croak Net::IP::Lite::_wrong_ip($addr) unless Net::IP::Lite::_ip_validate($bin_addr);
		return 0 unless Net::IP::Lite::_ip_type_equal($self->binary, $bin_addr);
		return Net::IP::Lite::__ip_in_range($bin_addr, $self->binary, $self->mask->binary);
	}
}


1;

__END__

=head1 NAME

Net::IP::Lite - Perl extension for manipulating IPv4/IPv6 addresses

=head1 SYNOPSIS

	use Net::IP::Lite;

	print ip2bin('127.0.0.1') . "\n";
	print ip_validate('127.0.0.1') . "\n";

	print ip_is_ipv4('127.0.0.1') . "\n";
	print ip_is_ipv6('::1') . "\n";
	print ip_is_ipv6ipv4('::ffff:7f00:1') . "\n";

	print ip_transform('127.0.0.1', {
		convert_to => 'ipv6ipv4',
		short_ipv6 => 1 }
	) . "\n";

	print ip_equal('0x7f000001', '127.0.0.1') . "\n";
	print ip_equal_v4('0x7f000001', '::ffff:127.0.0.1') . "\n";
	print ip_equal_v6('0x7f000001', '::ffff:127.0.0.1') . "\n";

	print ip_in_range('127.0.0.1', '127.0.0.1/8') . "\n";
	print ip_in_range('127.0.0.1', [
		'127.0.0.1/8',
		'10.0.0.0 255.255.255.255'
	]) . "\n";

	my $ip = Net::IP::Lite->new('127.0.0.1') || die 'Invalid IP address';
	print $ip->binary . "\n";
	print $ip->address . "\n";

	print $ip->is_ipv4('127.0.0.1') . "\n";
	print $ip->is_ipv6('::1') . "\n";
	print $ip->is_ipv6ipv4('::ffff:7f00:1') . "\n";

	print $ip->transform({
		convert_to => 'ipv6ipv4',
		short_ipv6 => 1
	}) . "\n";

	print $ip->equal('0x7f000001', '127.0.0.1') . "\n";
	print $ip->equal('0x7f000001', Net::IP::Lite->new('127.1')) . "\n";
	print $ip->equal_v4('0x7f000001', '::ffff:127.0.0.1') . "\n";
	print $ip->equal_v6('0x7f000001', '::ffff:127.0.0.1') . "\n";

	print $ip->in_range('127.0.0.1', '127.0.0.1/8') . "\n";
	print $ip->in_range('127.0.0.1', [
		'127.0.0.1/8',
		'10.0.0.0 255.0.0.0',
		Net::IP::Lite::Net->new('10.0.0.0/8')
	]) . "\n";

	my $net = Net::IP::Lite::Net->new('10.0.0.0/8') || die ...;
	print $net->address() . "\n";
	print $net->mask->address() . "\n";
	print $net->contains('10.1.1.1') . "\n";

=head1 DESCRIPTION

This is another module to manipulate B<IPv4/IPv6> addresses.
In contrast of NET::IP, it does not require Math::BigInt. Also, it supports
some additional IPv4 formats like 0x7f000001, 2130706433, 017700000001,
0177.0.0.1, 0x7f.0.0.0x1.

The module provides the following capabilities:

=over

=item * validating IP addresses;

=item * converting IP addresses in different format;

=item * comparing IP addresses;

=item * verifying whether an IP is an IPv4 or an IPv6 or an IPv4-embedded IPv6 address;

=item * verifying whether an IP is in a range.

=back

Most subroutines have two implementations, so you can use procedural
or object-oriented approach.

=head1 SUPPORTED FORMATS

You can use any IPv4 and IPv6 formats:

=over

=item * 127.0.0.1, 127.0.1, 127.1 (IPv4 with decimal octets);

=item * 0177.0.0.1, 0177.0.1, 0177.1 (IPv4 with octal octets);

=item * 0x7f.0x0.0x0.0x1, 0x7f.0x0.0x1, 0x7f.0x1 (IPv4 with hexadecimal octets);

=item * 0177.0.0.1, 0x7f.0.1, 0177.0x1 (IPv4 with mixed octets);

=item * 2130706433 (decimal IPv4);

=item * 0x7f000001 (hexadecimal IPv4);

=item * 017700000001 (octal IPv4);

=item * 0:0:0:0:0:0:0:1, ::, ::1 (IPv6);

=item * 0:0:0:0:0:ffff:127.0.0.1, ::ffff:127.0.0.1 (IPv4-embedded IPv6 address).

=back

=head1 PROCEDURAL INTERFACE

=head2 ip2bin

Returns a string that contains binary representation of an IP address.
Returns the empty string if an invalid IP address is specified.

	$ip = ip2bin('127.0.0.1'); # '01111111000000000000000000000001'
	$ip = ip2bin('::1');       # '0' x 127 . '1'
	$ip = ip2bin('::1:');      # ''

=head2 ip_validate

Returns TRUE if the specified IP address is a valid, or FALSE otherwise.

	$ok = ip_validate('127.0.0.1');     # TRUE
	$ok = ip_validate('::1');           # TRUE
	$ok = ip_validate('127.0.0.');      # FALSE
	$ok = ip_validate('127.256');       # FALSE
	$ok = ip_validate('::1:127.0.0.1'); # FALSE

=head2 ip_is_ipv4

Returns TRUE if the specified IP address is an IPv4 address, or FALSE otherwise.

	$ok = ip_is_ipv4('127.0.0.1');        # TRUE
	$ok = ip_is_ipv4('::1');              # FALSE
	$ok = ip_is_ipv4('0::0:');            # FALSE
	$ok = ip_is_ipv4('::ffff:127.0.0.1'); # FALSE

=head2 ip_is_ipv6

Returns TRUE if the specified IP address is an IPv6 address, or FALSE otherwise.

	$ok = ip_is_ipv6('::1');              # TRUE
	$ok = ip_is_ipv6('::ffff:127.0.0.1'); # TRUE
	$ok = ip_is_ipv6('0::0:');            # FALSE
	$ok = ip_is_ipv6('0::0:ffff1');       # FALSE
	$ok = ip_is_ipv6('127.0.0.1');        # FALSE

=head2 ip_is_ipv6ipv4

Returns TRUE if the specified IP address is an IPv4-embedded IPv6 address,
or FALSE otherwise.

	$ok = ip_is_ipv6ipv4('::ffff:127.0.0.1'); # TRUE
	$ok = ip_is_ipv6ipv4('::ffff:7f00:1');    # TRUE
	$ok = ip_is_ipv6ipv4('::fff1:7f00:1');    # FALSE
	$ok = ip_is_ipv6ipv4('127.0.0.1');        # FALSE

=head2 ip_transform

Converts an IP address string to another IP address string (or number).

	$ip = ip_transform($ip, $opts);

Where $opts is a hash that can have the following keys:

=over

=item * short_ipv6 => 1 (return abbreviated IPv6 address);

=item * short_ipv4 => 1 (return abbreviated IPv4 address);

=item * lead_zeros => 1 (add leading zeros to IPv6 address or hexadecimal IPv4 address);

=item * reverse => 1 (return reversed IP address);

=item * convert_to => 'ipv6' (transform IPv4 to IPv6 address);

=item * convert_to => 'ipv4' (transform IPv6-embedded address to IPv4);

=item * convert_to => 'ipv6ipv4' (transform IP address to format ::ffff:xx.xx.xx.xx);

=item * format_ipv4 => 'X' (transform IPv4 address to hexadecimal number);

=item * format_ipv4 => 'D' (transform IPv4 address to decimal number);

=item * format_ipv4 => 'O' (transform IPv4 address to octal number);

=item * format_ipv4 => 'x' (transform IPv4 address to hexadecimal octet format);

=item * format_ipv4 => 'o' (transform IPv4 address to octal number).

=back

	$ip = ip_transform('127.0.1');          # 127.0.0.1
	$ip = ip_transform('::1');              # 0:0:0:0:0:0:0:1
	$ip = ip_transform('::ffff:127.0.0.1'); # 0:0:0:0:0:ffff:7f00:1

	$ip = ip_transform('127.0.0.1', {
		short_ipv4 => 1
	}); # 127.1

	$ip = ip_transform('0:0::1', {
		short_ipv6 => 1
	}); # ::1

	$ip = ip_transform('0:0::1', {
		lead_zeros => 1
	}); # 0000:0000:0000:0000:0000:0000:0000:0001

	$ip = ip_transform('0:0::1', {
		short_ipv6 => 1,
		lead_zeros => 1
	}); # ::0001

	$ip = ip_transform('0:0::1', {
		reverse => 1
	}); # 1:0:0:0:0:0:0:0

	$ip = ip_transform('::ffff:127.0.0.1', {
		reverse => 1,
		short_ipv6 => 1
	}); # 1:7f00:ffff::

	$ip = ip_transform('127.0.0.1', {
		convert_to => 'ipv6'
	}); # 0:0:0:0:0:ffff:7f00:1

	$ip = ip_transform('::ffff:127.0.0.1', {
		convert_to => 'ipv6'
	}); # 0:0:0:0:0:ffff:7f00:1

	$ip = ip_transform('::ffff:7f00:1', {
		convert_to => 'ipv4'
	}); # 127.0.0.1

	$ip = ip_transform('::ffff:127.0.0.1', {
		convert_to => 'ipv4'
	}); # 127.0.0.1

	$ip = ip_transform('::ffff:7f00:1', {
		convert_to => 'ipv6ipv4'
	}); # 0:0:0:0:0:ffff:127.0.0.1

	$ip = ip_transform('::ffff:127.0.0.1', {
		convert_to => 'ipv6ipv4'
	}); # 0:0:0:0:0:ffff:127.0.0.1

	$ip = ip_transform('127.0.0.1', {
		convert_to => 'ipv6ipv4'
	}); # 0:0:0:0:0:ffff:127.0.0.1

	$ip = ip_transform('0.0.0.1', {
		format_ipv4 => 'X'
	}); # 0x1

	$ip = ip_transform('0.0.0.1', {
		format_ipv4 => 'X',
		lead_zeros => 1
	}); # 0x00000001

	$ip = ip_transform('127.0.0.1', {
		format_ipv4 => 'D'
	}); # 2130706433

	$ip = ip_transform('127.0.0.1', {
		format_ipv4 => 'O'
	});
	# 017700000001

	$ip = ip_transform('127.0.0.1', {
		format_ipv4 => 'x'
	}); # 0x7f.0x0.0x0.0x1

	$ip = ip_transform('127.0.0.1', {
		format_ipv4 => 'x',
	short_ipv4 => 1
	}); # 0x7f.0x1

	$ip = ip_transform('127.0.0.1', {
		format_ipv4 => 'x',
		lead_zeros => 1 });
	# 0x7f.0x00.0x00.0x01'

	$ip = ip_transform('127.0.0.1', {
		format_ipv4 => 'o'
	}); # 0177.0.0.01

=head2 ip_equal

Compares two IP addresses.

	$eq = ip_equal('127.0.0.1', '0x7f000001');       # TRUE
	$eq = ip_equal('::', '0:0:0:0:0:0:0:0');         # TRUE
	$eq = ip_equal('::ffff:127.0.0.1', '127.0.0.1'); # FALSE

=head2 ip_equal_v4

Compares two IP addresses as IPv4 addresses.

	$eq = ip_equal_v4('127.0.0.1', '0x7f000001');       # TRUE
	$eq = ip_equal_v4('::ffff:127.0.0.1', '127.0.0.1'); # TRUE
	$eq = ip_equal_v4('::', '127.0.0.1');               # dies

=head2 ip_equal_v6

Compares two IP addresses as IPv6 addresses.

	$eq = ip_equal_v6('127.0.0.1', '0x7f000001');       # TRUE
	$eq = ip_equal_v6('::1', '0:0::1');                 # TRUE
	$eq = ip_equal_v6('::ffff:127.0.0.1', '127.0.0.1'); # TRUE
	$eq = ip_equal_v6('::', '127.0.0.1');               # FALSE

=head2 ip_in_range

Verifies whether the specified IP address in a range.

	$in_range = ip_in_range('127.0.0.1', $range);

Where range can be specified in the following ways:

=over

=item * an IP address and a mask ('192.168.0.1 255.255.255.0');

=item * an IP address with a prefix ('ffff:ffff:1::/48');

=item * an IP address without mask ('129.168.0.1' (equivalent to '192.168.0.1/32'));

=item * as an array ([ '129.168.0.0/16', '172.16.0.0/12', '10.0.0.0 255.0.0.0', '::ffff/96' ]);

=back

	$in = ip_in_range('192.168.0.1', '192.168.0 255.255.255.0');   # TRUE
	$in = ip_in_range('10.10.10.19', [ '127.1', '10.0/8' ]);       # TRUE
	$in = ip_in_range('10.10.10.19', '10.10.10.8/29');             # FALSE
	$in = ip_in_range('a0:a0:a0:a0:1::1', 'a0:a0:a0:a0::/64');     # TRUE
	$in = ip_in_range('::ffff:10.10.10.10', '::ffff:0:0/96');      # TRUE
	$in = ip_in_range('1:2:3::8000:40', '1:2:3::8000:20/123');     # FALSE

=head1 EXPORTS

Net::IP::Lite exports the following functions:

=over

=item * ip2bin

=item * ip_validate

=item * ip_is_ipv4

=item * ip_is_ipv6

=item * ip_is_ipv6ipv4

=item * ip_transform

=item * ip_equal

=item * ip_equal_v4

=item * ip_equal_v6

=item * ip_in_range

=back

=head1 OBJECT-ORIENTED INTERFACE

When you use the object oriented approach, binary representation of IP address
is calculated once (when you create Net::SimpleIO object). Thus, if you are
going to use an IP address (or a range) more than once, you can use once
created object to reduce redundant IP-to-binary conversions.

=head2 Net::IP::Lite object

=head3 constructor

	$ip = Net::IP::Lite->new('10.77.0.77') || die 'Invalid IP address';
	$ip = Net::IP::Lite->new('::1') || die ...

=head3 address

Returns the original IP address that was specified as the constructor argument.

	$ip = Net::IP::Lite->new('10.77.77');
	print $ip->address(); # 10.77.77

=head3 binary

Returns a string that contains binary representation of the specified IP
address.

	$ip = Net::IP::Lite->new('10.77.77');
	print $ip->binary(); # 00001010010011010000000001001101

=head3 is_ipv4

Returns TRUE if the IP address is a IPv4 address, or FALSE otherwise.

	$ip = Net::IP::Lite->new('10.77.77');
	$ipv4 = $ip->is_ipv4(); # TRUE

	$ip = Net::IP::Lite->new('::1');
	$ipv4 = $ip->is_ipv4(); # FALSE

See also: L</"ip_is_ipv4">

=head3 is_ipv6

Returns TRUE if the IP address is a IPv6 address, or FALSE otherwise.

	$ip = Net::IP::Lite->new('::1');
	$ipv6 = $ip->is_ipv6(); # TRUE

	$ip = Net::IP::Lite->new('127.1');
	$ipv6 = $ip->is_ipv6(); # FALSE

See also: L</"ip_is_ipv6">

=head3 is_ipv6ipv4

Returns TRUE if the IP address is a IPv4-Embedded IPv6 address, or FALSE
otherwise.

	$ip = Net::IP::Lite->new('::ffff:127.0.0.1');
	$emb = $ip->is_ipv6ipv4(); # TRUE

	$ip = Net::IP::Lite->new('::ffff:7f00:1');
	$emb = $ip->is_ipv6ipv4(); # TRUE

	$ip = Net::IP::Lite->new('::1');
	$emb = $ip->is_ipv6ipv4(); # FALSE

	$ip = Net::IP::Lite->new('127.1');
	$emb = $ip->is_ipv6ipv4(); # FALSE

See also: L</"ip_is_ipv6ipv4">

=head3 transform

Converts the IP address to an IP address string (or number).

	$ip = Net::IP::Lite->new('0:0:0:0:0:0:0:1');
	print $ip->transform({ short_ipv6 => 1 }); # ::1

See L</"ip_transform"> for all possible values of $opts.

=head3 equal

Compares two IP addresses.

	$ip = Net::IP::Lite->new('0:0:0:0:0:0:0:1');
	$eq = $ip->equal('::1'); # TRUE
	$eq = $ip->equal('::2'); # FALSE

	$ip1 = Net::IP::Lite->new('0:0:0:0:0:0:0:1');
	$ip2 = Net::IP::Lite->new('::1');
	$eq = $ip->equal($ip2); # TRUE

See also: L</"ip_equal">

=head3 equal_v4

Compares two IP addresses as IPv4 addresses.

	$ip = Net::IP::Lite->new('::ffff:127.0.0.1');
	$eq = $ip->equal_v4('127.0.0.1'); # TRUE

	$ip1 = Net::IP::Lite->new('::ffff:7f00:1');
	$ip2 = Net::IP::Lite->new('127.0.0.1');
	$eq = $ip->equal_v4($ip2); # TRUE

	$ip = Net::IP::Lite->new('::7f00:1');
	$eq = $ip->equal_v4('127.0.0.1'); # dies

See also: L</"ip_equal_v4">

=head3 equal_v6

Compares two IP addresses as IPv6 addresses.

	$ip = Net::IP::Lite->new('::ffff:127.0.0.1');
	$eq = $ip->equal_v6('127.0.0.1'); # TRUE

	$ip1 = Net::IP::Lite->new('::ffff:7f00:1');
	$ip2 = Net::IP::Lite->new('127.0.0.1');
	$eq = $ip->equal_v6($ip2); # TRUE

See also: L</"ip_equal_v6">

=head3 in_range

Verifies whether the IP in a range.

	$ip = Net::IP::Lite->new('10.10.10.10');
	$in = $ip->in_range('10.10.10.8/29'); # TRUE
	$in = $ip->in_range([ '192.168.0 255.255.255.0', '10.0/8' ]); # TRUE

See also: L</"ip_in_range">

Apart from string IP addresses you specify Net::IP::Lite::Net object:

	$ip  = Net::IP::Lite->new('10.10.10.10');
	$net = Net::IP::Lite::Net->new('10.0/8') || die ...;
	$in = $ip->in_range($net); # TRUE

	$net = Net::IP::Lite::Net->new('1::/16') || die ...;
	$in = $ip->in_range($net);               # FALSE
	$in = $ip->in_range([ $net, '10.0/8' ]); # TRUE

See also: L</"Net::IP::Lite::Net object">

=head2 Net::IP::Lite::Net object

=head3 constructor

The Net::IP::Lite::Net class is a descendant of Net::IP::Lite. 

	$net = Net::IP::Lite::Net->new('10.0/8') || die ...;
	$net = Net::IP::Lite::Net->new('10.0.0.8 255.255.255.248') || die ...;
	$net = Net::IP::Lite::Net->new('1::/16') || die ...;
	$net = Net::IP::Lite::Net->new('1:: ffff::') || die ...;

Please note: Net::IP::Lite::Net allows you to create an network (without
possible hosts).

For example:

	$net = Net::IP::Lite::Net->new('10.10.10.8/28');

You can use the <L</"contains"> method to check whether there are any possible
hosts or not.

All Net:IP::Lite methods return the same values as if you created
Net::IP::Lite object without a mask.

	$net = Net::IP::Lite::Net->new('1:: ffff::') || die ...;
	print $net->address; # 1::

See also: L</"Net::IP::Lite object">

=head3 mask

Returns Net::IP::Lite instance for the network mask;

	$net = Net::IP::Lite::Net->new('1:: ffff::') || die ...;
	print $net->mask->address(); # ffff::

	$net = Net::IP::Lite::Net->new('1::/32') || die ...;
	print $net->mask->address(); # ffff:ffff:0:0:0:0:0:0

	$net = Net::IP::Lite::Net->new('10.0/8') || die ...;
	print $net->mask->binary(); # 11111111000000000000000000000000

=head3 network

Returns the original network definition that was specified as the constructor
argument.

	my $net = Net::IP::Lite::Net->new('1::/32') || die ...;
	print $net->network(); # 1::/32

=head3 contains

Verifies whether an IP in the net.

	$net = Net::IP::Lite::Net->new('1:: ffff::') || die ...;
	$in = $net->contains('1:ff::1'); # TRUE

Also you can pass an Net::IP::Lite object:

	$ip = Net::IP::Lite::Net->new('1::1') || die ...;
	$net = Net::IP::Lite::Net->new('1::/32') || die ...;
	my $in = $net->contains($ip); # TRUE

This method also can be used to check whether there are possible hosts
in the network or not:

	$net = Net::IP::Lite::Net->new('10.10.10.8/28');
	$ok = $net->contains($net); # FALSE

	$net = Net::IP::Lite::Net->new('10.10.10.8/29');
	$ok = $net->contains($net); # TRUE

See also: L</"ip_in_range">, L</"Net::IP::Lite object">

=head1 SEE ALSO

L<NET::IP>, L<NetAddr::IP>, L<NetAddr::IP::Lite>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Net::IP::Lite

You can also look for information at:

=over

=item * Code Repository at GitHub

L<http://github.com/alexey-komarov/Net-IP-Lite>

=item * GitHub Issue Tracker

L<http://github.com/alexey-komarov/Net-IP-Lite/issues>

=item * RT, CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-IP-Lite>

=back

=head1 AUTHOR

Alexey A. Komarov E<lt>alexkom@cpan.orgE<gt>

=head1 COPYRIGHT

2013 Alexey A. Komarov

=head1 LICENSE

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
