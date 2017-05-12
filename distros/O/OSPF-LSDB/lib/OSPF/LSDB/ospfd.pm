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

B<OSPF::LSDB::ospfd> - parse OpenBSD B<ospfd> link state database

=head1 SYNOPSIS

use OSPF::LSDB::ospfd;

my $ospfd = OSPF::LSDB::ospfd-E<gt>L<new>();

my $ospfd = OSPF::LSDB::ospfd-E<gt>L<new>(ssh => "user@host");

$ospfd-E<gt>L<parse>(%files);

=head1 DESCRIPTION

The B<OSPF::LSDB::ospfd> module parses the output of OpenBSD B<ospfctl>
and fills the B<OSPF::LSDB> base object.
The output of
C<show summary>,
C<show database router>,
C<show database network>,
C<show database summary>,
C<show database asbr>,
C<show database external>
is needed.
It can be given as separate files or obtained dynamically.
In the latter case B<sudo> is invoked if permissions are not
sufficient to run B<ospfctl>.
If the object has been created with the C<ssh> argument, the specified
user and host are used to login and run B<ospfctl> there.

There is only one public method:

=cut

package OSPF::LSDB::ospfd;
use base 'OSPF::LSDB';
use File::Slurp;
use Regexp::Common;
use fields qw(
    ospfctl ospfsock showdb
    selfid
    router network summary boundary external
);

sub new {
    my OSPF::LSDB::ospfd $self = OSPF::LSDB::new(@_);
    $self->{ospfctl} = "ospfctl";
    $self->{ospfsock} = "/var/run/ospfd.sock";
    $self->{showdb} = {
	router   => "router",
	network  => "network",
	summary  => "summary",
	boundary => "asbr",
	external => "external",
    };
    return $self;
}

# shortcut
my $IP = qr/$RE{net}{IPv4}{-keep}/;

sub ospfctl_show {
    my OSPF::LSDB::ospfd $self = shift;
    my @cmd = ($self->{ospfctl}, "show", @_);
    if ($self->{ssh}) {
	unshift @cmd, "ssh", $self->{ssh};
    } else {
	# no sudo if user is root or in wheel group
	# srw-rw----  1 root  wheel  0 Jun 13 10:10 /var/run/ospfd.sock
	unshift @cmd, "sudo" unless -w $self->{ospfsock};
    }
    my @lines = wantarray ? `@cmd` : scalar `@cmd`;
    die "Command '@cmd' failed: $?\n" if $?;
    return wantarray ? @lines : $lines[0];
}

sub read_files {
    my OSPF::LSDB::ospfd $self = shift;
    my %files = @_;
    my $file = $files{selfid};
    my @lines = $file ? read_file($file) : $self->ospfctl_show("summary");
    $self->{selfid} = \@lines;
    foreach (sort keys %{$self->{showdb}}) {
	my $file = $files{$_};
	my @lines = $file ? read_file($file) :
	    $self->ospfctl_show("database", $self->{showdb}{$_});
	$self->{$_} = \@lines;
    }
}

sub parse_self {
    my OSPF::LSDB::ospfd $self = shift;
    my($routerid, @areas);
    foreach (@{$self->{selfid}}) {
	if (/^Router ID: $IP$/) {
	    $routerid = $1;
	} elsif (/^Area ID: $IP$/) {
	    push @areas, $1;
	}
    }
    $self->{ospf}{self} = { routerid => $routerid, areas => \@areas };
}

