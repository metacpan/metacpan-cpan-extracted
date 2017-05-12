##########################################################################
# Copyright (c) 2010-2012 Alexander Bluhm <alexander.bluhm@gmx.net>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
##########################################################################

use strict;
use warnings;

=pod

=head1 NAME

B<OSPF::LSDB::Cisco> - parse Cisco OSPF link state database

=head1 SYNOPSIS

use OSPF::LSDB::Cisco;

my $cisco = OSPF::LSDB::Cisco-E<gt>L<new>();

my $cisco = OSPF::LSDB::Cisco-E<gt>L<new>(ssh => "user@host");

$cisco-E<gt>L<parse>(%files);

=head1 DESCRIPTION

The B<OSPF::LSDB::Cisco> module parses the output of the Cisco OSPF
IOS and fills the B<OSPF::LSDB> base object.
The output of
C<show ip ospf>,
C<show ip ospf database router>,
C<show ip ospf database network>,
C<show ip ospf database summary>,
C<show ip ospf database asbr-summary>,
C<show ip ospf database external>
is needed.
It can be given as separate files or obtained dynamically.
In the latter case B<ssh> is invoked.
If the object has been created with the C<ssh> argument, the specified
user and host are used to login otherwise C<cisco> is used as host
name.

There is only one public method:

=cut

package OSPF::LSDB::Cisco;
use base 'OSPF::LSDB';
use File::Slurp;
use Regexp::Common;
use fields qw(
    selfid
    router network summary boundary external
);

# shortcut
my $IP = qr/$RE{net}{IPv4}{-keep}/;

# convert prefix length to packed IPv4 address
sub _prefix2pack($) { pack("B32", "1"x$_[0]."0"x(32-$_[0])) }

# convert packed IPv4 address to decimal dotted format
sub _pack2ip($) { join('.', unpack("CCCC", $_[0])) }

sub ssh_show {
    my OSPF::LSDB::Cisco $self = shift;
    my $host = $self->{ssh} || "cisco";
    my @cmd = ("ssh", $host, "show", "ip", "ospf", @_);
    my @lines = wantarray ? `@cmd` : scalar `@cmd`;
    die "Command '@cmd' failed: $?\n" if $?;
    return wantarray ? @lines : $lines[0];
}

sub read_files {
    my OSPF::LSDB::Cisco $self = shift;
    my %files = @_;
    my $file = $files{selfid};
    my @lines = $file ? read_file($file) : $self->ssh_show();
    $self->{selfid} = \@lines;
    my %show = (
	router   => "router",
	network  => "network",
	summary  => "summary",
	boundary => "asbr-summary",
	external => "external",
    );
    foreach (qw(router network summary boundary external)) {
	my $file = $files{$_};
	my @lines = $file ?
	  read_file($file) : $self->ssh_show("database", $show{$_});
	$self->{$_} = \@lines;
    }
}

sub parse_self {
    my OSPF::LSDB::Cisco $self = shift;
    my($routerid, @areas);
    foreach (@{$self->{selfid}}) {
	s/\r\n/\n/;
	if (/^ Routing Process "[- \w]*" with ID $IP$/) {
	    $routerid = $1;
	} elsif (/^    Area $IP(?: \(Inactive\))?$/) {
	    push @areas, $1;
	} elsif (/^    Area BACKBONE\((0\.0\.0\.0)\)(?: \(Inactive\))?$/) {
	    push @areas, $1;
	}
    }
    $self->{ospf}{self} = { routerid => $routerid, areas => \@areas };
}

