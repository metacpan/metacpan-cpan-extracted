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

B<OSPF::LSDB::View6> - display OSPF for IPv6 database as graphviz dot

=head1 SYNOPSIS

use OSPF::LSDB;

use OSPF::LSDB::View6;

my $ospf = OSPF::LSDB-E<gt>L<new>();

my $view = OSPF::LSDB::View6-E<gt>L<new>($ospf);

my $dot = view-E<gt>L<graph>();

=head1 DESCRIPTION

The B<OSPF::LSDB::View6> module converts the IPv6 content of a
B<OSPF::LSDB> instance into a graphviz dot string.

Most of B<OSPF::LSDB::View6> is derived from B<OSPF::LSDB::View>.
Only differences between the v2 and v3 protocoll are implemented
and documented by this module.

=cut

package OSPF::LSDB::View6;
use base 'OSPF::LSDB::View';
use fields qw (
    sumlsids
    boundlsids
    externlsids
    lnkhash
    intraroutehash
    intranethash
);

sub new {
    my OSPF::LSDB::View6 $self = OSPF::LSDB::new(@_);
    die "$_[0] does not support IPv4" unless $self->ipv6();
    return $self;
}

########################################################################
# RFC 2740
#        LSA function code   LS Type   Description
#        ----------------------------------------------------
#        1                   0x2001    Router-LSA
########################################################################
# routers => [
#        area        => 'ipv4',
#        bits => {
#            B       => 'int',  # bit B
#            E       => 'int',  # bit E
#            V       => 'int',  # bit V
#            W       => 'int',  # bit W
#        },
#        pointtopoints => []    # Point-to-point connection to another router
#        transits => []         # Connection to a transit network
#        virtuals => []         # Virtual link
#        router      => 'ipv4', # Link State ID
#        routerid    => 'ipv4', # Advertising Router
# ],
########################################################################
# $routehash{$routerid} = {
#   graph   => { N => router10, color => red, style => solid, }
#   hashes  => [ { router hash } ]
#   areas   => { $area => 1 }
#   missing => 1 (optional)
# }
########################################################################

# take router hash
# detect inconsistencies and set colors
sub check_router {
    my OSPF::LSDB::View6 $self = shift;
    my $routehash = $self->{routehash} or die "Uninitialized member";
    while (my($rid,$rv) = each %$routehash) {
	my %colors;
	my @areas = keys %{$rv->{areas}};
	if (@areas > 1) {
	    $colors{black} = \@areas;
	    if (my @badareas = map { $_->{area} || () }
	      grep { ! $_->{bits}{B} } @{$rv->{hashes}}) {
		$self->error($colors{orange} =
		  "Router $rid in multiple areas is not border router ".
		  "in areas @badareas.");
	    }
	} else {
	    $colors{gray} = $areas[0];
	}
	if ($rv->{missing}) {
	    $self->error($colors{red} = "Router $rid missing.");
	} else {
	    while (my($area,$av) = each %{$rv->{areas}}) {
		# TODO check wether bits are equal
		while (my($lsid,$num) = each %$av) {
		    if ($num > 1) {
			$self->error($colors{magenta} =
			  "Router $rid has multiple link state IDs $lsid ".
			  "in area $area.");
		    }
		}
	    }
	}
	$rv->{colors} = \%colors;
    }
}

# take router hash, routerid,
# network hash, summary hash, boundary hash, external hash
# add missing routers to router hash
sub add_missing_router {
    my OSPF::LSDB::View6 $self = shift;
    my($index) = @_;
    my $boundhash = $self->{boundhash};
    my $externhash = $self->{externhash};
    # create router hash
    my %rid2areas;
    my @rids = map { keys %{$_->{routers}} }
      map { values %$_ } values %$externhash;
    foreach my $rid (@rids) {
	# if ase is conneted to boundary router, router is not missing
	next if $boundhash->{$rid};
	$rid2areas{$rid}{ase} = 1;
    }
    my $sumhash = $self->{sumhash};
    my @arearids = map { $_->{arearids} }
      (values %$boundhash, map { values %$_ } values %$sumhash);
    foreach my $ar (@arearids) {
	while (my($area,$av) = each %$ar) {
	    while (my($rid,$num) = each %$av) {
		$rid2areas{$rid}{$area} = 1;
	    }
	}
    }
    foreach my $type (qw(pointtopoint virtual)) {
	my $linkhash = $self->{$type."hash"} or die "Uninitialized member";
	while (my($dstrid,$dv) = each %$linkhash) {
	    while (my($area,$av) = each %$dv) {
		$rid2areas{$dstrid}{$area} = 1;
	    }
	}
    }
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my @hashes = map { @{$_->{hashes}} } map { values %$_ }
      map { values %$_ } values %$nethash;
    foreach my $n (@hashes) {
	my $area = $n->{area};
	$rid2areas{$n->{routerid}}{$area} = 1;
	foreach (@{$n->{attachments}}) {
	    $rid2areas{$_->{routerid}}{$area} = 1;
	}
    }
    my $routerid = $self->{ospf}{self}{routerid};
    my $routehash = $self->{routehash} or die "Uninitialized member";
    while (my($rid,$rv) = each %rid2areas) {
	my $elem = $routehash->{$rid};
	if (! $elem) {
	    $routehash->{$rid} = $elem = {};
	    $elem->{graph} = {
		N     => "router". $$index++,
		label => $rid,
		shape => "box",
		style => "dotted",
	    };
	    if ($rid eq $routerid) {
		$elem->{graph}{peripheries} = 2;
	    }
	    push @{$elem->{hashes}}, {};
	    $elem->{areas} = $rv;
	    $elem->{missing}++;
	}
    }
}

########################################################################
# RFC 2740
#         Type   Description
#         ---------------------------------------------------
#         1      Point-to-point connection to another router
########################################################################
# pointtopoints => [
#        address    => 'ipv4',  # Neighbor Interface ID
#        interface  => 'ipv4',  # Interface ID
#        metric     => 'int',   # Metric
#        routerid   => 'ipv4',  # Neighbor Router ID
# ]
########################################################################
# $pointtopointhash{$dst_routerid}{$areas}{$routerid} = {
#   hashes => [ { link hash } ]
# }
########################################################################

########################################################################
# RFC 2740
#         Type   Description
#         ---------------------------------------------------
#         4      Virtual link
########################################################################
# virtuals => [
#        address    => 'ipv4',  # Neighbor Interface ID
#        interface  => 'ipv4',  # Interface ID
#        metric     => 'int',   # Metric
#        routerid   => 'ipv4',  # Neighbor Router ID
# ],
########################################################################
# $virtualhash{$dst_routerid}{$areas}{$routerid} = {
#   hashes => [ { link hash } ]
# }
########################################################################

