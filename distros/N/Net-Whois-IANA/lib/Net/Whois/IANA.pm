package Net::Whois::IANA;

use 5.006;

use strict;
use warnings;

use Carp;
use IO::Socket;

use Net::CIDR;

use base 'Exporter';

our $WHOIS_PORT    = 43;
our $WHOIS_TIMEOUT = 30;

our %IANA = (
	apnic   => [
		[ 'whois.apnic.net',   $WHOIS_PORT, $WHOIS_TIMEOUT, \&apnic_query   ],
	],
	ripe    => [
		[ 'whois.ripe.net',    $WHOIS_PORT, $WHOIS_TIMEOUT, \&ripe_query    ],
	],
	arin    => [
		[ 'whois.arin.net',    $WHOIS_PORT, $WHOIS_TIMEOUT, \&arin_query    ],
	],
	lacnic  => [
		[ 'whois.lacnic.net',  $WHOIS_PORT, $WHOIS_TIMEOUT, \&lacnic_query  ],
	],
	afrinic => [
		[ 'whois.afrinic.net', $WHOIS_PORT, $WHOIS_TIMEOUT, \&afrinic_query ],
	],
);

use base 'Exporter';

our $AUTOLOAD;
our @IANA = keys %IANA;

our @EXPORT = qw(
	@IANA
	%IANA
);

our $VERSION = '0.41';

sub new ($) {

    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = {};

    bless $self, $class;
    return $self;
}

sub AUTOLOAD ($;@) {

	my $self = shift;
	my @params = @_;

	my $method = $AUTOLOAD;
	$method = lc $method;
	my @path = split(/\:\:/, $method);
	$method = pop @path;
	return if $method =~ 'destroy';
	carp "No such method or property $method\n"
		unless exists $self->{QUERY} && exists $self->{QUERY}{$method};
	return $self->{QUERY}{$method};
}

sub whois_connect ($;$$) {

    my $host    = shift;
	my $port;
	my $timeout;

	if (ref $host && ref $host eq 'ARRAY') {
		$port    = $host->[1] || $WHOIS_PORT;
		$timeout = $host->[2] || $WHOIS_TIMEOUT;
		$host    = $host->[0];
	}
	else {
		$port    = shift || $WHOIS_PORT;
		$timeout = shift || $WHOIS_TIMEOUT;
	}

	my $retries = 2;
	my $sleep   = 1;
	my $r = 0;
	my $sock;

	do {
		if ($r) {
			carp "Cannot connect to $host at port $port";
			carp $@;
			sleep $sleep;
		}
		$sock = IO::Socket::INET->new(
			PeerAddr => $host,
			PeerPort => $port,
			Timeout  => $timeout,
		);
		$r++;
	} until ($sock || $r == $retries);

    return $sock || 0;
}

sub is_valid_ip ($) {

	my $ip = shift;

	return $ip
		&& $ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/
		&& (($1+0)|($2+0)|($3+0)|($4+0)) < 0x100;
}

sub set_source ($$) {

	my $self   = shift;
	my $source = shift;

	$self->{source} = {%IANA} || return 0 unless $source;
	return 0 unless $source;
	unless (ref $source) {
		if($IANA{$source}) {
			$self->{source} = {$source => $IANA{$source} };
			return 0;
		}
		return 1;
	}
	return 2 unless ref $source eq 'HASH' && scalar grep {
		ref $_ && ref $_ eq 'ARRAY' && @{$_} &&
		ref $_->[0] && ref $_->[0] eq 'ARRAY' && @{$_->[0]} &&
		$_->[0][0]
	} values %{$source} == scalar keys %{$source};
	$self->{source} = $source;
	return 0;
}