sub parse_router {
    my OSPF::LSDB::Cisco $self = shift;
    my($area, $router, $link) = ("", "", "");
    my(@routers, $lnum, $type, $r, $l);
    foreach (@{$self->{router}}) {
	s/\r\n/\n/;
	if (/^ +OSPF Router with ID \($IP\) \(Process ID \d+\)$/) {
		# XXX TOOD implement support for multiple processes
		next;
	} elsif (/^\t+Router Link States \(Area $IP\)$/) {
	    die "$_ Link $link of router $router in area $area not finished.\n"
	      if $l;
	    die "$_ Too few links at router $router in area $area.\n" if $lnum;
	    die "$_ Router $router in area $area not finished.\n" if $r;
	    $area = $1;
	    next;
	} elsif (/^$/) {
	    if ($l) {
		die "Link $link of router $router in area $area without type.\n"
		  if ! $type;
		push @{$r->{$type.'s'}}, $l;
		undef $type;
		undef $l;
	    }
	    if (! $lnum) {
		undef $r;
	    }
	    next;
	} elsif (! $r && /^  \w/) {
	    die "$_ No area for router defined.\n" if ! $area;
	    $router = "";
	    $r = { area => $area, bits => { V => 0, E => 0, B => 0 } };
	    push @routers, $r;
	} elsif (! $l && /^ {4}\w/) {
	    die "$_ Too many links at router $router in area $area.\n"
	      if ! $lnum;
	    $lnum--;
	    $link = "";
	    $l = {};
	}
	if (/^  LS age: (?:MAXAGE\()?$RE{num}{int}{-keep}\)?$/) {
	    $r->{age} = $1;
	} elsif (/^  LS Type: ([\w ()]+)$/) {
	    die "$_ Type of router-LSA is $1 and not Links Router ".
	      "in area $area.\n" if $1 ne "Router Links";
	} elsif (/^  Link State ID: $IP$/) {
	    $r->{router} = $1;
	    $router = $1;
	} elsif (/^  Advertising Router: $IP$/) {
	    $r->{routerid} = $1;
	} elsif (/^  LS Seq Number: $RE{num}{hex}{-keep}$/) {
	    $r->{sequence} = "0x$1";
	} elsif (/^  AS Boundary Router$/) {
	    $r->{bits}{E} = 1;
	} elsif (/^  Area Border Router$/) {
	    $r->{bits}{B} = 1;
	} elsif (/^  Number of Links: $RE{num}{int}{-keep}$/) {
	    $lnum = $1;
	} elsif (/^    Link connected to: ([\w -]+)$/) {
	    if ($1 eq "a Point-to-Point") {
		$type = "pointtopoint";
	    } elsif ($1 eq "a Transit Network") {
		$type = "transit";
	    } elsif ($1 eq "a Stub Network") {
		$type = "stub";
	    } elsif ($1 eq "a Virtual Link") {
		$type = "virtual";
	    } else {
		die "$_ Unknown link type $1 at router $router ".
		  "in area $area.\n";
	    }
	} elsif (/^    Link ID \(Neighbors Router ID\): $IP$/) {
	    $l->{routerid} = $1;
	    $link = $1;
	} elsif (/^     \(Link ID\) Designated Router address: $IP$/) {
	    $l->{address} = $1;
	    $link = $1;
	} elsif (/^     \(Link ID\) Network\/subnet number: $IP$/) {
	    $l->{network} = $1;
	    $link = $1;
	} elsif (/^     \(Link Data\) Router Interface address: $IP$/) {
	    $l->{interface} = $1;
	} elsif (/^     \(Link Data\) Network Mask: $IP$/) {
	    $l->{netmask} = $1;
	} elsif (/^      Number of TOS metrics: 0$/) {
	    # TOS metrics unsupported
	} elsif (/^       TOS 0 Metrics: $RE{num}{int}{-keep}$/) {
	    $l->{metric} = $1;
	} elsif (/^ {4}\w/) {
	    die "$_ Unknown line at link $link of router $router ".
	      "in area $area.\n";
	} elsif (/^  Routing Bit Set on this LSA$/) {
	} elsif (/^  Adv Router is not-reachable$/) {
	} elsif (/^  Delete flag is set for this LSA$/) {
	} elsif (! /^  (Options|Checksum|Length):/) {
	    die "$_ Unknown line at router $router in area $area.\n";
	}
    }
    die "Link $link of router $router in area $area not finished.\n" if $l;
    die "Too few links at router $router in area $area.\n" if $lnum;
    die "Router $router in area $area not finished.\n" if $r;
    $self->{ospf}{database}{routers} = \@routers;
}

sub parse_network {
    my OSPF::LSDB::Cisco $self = shift;
    my($area, $network) = ("", "");
    my(@networks, $attachments, $n);
    foreach (@{$self->{network}}) {
	s/\r\n/\n/;
	if (/^ +OSPF Router with ID \($IP\) \(Process ID \d+\)$/) {
		# XXX TOOD implement support for multiple processes
		next;
	} elsif (/^\t+Net Link States \(Area $IP\)$/) {
	    die "$_ Attached routers of network $network in area $area ".
	      "not finished.\n" if $attachments;
	    die "$_ Network $network in area $area not finished.\n" if $n;
	    $area = $1;
	    next;
	} elsif (/^$/) {
	    undef $attachments;
	    undef $n;
	    next;
	} elsif (! $n) {
	    die "$_ No area for network defined.\n" if ! $area;
	    $network = "";
	    $n = { area => $area };
	    push @networks, $n;
	}
	if (/^  LS age: (?:MAXAGE\()?$RE{num}{int}{-keep}\)?$/) {
	    $n->{age} = $1;
	} elsif (/^  LS Type: ([\w ()]+)$/) {
	    die "$_ Type of network-LSA is $1 and not Network Links ".
	       "in area $area.\n" if $1 ne "Network Links";
	} elsif (/^  Link State ID: $IP \(address of Designated Router\)$/) {
	    $n->{address} = $1;
	    $network = $1;
	} elsif (/^  Advertising Router: $IP$/) {
	    $n->{routerid} = $1;
	} elsif (/^  LS Seq Number: $RE{num}{hex}{-keep}$/) {
	    $n->{sequence} = "0x$1";
	} elsif (/^  Network Mask: \/$RE{num}{int}{-keep}$/) {
	    $n->{netmask} = _pack2ip(_prefix2pack($1));
	} elsif (/^\tAttached Router: $IP$/) {
	    if (! $attachments) {
		$attachments = [];
		$n->{attachments} = $attachments;
	    }
	    push @$attachments, { routerid => $1 };
	} elsif (/^  Routing Bit Set on this LSA$/) {
	} elsif (/^  Adv Router is not-reachable$/) {
	} elsif (/^  Delete flag is set for this LSA$/) {
	} elsif (! /^  (Options|Checksum|Length):/) {
	    die "$_ Unknown line at network $network in area $area.";
	}
    }
    $self->{ospf}{database}{networks} = \@networks;
}