# take link hash, type (pointtopoint or virtual), router hash
# return list of edges from src router to dst router
sub router2edges {
    my OSPF::LSDB::View6 $self = shift;
    my($type) = @_;
    my $name = $type eq "pointtopoint" ? "Point-to-point" : "Virtual";
    my $style = $type eq "pointtopoint" ? "solid" : "dotted";
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $linkhash = $self->{$type."hash"} or die "Uninitialized member";
    my $ifaddrs = $self->{ifaddrs};
    my @elements;
    while (my($dstrid,$dv) = each %$linkhash) {
	while (my($area,$ev) = each %$dv) {
	    while (my($rid,$rv) = each %$ev) {
		my %colors = (gray => $area);
		my $src = $routehash->{$rid}{graph}{N};
		my $dst = $routehash->{$dstrid}{graph}{N};
		my @hashes = @{$rv->{hashes}};
		if (@hashes > 1) {
		    $self->error($colors{yellow} =
		      "$name link at router $rid to router $dstrid ".
		      "has multiple entries in area $area.");
		}
		if (! $routehash->{$dstrid}{areas}{$area}) {
		    $self->error($colors{orange} =
		      "$name link at router $rid to router $dstrid ".
		      "not in same area $area.");
		} elsif (! ($linkhash->{$rid} && $linkhash->{$rid}{$area} &&
		  $linkhash->{$rid}{$area}{$dstrid}) &&
		  ! $routehash->{$dstrid}{missing}) {
		    $self->error($colors{brown} =
		      "$name link at router $rid to router $dstrid ".
		      "not symmetric in area $area.");
		}
		foreach my $link (@hashes) {
		    my $intf = $link->{interface};
		    delete $colors{green};
		    if ($type eq "pointtopoint" and $ifaddrs->{$intf} &&
		      $ifaddrs->{$intf}{$rid} > 1) {
			$self->error($colors{green} =
			  "$name link at router $rid to router $dstrid ".
			  "interface address $intf not unique.");
		    }
		    my $metric = $link->{metric};
		    push @elements, { graph => {
			S         => $src,
			D         => $dst,
			label     => $intf,
			style     => $style,
			taillabel => $metric,
		    }, colors => { %colors } };
		}
	    }
	}
    }
    return $self->elements2graphs(@elements);
}

########################################################################
# RFC 2740
#         Type   Description
#         ---------------------------------------------------
#         2      Connection to a transit network
########################################################################
# transits => [
#        address    => 'ipv4',  # Neighbor Interface ID
#        interface  => 'ipv4',  # Interface ID
#        metric     => 'int',   # Metric
#        routerid   => 'ipv4',  # Neighbor Router ID
# ],
########################################################################
# $transithash{$address}{$netrouterid}{$area}{$routerid} = {
#   graph  => { N => transit2, color => red, style => solid, } (optional)
#   hashes => [ { link hash } ]
# }
# $transitnets->{$interface}{$routerid}{$area}{$address}{$netrouterid}++;
########################################################################

# take transit hash, transit cluster hash, net hash
# detect inconsistencies and set colors
sub check_transit {
    my OSPF::LSDB::View6 $self = shift;
    my($transitcluster) = @_;
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my $transithash = $self->{transithash} or die "Uninitialized member";
    while (my($addr, $av) = each %$transithash) {
	# TODO check if the there is more than one designated neigbor
	while (my($netrid, $nv) = each %$av) {
	    my %colors;
	    if (! $nethash->{$addr}{$netrid} &&
	      keys %$nv > 1) {
		$self->error($colors{orange} =
		  "Transit network $addr\@$netrid missing in multiple areas.");
	    }
	    while (my($area, $ev) = each %$nv) {
		$colors{gray} = $area;
		delete $colors{blue};
		if (! $nethash->{$addr}{$netrid} && keys %$ev > 1) {
		    $self->error($colors{blue} =
		      "Transit network $addr\@$netrid missing in area $area ".
		      "at multiple routers.");
		}
		while (my($rid, $rv) = each %$ev) {
		    next unless $rv->{graph};
		    delete @colors{qw(yellow red)};
		    if ($nethash->{$addr}{$netrid}) {
			$self->error($colors{yellow} =
			  "Transit network $addr\@$netrid in area $area ".
			  "at router $rid and network not in same area.");
		    } elsif (! $colors{orange} && ! $colors{blue}) {
			$self->error($colors{red} =
			  "Transit network $addr\@$netrid network missing.");
		    }
		    %{$rv->{colors}} = %colors;
		    push @{$transitcluster->{$addr}}, $rv->{graph};
		}
	    }
	}
    }
}

# take transit hash, router id, area, link structure, network hash
# add new element to transit hash
sub add_transit_value {
    my OSPF::LSDB::View6 $self = shift;
    my($transithash, $transitnets, $index, $rid, $area, $link) = @_;
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my $addr = $link->{address};
    my $netrid = $link->{routerid};
    my $intf = $link->{interface};
    $transitnets->{$intf}{$rid}{$area}{$addr}{$netrid}++;
    my $elem = $transithash->{$addr}{$netrid}{$area}{$rid};
    if (! $elem) {
	$transithash->{$addr}{$netrid}{$area}{$rid} = $elem = {};
	# check if address is in nethash and in matching nethash area
	if (! $nethash->{$addr}{$netrid} ||
	  ! $nethash->{$addr}{$netrid}{$area}) {
	    $elem->{graph} = {
	      N     => "transitnet". $$index++,
	      label => "$addr\\n$netrid",
	      shape => "ellipse",
	      style => "dotted",
	    };
	}
    }
    push @{$elem->{hashes}}, $link;
}

# take hash containing transit network nodes
# return list of nodes
sub transit2nodes {
    my OSPF::LSDB::View6 $self = shift;
    my $transithash = $self->{transithash} or die "Uninitialized member";
    return $self->elements2graphs(map { values %$_ } map { values %$_ }
      map { values %$_ } values %$transithash);
}

# take link hash, router hash, network hash
# return list of edges from router to transit network
sub transit2edges {
    my OSPF::LSDB::View6 $self = shift;
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $transithash = $self->{transithash} or die "Uninitialized member";
    my $ifaddrs = $self->{ifaddrs};
    my @elements;
    while (my($addr,$av) = each %$transithash) {
	while (my($netrid,$nv) = each %$av) {
	    my $nid = "$addr\@$netrid";
	    while (my($area,$ev) = each %$nv) {
		while (my($rid,$rv) = each %$ev) {
		    my %colors = (gray => $area);
		    my $src = $routehash->{$rid}{graph}{N};
		    if (@{$rv->{hashes}} > 1) {
			$self->error($colors{yellow} =
			  "Transit network $nid at router $rid ".
			  "has multiple entries in area $area.");
		    }
		    foreach my $link (@{$rv->{hashes}}) {
			my $intf = $link->{interface};
			delete $colors{green};
			if ($ifaddrs->{$intf} && $ifaddrs->{$intf}{$rid} > 1) {
			    $self->error($colors{green} =
			      "Transit link at router $rid to network $nid ".
			      "interface address $intf not unique.");
			}
			my $metric = $link->{metric};
			# link from designated router to attached net
			my $style = $netrid eq $rid && $addr eq $intf ?
			  "bold" : "solid";
			delete $colors{magenta};
			delete $colors{brown};
			delete $colors{tan};
			if ($rv->{graph}) {
			    my $dst = $rv->{graph}{N};
			    push @elements, { graph => {
				S         => $src,
				D         => $dst,
				headlabel => $intf,
				style     => $style,
				taillabel => $metric,
			    }, colors => { %colors } };
			    next;
			}
			my $nv = $nethash->{$addr}{$netrid};
			delete $colors{magenta};
			my $ev = $nv->{$area}
			  or next;
			delete $colors{brown};
			delete $colors{tan};
			if (! $ev->{attachrouters}{$rid}) {
			    $self->error($colors{brown} =
			      "Transit link at router $rid not attached ".
			      "by network $nid in area $area.");
			}
			my $dst = $ev->{graph}{N};
			push @elements, { graph => {
			    S         => $src,
			    D         => $dst,
			    headlabel => $intf,
			    style     => $style,
			    taillabel => $metric,
			}, colors => { %colors } };
		    }
		}
	    }
	}
    }
    return $self->elements2graphs(@elements);
}

########################################################################
# RFC 2740
#        LSA function code   LS Type   Description
#        ----------------------------------------------------
#        2                   0x2002    Network-LSA
########################################################################
# networks => [
#        address     => 'ipv4',         # Link State ID
#        area        => 'ipv4',
#        attachments => [
#            routerid       => 'ipv4',  # Attached Router
#        ],
#        routerid    => 'ipv4',         # Advertising Router
# ],
########################################################################
# $nethash{$address}{$routerid}{$area} = {
#   graph         => { N => network1, color => red, style => bold, }
#   hashes        => [ { network hash } ]
#   attachrouters => { $attachmentrouterid => 1 }
# }
# $nets{$address}{$routerid}++
# $netareas{$address}{$routerid}{$area}++
########################################################################

