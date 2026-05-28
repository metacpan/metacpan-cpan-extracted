package SignalWire::Utils::UrlValidator;

# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.
# See LICENSE file in the project root for full license information.

use strict;
use warnings;

use Socket qw(getaddrinfo unpack_sockaddr_in unpack_sockaddr_in6 AF_INET AF_INET6);
use URI;

use SignalWire::Logging;

# SSRF-prevention guard for user-supplied URLs.
#
# Mirrors Python's signalwire.utils.url_validator.validate_url:
# rejects non-http(s) schemes, missing hostnames, and any URL whose
# hostname resolves to a private / loopback / link-local / cloud-metadata
# IP. Either the second argument $allow_private being truthy, or the
# SWML_ALLOW_PRIVATE_URLS env var with value "1", "true" or "yes"
# (case-insensitive), bypasses the IP-blocklist check.
#
# validate_url is exported as a module-level free function. The Perl
# enumerate_signatures.py adapter projects packages with class=undef as
# Python module-level functions, so this maps to
# signalwire.utils.url_validator.validate_url directly.

# Cross-port SSRF block list. Order matches the Python reference.
our @BLOCKED_NETWORKS = (
    '10.0.0.0/8',
    '172.16.0.0/12',
    '192.168.0.0/16',
    '127.0.0.0/8',
    '169.254.0.0/16',  # link-local / cloud metadata
    '0.0.0.0/8',
    '::1/128',
    'fc00::/7',  # IPv6 private (ULA)
    'fe80::/10', # IPv6 link-local
);

# Pluggable resolver. Tests inject a coderef to keep the suite hermetic;
# production calls Socket::getaddrinfo. Underscore-prefixed so the
# adapter's _-name filter keeps it out of the public surface.
our $_RESOLVER;

sub validate_url {
    my ($url, $allow_private) = @_;
    $allow_private //= 0;

    my $log = SignalWire::Logging->get_logger('signalwire.url_validator');

    my $parsed = eval { URI->new($url) };
    if (!$parsed || $@) {
        $log->warn("URL validation error: $@");
        return 0;
    }

    my $scheme = lc($parsed->scheme // '');
    if ($scheme ne 'http' && $scheme ne 'https') {
        $log->warn("URL rejected: invalid scheme " . ($parsed->scheme // '(none)'));
        return 0;
    }

    my $hostname = $parsed->host // '';
    if ($hostname eq '') {
        $log->warn('URL rejected: no hostname');
        return 0;
    }
    # URI keeps brackets in host for IPv6 literals; strip them.
    if ($hostname =~ /^\[(.+)\]$/) {
        $hostname = $1;
    }

    if ($allow_private || _env_allows_private()) {
        return 1;
    }

    my $ips = _resolve($hostname);
    if (!$ips || @$ips == 0) {
        $log->warn("URL rejected: could not resolve hostname $hostname");
        return 0;
    }

    foreach my $ip (@$ips) {
        foreach my $cidr (@BLOCKED_NETWORKS) {
            if (_cidr_contains($cidr, $ip)) {
                $log->warn("URL rejected: $hostname resolves to blocked IP $ip (in $cidr)");
                return 0;
            }
        }
    }

    return 1;
}

sub _env_allows_private {
    my $v = lc($ENV{SWML_ALLOW_PRIVATE_URLS} // '');
    return ($v eq '1' || $v eq 'true' || $v eq 'yes') ? 1 : 0;
}

# Resolve a hostname to a list of IP-string addresses, or undef on failure.
sub _resolve {
    my ($hostname) = @_;
    if ($_RESOLVER) {
        return $_RESOLVER->($hostname);
    }
    # Literal-IP shortcut.
    if (_is_ip_literal($hostname)) {
        return [$hostname];
    }
    my ($err, @res) = getaddrinfo($hostname, undef, { socktype => 1 });
    return undef if $err;
    my @ips;
    for my $r (@res) {
        my $fam = $r->{family};
        if ($fam == AF_INET) {
            my ($port, $ipv4) = unpack_sockaddr_in($r->{addr});
            push @ips, _bytes_to_ipv4($ipv4);
        } elsif ($fam == AF_INET6) {
            my ($port, $ipv6) = unpack_sockaddr_in6($r->{addr});
            push @ips, _bytes_to_ipv6($ipv6);
        }
    }
    return @ips ? \@ips : undef;
}

sub _is_ip_literal {
    my ($s) = @_;
    return 1 if $s =~ /^\d{1,3}(\.\d{1,3}){3}$/;
    return 1 if $s =~ /^[0-9a-fA-F:]+$/ && $s =~ /:/;
    return 0;
}

sub _bytes_to_ipv4 {
    my ($bytes) = @_;
    return join('.', unpack('C4', $bytes));
}

sub _bytes_to_ipv6 {
    my ($bytes) = @_;
    my @parts = unpack('n8', $bytes);
    return sprintf('%x:%x:%x:%x:%x:%x:%x:%x', @parts);
}

# CIDR membership test.  Handles both IPv4 and IPv6 input strings.
sub _cidr_contains {
    my ($cidr, $ip) = @_;
    my ($net_str, $prefix) = split('/', $cidr, 2);
    return 0 unless defined $prefix;

    my $ip_bytes  = _ip_to_bytes($ip);
    my $net_bytes = _ip_to_bytes($net_str);
    return 0 unless defined $ip_bytes && defined $net_bytes;
    return 0 if length($ip_bytes) != length($net_bytes);

    my $total = length($ip_bytes) * 8;
    return 0 if $prefix < 0 || $prefix > $total;
    my $full   = int($prefix / 8);
    my $rem    = $prefix % 8;
    return 0 if $full > 0 && substr($ip_bytes, 0, $full) ne substr($net_bytes, 0, $full);
    if ($rem > 0) {
        my $mask = (0xFF << (8 - $rem)) & 0xFF;
        my $i = ord(substr($ip_bytes,  $full, 1)) & $mask;
        my $n = ord(substr($net_bytes, $full, 1)) & $mask;
        return 0 if $i != $n;
    }
    return 1;
}

sub _ip_to_bytes {
    my ($ip) = @_;
    return undef unless defined $ip;
    if ($ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) {
        return pack('C4', $1, $2, $3, $4);
    }
    if ($ip =~ /:/) {
        # IPv6: expand and pack.
        my @groups;
        if ($ip =~ /::/) {
            my ($head, $tail) = split('::', $ip, 2);
            $head //= '';
            $tail //= '';
            my @h = $head eq '' ? () : split(':', $head);
            my @t = $tail eq '' ? () : split(':', $tail);
            my $missing = 8 - (@h + @t);
            return undef if $missing < 0;
            @groups = (@h, ('0') x $missing, @t);
        } else {
            @groups = split(':', $ip);
        }
        return undef if @groups != 8;
        return pack('n8', map { hex($_) } @groups);
    }
    return undef;
}

1;