sub init_query ($%) {

    my $self = shift;
    my %param = @_;

    if (! is_valid_ip($param{-ip})) {
		warn q{
Method usage:
$iana->whois_query(
	-ip=>$ip,
	-debug=>$debug, # optional
	-whois=>$whois | -mywhois=>\%mywhois, # optional
};
		return {};
	}

	my $set_source = $self->set_source($param{-whois} || $param{-mywhois});
	if ($set_source == 1) {
		warn "Unknown whois server requested. Known servers are:\n";
		warn join(", ", @IANA) . "\n";
		return {};
	}
    elsif ($set_source == 2) {
		warn q{
Custom sources must be of form:
%source = (
	source_name1 => [
		[ source_host, source_port || undef, source_timeout || undef, \&source_query || undef ],
	],
	source_name1 => [
		[ source_host, source_port || undef, source_timeout || undef, \&source_query || undef ],
	],
	...,
);
		};
    }
}

sub source_connect ($$) {

	my $self = shift;
	my $source_name = shift;
	my $i = 0;
	my $sock;
	do {
		$sock = whois_connect($self->{source}{$source_name}[$i]);
		$self->{query_sub} =
			ref $self->{source}{$source_name}[$i][3] &&
			ref $self->{source}{$source_name}[$i][3] eq 'CODE' ?
				$self->{source}{$source_name}[$i][3] : \&default_query;
		$self->{whois_host} = $self->{source}{$source_name}[$i][0];
		$i++;
	} until ($sock || !defined $self->{source}{$source_name}[$i]);
	return $sock;
}

sub post_process_query (%) {

	my %query = @_;
	for my $qkey (keys %query) {
		chomp $query{$qkey} if defined $query{$qkey};
		$query{abuse} = $query{$qkey} and last
			if $qkey =~ /abuse/i && $query{$qkey} =~ /\@/;
	}
	unless ($query{abuse}) {
		if ($query{fullinfo} && $query{fullinfo} =~ /(\S*abuse\S*\@\S+)/m) {
			$query{abuse} = $1;
		}
		elsif ($query{email} || $query{'e-mail'} || $query{orgtechemail}) {
			$query{abuse} =
				$query{email} || $query{'e-mail'} || $query{orgtechemail};
		}
	}
	if (!ref $query{cidr}) {
		if ($query{cidr} =~ /\,/) {
			$query{cidr} = [split(/\, /, $query{cidr})];
		}
		else {
			$query{cidr} = [ $query{cidr} ];
		}
	}
	return %query;
}

sub whois_query ($%) {

	my $self = shift;
	my %params = @_;

	$self->init_query(%params);
	my @source_names = keys %{$self->{source}};
    $self->{QUERY} = {};
    for my $source_name (@source_names) {
		print STDERR "Querying $source_name ...\n" if $params{-debug};
		my $sock = $self->source_connect($source_name) ||
			carp "Connection failed to $source_name." && next;
		my %query = $self->{query_sub}($sock, $params{-ip});
		next if (! keys %query);
		carp "Warning: permission denied at $source_name server $self->{whois_host}\n" and next
			if $query{permission} eq 'denied';
		$query{server} = uc $source_name;
		$self->{QUERY} = {post_process_query(%query)};
		return $self->{QUERY};
    }
    return {};
}


sub default_query ($$) {

    return arin_query(@_);
}

sub ripe_read_query ($$) {

	my $sock = shift;
	my $ip = shift;

    my %query = (fullinfo => '');
    print $sock "-r $ip\n";
    while (<$sock>) {
		$query{fullinfo} .= $_;
		close $sock and return (permission => 'denied') if /ERROR:201/;
		next if (/^(\%|\#)/ || !/\:/);
		s/\s+$//;
		my ($field,$value) = split(/:/);
		$value =~ s/^\s+//;
		$query{$field} .= $value;
		last if (/^route/);
    }
    close $sock;
	return %query;
}

sub ripe_process_query (%) {

	my %query = @_;
    if (
		(
			defined $query{remarks} &&
			$query{remarks} =~ /The country is really world wide/
		) || (
			defined $query{netname} &&
			$query{netname} =~ /IANA-BLK/
		) || (
			defined $query{netname} &&
			$query{netname} =~ /AFRINIC-NET-TRANSFERRED/
		) || (
			defined $query{country} &&
			$query{country} =~ /world wide/
		)
	) {
		return ();
    }
    else {
		$query{permission} = 'allowed';
        $query{cidr} = [ Net::CIDR::range2cidr($query{inetnum}) ];
    }
    return %query;
}

sub ripe_query ($$) {

    my $sock = shift;
    my $ip = shift;

    my %query = ripe_read_query($sock, $ip);
    return () unless defined $query{country};
	return ripe_process_query(%query);
}

sub apnic_read_query ($$) {

    my $sock = shift;
    my $ip = shift;

    my %query = (fullinfo => '');
	my %tmp;
    print $sock "-r $ip\n";
    while (<$sock>) {
		$query{fullinfo} .= $_;
		close $sock and	return (permission => 'denied') if /^\%201/;
		next if (/^\%/ || !/\:/);
		s/\s+$//;
		my ($field,$value) = split(/:/);
		$value =~ s/^\s+//;
		if ($field eq 'inetnum') {
			%tmp = %query;
			%query = ();
			$query{fullinfo} = $tmp{fullinfo};
		}
		$query{$field} .= $value;
    }
    close $sock;
    for (keys %tmp) {
		$query{$_} = $tmp{$_} if ! defined $query{$_};
    }
	return %query;
}

sub apnic_process_query (%) {

	my %query = @_;
    if (
		(
			defined $query{remarks} &&
			$query{remarks} =~ /address range is not administered by APNIC/
		) || (
			defined $query{descr} &&
			$query{descr} =~ /not allocated to|by APNIC|placeholder reference/i
		)
	) {
		return ();
    }
    else {
    	$query{permission} = 'allowed';
		$query{cidr} = [Net::CIDR::range2cidr($query{inetnum})];
    }
    return %query;
}

sub apnic_query ($$) {

    my $sock = shift;
    my $ip = shift;

    my %query = apnic_read_query($sock, $ip);
	return apnic_process_query(%query);
}

sub arin_read_query ($$) {

	my $sock = shift;
	my $ip = shift;

    my %query = (fullinfo => '');
	my %tmp = ();

    print $sock "+ $ip\n";
    while (<$sock>) {
		$query{fullinfo} .= $_;
		close $sock and return (permission => 'denied') if /^\#201/;
		return () if /no match found for/i;
		next if (/^\#/ || !/\:/);
		s/\s+$//;
		my ($field,$value) = split(/:/);
		$value =~ s/^\s+//;
		if ($field eq 'OrgName' ||
				$field eq 'CustName') {
			%tmp = %query;
			%query = ();
			$query{fullinfo} = $tmp{fullinfo};
		}
		$query{lc($field)} .= $value;
    }
    close $sock;
    $query{orgname} = $query{custname} if defined $query{custname};
    for (keys %tmp) {
		$query{$_} = $tmp{$_} unless defined $query{$_};
    }
	return %query;
}

sub arin_process_query (%) {

	my %query = @_;

    return () unless
		$query{country} or
		$query{nettype} !~ /allocated to/i or
			$query{comment} &&
			$query{comment} =~ /This IP address range is not registered in the ARIN/ or
			$query{orgid} &&
			$query{orgid} =~ /RIPE|LACNIC|APNIC|AFRINIC/;

	$query{permission} = 'allowed';
	$query{descr}   = $query{orgname};
	$query{remarks} = $query{comment};
	$query{status}  = $query{nettype};
	$query{inetnum} = $query{netrange};
	$query{source}  = 'ARIN';
	if ($query{cidr} =~ /\,/) {
		$query{cidr} = [split(/\, /,$query{cidr})];
	}
	else {
		$query{cidr} = [$query{cidr}];
	}
    return %query;
}


sub arin_query ($$) {

    my $sock = shift;
    my $ip = shift;
    my %query = arin_read_query($sock, $ip);
	return arin_process_query(%query);
}

sub lacnic_read_query ($$) {

    my $sock = shift;
    my $ip = shift;
    my %query = (fullinfo => '');

    print $sock "$ip\n";

    while (<$sock>) {
		$query{fullinfo} .= $_;
		close $sock and return (permission => 'denied') if
			/^\%201/ ||
			/^\% Query rate limit exceeded/ ||
			/^\% Not assigned to LACNIC/ ||
			/\% Permission denied/;
		if (/^\% (\S+) resource:/) {
			my $srv = $1;
			close $sock and return () if $srv !~ /lacnic|brazil/i;
		}
		next if (/^\%/ || !/\:/);
		s/\s+$//;
		my ($field,$value) = split(/:/);
		$value =~ s/^\s+//;
		next if $field eq 'country' && $query{country};
		$query{lc($field)} .= ( $query{lc($field)} ?  ' ' : '') . $value;
    }
	close $sock;
	return %query;
}

sub lacnic_process_query (%) {

	my %query = @_;

	$query{permission} = 'allowed';
    $query{descr} = $query{owner};
    $query{netname} = $query{ownerid};
    $query{source} = 'LACNIC';
	if ($query{inetnum}) {
		$query{cidr} = $query{inetnum};
		$query{inetnum} = (Net::CIDR::cidr2range($query{cidr}))[0];
	}
	unless ($query{country}) {
		if ($query{nserver} && $query{nserver} =~ /\.(\w\w)$/) {
			$query{country} = uc $1;
		}
		elsif ($query{descr} && $query{descr} =~ /\s(\w\w)$/) {
			$query{country} = uc $1;
		}
		else {
			return ();
		}
	}
    return %query;
}

sub lacnic_query ($$) {

    my $sock = shift;
    my $ip = shift;
    my %query = lacnic_read_query($sock, $ip);
	return lacnic_process_query(%query);
}

sub afrinic_read_query ($$) {

    my $sock = shift;
    my $ip = shift;

    my %query = (fullinfo => '');
    print $sock "-r $ip\n";
    while (<$sock>) {
        $query{fullinfo} .= $_;
        close $sock and return (permission => 'denied') if /^\%201/;
        next if (/^\%/ || !/\:/);
        s/\s+$//;
        my ($field,$value) = split(/:/);
        $value =~ s/^\s+//;
        $query{$field} .= $value;
    }
    close $sock;
	return %query;
}

sub afrinic_process_query (%) {

	my %query = @_;

    return () if
		defined $query{remarks} &&
		$query{remarks} =~ /country is really worldwide/
			or
		defined $query{descr} &&
		$query{descr} =~ /Here for in-addr\.arpa authentication/;
	$query{permission} = 'allowed';
	$query{cidr} = [ Net::CIDR::range2cidr($query{inetnum}) ];
    return %query;
}

sub afrinic_query ($$) {

    my $sock = shift;
    my $ip = shift;
    my %query = afrinic_read_query($sock, $ip);
	return afrinic_process_query(%query);
}

sub is_mine ($$;@) {

	my $self = shift;
	my $ip   = shift;
	my @cidr = @_;

    return 0 unless is_valid_ip($ip);
    @cidr = @{$self->cidr()} unless @cidr;
	@cidr = map(split(/\s+/), @cidr);
	@cidr = map {
		my @dots = (split/\./);
		my $pad = '.0' x (4 - @dots);
		s|(/.*)|$pad$1|;
		$_;
	} @cidr;
	return Net::CIDR::cidrlookup($ip, @cidr);
}

1;

__END__

=head1 NAME

Net::Whois::IANA - A universal WHOIS data extractor.

=head1 SYNOPSIS

  use Net::Whois::IANA;
  my $ip = '132.66.16.2';
  my $iana = new Net::Whois::IANA;
  $iana->whois_query(-ip=>$ip);
  print "Country: " , $iana->country()            , "\n";
  print "Netname: " , $iana->netname()            , "\n";
  print "Descr: "   , $iana->descr()              , "\n";
  print "Status: "  , $iana->status()             , "\n";
  print "Source: "  , $iana->source()             , "\n";
  print "Server: "  , $iana->server()             , "\n";
  print "Inetnum: " , $iana->inetnum()            , "\n";
  print "CIDR: "    , join(",", $iana->cidr())    , "\n";


=head1 ABSTRACT

  This is a simple module to extract the descriptive whois
information about various IPs as they are stored in the four
regional whois registries of IANA - RIPE (Europe, Middle East)
APNIC (Asia/Pacific), ARIN (North America), AFRINIC (Africa) 
and LACNIC (Latin American & Caribbean).

  It is designed to serve statistical harvesters of various
access logs and likewise, therefore it only collects partial
and [rarely] unprecise information.

=head1 DESCRIPTION

  Various Net::Whois and IP:: modules have been created.
This is just something I had to write because none of them s
uited my purpose. It is conceptually based on Net::Whois::IP
by Ben Schmitz <bschmitz@orbitz.com>, but differs from it by
a few points:

  * It is object-oriented.
  * It has a few immediate methods for representing some whois
  fields.
  * It allows the user to specify explicitly which whois servers
  to query, and those servers might even not be of the four main
  registries mentioned above.
  * It has more robust error handling.

  Net::Whois::IANA was designed to provide a mechanism to lookup
whois information and store most descriptive part of it (descr,
netname and country fields) in the object. This mechanism is
supposed to be attached to a log parser (for example an Apache
web server log) to provide various accounting and statistics
information.

  The query is performed in a roundrobin system over all four
registries until a valid entry is found. The valid entry stops
the main query loop and the object with information is returned.
Unfortunately, the output formats of each one of the registries
is not completely the same and sometimes even unsimilar but
some common ground was always found and the assignment of the
information into the query object is based upon this common
ground, whatever misleading it might be.

  The query to the RIPE and APNIC registries are always performed
with a '-r' flag to avoid blocking of the querying IP. Thus, the
contact info for the given entry is not obtainable with this
module. The query to the ARIN registry is performed with a '+'
flag to force the colon-separated output of the information.

=head2 EXPORT

  For the convenience of the user, basic list of IANA servers
(@IANA) and their mapping to host names and ports (%IANA) are
being exported.

  Also the following methods are being exported:

  $iana->whois_query(-ip=>$ip,-whois=>$whois|-mywhois=>\%mywhois) :

    Perform the query on the ip specified by $ip. You can limit
  the lookup to a single server (of the IANA list) by specifying
  '-whois=>$whois' pair or you can provide a set of your own
  servers by specifying the '-mywhois=>\%mywhois' pair. The latter
  one overrides all of the IANA list for lookup. You can also set
  -debug option in order to trigger some verbosity in the output.

  $iana->descr()

    Returns some of the "descr:" field contents of the queried IP.

  $iana->netname()

    Returns the "netname:" field contents of the queried IP.

  $iana->country()

    Returns "country:" field contents of the queried IP. Useful
  to combine with the Geography::Countries module.

  $iana->inetnum()

    Returns the IP range of the queried IP. Often it is contained
  within the inetnum field, but it is calculated for LACNIC.

  $iana->status()

    Returns the "status:" field contents of the queried IP.

  $iana->source()

    Returns the "source:" field contents of the queried IP.

  $iana->server()

    Returns the server that returned most valuable ntents of
  the queried IP.

  $iana->cidr()

    Returns an array in CIDR notation (1.2.3.4/5) of the IP's registered
  range.

  $iana->fullinfo()

    Returns the complete output of the query.

  $iana->is_mine($ip,@cidrrange)

    Checks if the ip is within one of the CIDR ranges given by
  @cidrrange. Returns 0 if none, 1 if a range matches.

  $iana->abuse()

    Yields the best guess for the potential abuse report email address
  candidate. This is not a very reliable thing, but sometimes it proves
  useful.

=head1 BUGS

  As stated many times before, this module is not completely
homogeneous and precise because of the differences between
outputs of the IANA servers and because of some inconsistencies
within each one of them. Its primary target is to collect info
for general, shallow statistical purposes. The is_mine() method
might be optimized.

=head1 CAVEATS

  The introduction of AFRINIC server may create some confusion
among servers. It might be that some entries are existant either in
both ARIN and AFRINIC or in both RIPE and AFRINIC, and some do not
exist at all. Moreover, there is a border confusion between Middle
East and Africa, thus, some Egypt sites appear under RIPE and some
under AFRINIC. LACNIC server arbitrarily imposes query rate temporary
block. ARIN "subconciously" redirects the client to appropriate
server sometimes. This redirection is not reflected yet by the package.

=head1 SEE ALSO

  Net::Whois::IP, Net::Whois::RIPE, IP::Country,
  Geography::Countries, Net::CIDR, NetAddr::IP,

=head1 AUTHOR

Roman M. Parparov, E<lt>roman@parparov.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2011 Bolet Consulting <bolet@parparov.com> and Roman M. Parparov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