# take network hash, net cluster hash, net hash
# detect inconsistencies and set colors
sub check_network {
    my OSPF::LSDB::View6 $self = shift;
    my($netcluster) = @_;
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my $nets = $self->{nets} or die "Uninitialized member";
    my %colors;
    while (my($addr,$av) = each %$nethash) {
	while (my($rid, $rv) = each %$av) {
	    my $nid = "$addr\@$rid";
	    delete $colors{green};
	    if ($nets->{$addr}{$rid} > 1) {
		$self->error($colors{green} =
		  "Network $nid not unique at router $rid.");
	    }
	    delete $colors{orange};
	    if (keys %$rv > 1) {
		$self->error($colors{orange} =
		  "Network $nid at router $rid in multiple areas.");
	    }
	    while (my($area, $ev) = each %$rv) {
		$colors{gray} = $area;
		delete $colors{yellow};
		if (@{$ev->{hashes}} > 1) {
		    $self->error($colors{yellow} =
		      "Network $nid at router $rid ".
		      "has multiple entries in area $area.");
		}
		delete $colors{brown};
		my @attrids = keys %{$ev->{attachrouters}};
		if (@attrids == 0) {
		    $self->error($colors{red} =
		      "Network $nid at router $rid not attached ".
		      "to any router in area $area.");
		}
		if (@attrids == 1) {
		    $self->error($colors{brown} =
		      "Network $nid at router $rid attached only ".
		      "to router @attrids in area $area.");
		}
		%{$ev->{colors}} = %colors;
		# TODO move netcluster to prefix lsa
		push @{$netcluster->{"$addr\@$rid"}}, $ev->{graph};
	    }
	}
    }
}

# take network structure, net cluster hash
# return network hash
sub create_network {
    my OSPF::LSDB::View6 $self = shift;
    my $index = 0;
    my %nethash;
    my %nets;
    my %netareas;
    foreach my $n (@{$self->{ospf}{database}{networks}}) {
	my $addr = $n->{address};
	my $rid = $n->{routerid};
	my $nid = "$addr\@$rid";
	$nets{$addr}{$rid}++;
	my $area = $n->{area};
	$netareas{$addr}{$rid}{$area}++;
	my $elem = $nethash{$addr}{$rid}{$area};
	if (! $elem) {
	    $nethash{$addr}{$rid}{$area} = $elem = {};
	    $elem->{graph} = {
		N     => "network". $index++,
		label => "$addr\\n$rid",
		shape => "ellipse",
		style => "bold",
	    };
	}
	push @{$elem->{hashes}}, $n;
	foreach my $att (@{$n->{attachments}}) {
	    $elem->{attachrouters}{$att->{routerid}} = 1;
	}
    }
    $self->{nethash} = \%nethash;
    $self->{nets} = \%nets;
    # TODO netareas should handle prefixes
    $self->{netareas} = \%netareas;
}

# take network hash,
# intra network hash
# add missing networks to network hash
sub add_missing_network {
    my OSPF::LSDB::View6 $self = shift;
    my($index) = @_;
    my $intranethash = $self->{intranethash};
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my $nets = $self->{nets} or die "Uninitialized member";
    my $netareas = $self->{netareas} or die "Uninitialized member";
    while (my($addr,$av) = each %$intranethash) {
	while (my($rid,$rv) = each %$av) {
	    while (my($area,$ev) = each %$rv) {
		my $elem = $nethash->{$addr}{$rid}{$area};
		if (! $elem) {
		    $nets->{$addr}{$rid}++;
		    $netareas->{$addr}{$rid}{$area}++;
		    $nethash->{$addr}{$rid}{$area} = $elem = {};
		    $elem->{graph} = {
			N     => "network". $$index++,
			label => "$addr\\n$rid",
			shape => "ellipse",
			style => "dotted",
		    };
		    push @{$elem->{hashes}}, {
			area     => $area,
			routerid => $rid,
		    };
		    $elem->{missing}++;
		}
	    }
	}
    }
}

# take hash containing network nodes
# return list of nodes
sub network2nodes {
    my OSPF::LSDB::View6 $self = shift;
    my $nethash = $self->{nethash} or die "Uninitialized member";
    return $self->elements2graphs(map { values %$_ } map { values %$_ }
      values %$nethash);
}

# take network hash, router hash
# return list of edges from transit network to router
sub network2edges {
    my OSPF::LSDB::View6 $self = shift;
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $transithash = $self->{transithash} or die "Uninitialized member";
    my @elements;
    while (my($addr,$av) = each %$nethash) {
	while (my($rid,$rv) = each %$av) {
	    my $nid = "$addr\@$rid";
	    while (my($area,$ev) = each %$rv) {
		my $src = $ev->{graph}{N};
		foreach my $net (@{$ev->{hashes}}) {
		    my %attcolors;
		    foreach (@{$net->{attachments}}) {
			my $arid = $_->{routerid};
			if ($attcolors{$arid}) {
			    $self->error($attcolors{$arid}{yellow} =
			      "Network $nid in area $area at router $rid ".
			      "attached to router $arid multiple times.");
			    next;
			}
			$attcolors{$arid}{gray} = $area;
			if ($routehash->{$arid}{areas} &&
			  ! $routehash->{$arid}{areas}{$area}) {
			    $self->error($attcolors{$arid}{orange} =
			      "Network $nid and router $arid ".
			      "not in same area $area.");
			    next;
			}
			my $tv = $transithash->{$addr}{$rid}{$area}{$arid};
			if (! $tv && ! $routehash->{$arid}{missing}) {
			    $self->error($attcolors{$arid}{brown} =
			      "Network $nid not transit net ".
			      "of attached router $arid in area $area.");
			    next;
			}
			if ($arid eq $rid && $tv && ! grep { $addr eq
			  $_->{interface} } @{$tv->{hashes}}) {
			    $self->error($attcolors{$arid}{tan} =
			      "Network $nid at router $arid in area $area ".
			      "is designated but transit link is not.");
			    next;
			}
		    }
		    foreach (@{$net->{attachments}}) {
			my $arid = $_->{routerid};
			my $dst = $routehash->{$arid}{graph}{N}
			  or die "No router graph $arid";
			my $style = "solid";
			if ($arid eq $rid) {
			    # router is designated router
			    $style = "bold";
			}
			push @elements, { graph => {
			    S     => $src,
			    D     => $dst,
			    style => $style,
			}, colors => { %{$attcolors{$arid}} } };
		    }
		    if (! $attcolors{$rid}) {
			my $dst = $routehash->{$rid}{graph}{N}
			  or die "No router graph $rid";
			$attcolors{$rid}{gray} = $area;
			$self->error($attcolors{$rid}{red} =
			  "Network $nid not attached ".
			  "to designated router $rid in area $area.");
			push @elements, { graph => {
			    S         => $src,
			    D         => $dst,
			    style     => "bold",
			}, colors => { %{$attcolors{$rid}} } };
		    }
		}
	    }
	}
    }
    return $self->elements2graphs(@elements);
}

########################################################################
# RFC 2740
#        LSA function code   LS Type   Description
#        ----------------------------------------------------
#        3                   0x2003    Inter-Area-Prefix-LSA
########################################################################
# summarys => [
#        address     => 'ipv4',         # Link State ID
#        area        => 'ipv4',
#        metric      => 'int',          # Metric
#        prefixaddress       => 'ipv6', # Address Prefix
#        prefixlength        => 'int',  # PrefixLength
#        routerid    => 'ipv4',         # Advertising Router
# ],
########################################################################
# $sumhash{$prefixaddress}{$prefixlength} = {
#   graph    => { N => summary4, color => red, style => solid, }
#   hashes   => [ { summary hash } ]
#   arearids => { $area => { $routerid => 1 } }
# }
########################################################################

