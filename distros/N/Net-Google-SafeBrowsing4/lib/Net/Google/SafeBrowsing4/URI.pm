package Net::Google::SafeBrowsing4::URI;

use strict;
use warnings;

use Digest::SHA qw(sha256);
use Net::IP::Lite qw();
use URI;

=encoding utf-8

=head1 NAME

Net::Google::SafeBrowsing4::URI - URI management Class for the Google SafeBrowsing (version 4) API.


=head1 SYNOPSIS

	use Net::Google::SafeBrowsing4::URI;

	my $gsb_uri = Net::Google::SafeBrowsing4::URI->new('http://my.example.site:80/path/to/file.html?query=param#fragment');
	my @uris = $gsb_uri->generate_lookupuris();

=head1 DESCRIPTION

Net::Google::SafeBrowsing4::URI takes care of normalizing URLs, extracting suffix/prefix expressions, calculating hashes.

=head1 METHODS

=over

=item new

=back

	my $gsb_uri = Net::Google::SafeBrowsing4::URI->new('http://my.example.site:80/path/to/file.html?query=param#fragment');

=over

Initializes the object.

Arguments:

=over

=item $uri The URL to parse

=back

=back

=cut

sub new {
	my $class = shift;
	my @args = @_;

	if ((scalar(@args) == 0) || !$args[0]) {
		return undef;
	}

	my $self = {
		rawuri => $args[0],
	};

	bless($self, $class);
	return $self->_normalize() ? $self : undef;
}

=over

=item as_string

Returns the normalized URI as string.

=back

=cut

sub as_string {
	my $self = shift;

	return '' . $self->{uri};
}

=item generate_lookupuris

Generates all partial/full URIs supported by Google SafeBrowsing. See "suffix/prefix expressions" topic in GSBv4 API reference.
Returns a list of L<Net::Google::SafeBrowsing4::URI> objects.

=cut

