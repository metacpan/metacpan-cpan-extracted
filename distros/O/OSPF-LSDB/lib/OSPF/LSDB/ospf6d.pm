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

B<OSPF::LSDB::ospf6d> - parse OpenBSD B<ospf6d> link state database

=head1 SYNOPSIS

use OSPF::LSDB::ospf6d;

my $ospf6d = OSPF::LSDB::ospf6d-E<gt>L<new>();

my $ospf6d = OSPF::LSDB::ospf6d-E<gt>L<new>(ssh => "user@host");

$ospf6d-E<gt>L<parse>(%files);

=head1 DESCRIPTION

The B<OSPF::LSDB::ospf6d> module parses the output of OpenBSD
B<ospf6ctl> and fills the B<OSPF::LSDB> base object.
The output of
C<show summary>,
C<show database router>,
C<show database network>,
C<show database summary>,
C<show database asbr>,
C<show database external>
C<show database link>
C<show database intra>
is needed.
It can be given as separate files or obtained dynamically.
In the latter case B<sudo> is invoked if permissions are not
sufficient to run B<ospf6ctl>.
If the object has been created with the C<ssh> argument, the specified
user and host are used to login and run B<ospf6ctl> there.

There is only one public method:

=cut

package OSPF::LSDB::ospf6d;
use base 'OSPF::LSDB::ospfd';
use File::Slurp;
use Regexp::Common;
use Regexp::IPv6;
use fields qw(
    link intra
);

sub new {
    my OSPF::LSDB::ospf6d $self = OSPF::LSDB::ospfd::new(@_);
    $self->{ospfctl} = "ospf6ctl";
    $self->{ospfsock} = "/var/run/ospf6d.sock";
    %{$self->{showdb}} = (%{$self->{showdb}}, (
	link   => "link",
	intra  => "intra",
    ));
    return $self;
}

# shortcut
my $IP = qr/$RE{net}{IPv4}{-keep}/;
my $IP6 = qr/($Regexp::IPv6::IPv6_re|::)/;
my $PREFIX = qr,($Regexp::IPv6::IPv6_re|::)/$RE{num}{int}{-keep},;

sub parse_router {
    my OSPF::LSDB::ospf6d $self = shift;
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
	} elsif (/^Advertising Router: $IP$/) {
	    $r->{routerid} = $1;
	    $router = $1;
	} elsif (/^LS Seq Number: (0x$RE{num}{hex})$/) {
	    $r->{sequence} = $1;
	} elsif (/^Flags: ([-*|\w]*)$/) {
	    my $flags = $1;
	    foreach (qw(W V E B)) {
		$r->{bits}{$_} = $flags =~ /\b$_\b/ ? 1 : 0;
	    }
	} elsif (/^Number of Links: $RE{num}{int}{-keep}$/) {
	    $lnum = $1;
	} elsif (/^    Link \([ .\w]*\) connected to: ([\w -]+)$/) {
	    if ($1 eq "Point-to-Point") {
		$type = "pointtopoint";
	    } elsif ($1 eq "Transit Network") {
		$type = "transit";
	    } elsif ($1 eq "Virtual Link") {
		$type = "virtual";
	    } else {
		die "$_ Unknown link type $1 at router $router ".
		  "in area $area.\n";
	    }
	    if (/\(Interface ID $IP\)/) {
		$l->{interface} = $1;
	    }
	} elsif (/^    Designated Router ID: $IP$/) {
	    $l->{routerid} = $1;
	    $link = $1;
	} elsif (/^    DR Interface ID: $IP$/) {
	    $l->{address} = $1;
	    $link = "$1\@$link";
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
    my OSPF::LSDB::ospf6d $self = shift;
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
	} elsif (/^Link State ID: $IP \(Interface ID of Designated Router\)$/) {
	    $n->{address} = $1;
	    $network = $1;
	} elsif (/^Advertising Router: $IP$/) {
	    $n->{routerid} = $1;
	    $network .= "\@$1";
	} elsif (/^LS Seq Number: (0x$RE{num}{hex})$/) {
	    $n->{sequence} = $1;
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
    my OSPF::LSDB::ospf6d $self = shift;
    # XXX not yet
    $self->{ospf}{database}{summarys} = [];
}

