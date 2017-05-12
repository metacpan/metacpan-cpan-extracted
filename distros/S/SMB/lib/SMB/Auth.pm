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

package SMB::Auth;

use strict;
use warnings;

use parent 'SMB';

use bytes;
use Sys::Hostname qw(hostname);
use Encode qw(encode);

use SMB::Crypt qw(des_crypt56 md4 hmac_md5);
use SMB::Parser;
use SMB::Packer;
use SMB::Time qw(to_nttime);

# Abstract Syntax Notation One (small subset)

use constant {
	ASN1_BINARY      => 0x04,
	ASN1_OID         => 0x06,
	ASN1_ENUMERATED  => 0x0a,
	ASN1_SEQUENCE    => 0x30,
	ASN1_APPLICATION => 0x60,
	ASN1_CONTEXT     => 0xa0,
};

# Generic Security Service API / Simple Protected Negotiation

use constant {
	OID_SPNEGO       => '1.3.6.1.5.5.2',
	OID_MECH_NTLMSSP => '1.3.6.1.4.1.311.2.2.10',

	SPNEGO_ACCEPT_COMPLETED  => 0,
	SPNEGO_ACCEPT_INCOMPLETE => 1,
};

# NTLMSSP mechanism

use constant {
	NTLMSSP_ID_STR => "NTLMSSP\0",

	NTLMSSP_NEGOTIATE => 1,
	NTLMSSP_CHALLENGE => 2,
	NTLMSSP_AUTH      => 3,
	NTLMSSP_SIGNATURE => 4,

	NTLMSSP_ITEM_TERMINATOR    => 0,
	NTLMSSP_ITEM_NETBIOSHOST   => 1,
	NTLMSSP_ITEM_NETBIOSDOMAIN => 2,
	NTLMSSP_ITEM_DNSHOST       => 3,
	NTLMSSP_ITEM_DNSDOMAIN     => 4,
	NTLMSSP_ITEM_TIMESTAMP     => 7,

	NTLMSSP_FLAGS_CLIENT => 0x60008215,
	NTLMSSP_FLAGS_SERVER => 0x628a8215,
};

sub new ($) {
	my $class = shift;

	return $class->SUPER::new(
		ntlmssp_supported     => undef,
		client_host           => undef,
		client_domain         => undef,
		server_challenge      => undef,
		server_host           => undef,
		server_netbios_host   => undef,
		server_netbios_domain => undef,
		server_dns_host       => undef,
		server_dns_domain     => undef,
		server_timestamp      => undef,
		client_challenge      => undef,
		lm_response           => undef,
		ntlm_response         => undef,
		domain                => undef,
		host                  => undef,
		username              => undef,
		session_key           => undef,
		auth_completed        => undef,
		user_passwords        => {},
		parser => SMB::Parser->new,
		packer => SMB::Packer->new,
	);
}

sub set_user_passwords ($$) {
	my $self = shift;
	my $user_passwords = shift || die "No user passwords to set";

	die "User passwords should be HASH"
		unless ref($user_passwords) eq 'HASH';

	$self->user_passwords($user_passwords);
}