# take summary hash, net cluster hash, network hash, stub hash
# detect inconsistencies and set colors
sub check_summary {
    my OSPF::LSDB::View6 $self = shift;
    my($netcluster) = @_;
    my $netareas = $self->{netareas} or die "Uninitialized member";
    my $sumhash = $self->{sumhash} or die "Uninitialized member";
    while (my($paddr,$av) = each %$sumhash) {
	while (my($plen,$lv) = each %$av) {
	    my %colors;
	    my $nid = "$paddr/$plen";
	    my @areas = keys %{$lv->{arearids}};
	    if (@areas > 1) {
		$colors{black} = \@areas;
	    } else {
		$colors{gray} = $areas[0];
	    }
	    # TODO check wether lower prefix address is zero
	    # TODO check Link- and Prefix-LSAs
#	    if (my @badareas = grep { $netareas->{$net}{$mask}{$_} } @areas) {
#		$self->error($colors{blue} =
#		  "Summary network $nid is also network in areas @badareas.");
#	    }
#	    if ($stubareas and
#	      my @badareas = grep { $stubareas->{$net}{$mask}{$_} } @areas) {
#		$self->error($colors{green} =
#		  "Summary network $nid is also stub network ".
#		  "in areas @badareas.");
#	    }
	    # TODO check for duplicate Link-State-IDs
	    $lv->{colors} = \%colors;
	    push @{$netcluster->{"$paddr/$plen"}}, $lv->{graph};
	}
    }
}

# take summary structure, net cluster hash, network hash, link hash
# return summary hash
sub create_summary {
    my OSPF::LSDB::View6 $self = shift;
    my $index = 0;
    my %sumhash;
    my %sums;
    my %sumlsids;
    foreach my $s (@{$self->{ospf}{database}{summarys}}) {
	my $paddr = $s->{prefixaddress};
	my $plen = $s->{prefixlength};
	my $nid = "$paddr/$plen";
	my $rid = $s->{routerid};
	my $addr = $s->{address};
	my $area = $s->{area};
	$sumlsids{$area}{$rid}{$addr}++;
	my $elem = $sumhash{$paddr}{$plen};
	if (! $elem) {
	    $sumhash{$paddr}{$plen} = $elem = {};
	    $elem->{graph} = {
		N     => "summary". $index++,
		label => "$paddr/$plen",
		shape => "ellipse",
		style => "dashed",
	    };
	}
	push @{$elem->{hashes}}, $s;
	$elem->{arearids}{$area}{$rid}++;
    }
    $self->{sumhash} = \%sumhash;
    $self->{sums} = \%sums;
    $self->{sumlsids} = \%sumlsids;
}

# take summary hash, router hash
# return list of edges from summary network to router
sub summary2edges {
    my OSPF::LSDB::View6 $self = shift;
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $sumhash = $self->{sumhash} or die "Uninitialized member";
    my $sumlsids = $self->{sumlsids} or die "Uninitialized member";
    my @elements;
    while (my($paddr,$av) = each %$sumhash) {
	while (my($plen,$lv) = each %$av) {
	    my $nid = "$paddr/$plen";
	    my $src = $lv->{graph} && $lv->{graph}{N};
	    foreach my $s (@{$lv->{hashes}}) {
		my $rid = $s->{routerid};
		my $dst = $routehash->{$rid}{graph}{N}
		  or die "No router graph $rid";
		my $addr = $s->{address};
		my $area = $s->{area};
		my %colors = (gray => $area);
		if (! $routehash->{$rid}{areas}{$area}) {
		    $self->error($colors{orange} =
		      "Summary network $nid and router $rid ".
		      "not in same area $area.");
		}
		if ($lv->{arearids}{$area}{$rid} > 1) {
		    $self->error($colors{yellow} =
		      "Summary network $nid at router $rid ".
		      "has multiple entries in area $area.");
		}
		if ($sumlsids->{$area}{$rid}{$addr} > 1) {
		    $self->error($colors{magenta} =
		      "Summary network $nid at router $rid ".
		      "has multiple link state IDs $addr in area $area.");
		}
		my $metric = $s->{metric};
		$s->{graph} = {
		    S         => $src,
		    D         => $dst,
		    headlabel => $metric,
		    style     => "dashed",
		    taillabel => $addr,
		};
		$s->{colors} = \%colors;
		# in case of aggregation src is undef
		push @elements, $s if $src;
	    }
	}
    }
    return $self->elements2graphs(@elements);
}

########################################################################
# RFC 2740
#        LSA function code   LS Type   Description
#        ----------------------------------------------------
#        4                   0x2004    Inter-Area-Router-LSA
########################################################################
# boundarys => [
#        address     => 'ipv4', # Link State ID
#        area        => 'ipv4',
#        asbrouter   => 'ipv4', # Destination Router ID
#        metric      => 'int',  # Metric
#        routerid    => 'ipv4', # Advertising Router
# ],
########################################################################
# $boundhash{$asbrouter} = {
#   graph     => { N => boundary6, color => red, style => dashed, }
#   hashes    => [ { boundary hash } ]
#   arearids  => { $area => { $routerid => 1 }
#   aggregate => { $asbraggr => 1 } (optional)
# }
########################################################################

# take boundary structure
# return boundary hash
sub create_boundary {
    my OSPF::LSDB::View6 $self = shift;
    my $index = 0;
    my %boundhash;
    my %boundlsids;
    foreach my $b (@{$self->{ospf}{database}{boundarys}}) {
	my $asbr = $b->{asbrouter};
	my $rid = $b->{routerid};
	my $area = $b->{area};
	my $addr = $b->{address};
	$boundlsids{$area}{$rid}{$addr}++;
	my $elem = $boundhash{$asbr};
	if (! $elem) {
	    $boundhash{$asbr} = $elem = {};
	    $elem->{graph} = {
		N     => "boundary". $index++,
		label => $asbr,
		shape => "box",
		style => "dashed",
	    };
	}
	push @{$elem->{hashes}}, $b;
	$elem->{arearids}{$area}{$rid}++;
    }
    $self->{boundhash} = \%boundhash;
    $self->{boundlsids} = \%boundlsids;
}

# take boundary hash, router hash
# return list of edges from boundary router to router
sub boundary2edges {
    my OSPF::LSDB::View6 $self = shift;
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $boundhash = $self->{boundhash} or die "Uninitialized member";
    my $boundlsids = $self->{boundlsids} or die "Uninitialized member";
    my @elements;
    while (my($asbr,$bv) = each %$boundhash) {
	my $src;
	if ($bv->{graph}) {
	    $src = $bv->{graph}{N};
	} elsif ($routehash->{$asbr}) {
	    $src = $routehash->{$asbr}{graph}{N}
	}
	foreach my $b (@{$bv->{hashes}}) {
	    my $rid = $b->{routerid};
	    my $dst = $routehash->{$rid}{graph}{N}
	      or die "No router graph $rid";
	    my $addr = $b->{address};
	    my $area = $b->{area};
	    my %colors = (gray => $area);
	    if ($asbr eq $rid) {
		$self->error($colors{brown} =
		  "AS boundary router $asbr is advertized by itself ".
		  "in area $area.");
	    } elsif ($routehash->{$asbr} && $routehash->{$asbr}{areas}{$area}) {
		$self->error($colors{blue} =
		  "AS boundary router $asbr is router in same area $area.");
	    }
	    if (! $routehash->{$rid}{areas}{$area}) {
		$self->error($colors{orange} =
		  "AS boundary router $asbr and router $rid ".
		  "not in same area $area.");
	    }
	    if ($bv->{arearids}{$area}{$rid} > 1) {
		$self->error($colors{yellow} =
		  "AS boundary router $asbr at router $rid ".
		  "has multiple entries in area $area.");
	    }
	    if ($boundlsids->{$area}{$rid}{$addr} > 1) {
		$self->error($colors{magenta} =
		  "AS boundary router $asbr at router $rid ".
		  "has multiple link state IDs $addr in area $area.");
	    }
	    my $metric = $b->{metric};
	    $b->{graph} = {
		S         => $src,
		D         => $dst,
		headlabel => $metric,
		style     => "dashed",
		taillabel => $addr,
	    };
	    $b->{colors} = \%colors;
	    # in case of aggregation src is undef
	    push @elements, $b if $src;
	}
    }
    return $self->elements2graphs(@elements);
}