sub parse_summary {
    my OSPF::LSDB::Cisco $self = shift;
    my($area, $summary) = ("", "");
    my(@summarys, $s);
    foreach (@{$self->{summary}}) {
	s/\r\n/\n/;
	if (/^ +OSPF Router with ID \($IP\) \(Process ID \d+\)$/) {
		# XXX TOOD implement support for multiple processes
		next;
	} elsif (/^\t+Summary Net Link States \(Area $IP\)$/) {
	    die "$_ Summary $summary in area $area not finished.\n" if $s;
	    $area = $1;
	    next;
	} elsif (/^$/) {
	    undef $s;
	    next;
	} elsif (! $s) {
	    die "$_ No area for summary defined.\n" if ! $area;
	    $summary = "";
	    $s = { area => $area };
	    push @summarys, $s;
	}
	if (/^  LS age: (?:MAXAGE\()?$RE{num}{int}{-keep}\)?$/) {
	    $s->{age} = $1;
	} elsif (/^  LS Type: ([\w ()]+)$/) {
	    die "$_ Type of summary-LSA is $1 and not Summary Links(Network) ".
	      "in area $area.\n" if $1 ne "Summary Links(Network)";
	} elsif (/^  Link State ID: $IP \(summary Network Number\)$/) {
	    $s->{address} = $1;
	    $summary = $1;
	} elsif (/^  Advertising Router: $IP$/) {
	    $s->{routerid} = $1;
	} elsif (/^  LS Seq Number: $RE{num}{hex}{-keep}$/) {
	    $s->{sequence} = "0x$1";
	} elsif (/^  Network Mask: \/$RE{num}{int}{-keep}$/) {
	    $s->{netmask} = _pack2ip(_prefix2pack($1));
	} elsif (/^\tTOS: 0 \tMetric: $RE{num}{int}{-keep} $/) {
	    $s->{metric} = $1;
	} elsif (/^  Routing Bit Set on this LSA$/) {
	} elsif (/^  Adv Router is not-reachable$/) {
	} elsif (/^  Delete flag is set for this LSA$/) {
	} elsif (! /^  (Options|Checksum|Length):/) {
	    die "$_ Unknown line at summary $summary in area $area.\n";
	}
    }
    $self->{ospf}{database}{summarys} = \@summarys;
}

sub parse_boundary {
    my OSPF::LSDB::Cisco $self = shift;
    my($area, $boundary) = ("", "");
    my(@boundarys, $b);
    foreach (@{$self->{boundary}}) {
	s/\r\n/\n/;
	if (/^ +OSPF Router with ID \($IP\) \(Process ID \d+\)$/) {
		# XXX TOOD implement support for multiple processes
		next;
	} elsif (/^\t+Summary ASB Link States \(Area $IP\)$/) {
	    die "$_ Boundary $boundary in area $area not finished.\n" if $b;
	    $area = $1;
	    next;
	} elsif (/^$/) {
	    undef $b;
	    next;
	} elsif (! $b) {
	    die "$_ No area for boundary defined.\n" if ! $area;
	    $boundary = "";
	    $b = { area => $area };
	    push @boundarys, $b;
	}
	if (/^  LS age: (?:MAXAGE\()?$RE{num}{int}{-keep}\)?$/) {
	    $b->{age} = $1;
	} elsif (/^  LS Type: ([\w ()]+)$/) {
	    die "$_ Type of boundary-LSA is $1 and not ".
	      "Summary Links(AS Boundary Router) in area $area.\n"
	      if $1 ne "Summary Links(AS Boundary Router)";
	} elsif (/^  Link State ID: $IP \(AS Boundary Router address\)$/) {
	    $b->{asbrouter} = $1;
	    $boundary = $1;
	} elsif (/^  Advertising Router: $IP$/) {
	    $b->{routerid} = $1;
	} elsif (/^  LS Seq Number: $RE{num}{hex}{-keep}$/) {
	    $b->{sequence} = "0x$1";
	} elsif (/^\tTOS: 0 \tMetric: $RE{num}{int}{-keep} $/) {
	    $b->{metric} = $1;
	} elsif (/^  Routing Bit Set on this LSA$/) {
	} elsif (/^  Adv Router is not-reachable$/) {
	} elsif (/^  Delete flag is set for this LSA$/) {
	} elsif (! /^  (Options|Checksum|Length|Network Mask):/) {
	    die "$_ Unknown line at boundary $boundary in area $area.\n";
	}
    }
    $self->{ospf}{database}{boundarys} = \@boundarys;
}