sub create_lm_hash ($) {
	my $password = substr(encode('ISO-8859-1', uc(shift // "")), 0, 14);
	$password .= "\0" x (14 - length($password));

	return join('', map {
		des_crypt56('KGS!@#$%', $_)
	} $password =~ /^(.{7})(.{7})$/);
}

sub create_ntlm_hash ($) {
	my $password = encode('UTF-16LE', shift // "");

	return md4($password);
}

sub create_lm_response ($$) {
	my $lm_hash = shift || die;
	my $server_challenge = shift;

	$lm_hash .= "\0" x (21 - length($lm_hash));

	return join('', map {
		des_crypt56([ map { ord($_) } split '', $server_challenge ], $_)
	} $lm_hash =~ /^(.{7})(.{7})(.{7})$/);
}

sub create_ntlmv2_hash ($$$) {
	my $ntlm_hash = shift || die;
	my $username = shift // '';
	my $domain = shift // '';

	return hmac_md5(encode('UTF-16LE', uc($username . $domain)), $ntlm_hash);
}

sub create_lmv2_response ($$$$) {
	return create_ntlmv2_response($_[0], $_[1], $_[2], $_[3], 8);
}

sub create_ntlmv2_response ($$$$;$) {
	my $ntlm_hash = shift;
	my $username = shift;
	my $domain = shift;
	my $server_challenge = shift;
	my $client_challenge_len = shift || 24;

	my $client_challenge = join('', map { chr(rand(0x100)) } 1 .. $client_challenge_len);
	my $ntlmv2_hash = create_ntlmv2_hash($ntlm_hash, $username, $domain);

	return hmac_md5($server_challenge . $client_challenge, $ntlmv2_hash) . $client_challenge;
}

sub get_user_passwd_line ($$) {
	my $username = shift;
	my $password = shift;

	return "$username:" . join('',
		map { map { sprintf "%02x", ord($_) } split '', $_ }
		create_lm_hash($password), create_ntlm_hash($password)
	);
}

sub load_user_passwords ($$) {
	my $self = shift;
	my $filename = shift || return;

	open PASSWD, "<$filename" or return;
	my @lines = <PASSWD>;
	close PASSWD or return;

	my %user_passwords = map {
		s/^\s+//;
		s/\s+$//;
		my ($username, $hash_str) = split ':', $_;
		my @hash_bytes = ($hash_str || '') =~ /^[0-9a-f]{64}$/
			? map { chr(hex(substr($hash_str, $_ * 2, 2))) } 0 .. 31
			: ();
		$username && $username =~ /^\w[\w.+-]*$/ && @hash_bytes
			? ($username => [ join('', @hash_bytes[0 .. 15]), join('', @hash_bytes[16 .. 31]) ])
			: ();
	} grep !/^\s*#/, @lines;

	$self->user_passwords(\%user_passwords);

	# in scalar context - number of users loaded
	return keys %user_passwords;
}

sub is_user_authenticated ($) {
	my $self = shift;

#	my $lm_response   = $self->lm_response   || return $self->err("No lm_response from client");
	my $ntlm_response = $self->ntlm_response || return $self->err("No ntlm_response from client");

	my ($hmac, $client_data) = $ntlm_response =~ /^(.{16})(.+)$/s;
	return $self->err("Invalid short ntlm_response from client")
		unless $hmac;

	my $username = $self->username // return $self->err("No username from client");
	my $password = $self->user_passwords->{$username} // return $self->err("No user '$username' on server");
	my ($lm_hash, $ntlm_hash) = ref($password) eq 'ARRAY' ? @$password : ();

#	$lm_hash   ||= create_lm_hash($password);
	$ntlm_hash ||= create_ntlm_hash($password);
	my $ntlmv2_hash = create_ntlmv2_hash($ntlm_hash, $username, $self->client_domain);

	return $self->err("Failed password check for user '$username', client not authenticated")
		unless $hmac eq hmac_md5($self->server_challenge . $client_data, $ntlmv2_hash);

	return 1;
}

my @parsed_context_values;

sub parse_asn1 {
	my $bytes = shift;

	my $tag = ord(shift @$bytes);
	my $len = ord(shift @$bytes);
	if ($len >= 0x80) {
		my $llen = $len - 0x80;
		my $factor = 1;
		$len = 0;
		for (1 .. $llen) {
			$len = $len * $factor + ord(shift @$bytes);
			$factor *= 256;
		}
	}

	my @contents;
	my @bytes = splice(@$bytes, 0, $len);
	if ($tag == ASN1_BINARY) {
		@contents = (\@bytes);
	} elsif ($tag == ASN1_OID) {
		my $idx = 0;
		my $carry = 0;
		@contents = (join('.', map {
			my @i;
			if (0 == $idx++) { @i = (int($_ / 40), $_ % 40); }
			elsif ($_ >= 0x80) { $carry = $carry * 0x80 + $_ - 0x80; }
			else { @i = ($carry * 0x80 + $_); $carry = 0; }
			@i
		} map { ord($_) } @bytes));
	} elsif ($tag == ASN1_ENUMERATED) {
		die "Unsupported len=$len" unless $len == 1;
		@contents = map { ord($_) } @bytes;
	} elsif ($tag == ASN1_SEQUENCE || $tag == ASN1_APPLICATION) {
		push @contents, parse_asn1(\@bytes)
			while @bytes;
	} elsif ($tag >= ASN1_CONTEXT && $tag <= ASN1_CONTEXT + 3) {
		@contents = @{parse_asn1(\@bytes)};
		$parsed_context_values[$tag - ASN1_CONTEXT] //= \@contents;
	} else {
		warn sprintf "Unsupported asn1 tag 0x%x on parse\n", $tag;
	}

	return [ $tag, @contents ];
}

sub generate_asn1 {
	my $tag     = shift // die "No asn1 tag";
	my $content = shift // die "No asn1 tag content";

	my @bytes;
	if ($tag == ASN1_BINARY) {
		@bytes = split('', $content);
	} elsif ($tag == ASN1_OID) {
		my $idx = 0;
		my $id0;
		@bytes = map { chr($_) } map {
			0 == $idx++ ? ($id0 = $_) && () : 2 == $idx ? ($id0 * 40 + $_) : (
				$_ >= 1 << 28 ? (0x80 | (($_ >> 28) & 0x7f)) : (),
				$_ >= 1 << 21 ? (0x80 | (($_ >> 21) & 0x7f)) : (),
				$_ >= 1 << 14 ? (0x80 | (($_ >> 14) & 0x7f)) : (),
				$_ >= 1 <<  7 ? (0x80 | (($_ >>  7) & 0x7f)) : (),
				$_ & 0x7f
			)
		} split(/\./, $content);
	} elsif ($tag == ASN1_ENUMERATED) {
		@bytes = (chr($content));
	} elsif ($tag == ASN1_SEQUENCE || $tag == ASN1_APPLICATION) {
		do {
			push @bytes, @{generate_asn1(@$content)};
			$content = shift;
		} while $content;
	} elsif ($tag >= ASN1_CONTEXT && $tag <= ASN1_CONTEXT + 3) {
		@bytes = @{generate_asn1($content, @_)};
	} else {
		warn sprintf "Unsupported asn1 tag 0x%x on generate\n", $tag;
	}

	my $len = @bytes;
	my @sub_lens;
	while ($len >= 0x80) {
		push @sub_lens, $len % 256;
		$len /= 256;
	}
	my @len_bytes = @sub_lens ? (0x80 + @sub_lens + 1, $len, @sub_lens) : ($len);

	return [ (map { chr($_) } $tag, @len_bytes), @bytes ];
}

sub process_spnego ($$%) {
	my $self = shift;
	my $buffer = shift // return;
	my %options = @_;

	my @bytes = split '', $buffer;
	return unless @bytes > 2;

	@parsed_context_values = ();
	my $struct = parse_asn1(\@bytes);
	return unless $struct;

	if (!defined $self->ntlmssp_supported || $options{is_initial}) {
		my $value = $parsed_context_values[0];
		return $self->err("No expected spnego context value")
			unless ref($value) eq 'ARRAY' && shift @$value == ASN1_SEQUENCE;
		for (@$value) {
			return $self->ntlmssp_supported(1)
				if $_->[0] == ASN1_OID && $_->[1] eq OID_MECH_NTLMSSP;
		}
		return $self->ntlmssp_supported(0);
	}

	my $value = $parsed_context_values[2];
	my $ntlmssp_bytes = ref($value) eq 'ARRAY' && shift @$value == ASN1_BINARY
		? shift @$value
		: undef;
	my $parser = $self->parser;
	unless (defined $self->client_challenge) {
		return $self->err("No expected spnego context+2 value (ntlmssp)")
			unless $ntlmssp_bytes;
		$parser->set(join('', @$ntlmssp_bytes));
		return $self->err("No expected NTLMSSP id string")
			unless $parser->bytes(length(NTLMSSP_ID_STR)) eq NTLMSSP_ID_STR;
	}

	if (!defined $self->client_host) {
		return $self->err("No expected NTLMSSP_NEGOTIATE")
			unless $parser->uint32 == NTLMSSP_NEGOTIATE;
		$parser->skip(4);  # skip flags
		my $len1 = $parser->uint16;
		my $off1 = $parser->skip(2)->uint32;
		my $len2 = $parser->uint16;
		my $off2 = $parser->skip(2)->uint32;
		$self->client_domain($parser->reset($off1)->bytes($len1));
		$self->client_host  ($parser->reset($off2)->bytes($len2));
	} elsif (!defined $self->server_challenge) {
		return $self->err("No expected NTLMSSP_CHALLENGE")
			unless $parser->uint32 == NTLMSSP_CHALLENGE;
		my $len1 = $parser->uint16;
		my $off1 = $parser->skip(2)->uint32;
		$self->server_challenge($parser->reset(24)->bytes(8));
		$self->server_host($parser->reset($off1)->str($len1));
		my $itemtype;
		do {{
			$itemtype = $parser->uint16;
			$parser->uint16 == 8 && $self->server_timestamp($parser->uint64), next
				if $itemtype == NTLMSSP_ITEM_TIMESTAMP;
			my $str = $parser->str($parser->uint16);
			$self->server_netbios_host($str)
				if $itemtype == NTLMSSP_ITEM_NETBIOSHOST;
			$self->server_netbios_domain($str)
				if $itemtype == NTLMSSP_ITEM_NETBIOSDOMAIN;
			$self->server_dns_host($str)
				if $itemtype == NTLMSSP_ITEM_DNSHOST;
			$self->server_dns_domain($str)
				if $itemtype == NTLMSSP_ITEM_DNSDOMAIN;
		}} while ($itemtype != NTLMSSP_ITEM_TERMINATOR)
	} elsif (!defined $self->client_challenge) {
		return $self->err("No expected NTLMSSP_AUTH")
			unless $parser->uint32 == NTLMSSP_AUTH;
		my $llen = $parser->uint16;
		my $loff = $parser->skip(2)->uint32;
		my $nlen = $parser->uint16;
		my $noff = $parser->skip(2)->uint32;
		my $len1 = $parser->uint16;
		my $off1 = $parser->skip(2)->uint32;
		my $len2 = $parser->uint16;
		my $off2 = $parser->skip(2)->uint32;
		my $len3 = $parser->uint16;
		my $off3 = $parser->skip(2)->uint32;
		$self->client_challenge($parser->reset($noff + 28)->bytes(8));
		$self->lm_response  ($parser->reset($loff)->bytes($llen));
		$self->ntlm_response($parser->reset($noff)->bytes($nlen));
		$self->client_domain($parser->reset($off1)->str($len1));
		$self->username     ($parser->reset($off2)->str($len2));
		$self->client_host  ($parser->reset($off3)->str($len3));
	} elsif (!defined $self->auth_completed) {
		my $value = $parsed_context_values[0];
		return $self->err("No expected spnego context value (ACCEPT_COMPLETED)")
			unless ref($value) eq 'ARRAY' && shift @$value == ASN1_ENUMERATED;
		$self->auth_completed(shift @$value == SPNEGO_ACCEPT_COMPLETED ? 1 : 0);
	} else {
		$self->err("process_spnego called after auth_completed");
	}

	return 1;
}

sub generate_spnego ($%) {
	my $self = shift;
	my %options = @_;

	my $struct;

	if (!defined $self->ntlmssp_supported || $options{is_initial}) {
		$self->ntlmssp_supported(1);
		$struct = [ ASN1_APPLICATION,
			[ ASN1_OID, OID_SPNEGO ],
			[ ASN1_CONTEXT, ASN1_SEQUENCE,
				[ ASN1_CONTEXT, ASN1_SEQUENCE,
					[ ASN1_OID, OID_MECH_NTLMSSP ],
				],
			],
		];
		goto RETURN;
	}

	my @names = hostname =~ /^([^.]*+)\.?+(.*)$/;
	my $host   = $options{host}   || $names[0];
	my $domain = $options{domain} || $names[1];

	if (!defined $self->client_host) {
		$self->client_host($host);
		$self->client_domain($domain);

		$self->packer->reset
			->bytes(NTLMSSP_ID_STR)
			->uint32(NTLMSSP_NEGOTIATE)
			->uint32(NTLMSSP_FLAGS_CLIENT)
			->uint16(length($domain))
			->uint16(length($domain))
			->uint32(32)
			->uint16(length($host))
			->uint16(length($host))
			->uint32(32 + length($domain))
			->bytes($domain)
			->bytes($host)
		;
		$struct = [ ASN1_APPLICATION,
			[ ASN1_OID, OID_SPNEGO ],
			[ ASN1_CONTEXT, ASN1_SEQUENCE,
				[ ASN1_CONTEXT, ASN1_SEQUENCE,
					[ ASN1_OID, OID_MECH_NTLMSSP ],
				],
				[ ASN1_CONTEXT + 2, ASN1_BINARY, $self->packer->data ],
			],
		];
	} elsif (!defined $self->server_challenge) {
		$self->server_challenge(join('', map { chr(rand(0x100)) } 1 .. 8));
		$self->server_host($host);
		$self->server_netbios_host($host);
		$self->server_netbios_domain($domain);
		$self->server_dns_host($host);
		$self->server_dns_domain($domain);
		my $tlen = 32 + length(
			$self->server_netbios_host .
			$self->server_netbios_domain .
			$self->server_dns_host .
			$self->server_dns_domain
		) * 2;

		$self->packer->reset
			->bytes(NTLMSSP_ID_STR)
			->uint32(NTLMSSP_CHALLENGE)
			->uint16(length($self->server_host) * 2)
			->uint16(length($self->server_host) * 2)
			->uint32(56)
			->uint32(NTLMSSP_FLAGS_SERVER)
			->bytes($self->server_challenge)
			->uint64(0)  # reserved
			->uint16($tlen)
			->uint16($tlen)
			->uint32(56 + length($self->server_host) * 2)
			->bytes("\x06\x01\xb1\x1d\x00\x00\x00\x0f")  # version
			->str($self->server_host)
			->uint16(NTLMSSP_ITEM_NETBIOSDOMAIN)
			->uint16(length($self->server_netbios_domain) * 2)
			->str($self->server_netbios_domain)
			->uint16(NTLMSSP_ITEM_NETBIOSHOST)
			->uint16(length($self->server_netbios_host) * 2)
			->str($self->server_netbios_host)
			->uint16(NTLMSSP_ITEM_DNSDOMAIN)
			->uint16(length($self->server_dns_domain) * 2)
			->str($self->server_dns_domain)
			->uint16(NTLMSSP_ITEM_DNSHOST)
			->uint16(length($self->server_dns_host) * 2)
			->str($self->server_dns_host)
			->uint16(NTLMSSP_ITEM_TIMESTAMP)
			->uint16(8)
			->bytes("\0" x 8)
			->uint16(NTLMSSP_ITEM_TERMINATOR)
			->uint16(0)
		;

		$struct = [ ASN1_CONTEXT + 1, ASN1_SEQUENCE,
			[ ASN1_CONTEXT, ASN1_ENUMERATED, SPNEGO_ACCEPT_INCOMPLETE ],
			[ ASN1_CONTEXT + 1, ASN1_OID, OID_MECH_NTLMSSP ],
			[ ASN1_CONTEXT + 2, ASN1_BINARY, $self->packer->data ],
		];
	} elsif (!defined $self->client_challenge) {
		my $username = $options{username} || '';
		my $password = $options{password} || '';
		$domain = $options{domain} || 'MYGROUP';
		$self->client_challenge(join('', map { chr(rand(0x100)) } 1 .. 8));
		$self->username($username);
		$self->domain($domain);
		$self->session_key([ map { chr(rand(0x100)) } 1 .. 16 ]);

#		my $lm_hash   = $options{lm_password_hash}   || create_lm_hash($password);
		my $ntlm_hash = $options{ntlm_password_hash} || create_ntlm_hash($password);
		my $ntlmv2_hash = create_ntlmv2_hash($ntlm_hash, $self->username, $self->domain);

		$self->packer->reset
			->uint32(0x0101)    # header
			->uint32(0)         # reserved
			->uint64(to_nttime(time))
			->bytes($self->client_challenge)
			->uint32(0)         # unknown
			->uint16(NTLMSSP_ITEM_NETBIOSDOMAIN)
			->uint16(length($self->server_netbios_domain) * 2)
			->str($self->server_netbios_domain)
			->uint16(NTLMSSP_ITEM_NETBIOSHOST)
			->uint16(length($self->server_netbios_host) * 2)
			->str($self->server_netbios_host)
			->uint16(NTLMSSP_ITEM_DNSDOMAIN)
			->uint16(length($self->server_dns_domain) * 2)
			->str($self->server_dns_domain)
			->uint16(NTLMSSP_ITEM_DNSHOST)
			->uint16(length($self->server_dns_host) * 2)
			->str($self->server_dns_host)
			->uint16(NTLMSSP_ITEM_TIMESTAMP)
			->uint16(8)
			->uint64($self->server_timestamp || 0)
			->uint16(NTLMSSP_ITEM_TERMINATOR)
			->uint16(0)
		;

		my $client_data = $self->packer->data;
		my $hmac = hmac_md5($self->server_challenge . $client_data, $ntlmv2_hash);
		my $ntlm_response = "$hmac$client_data";
		my $nlen = 16 + $self->packer->size;  # hmac + client data

		my $lm_response = create_lmv2_response($ntlm_hash, $username, $domain, $self->server_challenge);

		$self->lm_response($lm_response);
		$self->ntlm_response($ntlm_response);

		$self->packer->reset
			->bytes(NTLMSSP_ID_STR)
			->uint32(NTLMSSP_AUTH)
			->uint16(24)
			->uint16(24)
			->uint32(64)
			->uint16($nlen)
			->uint16($nlen)
			->uint32(88)
			->uint16(length($domain) * 2)
			->uint16(length($domain) * 2)
			->uint32(88 + $nlen)
			->uint16(length($username) * 2)
			->uint16(length($username) * 2)
			->uint32(88 + $nlen + length($domain) * 2)
			->uint16(length($host) * 2)
			->uint16(length($host) * 2)
			->uint32(88 + $nlen + length("$domain$username") * 2)
			->uint16(16)
			->uint16(16)
			->uint32(88 + $nlen + length("$domain$username$host") * 2)
			->uint32(NTLMSSP_FLAGS_CLIENT)
			->bytes($lm_response)
			->bytes($ntlm_response)
			->str($domain)
			->str($username)
			->str($host)
			->bytes($self->session_key)
		;

		$struct = [ ASN1_CONTEXT + 1, ASN1_SEQUENCE,
			[ ASN1_CONTEXT + 2, ASN1_BINARY, $self->packer->data ],
		];
	} elsif (!defined $self->auth_completed) {
		$self->auth_completed($self->is_user_authenticated ? 1 : 0);
		$struct = [ ASN1_CONTEXT + 1, ASN1_SEQUENCE,
			[ ASN1_CONTEXT, ASN1_ENUMERATED, SPNEGO_ACCEPT_COMPLETED ],
		] if $self->auth_completed;
	} else {
		$self->err("generate_spnego called after auth_completed");
	}

RETURN:
	return undef unless $struct;

	return join '', @{generate_asn1(@$struct)};
}

1;

__END__
# ----------------------------------------------------------------------------

=head1 NAME

SMB::Auth - Authentication mechanisms for SMB (NTLMSSP and more)

=head1 SYNOPSIS

	use SMB::Auth;

	# usually only one side is needed, not both like here
	my $server_auth = SMB::Auth->new;
	my $client_auth = SMB::Auth->new;

	$server_auth->load_user_passwords("p.txt") or
		$server_auth->set_user_passwords({ tom => '%#' });

	# Negotiate Response
	my $buffer = $server_auth->generate_spnego;
	# suppose security-buffer is sent/received over network
	$client_auth->process_spnego($buffer) or die;

	# SessionSetup Request 1
	$buffer = $client_auth->generate_spnego(host => 'client');
	$server_auth->process_spnego($buffer) or die;

	# SessionSetup Response 1
	$buffer = $server_auth->generate_spnego(host => 'server');
	$client_auth->process_spnego($buffer) or die;

	# SessionSetup Request 2
	$buffer = $client_auth->generate_spnego(
		username => 'tom',
		password => '%#',
		domain => 'galaxy',
	);
	$server_auth->process_spnego($buffer)
		or die "Failed to verify user password";

	# SessionSetup Response 2
	$buffer = $server_auth->generate_spnego();
	$client_auth->process_spnego($buffer)
		or die "Server didn't authenticate us";

=head1 ABSTRACT

SMB supports multiple mechanisms for authentication. Kerberos and NTLMSSP
are the main mechanisms. The messages are encoded into security buffer of
Negotiate response and SessionSetup requests/responses using ASN1
(Abstract Syntax Notation One) encoding and GSS-API (Generic Security
Service API) or SPNEGO (Simple Protected Negotiation).

NTLMSSP stands for NT LAN Manager Security Support Provider. This is a
binary messaging protocol utilizing NTLM authentication. NTLM is a
challenge response authentication, NTLMv1 uses a server challenge, and
NTLMv2 adds a client challenge. NTLMSSP is used when Kerberos can't be
used or in some special cases, for example when a share is specified
using IP rather than hostname, or a server does not belong to a domain.

=head1 DESCRIPTION

This class implement a client and a server authentication using NTLMSSP.

This is implemented as a state machine. A client must alternatively call
B<process_spnego> and B<generate_spnego>, a server must alternatively call
B<generate_spnego> and B<process_spnego>.

The authentication steps are usually:

	INITIAL (listing supported mechanisms in Negotiate Response)
	NTLMSSP_NEGOTIATE (first SessionSetup request)
	NTLMSSP_CHALLENGE (first SessionSetup response)
	NTLMSSP_AUTH (second SessionSetup request)
	FINAL (second SessionSetup response, success or logon failure)

This class inherits from L<SMB>, so B<msg>, B<err>, B<mem>, B<dump>,
auto-created field accessor and other methods are available as well.

=head1 METHODS

=over 4

=item new

Class constructor. Creates an instance of SMB::Auth.

=item set_user_passwords HASH

Defines user passwords for a server implementation.

Each HASH key is a user name. Each HASH value is either a scalar, in
which case it is taken as a plain password, or ARRAY of two 16-byte
blobs (LM password hash and NTLM password hash).

=item load_user_passwords PASSWD_FILENAME

Initializes user passwords for a server from a file containing users
with their password hashes. The file format is
USERNAME:LM_PASSWORD_HEX_HASH+NTLM_PASSWORD_HEX_HASH, like
test:aebd4de384c7ec43aad3b435b51404ee7a21990fcd3d759941e45c490f143d5f

File lines in a different format are ignored without a warning.

Returns undef on file reading problem, and the number of users loaded
otherwise. Note, that 0 is returned as a false value with no magic, since
this usually means an error (like a non-passwd file).

=item process_spnego BUFFER [OPTIONS]

A client or a server should call this method after receiving security
BUFFER in Negotiate response or SessionSetup request or SessionSetup
response.

Options: flag "is_initial" if given, instructs to restart the state
machine (it must be specified on the second Negotiate response if any).

=item generate_spnego [OPTIONS]

A client or a server should call this method to generate security buffer
for Negotiate response or SessionSetup request or SessionSetup response.

Options: flag "is_initial" if given, instructs to restart the state
machine (it must be specified on the second Negotiate response if any).

Other options may be required depending on the state: "host", "domain",
"username", "password" (strings in utf-8), "lm_password_hash",
"ntlm_password_hash" (16-byte blobs).

=back

=head1 INTERNAL METHODS

=over 4

=item is_user_authenticated

This may be explicitly called by a server to determine whether it
received valid challenge/username/password response from a client after
SessionSetup request with NTLMSSP_AUTH. The server starts from the user
password (or its hash) and encrypts it in the same way the client does it,
then compares the result with the received HMAC.

Returns true if the user/client is authenticated. On false, server
implementations should usually return STATUS_LOGON_FAILURE.

Instead of explicitly calling this method a server implementation may
just check the return value of the corresponding B<process_spnego>, that
is undef upon user logon failure.

=back

=head1 FUNCTIONS

No functions are exported, they may be called as SMB::Auth::FUNC_NAME.

=over 4

=item create_lm_hash PASSWORD

=item create_ntlm_hash PASSWORD

Creates LM or NTLM password hash (16-byte blob) from a plain password.

=item create_lm_response LM_HASH SERVER_CHALLENGE

=item create_ntlmv2_hash NTLM_HASH USERNAME DOMAIN

=item create_lmv2_response NTLM_HASH USERNAME DOMAIN SERVER_CHALLENGE

=item create_ntlmv2_response NTLM_HASH USERNAME DOMAIN SERVER_CHALLENGE

These internal functions expose the NTLM authentication details.

=item get_user_passwd_line USERNAME PASSWORD

May be used to create user password file loaded by a server.

Returns a string (without end-of-line) for USERNAME and PASSWORD in
passwd file format.

=item parse_asn1 ASN1

This internal function is used by B<process_spnego>.

Returns perl structure given the ASN1 bytes (ARRAY).

=item generate_asn1 TAG CONTENT ...

This internal function is used by B<generate_spnego>.

Returns ASN1 bytes (ARRAY) given the nested perl structure specified by
TAG and CONTENT(s).

=back

=head1 SEE ALSO

L<SMB::Crypt>, L<SMB>.

=head1 AUTHOR

Mikhael Goikhman <migo@cpan.org>