########################################################################
# RFC 2740
#        LSA function code   LS Type   Description
#        ----------------------------------------------------
#        5                   0x4005    AS-External-LSA
########################################################################
# externals => [
#        address     => 'ipv4',         # Link State ID
#        metric      => 'int',          # Metric
#        prefixaddress       => 'ipv6', # Address Prefix
#        prefixlength        => 'int',  # PrefixLength
#        routerid    => 'ipv4',         # Advertising Router
#        type        => 'int',          # bit E
# ],
########################################################################
# $externhash{$prefixaddress}{$prefixlength} = {
#   graph   => { N => external8, color => red, style => dashed, }
#   hashes  => [ { ase hash } ]
#   routers => { $routerid => 1 }
# }

# take external hash, net cluster hash, network hash, stub hash, summary hash
# detect inconsistencies and set colors
sub check_external {
    my OSPF::LSDB::View6 $self = shift;
    my($netcluster) = @_;
    my $nets = $self->{nets} or die "Uninitialized member";
    my $sums = $self->{sums};
    my $externhash = $self->{externhash} or die "Uninitialized member";
    while (my($paddr,$av) = each %$externhash) {
	while (my($plen,$lv) = each %$av) {
	    my %colors = (gray => "ase");
	    my $nid = "$paddr/$plen";
	    # TODO check wether lower prefix address is zero
	    # TODO check Link- and Prefix-LSAs
#	    if ($nets->{$net}{$mask}) {
#		$self->error($colors{blue} =
#		  "AS external network $nid is also network.");
#	    }
#	    if ($stubs->{$net}{$mask}) {
#		$self->error($colors{green} =
#		  "AS external network $nid is also stub network.");
#	    }
#	    if ($sums->{$net}{$mask}) {
#		$self->error($colors{cyan} =
#		  "AS external network $nid is also summary network.");
#	    }
	    # TODO check for duplicate Link-State-IDs
	    $lv->{colors} = \%colors;
	    push @{$netcluster->{"$paddr/$plen"}}, $lv->{graph};
	}
    }
}

# take external structure, net cluster hash, network hash, link hash
# return external hash
sub create_external {
    my OSPF::LSDB::View6 $self = shift;
    my $index = 0;
    my %externhash;
    my %externlsids;
    foreach my $e (@{$self->{ospf}{database}{externals}}) {
	my $paddr = $e->{prefixaddress};
	my $plen = $e->{prefixlength};
	my $rid = $e->{routerid};
	my $addr = $e->{address};
	$externlsids{$rid}{$addr}++;
	my $elem = $externhash{$paddr}{$plen};
	if (! $elem) {
	    $externhash{$paddr}{$plen} = $elem = {};
	    $elem->{graph} = {
		N     => "external". $index++,
		label => "$paddr/$plen",
		shape => "egg",
		style => "solid",
	    };
	}
	push @{$elem->{hashes}}, $e;
	$elem->{routers}{$rid}++;
    }
    $self->{externhash} = \%externhash;
    $self->{externlsids} = \%externlsids;
}

# take external hash, router hash, boundary hash, boundary aggregate
# return list of edges from external network to router
sub external2edges {
    my OSPF::LSDB::View6 $self = shift;
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $boundhash = $self->{boundhash};
    my $boundaggr = $self->{boundaggr};
    my $externhash = $self->{externhash} or die "Uninitialized member";
    my $externlsids = $self->{externlsids} or die "Uninitialized member";
    my @elements;
    while (my($paddr,$pv) = each %$externhash) {
	while (my($plen,$lv) = each %$pv) {
	    my $nid = "$paddr/$plen";
	    my $src = $lv->{graph}{N};
	    my %dtm;  # when dst is aggregated, aggregate edges
	    foreach my $e (@{$lv->{hashes}}) {
		my $rid = $e->{routerid};
		my $addr = $e->{address};
		my $type = $e->{type};
		my $metric = $e->{metric};
		my %colors = (gray => "ase");
		if ($lv->{routers}{$rid} > 1) {
		    $self->error($colors{yellow} =
		      "AS external network $nid at router $rid ".
		      "has multiple entries.");
		}
		if ($externlsids->{$rid}{$addr} > 1) {
		    $self->error($colors{magenta} =
		      "AS external network $nid at router $rid ".
		      "has multiple link state IDs $addr.");
		}
		my $style = $type == 1 ? "solid" : "dashed";
		my %graph = (
		    S         => $src,
		    headlabel => $metric,
		    style     => $style,
		    taillabel => $addr,
		);
		if ($routehash->{$rid}) {
		    my $dst = $routehash->{$rid}{graph}{N}
		      or die "No router graph $rid";
		    $graph{D} = $dst;
		    $e->{elems}{$dst} = {
			graph  => \%graph,
			colors => \%colors,
		    };
		    push @elements, $e->{elems}{$dst} if $src;
		    next;
		}
		my $av = $boundhash->{$rid}{aggregate};
		if (! $av) {
		    my $dst = $boundhash->{$rid}{graph}{N}
		      or die "No ASB router graph $rid";
		    $graph{D} = $dst;
		    $e->{elems}{$dst} = {
			graph  => \%graph,
			colors => \%colors,
		    };
		    push @elements, $e->{elems}{$dst} if $src;
		    next;
		}
		while (my($asbraggr,$num) = each %$av) {
		    my $dst = $boundaggr->{$asbraggr}{graph}{N}
		      or die "No ASBR graph $asbraggr";
		    $graph{D} = $dst;
		    $e->{elems}{$dst} = {
			graph  => { %graph },
			colors => { %colors },
		    };
		    # no not aggregate graphs with errors
		    if (grep { ! /^(gray|black)$/ } keys %colors) {
			push @elements, $e->{elems}{$dst} if $src;
		    } else {
			$dtm{$dst}{$type}{$metric} = $e->{elems}{$dst};
		    }
		}
	    }
	    push @elements, map { values %$_ } map { values %$_ } values %dtm
	      if $src;
	}
    }
    return $self->elements2graphs(@elements);
}

########################################################################
# $externaggr{$netaggr} = {
#   graph   => { N => external9, color => red, style => dashed, }
#   routers => { $routerid => { $type => { $metric => [ { ase hash } ] } } }
# }
########################################################################