sub parse_router {
    my OSPF::LSDB::ospfd $self = shift;
    my($area, $router, $link) = ("", "", "");
    my(@routers, $lnum, $type, $r, $l);
    foreach (@{$self->{router}}) {
	if (/^ +Router Link States \(Area $IP\)$/) {
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
	} elsif (! $r && /^\w/) {
	    die "$_ No area for router defined.\n" if ! $area;
	    $router = "";
	    $r = { area => $area };
	    push @routers, $r;
	} elsif (! $l && /^ {4}\w/) {
	    die "$_ Too many links at router $router in area $area.\n"
	      if ! $lnum;
	    $lnum--;
	    $link = "";
	    $l = {};
	}
	if (/^LS age: $RE{num}{int}{-keep}$/) {
	    $r->{age} = $1;
	} elsif (/^LS Type: ([\w ()]+)$/) {
	    die "$_ Type of router-LSA is $1 and not Router in area $area.\n"
	      if $1 ne "Router";
	} elsif (/^Link State ID: $IP$/) {
	    $r->{router} = $1;
	    $router = $1;
	} elsif (/^Advertising Router: $IP$/) {
	    $r->{routerid} = $1;
	} elsif (/^LS Seq Number: (0x$RE{num}{hex})$/) {
	    $r->{sequence} = $1;
	} elsif (/^Flags: ([-*|\w]*)$/) {
	    my $flags = $1;
	    foreach (qw(V E B)) {
		$r->{bits}{$_} = $flags =~ /\b$_\b/ ? 1 : 0;
	    }
	} elsif (/^Number of Links: $RE{num}{int}{-keep}$/) {
	    $lnum = $1;
	} elsif (/^    Link connected to: ([\w -]+)$/) {
	    if ($1 eq "Point-to-Point") {
		$type = "pointtopoint";
	    } elsif ($1 eq "Transit Network") {
		$type = "transit";
	    } elsif ($1 eq "Stub Network") {
		$type = "stub";
	    } elsif ($1 eq "Virtual Link") {
		$type = "virtual";
	    } else {
		die "$_ Unknown link type $1 at router $router ".
		  "in area $area.\n";
	    }
	} elsif (/^    Link ID \(Neighbors Router ID\): $IP$/) {
	    $l->{routerid} = $1;
	    $link = $1;
	} elsif (/^    Link ID \(Designated Router address\): $IP$/) {
	    $l->{address} = $1;
	    $link = $1;
	} elsif (/^    Link ID \(Network ID\): $IP$/) {
	    $l->{network} = $1;
	    $link = $1;
	} elsif (/^    Link Data \(Router Interface address\): $IP$/) {
	    $l->{interface} = $1;
	} elsif (/^    Link Data \(Network Mask\): $IP$/) {
	    $l->{netmask} = $1;
	} elsif (/^    Metric: $RE{num}{int}{-keep}$/) {
	    $l->{metric} = $1;
	} elsif (/^ {4}\w/) {
	    die "$_ Unknown line at link $link of router $router ".
	      "in area $area.\n";
	} elsif (! /^(Options|Checksum|Length):/) {
	    die "$_ Unknown line at router $router in area $area.\n";
	}
    }
    die "Link $link of router $router in area $area not finished.\n" if $l;
    die "Too few links at router $router in area $area.\n" if $lnum;
    die "Router $router in area $area not finished.\n" if $r;
    $self->{ospf}{database}{routers} = \@routers;
}

sub parse_network {
    my OSPF::LSDB::ospfd $self = shift;
    my($area, $network) = ("", "");
    my(@networks, $attachments, $rnum, $n);
    foreach (@{$self->{network}}) {
	if (/^ +Net Link States \(Area $IP\)$/) {
	    die "$_ Attached routers of network $network in area $area ".
	      "not finished.\n" if $attachments;
	    die "$_ Network $network in area $area not finished.\n" if $n;
	    $area = $1;
	    next;
	} elsif (/^$/) {
	    die "$_ Too few attached routers at network $network ".
	      "in area $area.\n" if $rnum;
	    undef $attachments;
	    undef $n;
	    next;
	} elsif (! $n) {
	    die "$_ No area for network defined.\n" if ! $area;
	    $network = "";
	    $n = { area => $area };
	    push @networks, $n;
	}
	if (/^LS age: $RE{num}{int}{-keep}$/) {
	    $n->{age} = $1;
	} elsif (/^LS Type: ([\w ()]+)$/) {
	    die "$_ Type of network-LSA is $1 and not Network in area $area.\n"
	      if $1 ne "Network";
	} elsif (/^Link State ID: $IP \(address of Designated Router\)$/) {
	    $n->{address} = $1;
	    $network = $1;
	} elsif (/^Advertising Router: $IP$/) {
	    $n->{routerid} = $1;
	} elsif (/^LS Seq Number: (0x$RE{num}{hex})$/) {
	    $n->{sequence} = $1;
	} elsif (/^Network Mask: $IP$/) {
	    $n->{netmask} = $1;
	} elsif (/^Number of Routers: $RE{num}{int}{-keep}$/) {
	    $rnum = $1;
	} elsif (/^    Attached Router: $IP$/) {
	    if (! $attachments) {
		$attachments = [];
		$n->{attachments} = $attachments;
	    }
	    $rnum-- if defined $rnum ;
	    push @$attachments, { routerid => $1 };
	} elsif (! /^(Options|Checksum|Length):/) {
	    die "$_ Unknown line at network $network in area $area.\n";
	}
    }
    die "Attached routers of network $network in area $area not finished.\n"
      if $attachments;
    die "Network $network in area $area not finished.\n" if $n;
    $self->{ospf}{database}{networks} = \@networks;
}