sub parse_boundary {
    my OSPF::LSDB::ospf6d $self = shift;
    # XXX not yet
    $self->{ospf}{database}{boundarys} = [];
}

sub parse_external {
    my OSPF::LSDB::ospf6d $self = shift;
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
	} elsif (/^Link State ID: $IP$/) {
	    $e->{address} = $1;
	    $external = $1;
	} elsif (/^Advertising Router: $IP$/) {
	    $e->{routerid} = $1;
	    $external .= "\@$1";
	} elsif (/^LS Seq Number: (0x$RE{num}{hex})$/) {
	    $e->{sequence} = $1;
	} elsif (/^    Metric: $RE{num}{int}{-keep} Type: ([1-2])$/) {
	    $e->{metric} = $1;
	    $e->{type} = $4;
	} elsif (/^    Prefix: $PREFIX$/) {
	    $e->{prefixaddress} = $1;
	    $e->{prefixlength} = $2;
	} elsif (! /^(Checksum|Length|    Flags):/) {
	    die "$_ Unknown line at external $external.\n";
	}
    }
    die "External $external not finished.\n" if $e;
    $self->{ospf}{database}{externals} = \@externals;
}

sub parse_link {
    my OSPF::LSDB::ospf6d $self = shift;
    my($area, $link) = ("", "");
    my(@links, $prefixes, $pnum, $l);
    foreach (@{$self->{link}}) {
	if (/^ +Link \(Type-8\) Link States \(Area $IP Interface \w+\)$/) {
	    die "$_ Prefixes of link $link in area $area not finished.\n"
	      if $prefixes;
	    die "$_ Link $link in area $area not finished.\n" if $l;
	    $area = $1;
	    next;
	} elsif (/^$/) {
	    die "$_ Too few prefixes at link $link in area $area.\n" if $pnum;
	    undef $prefixes;
	    undef $l;
	    next;
	} elsif (! $l) {
	    die "$_ No area for link defined.\n" if ! $area;
	    $link = "";
	    $l = { area => $area };
	    push @links, $l;
	}
	if (/^LS age: $RE{num}{int}{-keep}$/) {
	    $l->{age} = $1;
	} elsif (/^LS Type: ([\w ()]+)$/) {
	    die "$_ Type of link-LSA is $1 and not Link in area $area.\n"
	      if $1 ne "Link";
	} elsif (/^Link State ID: $IP \(Interface ID of Advertising Router\)$/){
	    $l->{interface} = $1;
	    $link = $1;
	} elsif (/^Advertising Router: $IP$/) {
	    $l->{routerid} = $1;
	    $link .= "\@$1";
	} elsif (/^LS Seq Number: (0x$RE{num}{hex})$/) {
	    $l->{sequence} = $1;
	} elsif (/^Link Local Address: ($IP6)$/) {
	    $l->{linklocal} = $1;
	} elsif (/^Number of Prefixes: $RE{num}{int}{-keep}$/) {
	    $pnum = $1;
	} elsif (/^    Prefix: $PREFIX$/) {
	    if (! $prefixes) {
		$prefixes = [];
		$l->{prefixes} = $prefixes;
	    }
	    $pnum-- if defined $pnum ;
	    push @$prefixes, { prefixaddress => $1, prefixlength => $2 };
	} elsif (! /^(Options|Checksum|Length):/) {
	    die "$_ Unknown line at link $link in area $area.\n";
	}
    }
    die "Prefixes of link $link in area $area not finished.\n" if $prefixes;
    die "Link $link in area $area not finished.\n" if $l;
    $self->{ospf}{database}{links} = \@links;
}