# take external hash
# return external aggregate
sub create_externaggr {
    my OSPF::LSDB::View6 $self = shift;
    # $ridnets{$rid}{$network} =
    #   color => orange,
    #   types => { $type => { $metric => [ { ase hash } ] } }
    my $externhash = $self->{externhash} or die "Uninitialized member";
    my %ridnets;
    while (my($net,$nv) = each %$externhash) {
	while (my($mask,$mv) = each %$nv) {
	    my $nid = "$net/$mask";
	    # no not aggregate clustered graphs
	    next if $mv->{graph}{C};
	    my $colors = $mv->{colors};
	    # no not aggregate graphs with errors
	    next if grep { ! /^(gray|black)$/ } keys %$colors;
	    foreach my $e (@{$mv->{hashes}}) {
		my $rid = $e->{routerid};
		my $type = $e->{type};
		my $metric = $e->{metric};
		my $elem = $ridnets{$rid}{$nid};
		if (! $elem) {
		    $ridnets{$rid}{$nid} = $elem = {
			colors => { %$colors },
		    };
		} elsif (! $elem->{colors}{gray} || ! $colors->{gray} ||
		  $elem->{colors}{gray} ne $colors->{gray}) {
		    push @{$elem->{colors}{black}},
		      (delete($elem->{colors}{gray}) || ()),
		      ($colors->{gray} || ()), @{$colors->{black} || []};
		}
		push @{$elem->{types}{$type}{$metric}}, $e;
	    }
	    delete $mv->{graph};
	}
    }
    my $index = 0;
    my %externaggr;
    while (my($rid,$rv) = each %ridnets) {
	my $netaggr = join('\n', sort keys %$rv);  # TODO ip sort
	my $elem = $externaggr{$netaggr};
	if (! $elem) {
	    $externaggr{$netaggr} = $elem = {};
	    $elem->{graph} = {
		N     => "externalaggregate". $index++,
		label => $netaggr,
		shape => "egg",
		style => "solid",
	    };
	}
	while (my($nid,$nv) = each %$rv) {
	    my $colors = $nv->{colors};
	    if (! $elem->{colors}) {
		%{$elem->{colors}} = %$colors;
	    } elsif (! $elem->{colors}{gray} || ! $colors->{gray} ||
	      $elem->{colors}{gray} ne $colors->{gray}) {
		push @{$elem->{colors}{black}},
		  (delete($elem->{colors}{gray}) || ()),
		  ($colors->{gray} || ()), @{$colors->{black} || []};
	    }
	    while (my($type,$tv) = each %{$nv->{types}}) {
		while (my($metric,$es) = each %$tv) {
		    push @{$elem->{routers}{$rid}{$type}{$metric}}, @$es;
		}
	    }
	}
    }
    $self->{externaggr} = \%externaggr;
}

########################################################################
# RFC 2740
#        LSA function code   LS Type   Description
#        ----------------------------------------------------
#        8                   0x0008    Link-LSA
########################################################################
# links => [
#        area        => 'ipv4',
#        interface   => 'ipv4',         # Link State ID
#        linklocal   => 'ipv6',         # Link-local Interface Address
#        prefixes => [
#            prefixaddress   => 'ipv6', # Address Prefix
#            prefixlength    => 'int',  # PrefixLength
#        ],
#        routerid    => 'ipv4',         # Advertising Router
# ],
########################################################################
# $lnkhash{$interface}{$routerid}{$area} = {
#   graph    => { N => link1, color => red, }
#   hashes   => [ { link hash } ]
# }
########################################################################

# take link hash
# detect inconsistencies and set colors
sub check_link {
    my OSPF::LSDB::View6 $self = shift;
    my $lnkhash = $self->{lnkhash} or die "Uninitialized member";
    my %colors;
    while (my($intf,$iv) = each %$lnkhash) {
	while (my($rid, $rv) = each %$iv) {
	    my $lid = "$intf\@$rid";
	    while (my($area, $av) = each %$rv) {
		$colors{gray} = $area;
		%{$av->{colors}} = %colors;
	    }
	}
    }
}

sub create_link {
    my OSPF::LSDB::View6 $self = shift;
    my $index = 0;
    my %lnkhash;
    foreach my $l (@{$self->{ospf}{database}{links}}) {
	my $intf = $l->{interface};
	my $rid = $l->{routerid};
	my $lid = "$intf\@$rid";
	my $area = $l->{area};
	my $linklocal = $l->{linklocal};
	my $prefixes = join("\\n",
	  map { "$_->{prefixaddress}/$_->{prefixlength}" }
	  @{$l->{prefixes} || []});
	my $elem = $lnkhash{$intf}{$rid}{$area};
	if (! $elem) {
	    $lnkhash{$intf}{$rid}{$area} = $elem = {};
	    $elem->{graph} = {
		N     => "link". $index++,
		label => "$linklocal\\n$prefixes",
		shape => "hexagon",
		style => "solid",
	    };
	}
	push @{$elem->{hashes}}, $l;
    }
    $self->{lnkhash} = \%lnkhash;
}

# take hash containing link nodes
# return list of nodes
sub link2nodes {
    my OSPF::LSDB::View6 $self = shift;
    my $lnkhash = $self->{lnkhash} or die "Uninitialized member";
    return $self->elements2graphs(map { values %$_ } map { values %$_ }
      values %$lnkhash);
}

# take link hash, network hash, router hash
# return list of edges from network and router to link
sub link2edges {
    my OSPF::LSDB::View6 $self = shift;
    my $lnkhash = $self->{lnkhash} or die "Uninitialized member";
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $transithash = $self->{transithash} or die "Uninitialized member";
    my $transitnets = $self->{transitnets} or die "Uninitialized member";
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my @elements;
    while (my($intf,$iv) = each %$lnkhash) {
	while (my($rid,$rv) = each %$iv) {
	    my $lid = "$intf\@$rid";
	    my $rdst = $routehash->{$rid}{graph}{N}
	      or die "No router graph $rid";
	    # TODO create missing router
	    while (my($area,$av) = each %$rv) {
		my $src = $av->{graph}{N};
		my %colors;
		$colors{gray} = $area;
		push @elements, { graph => {
		    S         => $src,
		    D         => $rdst,
		    style     => "bold",
		    taillabel => $intf,
		}, colors => \%colors };
		my $tv = $transitnets->{$intf}{$rid}{$area}
		  or next;
		# TODO check for duplicates in check_transit
		my($netaddr,$nv) = each %$tv;
		my($netrid,$num) = each %$nv;
		my $ndst = $nethash->{$netaddr}{$netrid}{$area}{graph}{N} ||
		  $transithash->{$netaddr}{$netrid}{$area}{$rid}{graph}{N}
		  or next;
		push @elements, { graph => {
		    S         => $src,
		    D         => $ndst,
		    style     => "solid",
		}, colors => \%colors };
	    }
	}
    }
    return $self->elements2graphs(@elements);
}

########################################################################
# RFC 2740
#        LSA function code   LS Type   Description
#        ----------------------------------------------------
#        9                   0x2009    Intra-Area-Prefix-LSA
#        Referenced LS type  1         router-LSA
########################################################################
# intrarouters => [
#        address     => 'ipv4',         # Link State ID
#        area        => 'ipv4',
#        interface   => 'ipv4',         # Referenced Link State ID, 0
#                                       # 0
#        prefixes => [
#            prefixaddress   => 'ipv6', # Address Prefix
#            prefixlength    => 'int',  # PrefixLength
#        ],
#        router      => 'ipv4',         # Referenced Advertising Router
#                                       # originating router's Router ID
#        routerid    => 'ipv4',         # Advertising Router
# ],
########################################################################
# $intraroutehash{$router}{$area} = {
#   graph    => { N => intrarouter1, color => red, }
#   hashes   => [ { intrarouter hash } ]
# }
########################################################################

# take intrarouter hash
# detect inconsistencies and set colors
sub check_intrarouter {
    my OSPF::LSDB::View6 $self = shift;
    my $intraroutehash = $self->{intraroutehash} or die "Uninitialized member";
    my %colors;
    while (my($rid, $rv) = each %$intraroutehash) {
	my $iid = "$rid";
	while (my($area, $av) = each %$rv) {
	    $colors{gray} = $area;
	    %{$av->{colors}} = %colors;
	}
    }
}