sub parse_external {
    my OSPF::LSDB::Cisco $self = shift;
    my $external = "";
    my(@externals, $e);
    foreach (@{$self->{external}}) {
	s/\r\n/\n/;
	if (/^ +OSPF Router with ID \($IP\) \(Process ID \d+\)$/) {
		# XXX TOOD implement support for multiple processes
		next;
	} elsif (/^\t+Type-5 AS External Link States$/) {
	    die "$_ External $external not finished.\n" if $e;
	    die "$_ Too many external sections.\n", if @externals;
	    next;
	} elsif (/^$/) {
	    undef $e;
	    next;
	} elsif (! $e) {
	    $external = "";
	    $e = {};
	    push @externals, $e;
	}
	if (/^  LS age: (?:MAXAGE\()?$RE{num}{int}{-keep}\)?$/) {
	    $e->{age} = $1;
	} elsif (/^  LS Type: ([\w ()]+)$/) {
	    die "$_ Type of external-LSA is $1 and not AS External Link.\n"
	      if $1 ne "AS External Link";
	} elsif (/^  Link State ID: $IP \(External Network Number \)$/) {
	    $e->{address} = $1;
	    $external = $1;
	} elsif (/^  Advertising Router: $IP$/) {
	    $e->{routerid} = $1;
	} elsif (/^  LS Seq Number: $RE{num}{hex}{-keep}$/) {
	    $e->{sequence} = "0x$1";
	} elsif (/^  Network Mask: \/$RE{num}{int}{-keep}$/) {
	    $e->{netmask} = _pack2ip(_prefix2pack($1));
	} elsif (/^\tMetric Type: ([1-2]) /) {
	    $e->{type} = $1;
	} elsif (/^\tMetric: $RE{num}{int}{-keep} $/) {
	    $e->{metric} = $1;
	} elsif (/^\tForward Address: $IP$/) {
	    $e->{forward} = $1;
	} elsif (/^\t(TOS|External Route Tag):/) {
	} elsif (/^  Routing Bit Set on this LSA$/) {
	} elsif (/^  Adv Router is not-reachable$/) {
	} elsif (/^  Delete flag is set for this LSA$/) {
	} elsif (! /^  (Options|Checksum|Length):/) {
	    die "$_ Unknown line at external $external.";
	}
    }
    $self->{ospf}{database}{externals} = \@externals;
}

sub parse_lsdb {
    my OSPF::LSDB::Cisco $self = shift;
    $self->parse_router();
    $self->parse_network();
    $self->parse_summary();
    $self->parse_boundary();
    $self->parse_external();
}

=pod

=over 4

=item $self-E<gt>L<parse>(%files)

This function takes a hash with file names as value containing the
Cisco C<show ip ospf> output data.
The hash keys are named C<selfid>, C<router>, C<network>, C<summary>,
C<boundary>, C<external>.
If a hash entry is missing, B<ssh> to the Cisco router is run instead
to obtain the information dynamically.

The complete OSPF link state database is stored in the B<ospf> field
of the base class.

=back

=cut

sub parse {
    my OSPF::LSDB::Cisco $self = shift;
    my %files = @_;
    $self->read_files(%files);
    $self->parse_self();
    $self->parse_lsdb();
    $self->{ospf}{ipv6} = 0;
}

=pod

This module has been tested with Cisco IOS 12.4.
If it works with other versions is unknown.

=head1 ERRORS

The methods die if any error occurs.

=head1 SEE ALSO

L<OSPF::LSDB>

L<ciscoospf2yaml>

=head1 AUTHORS

Alexander Bluhm

=head1 BUGS

Cisco support is experimental.
This module is far from complete.

No support for multiple router processes.

No support for IPv6.

=cut

1;