sub generate_lookupuris {
	my $self = shift;
	my @uris = ();

	$self->as_string() =~ /^(https?:\/\/)([^\/]+)(\/[^\?]*)(\??.*)$/i;
	my ($scheme, $host, $path, $query) = ($1, $2, $3, $4);

	# Collect host suffixes
	my @domains = ();
	if ($host !~ /^\d+\.\d+\.\d+\.\d+$/) {
		my @parts = split(/\./, $host);
		splice(@parts, 0, -6); # take 5 top most components

		while (scalar(@parts) > 2) {
			shift(@parts);
			push(@domains, join(".", @parts));
		}
	}
	push(@domains, $host);

	# Collect path & query prefixes
	my @paths = ();
	if ($path ne '/') {
		my @parts = split(/\//, $path);
		my $part_count = scalar(@parts);
		$part_count = $part_count > 4 ? 4 : $part_count - 1; # limit to 4
		my $previous = "";
		
		push(@paths, "/");
		# Skip the first entry in @parts as it is always an empty string
		for (my $i = 1; $i < $part_count; $i++) {
			$previous .= "/" . $parts[$i] ."/";
			push(@paths, $previous);
		}
	}
	push(@paths, $path);
	if ($query =~ /^\?.*/) {
		push(@paths, $path . $query);
	}

	# Assemble the list of Net::Google::SafeBrowsing4::URI objects
	foreach my $domain (@domains) {
		foreach my $path (@paths) {
			my $gsb_uri = Net::Google::SafeBrowsing4::URI->new($scheme . $domain . $path);
			# @TODO Sub-URI of a valid URI should be a valid URI. Condition should not be necessary.
			if (defined($gsb_uri)) {
				push(@uris, $gsb_uri);
			}
		}
	}

	return @uris;
}

=item hash

Generates the SHA-256 hash of the URI (with scheme removed).

=cut

sub hash {
	my $self = shift;

	my $uri = $self->as_string();
	$uri =~ s/^https?:\/\///i;

	return sha256($uri);
}

=head1 PRIVATE METHODS

=over

=item _normalize

Parses and normalizes the URI.

=back

=cut

sub _normalize {
	my $self = shift;
	my $modified_rawuri = $self->{rawuri};

	# Remove third and more slashes after the scheme
	$modified_rawuri =~ s/^(\s*https?:\/\/)\/+/$1/si;
	# Remove any Tab, CR, LF characters from the URI
	$modified_rawuri =~ s/[\r\n\t]+//sgi;
	# Recursive percent-unescape (everything but '#' not to confuse URI parser)
	while ($modified_rawuri =~ s{%(?!23)([[:xdigit:]]{2})}{chr(hex($1))}esg) { }

	# Parse URI
	my $uri_obj = URI->new($modified_rawuri);
	if (ref($uri_obj) !~ /^URI::https?$/) {
		if (!$uri_obj->scheme() || (!$uri_obj->has_recognized_scheme() && $modified_rawuri =~ /^[^:]+:\d{1,5}(?:\/|$)/)) {
			$uri_obj = URI->new("http://" . $modified_rawuri);
		}
	}
	# Only http and https URIs are supported
	if (ref($uri_obj) !~ /^URI::https?$/) {
		return undef;
	}

	# Remove userinfo
	$uri_obj->userinfo(undef);
	# Remove port
	$uri_obj->port(undef);
	# Remove Fragment
	$uri_obj->fragment(undef);

	# Host modifications
	my $modified_host = $uri_obj->host();
	# Host part cannot be empty
	if ($modified_host =~ /^\s*$/) {
		return undef;
	}
	# Collapse consecutive dots into one
	$modified_host =~ s/\.\.+/\./sg;
	# Remove leading and trailing dot
	$modified_host =~ s/^\.|\.$//sg;

	# IPv4 canonicalizations
	$modified_host = _normalize_ip($modified_host);
	if (!defined($modified_host)) {
		return undef;
	}
	$uri_obj->host($modified_host);

	# Empty/separator-only host
	if ($uri_obj->host() =~ /^[\s.\/]*$/) {
		return undef;
	}

	# Numeric TLD (and not IPv4)
	if ($uri_obj->host() =~ /\.\d[^\.]*$/
	 && $uri_obj->host() !~ /^(?:2(?:5[0-5]|[0-4][0-9])|[01]?[0-9]{1,2})(?:\.(?:2(?:5[0-5]|[0-4][0-9])|[01]?[0-9]{1,2})){3}$/) {
		return undef;
	}

	my $modified_path = $uri_obj->path();
	# Eliminate current directory /./ parts
	while ($modified_path =~ s/\/\.(?:\/|$)/\//sg) {};
	# Eliminate parent directory /something/./ parts
	while ($modified_path =~ s/\/[^\/]+\/\.\.(?:\/|$)/\//sg) {};
	# Eliminate double // slashes from path
	$modified_path =~ s/\/\/+/\//sg;
	if ($modified_path eq '') {
		$modified_path = '/';
	}
	$uri_obj->path($modified_path);

	# Fix some percent encoding
	my $modified_path_query = $uri_obj->path_query();
	# Fix lone percent signs %
	$modified_path_query =~ s/%(?![[:xdigit:]]{2})/%25/sg;
	$uri_obj->path_query($modified_path_query);

	my $canonical = $uri_obj->canonical();
	# Fix caret escaping
	$canonical=~ s/%5E/\^/sg;

	$self->{uri} = $canonical;

	return $self->{uri};
}

=head1 PRIVATE FUNCTIONS

=over

=item _normalize_ip

Function for recognising various IPv4 formatted addresses and convert them to I<dotted-decimal-quad> format (111.11.1.1)

Arguments:

=over

=item $host

Hostname to parse as IP Address

=back

=back

=cut

sub _normalize_ip {
	my $host = shift;

	# Shortcut: If it doesn't look like an IPv4, then return early
	if ($host !~ /^(?:0x[[:xdigit:]]+|\d+)(?:\.(?:0x[[:xdigit:]]+|\d+))*$/si) {
		return $host;
	}

	# Most formats are detected and converted by Net::IP::Lite
	my $ip = Net::IP::Lite->new($host);
	if ($ip) {
		return $ip->transform();
	}

	# One and two dots case is missing: xxx.xxxxxxxxxx, xxx.xxx.xxxxxx
	my $bits = 32;
	my @segments = split(/\./, $host);
	my $segment_count = scalar(@segments);

	my $decimal = 0;
	for (my $i = 0; $i < $segment_count; $i++) {
		my $is_last_segment = $i >= $segment_count - 1;
		my $segment = _parse_ipv4_segment($segments[$i], !$is_last_segment ? 8 : $bits);
		if (!defined($segment)) {
			return undef;
		}
		$bits -= 8;
		$decimal +=  $segment << (!$is_last_segment ? $bits : 0);
	}

	$ip = Net::IP::Lite->new($decimal);
	return $ip->transform();
}

=over

=item _parse_ipv4_segment

=back

	my $decimal = _parse_ipv4_part($segment, $bits)

=over

Transforms one IPv4 segment to decimal with range checking.

Arguments:

=over

=item $segment

Decimal/octal/hexadecimal value to parse

=item $bits

Bit length for range checking

=back

=back

=cut

sub _parse_ipv4_segment {
	my $segment = shift;
	my $bits = shift;
	my $decimal;

	if ($segment =~ /^0+([0-7]{0,10}|[0-3][0-7]{10})$/) {
		$decimal = oct($1);
	}
	elsif ($segment =~ /^0x0*([[:xdigit:]]{1,8})$/si) {
		$decimal = hex($1);
	}
	elsif ($segment =~ /^[1-9]\d+$/) {
		$decimal = $segment;
	}
	else {
		return undef;
	}

	if ($decimal >= (1 << $bits)) {
		return undef;
	}
	return $decimal;
}

=head1 BUGS

Some URI normalizatuion cases are still missing:

=over

=item Highbit characters in hostname are punycoded, not percent encoded.

Google's GO Client percent-escapes based on the hostname is a valid unicode string or not

=back

=head1 AUTHORS

Tamás Fehérvári, E<lt>geever@users.sourceforge.net<gt>
Julien Sobrier, E<lt>julien@sobrier.netE<gt>,

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Julien Sobrier, Tamás Fehérvári

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