sub create_intrarouters {
    my OSPF::LSDB::View6 $self = shift;
    my $index = 0;
    my %intraroutehash;
    foreach my $i (@{$self->{ospf}{database}{intrarouters}}) {
	my $intf = $i->{interface};
	my $rid = $i->{router};
	my $area = $i->{area};
	my $elem = $intraroutehash{$rid}{$area};
	if (! $elem) {
	    $intraroutehash{$rid}{$area} = $elem = {};
	    $elem->{graph} = {
		N     => "intrarouter". $index++,
		label => "prefixes",
		shape => "octagon",
		style => "solid",
	    };
	}
	push @{$elem->{hashes}}, $i;
	$elem->{graph}{label} = join("\\n",
	    map { "$_->{prefixaddress}/$_->{prefixlength}" }
	    map { @{$_->{prefixes} || []} } @{$elem->{hashes}});
    }
    $self->{intraroutehash} = \%intraroutehash;
}

# take hash containing intrarouter nodes
# return list of nodes
sub intrarouter2nodes {
    my OSPF::LSDB::View6 $self = shift;
    my $intraroutehash = $self->{intraroutehash} or die "Uninitialized member";
    return $self->elements2graphs(map { values %$_ } values %$intraroutehash);
}

# take intrarouter hash, router hash
# return list of edges from intrarouter to router
sub intrarouter2edges {
    my OSPF::LSDB::View6 $self = shift;
    my $intraroutehash = $self->{intraroutehash} or die "Uninitialized member";
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my @elements;
    while (my($rid,$rv) = each %$intraroutehash) {
	my $iid = "$rid";
	while (my($area,$av) = each %$rv) {
	    my $src = $av->{graph}{N};
	    my $dst = $routehash->{$rid}{graph}{N}
	      or die "No router graph $rid";
	    # TODO create missing router
	    my %colors;
	    $colors{gray} = $area;
	    foreach my $i (@{$av->{hashes}}) {
		my $addr = $i->{address};
		push @elements, { graph => {
		    S         => $src,
		    D         => $dst,
		    style     => "bold",
		    taillabel => $addr,
		}, colors => { %colors } };
	    }
	}
    }
    return $self->elements2graphs(@elements);
}

########################################################################
# RFC 2740
#        LSA function code   LS Type   Description
#        ----------------------------------------------------
#        9                   0x2009    Intra-Area-Prefix-LSA
#        Referenced LS type  2         network-LSA
########################################################################
# intranetworks => [
#        address     => 'ipv4',         # Link State ID
#        area        => 'ipv4',
#        interface   => 'ipv4',         # Referenced Link State ID
#                                       # Interface ID of Designated Router
#        prefixes => [
#            prefixaddress   => 'ipv6', # Address Prefix
#            prefixlength    => 'int',  # PrefixLength
#        ],
#        router      => 'ipv4',         # Referenced Advertising Router
#                                       # Designated Router's Router ID
#        routerid    => 'ipv4',         # Advertising Router
# ],
########################################################################
# $intranethash{$interface}{$router}{$area} = {
#   graph    => { N => intranetwork1, color => red, }
#   hashes   => [ { intranetwork hash } ]
# }
########################################################################

# take intranetwork hash
# detect inconsistencies and set colors
sub check_intranetwork {
    my OSPF::LSDB::View6 $self = shift;
    my $intranethash = $self->{intranethash} or die "Uninitialized member";
    my %colors;
    while (my($intf,$iv) = each %$intranethash) {
	while (my($rid, $rv) = each %$iv) {
	    my $iid = "$intf\@$rid";
	    while (my($area, $av) = each %$rv) {
		$colors{gray} = $area;
		%{$av->{colors}} = %colors;
	    }
	}
    }
}

sub create_intranetworks {
    my OSPF::LSDB::View6 $self = shift;
    my $index = 0;
    my %intranethash;
    foreach my $i (@{$self->{ospf}{database}{intranetworks}}) {
	my $intf = $i->{interface};
	my $rid = $i->{router};
	my $area = $i->{area};
	my $elem = $intranethash{$intf}{$rid}{$area};
	if (! $elem) {
	    $intranethash{$intf}{$rid}{$area} = $elem = {};
	    $elem->{graph} = {
		N     => "intranetwork". $index++,
		label => "prefixes",
		shape => "octagon",
		style => "bold",
	    };
	}
	push @{$elem->{hashes}}, $i;
	$elem->{graph}{label} = join("\\n",
	    map { "$_->{prefixaddress}/$_->{prefixlength}" }
	    map { @{$_->{prefixes} || []} } @{$elem->{hashes}});
    }
    $self->{intranethash} = \%intranethash;
}

# take hash containing intranetwork nodes
# return list of nodes
sub intranetwork2nodes {
    my OSPF::LSDB::View6 $self = shift;
    my $intranethash = $self->{intranethash} or die "Uninitialized member";
    return $self->elements2graphs(map { values %$_ } map { values %$_ }
      values %$intranethash);
}

# take intranetwork hash, network hash, router hash
# return list of edges from intranetwork to network and router
sub intranetwork2edges {
    my OSPF::LSDB::View6 $self = shift;
    my $intranethash = $self->{intranethash} or die "Uninitialized member";
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my @elements;
    while (my($intf,$iv) = each %$intranethash) {
	while (my($rid,$rv) = each %$iv) {
	    my $iid = "$intf\@$rid";
	    while (my($area,$av) = each %$rv) {
		my $src = $av->{graph}{N};
		my $dst = $nethash->{$intf}{$rid}{$area}{graph}{N}
		  or die "No network graph $intf $rid $area";
		my %colors;
		$colors{gray} = $area;
		foreach my $i (@{$av->{hashes}}) {
		    my $addr = $i->{address};
		    push @elements, { graph => {
			S         => $src,
			D         => $dst,
			style     => "bold",
			taillabel => $addr,
		    }, colors => { %colors } };
		}
	    }
	}
    }
    return $self->elements2graphs(@elements);
}

# return legend routers as dot graph
sub legend_router {
    my $class = shift;
    my $index = 0;
    my @nodes = (
	{
	    label       => 'ospf\nrouter',
	}, {
	    label       => 'current\nlocation',
	    peripheries => 2,
	}, {
	    label       => 'area border\nrouter',
	    style       => 'bold',
	}, {
	    label       => 'summary AS\nboundary router',
	    style       => 'dashed',
	},
    );
    foreach (@nodes) {
	$_->{N}       = 'router'. $index++;
	$_->{shape} ||= 'box';
	$_->{style} ||= 'solid';
    }

    my $dot = "";
    $dot .= $class->graph_nodes(@nodes);
    $dot .= "\t{ rank=same;";
    $dot .= join("", map { " $_->{N};" } @nodes);
    $dot .= " }\n";
    return $dot;
}

# return legend networks as dot graph
sub legend_network {
    my $class = shift;
    my $index = 0;
    my @nodes = (
	{
	    label => 'transit\nnetwork',
	    style => 'bold',
	}, {
	    label => 'summary\nnetwork',
	    style => 'dashed',
	}, {
	    color => 'gray35',
	    label => 'AS external\nnetwork',
	    shape => 'egg',
	}, {
	    label => 'link\nprefix',
	    shape => 'hexagon',
	}, {
	    label => 'intra-area\nprefix',
	    shape => 'octagon',
	},
    );
    foreach (@nodes) {
	$_->{N}       = 'network'. $index++;
	$_->{shape} ||= 'ellipse';
	$_->{style} ||= 'solid';
    }

    my $dot = "";
    $dot .= $class->graph_nodes(@nodes);
    $dot .= "\t{ rank=same;";
    $dot .= join("", map { " $_->{N};" } @nodes);
    $dot .= " }\n";
    return $dot;
}