sub parse_summary {
    my OSPF::LSDB::ospfd $self = shift;
    my($area, $summary) = ("", "");
    my(@summarys, $s);
    foreach (@{$self->{summary}}) {
	if (/^ +Summary Net Link States \(Area $IP\)$/) {
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
	if (/^LS age: $RE{num}{int}{-keep}$/) {
	    $s->{age} = $1;
	} elsif (/^LS Type: ([\w ()]+)$/) {
	    die "$_ Type of summary-LSA is $1 and not Summary (Network) ".
	      "in area $area.\n" if $1 ne "Summary (Network)";
	} elsif (/^Link State ID: $IP \(Network ID\)$/) {
	    $s->{address} = $1;
	    $summary = $1;
	} elsif (/^Advertising Router: $IP$/) {
	    $s->{routerid} = $1;
	} elsif (/^LS Seq Number: (0x$RE{num}{hex})$/) {
	    $s->{sequence} = $1;
	} elsif (/^Network Mask: $IP$/) {
	    $s->{netmask} = $1;
	} elsif (/^Metric: $RE{num}{int}{-keep}$/) {
	    $s->{metric} = $1;
	} elsif (! /^(Options|Checksum|Length):/) {
	    die "$_ Unknown line at summary $summary in area $area.\n";
	}
    }
    die "Summary $summary in area $area not finished.\n" if $s;
    $self->{ospf}{database}{summarys} = \@summarys;
}

sub parse_boundary {
    my OSPF::LSDB::ospfd $self = shift;
    my($area, $boundary) = ("", "");
    my(@boundarys, $b);
    foreach (@{$self->{boundary}}) {
	if (/^ +Summary Router Link States \(Area $IP\)$/) {
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
	if (/^LS age: $RE{num}{int}{-keep}$/) {
	    $b->{age} = $1;
	} elsif (/^LS Type: ([\w ()]+)$/) {
	    die "$_ Type of boundary-LSA is $1 and not Summary (Router) ".
	      "in area $area.\n" if $1 ne "Summary (Router)";
	} elsif (/^Link State ID: $IP \(ASBR Router ID\)$/) {
	    $b->{asbrouter} = $1;
	    $boundary = $1;
	} elsif (/^Advertising Router: $IP$/) {
	    $b->{routerid} = $1;
	} elsif (/^LS Seq Number: (0x$RE{num}{hex})$/) {
	    $b->{sequence} = $1;
	} elsif (/^Metric: $RE{num}{int}{-keep}$/) {
	    $b->{metric} = $1;
	} elsif (! /^(Options|Checksum|Length|Network Mask):/) {
	    die "$_ Unknown line at boundary $boundary in area $area.\n";
	}
    }
    die "Boundary $boundary in area $area not finished.\n" if $b;
    $self->{ospf}{database}{boundarys} = \@boundarys;
}

sub parse_external {
    my OSPF::LSDB::ospfd $self = shift;
    my $external = "";
    my(@externals, $e);
    foreach (@{$self->{external}}) {
	if (/^ +Type-5 AS External Link States$/) {
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
	if (/^LS age: $RE{num}{int}{-keep}$/) {
	    $e->{age} = $1;
	} elsif (/^LS Type: ([\w ()]+)$/) {
	    die "$_ Type of external-LSA is $1 and not AS External.\n"
	      if $1 ne "AS External";
	} elsif (/^Link State ID: $IP \(External Network Number\)$/) {
	    $e->{address} = $1;
	    $external = $1;
	} elsif (/^Advertising Router: $IP$/) {
	    $e->{routerid} = $1;
	} elsif (/^LS Seq Number: (0x$RE{num}{hex})$/) {
	    $e->{sequence} = $1;
	} elsif (/^Network Mask: $IP$/) {
	    $e->{netmask} = $1;
	} elsif (/^    Metric type: ([1-2])$/) {
	    $e->{type} = $1;
	} elsif (/^    Metric: $RE{num}{int}{-keep}$/) {
	    $e->{metric} = $1;
	} elsif (/^    Forwarding Address: $IP$/) {
	    $e->{forward} = $1;
	} elsif (! /^(Options|Checksum|Length|    External Route Tag):/) {
	    die "$_ Unknown line at external $external.\n";
	}
    }
    die "External $external not finished.\n" if $e;
    $self->{ospf}{database}{externals} = \@externals;
}

sub parse_lsdb {
    my OSPF::LSDB::ospfd $self = shift;
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
B<ospfctl> output data.
The hash keys are named C<selfid>, C<router>, C<network>, C<summary>,
C<boundary>, C<external>.
If a hash entry is missing, B<ospfctl> is run instead to obtain the
information dynamically.

The complete OSPF link state database is stored in the B<ospf> field
of the base class.

=back

=cut

sub parse {
    my OSPF::LSDB::ospfd $self = shift;
    my %files = @_;
    $self->read_files(%files);
    $self->parse_self();
    $self->parse_lsdb();
    $self->{ospf}{ipv6} = 0;
}

=pod

This module has been tested with OpenBSD 4.8 and 5.1.
If it works with other versions is unknown.

=head1 ERRORS

The methods die if any error occurs.

=head1 SEE ALSO

L<OSPF::LSDB>,
L<OSPF::LSDB::ospf6d>

L<ospfd2yaml>

=head1 AUTHORS

Alexander Bluhm

=cut

1;