sub parse_intra {
    my OSPF::LSDB::ospf6d $self = shift;
    my($area, $intra) = ("", "");
    my(@intranetworks, @intrarouters, $type, $prefixes, $pnum, $i);
    foreach (@{$self->{intra}}) {
	if (/^ +Intra Area Prefix Link States \(Area $IP\)$/) {
	    die "$_ Prefixes of intra-area-prefix $intra in area $area ".
	      "not finished.\n" if $prefixes;
	    die "$_ Intra-area-prefix $intra in area $area not finished.\n"
	      if $i;
	    $area = $1;
	    next;
	} elsif (/^$/) {
	    die "$_ Too few prefixes at intra-area-prefix $intra ".
	      "in area $area.\n" if $pnum;
	    die "$_ Intra-area-prefix $intra in area $area has no ".
	      "referenced LS type.\n" if $i && ! $type;
	    undef $type;
	    undef $prefixes;
	    undef $i;
	    next;
	} elsif (! $i) {
	    die "$_ No area for intra-area-prefix defined.\n" if ! $area;
	    $intra = "";
	    $i = { area => $area };
	}
	if (/^LS age: $RE{num}{int}{-keep}$/) {
	    $i->{age} = $1;
	} elsif (/^LS Type: ([\w ()]+)$/) {
	    die "$_ Type of intra-area-prefix-LSA is $1 and not Intra Area ".
	      "(Prefix) in area $area.\n" if $1 ne "Intra Area (Prefix)";
	} elsif (/^Link State ID: $IP$/){
	    $i->{address} = $1;
	    $intra = $1;
	} elsif (/^Advertising Router: $IP$/) {
	    $i->{routerid} = $1;
	    $intra .= "\@$1";
	} elsif (/^LS Seq Number: (0x$RE{num}{hex})$/) {
	    $i->{sequence} = $1;
	} elsif (/^Referenced LS Type: (\w+)$/) {
	    die "$_ Referenced LS type given more than once ".
	      "at intra-area-prefix $intra in area $area.\n" if $type;
	    $type = $1;
	    if ($type eq "Router") {
		push @intrarouters, $i
	    } elsif ($type eq "Network") {
		push @intranetworks, $i
	    } else {
		die "$_ Unknown referenced LS type $type ".
		  "at intra-area-prefix $intra in area $area.\n";
	    }
	} elsif (/^Referenced Link State ID: $IP$/) {
	    $i->{interface} = $1;
	} elsif (/^Referenced Advertising Router: $IP$/) {
	    $i->{router} = $1;
	} elsif (/^Number of Prefixes: $RE{num}{int}{-keep}$/) {
	    $pnum = $1;
	} elsif (/^    Prefix: $PREFIX($| Options:)/) {
	    if (! $prefixes) {
		$prefixes = [];
		$i->{prefixes} = $prefixes;
	    }
	    $pnum-- if defined $pnum ;
	    push @$prefixes, { prefixaddress => $1, prefixlength => $2 };
	} elsif (! /^(Checksum|Length):/) {
	    die "$_ Unknown line at intra-area-prefix $intra in area $area.\n";
	}
    }
    die "Prefixes of intra-area-prefix $intra in area $area not finished.\n"
      if $prefixes;
    die "Intra-area-prefix $intra in area $area not finished.\n" if $i;
    $self->{ospf}{database}{intranetworks} = \@intranetworks;
    $self->{ospf}{database}{intrarouters} = \@intrarouters;
}

sub parse_lsdb {
    my OSPF::LSDB::ospf6d $self = shift;
    $self->SUPER::parse_lsdb(@_);
    $self->parse_link();
    $self->parse_intra();
}

=pod

=over 4

=item $self-E<gt>L<parse>(%files)

This function takes a hash with file names as value containing the
B<ospf6ctl> output data.
The hash keys are named C<selfid>, C<router>, C<network>, C<summary>,
C<boundary>, C<external>, C<link>, C<intra>.
If a hash entry is missing, B<ospf6ctl> is run instead to obtain the
information dynamically.

The complete OSPF link state database is stored in the B<ospf> field
of the base class.

=back

=cut

sub parse {
    my OSPF::LSDB::ospf6d $self = shift;
    $self->SUPER::parse(@_);
    $self->{ospf}{ipv6} = 1;
}

=pod

This module has been tested with OpenBSD 5.1.
If it works with other versions is unknown.

=head1 ERRORS

The methods die if any error occurs.

=head1 SEE ALSO

L<OSPF::LSDB>,
L<OSPF::LSDB::ospfd>

L<ospfd2yaml>

=head1 AUTHORS

Alexander Bluhm

=cut

1;