# return legend router network edges as dot graph
sub legend_edge {
    my $class = shift;
    my @networknodes = (
	{
	    label => 'network',
	}, {
	    label => 'transit\nnetwork',
	    style => 'bold',
	}, {
	    color => 'gray35',
	    label => 'ASE type 1\nnetwork',
	    shape => 'egg',
	}, {
	    color => 'gray35',
	    label => 'ASE type 2\nnetwork',
	    shape => 'egg',
	}, {
	    label => 'link\nprefix',
	    shape => 'hexagon',
	}, {
	    label => 'intra-area\nrouter prefix',
	    shape => 'octagon',
	},
    );
    foreach (@networknodes) {
	$_->{shape} ||= 'ellipse';
	$_->{style} ||= 'solid';
    }

    my @routernodes = (
	{
	    label => 'router',
	}, {
	    label => 'designated\nrouter',
	}, {
	    label => 'AS boundary\nrouter',
	}, {
	    label => 'AS boundary\nrouter',
	}, {
	    label => 'router',
	},
    );
    foreach (@routernodes) {
	$_->{shape} ||= 'box';
	$_->{style} ||= 'solid';
    }

    my $index = 0;
    my @edges = (
	{
	    headlabel => 'Interface',
	    style     => 'solid',
	    taillabel => 'cost',
	}, {
	    style     => 'bold',
	}, {
	    color     => 'gray35',
	    headlabel => 'cost',
	    style     => 'solid',
	    taillabel => 'LS-ID'
	}, {
	    color     => 'gray35',
	    headlabel => 'cost',
	    style     => 'dashed',
	    taillabel => 'LS-ID'
	}, {
	    style     => 'bold',
	    taillabel => 'Interface'
	}, {
	    style     => 'bold',
	    taillabel => 'LS-ID'
	},
    );
    for(my $i=0; $i<@edges; $i++) {
	$networknodes[$i]{N} = 'edgenetwork'. $index;
	$routernodes [$i]{N} = 'edgerouter'.  $index;
	$edges       [$i]{S} = 'edgenetwork'. $index;
	$edges       [$i]{D} = 'edgerouter'.  $index;
	$index++;
    }
    # swap arrow for cost IF explanation
    ($edges[0]{D}, $edges[0]{S}) = ($edges[0]{S}, $edges[0]{D});
    # link and intra area prefix have same router destination
    $edges[-1]{D} = $edges[-2]{D};
    pop @routernodes;

    my $dot = "";
    $dot .= $class->graph_nodes(@networknodes);
    $dot .= $class->graph_nodes(@routernodes);
    $dot .= $class->graph_edges(@edges);
    $dot .= "\t{ rank=same;";
    $dot .= join("", map { " $_->{S};" } @edges);
    $dot .= " }\n";
    return $dot;
}

# return legend router link to router or network as dot graph
sub legend_link {
    my $class = shift;
    my @routernodes = (
	{}, {}, {
	    label => 'designated\nrouter',
	}, {}, {
	    label => 'link\nprefix',
	    shape => 'hexagon',
	}, {
	    label => 'intra-area\nnetwork prefix',
	    shape => 'octagon',
	},
    );
    foreach (@routernodes) {
	$_->{label} ||= 'router';
	$_->{shape} ||= 'box';
	$_->{style} ||= 'solid';
    }

    my @dstnodes = (
	{}, {
	    label => 'transit\nnetwork',
	    style => 'bold',
	    shape => 'ellipse',
	}, {
	    label => 'transit\nnetwork',
	    style => 'bold',
	    shape => 'ellipse',
	}, {}, {
	    label => 'transit\nnetwork',
	    style => 'bold',
	    shape => 'ellipse',
	},
    );
    foreach (@dstnodes) {
	$_->{label} ||= 'router',
	$_->{shape} ||= 'box';
	$_->{style} ||= 'solid';
    }

    my $index = 0;
    my @edges = (
	{
	    label => 'point-to-point\nlink',
	}, {
	    label => 'link to\ntransit network',
	}, {
	    label => 'link to\ntransit network',
	    style => 'bold',
	}, {
	    label => 'virtual\nlink',
	    style => 'dotted',
	}, {
	    style     => 'solid',
	}, {
	    style     => 'bold',
	    taillabel => 'LS-ID',
	},
    );
    foreach (@edges) {
	$_->{style} ||= 'solid';
    }
    for(my $i=0; $i<@edges; $i++) {
	$routernodes[$i]{N} = 'linkrouter'. $index;
	$dstnodes   [$i]{N} = 'linkdst'.    $index;
	$edges      [$i]{S} = 'linkrouter'. $index;
	$edges      [$i]{D} = 'linkdst'.    $index;
	$index++;
    }
    # link and intra area prefix have same network destination
    $edges[-1]{D} = $edges[-2]{D};
    pop @dstnodes;

    my $dot = "";
    $dot .= $class->graph_nodes(@routernodes);
    $dot .= $class->graph_nodes(@dstnodes);
    $dot .= $class->graph_edges(@edges);
    $dot .= "\t{ rank=same;";
    $dot .= join("", map { " $_->{S};" } @edges);
    $dot .= " }\n";
    return $dot;
}

# return legend summary network and router edges as dot graph
sub legend_summary {
    my $class = shift;
    my @networknodes = (
	{
	    label => 'summary\nnetwork',
	    style => 'dashed',
	}, {
	    label => 'summary AS\nboundary router',
	    shape => 'box',
	    style => 'dashed',
	}, {
	    label => 'router and summary \nAS boundary router',
	    shape => 'box',
	}, {
	    color => 'gray35',
	    label => 'ASE\nnetwork',
	    shape => 'egg',
	},
    );
    foreach (@networknodes) {
	$_->{shape} ||= 'ellipse';
	$_->{style} ||= 'solid';
    }

    my @routernodes = (
	{}, {}, {
	    color => 'black',
	}, {
	    color => 'gray35',
	    label => 'summary AS\nboundary router',
	    style => 'dashed',
	},
    );
    foreach (@routernodes) {
	$_->{label} ||= 'area border\nrouter';
	$_->{shape} ||= 'box';
	$_->{style} ||= 'bold';
    }

    my $index = 0;
    my @edges = (
	{
	    headlabel => 'cost',
	    style     => 'dashed',
	    taillabel => 'LS-ID'
	}, {
	    headlabel => 'cost',
	    style     => 'dashed',
	    taillabel => 'LS-ID'
	}, {
	    color     => 'gray75',
	    headlabel => 'cost',
	    style     => 'dashed',
	    taillabel => 'LS-ID'
	}, {
	    color     => 'gray35',
	    headlabel => 'cost',
	    style     => 'solid',
	    taillabel => 'LS-ID'
	},
    );
    for(my $i=0; $i<@edges; $i++) {
	$networknodes[$i]{N} = 'summarynetwork'. $index;
	$routernodes [$i]{N} = 'summaryrouter'.  $index;
	$edges       [$i]{S} = 'summarynetwork'. $index;
	$edges       [$i]{D} = 'summaryrouter'.  $index;
	$index++;
    }

    my $dot = "";
    $dot .= $class->graph_nodes(@networknodes);
    $dot .= $class->graph_nodes(@routernodes);
    $dot .= $class->graph_edges(@edges);
    $dot .= "\t{ rank=same;";
    $dot .= join("", map { " $_->{S};" } @edges);
    $dot .= " }\n";
    return $dot;
}

=pod

=head1 SEE ALSO

L<OSPF::LSDB>,
L<OSPF::LSDB::View>

L<ospf2dot>,
L<ospfview>

RFC 5340 - OSPF for IPv6 - July 2008

=head1 AUTHORS

Alexander Bluhm

=head1 BUGS

IPv6 support has not been finished yet.
Especially there are much less checks than in IPv4.

=cut

1;
