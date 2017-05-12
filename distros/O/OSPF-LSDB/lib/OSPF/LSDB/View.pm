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

B<OSPF::LSDB::View> - display OSPF database as graphviz dot

=head1 SYNOPSIS

use OSPF::LSDB;

use OSPF::LSDB::View;

my $ospf = OSPF::LSDB-E<gt>L<new>();

my $view = OSPF::LSDB::View-E<gt>L<new>($ospf);

my $dot = view-E<gt>L<graph>();

=head1 DESCRIPTION

The B<OSPF::LSDB::View> module converts the content of a B<OSPF::LSDB>
instance into a graphviz dot string.
Routers and Networks become nodes, the links between them are
directed edges.
The different OSPF vertices are displayed with drawing styles that
are documented in the legend.

During conversion the link state database is checked.
Each inconsistency is reported as B<OSPF::LSDB> error and the color
of the object changes.
The colors are prioritized by severity.

=over 8

=item gray

All areas and ASE have unique gray levels.

=item black

Vertex is in multiple areas.

=item purple

An area is not in the list of all areas.

=item tan

Asymmetric designated router.

=item brown

Asymmetric links.

=item cyan

Conflicting AS external network.

=item green

Conflicting stub network.

=item blue

Conflicting network.

=item orange

Conflicting area.

=item yellow

Multiple links.

=item magenta

Conflicting link.

=item red

Missing node.

=back

Normally the B<OSPF::LSDB> copy constructor creates the object.
The public methods are:

=cut

package OSPF::LSDB::View;
use base 'OSPF::LSDB';
use List::MoreUtils qw(uniq);
use fields qw (
    routehash
    pointtopointhash transithash transitnets stubhash stubs stubareas
    virtualhash ifaddrs
    nethash nets netareas
    sumhash sums sumaggr
    boundhash boundaggr
    externhash externaggr
    netcluster transitcluster
    areagrays
    todo
);

sub new {
    my OSPF::LSDB::View $self = OSPF::LSDB::new(@_);
    die "$_[0] does not support IPv6" if $self->ipv6();
    return $self;
}

# convert decimal dotted IPv4 address to packed format
sub _ip2pack($) { pack("CCCC", split(/\./, $_[0])) }

# convert packed IPv4 address to decimal dotted format
sub _pack2ip($) { join('.', unpack("CCCC", $_[0])) }

# mask decimal dotted IPv4 network with decimal dotted IPv4 netmask
sub _maskip($$) { _pack2ip(_ip2pack($_[0]) & _ip2pack($_[1])) }

# compare function for sorting decimal dotted IPv4 address
sub _cmp_ip { unpack("N",_ip2pack($a)) <=> unpack("N",_ip2pack($b)) }

# compare function for sorting IPv4 address / netmask
sub _cmp_ip_net {
    my @a = split(/\//, $a);
    my @b = split(/\//, $b);
    return unpack("N",_ip2pack($a[0])) <=> unpack("N",_ip2pack($b[0])) ||
	   unpack("N",_ip2pack($a[1])) <=> unpack("N",_ip2pack($b[1]));
}

# take list of all areas
# create hash mapping from area to gray color
sub create_area_grays {
    my OSPF::LSDB::View $self = shift;
    my $ospf = $self->{ospf} or die "Uninitialized member";
    my @areas = sort _cmp_ip @{$ospf->{self}{areas}};
    my @colors = map { "gray". int(50 + ($_* 50 / @areas)) } (0..$#areas);
    my %areagrays;
    @areagrays{@areas} = @colors;
    $areagrays{ase} = "gray35";
    $self->{areagrays} = \%areagrays;
}

# each color gets a weight indicating the severity of its message
my %COLORWEIGHT;
@COLORWEIGHT{qw(black purple tan brown cyan green blue orange yellow magenta
  red)} = 1..100;
@COLORWEIGHT{map { "gray$_" } 1..99} = -99..-1;
$COLORWEIGHT{gray} = -100;

# take hash with color names and messages
# return color name
sub colors2string {
    my OSPF::LSDB::View $self = shift;
    my($colors) = @_;
    if (my $area = $colors->{gray}) {
	my $areagrays = $self->{areagrays} or die "Uninitialized member";
	my $gray = $areagrays->{$area};
	delete $colors->{purple};
	if (! $gray) {
	    $self->error($colors->{purple} = "Unexpected area $area.");
	} else {
	    $colors->{$gray} = $area eq "ase" ? "AS external" : "Area: $area";
	    delete $colors->{gray};
	}
    }
    if (my @areas = uniq @{$colors->{black} || []}) {
	$colors->{black} = "Areas: @areas";
    }
    return (sort { $COLORWEIGHT{$a} <=> $COLORWEIGHT{$b} } keys %$colors)[-1];
}

########################################################################
# RFC 2328
#       LS     LSA                LSA description
#       type   name
#       ________________________________________________________
#       1      Router-LSAs        Originated by all routers.
#                                 This LSA describes
#                                 the collected states of the
#                                 router's interfaces to an
#                                 area. Flooded throughout a
#                                 single area only.
########################################################################
# routers => [ {
#       area        => 'ipv4',
#       bits => {
#           B       => 'int',   # bit B
#           E       => 'int',   # bit E
#           V       => 'int',   # bit V
#       },
#       pointtopoints => [],    # Point-to-point connection to another router
#       transits => [],         # Connection to a transit network
#       stubs => [],            # Connection to a stub network
#       virtuals => [],         # Virtual link
#       router      => 'ipv4',  # Link State ID
#       routerid    => 'ipv4',  # Advertising Router
# ],
########################################################################
# $routehash{$router} = {
#   graph   => { N => router10, color => red, style => solid, }
#   hashes  => [ { router hash } ]
#   areas   => { $area => 1 }
#   missing => 1 (optional)
# }
# check wether interface addresses are used more than once
# $ifaddrs{$interface}{$router}++
########################################################################

# take router hash
# detect inconsistencies and set colors
sub check_router {
    my OSPF::LSDB::View $self = shift;
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
	if (my @badareas = grep { $rv->{areas}{$_} > 1 } @areas) {
	    $self->error($colors{yellow} =
	      "Router $rid has multiple entries in areas @badareas.");
	}
	if ($rv->{missing}) {
	    $self->error($colors{red} = "Router $rid missing.");
	} elsif (my @badids = grep { $_ ne $rid } map { $_->{routerid} }
	  @{$rv->{hashes}}) {
	    $self->error($colors{magenta} =
	      "Router $rid advertized by @badids.");
	}
	$rv->{colors} = \%colors;
    }
}

# take router structure, router id
# create routehash
# create pointtopointhash transithash transitnets stubhash stubs stubareas
# virtualhash
sub create_router {
    my OSPF::LSDB::View $self = shift;
    my($index) = @_;
    my $routerid = $self->{ospf}{self}{routerid};
    my %routehash;
    my %pointtopointhash;
    my %transithash;
    my %transitnets;
    my %stubhash;
    my %stubs;
    my %stubareas;
    my %virtualhash;
    my($transitindex, $stubindex) = (0, 0);
    foreach my $r (@{$self->{ospf}{database}{routers}}) {
	my $rid = $self->ipv6 ? $r->{routerid} : $r->{router};
	my $area = $r->{area};
	my $bits = $r->{bits};
	my $elem = $routehash{$rid};
	if (! $elem) {
	    $routehash{$rid} = $elem = {};
	    $elem->{graph} = {
		N     => "router". $$index++,
		label => $rid,
		shape => "box",
		style => $bits->{B} ? "bold" : "solid",
	    };
	    if ($rid eq $routerid) {
		$elem->{graph}{peripheries} = 2;
	    }
	}
	push @{$elem->{hashes}}, $r;
	if ($self->ipv6) {
	    my $lsid = $r->{router};
	    $elem->{areas}{$area}{$lsid}++;
	} else {
	    $elem->{areas}{$area}++;
	}

	foreach my $l (@{$r->{pointtopoints}}) {
	    $self->add_router_value(\%pointtopointhash, $rid, $area, $l);
	    $self->{ifaddrs}{$l->{interface}}{$rid}++;
	}
	foreach my $l (@{$r->{transits}}) {
	    $self->add_transit_value(\%transithash, \%transitnets,
	      \$transitindex, $rid, $area, $l);
	    $self->{ifaddrs}{$l->{interface}}{$rid}++;
	}
	foreach my $l (@{$r->{stubs}}) {
	    $self->add_stub_value(\%stubhash, \%stubs, \%stubareas,
	      \$stubindex, $rid, $area, $l);
	}
	foreach my $l (@{$r->{virtuals}}) {
	    $self->add_router_value(\%virtualhash, $rid, $area, $l);
	}
    }
    $self->{routehash} = \%routehash;
    $self->{pointtopointhash} = \%pointtopointhash;
    $self->{transithash} = \%transithash;
    $self->{transitnets} = \%transitnets;
    $self->{stubhash} = \%stubhash			unless $self->ipv6;
    $self->{stubs} = \%stubs				unless $self->ipv6;
    $self->{stubareas} = \%stubareas			unless $self->ipv6;
    $self->{virtualhash} = \%virtualhash;
}

# take router hash, routerid,
# network hash, summary hash, boundary hash, external hash
# add missing routers to router hash
sub add_missing_router {
    my OSPF::LSDB::View $self = shift;
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
      map { values %$_ } map { values %$_ } values %$nethash;
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

# take router hash, boundary hash
# remove duplicate routers from boundary hash
sub remove_duplicate_router {
    my OSPF::LSDB::View $self = shift;
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $boundhash = $self->{boundhash};
    # if AS boundary router is also regular router, only use the regular
    while (my($asbr,$bv) = each %$boundhash) {
	if ($routehash->{$asbr}) {
	    delete $bv->{graph};
	}
    }
}

# take hash containing router nodes
# return list of nodes
sub router2nodes {
    my OSPF::LSDB::View $self = shift;
    my $routehash = $self->{routehash} or die "Uninitialized member";
    return $self->elements2graphs(values %$routehash);
}

########################################################################
# RFC 2328
#                Type   Description
#                __________________________________________________
#                1      Point-to-point connection to another router
########################################################################
# pointtopoints => [ {
#        interface  => 'ipv4',  # Link Data
#                               # interface's ifIndex value
#        metric     => 'int',   # metric
#        routerid   => 'ipv4',  # Link ID
#                               # Neighboring router's Router ID
# ],
########################################################################
# $pointtopointhash{$pointtopointrouterid}{$area}{$routerid} = {
#   hashes => [ { link hash } ]
# }
########################################################################

########################################################################
# RFC 2328
#                Type   Description
#                __________________________________________________
#                4      Virtual link
########################################################################
# virtuals => [ {
#        interface  => 'ipv4',  # Link Data
#                               # router interface's IP address
#        metric     => 'int',   # metric
#        routerid   => 'ipv4',  # Link ID
#                               # Neighboring router's Router ID
# ],
########################################################################
# $virtualhash{$virtualrouterid}{$area}{$routerid} = {
#   hashes => [ { link hash } ]
# }
########################################################################

# take pointtopoint or virtual hash, type, router id, area, link structure
# add new element to pointtopoint or virtual hash
sub add_router_value {
    my OSPF::LSDB::View $self = shift;
    my($linkhash, $rid, $area, $link) = @_;
    my $dstrid = $link->{routerid};
    my $elem = $linkhash->{$dstrid}{$area}{$rid};
    if (! $elem) {
	$linkhash->{$dstrid}{$area}{$rid} = $elem = {};
    }
    push @{$elem->{hashes}}, $link;
}

# take link hash, type (pointtopoint or virtual), router hash
# return list of edges from src router to dst router
sub router2edges {
    my OSPF::LSDB::View $self = shift;
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
		    delete $colors{blue};
		    if ($type eq "pointtopoint" and my @badrids =
		      grep { $_ ne $rid } keys %{$ifaddrs->{$intf}}) {
			$self->error($colors{blue} =
			  "$name link at router $rid to router $dstrid ".
			  "interface address $intf also at router @badrids.");
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
# RFC 2328
#                Type   Description
#                __________________________________________________
#                2      Connection to a transit network
########################################################################
# transits => [ {
#        address    => 'ipv4',  # Link ID
#                               # IP address of Designated Router
#        interface  => 'ipv4',  # Link Data
#                               # router interface's IP address
#        metric     => 'int',   # metric
# ],
########################################################################
# $transithash{$transitaddress}{$area}{$routerid} = {
#   graph  => { N => transit2, color => red, style => solid, } (optional)
#   hashes => [ { link hash } ]
# }
# $transitnets->{$interface}{$routerid}{$area}{$address}++;
########################################################################

# take transit hash, transit cluster hash, net hash
# detect inconsistencies and set colors
sub check_transit {
    my OSPF::LSDB::View $self = shift;
    my($transitcluster) = @_;
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my $transithash = $self->{transithash} or die "Uninitialized member";
    while (my($addr, $av) = each %$transithash) {
	my %colors;
	if (! $nethash->{$addr} && keys %$av > 1) {
	    $self->error($colors{orange} =
	      "Transit network $addr missing in multiple areas.");
	}
	while (my($area, $ev) = each %$av) {
	    $colors{gray} = $area;
	    delete $colors{blue};
	    if (! $nethash->{$addr} && keys %$ev > 1) {
		$self->error($colors{blue} =
		  "Transit network $addr missing in area $area ".
		  "at multiple routers.");
	    }
	    while (my($rid, $rv) = each %$ev) {
		next unless $rv->{graph};
		delete @colors{qw(yellow red)};
		if ($nethash->{$addr}) {
		    $self->error($colors{yellow} =
		      "Transit network $addr in area $area ".
		      "at router $rid and network not in same area.");
		} elsif (! $colors{orange} && ! $colors{blue}) {
		    $self->error($colors{red} =
		      "Transit network $addr network missing.");
		}
		%{$rv->{colors}} = %colors;
		push @{$transitcluster->{$addr}}, $rv->{graph};
	    }
	}
    }
}

# take transit hash, router id, area, link structure, network hash
# add new element to transit hash
sub add_transit_value {
    my OSPF::LSDB::View $self = shift;
    my($transithash, $transitnets, $index, $rid, $area, $link) = @_;
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my $addr = $link->{address};
    my $intf = $link->{interface};
    $transitnets->{$intf}{$rid}{$area}{$addr}++;
    my $elem = $transithash->{$addr}{$area}{$rid};
    if (! $elem) {
	$transithash->{$addr}{$area}{$rid} = $elem = {};
	# check if address is in nethash and in matching nethash area
	if (! $nethash->{$addr} || ! map { $_->{$area} ? 1 : () }
	  map { values %$_ } values %{$nethash->{$addr}}) {
	    $elem->{graph} = {
	      N     => "transitnet". $$index++,
	      label => $addr,
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
    my OSPF::LSDB::View $self = shift;
    my $transithash = $self->{transithash} or die "Uninitialized member";
    return $self->elements2graphs(map { values %$_ } map { values %$_ }
      values %$transithash);
}

# take link hash, router hash, network hash
# return list of edges from router to transit network
sub transit2edges {
    my OSPF::LSDB::View $self = shift;
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $transithash = $self->{transithash} or die "Uninitialized member";
    my $ifaddrs = $self->{ifaddrs};
    my @elements;
    while (my($addr,$av) = each %$transithash) {
	while (my($area,$ev) = each %$av) {
	    while (my($rid,$rv) = each %$ev) {
		my %colors = (gray => $area);
		my $src = $routehash->{$rid}{graph}{N};
		if (@{$rv->{hashes}} > 1) {
		    $self->error($colors{yellow} =
		      "Transit network $addr at router $rid ".
		      "has multiple entries in area $area.");
		}
		foreach my $link (@{$rv->{hashes}}) {
		    my $intf = $link->{interface};
		    delete $colors{green};
		    if ($ifaddrs->{$intf} && $ifaddrs->{$intf}{$rid} > 1) {
			$self->error($colors{green} =
			  "Transit link at router $rid to network $addr ".
			  "interface address $intf not unique.");
		    }
		    delete $colors{blue};
		    if (my @badrids = grep { $_ ne $rid }
		      keys %{$ifaddrs->{$intf}}) {
			$self->error($colors{blue} =
			  "Transit link at router $rid to network $addr ".
			  "interface address $intf also at router @badrids.");
		    }
		    my $metric = $link->{metric};
		    # link from designated router to attached net
		    my $style = $addr eq $intf ? "bold" : "solid";
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
		    my $av = $nethash->{$addr};
		    while (my($mask,$mv) = each %$av) {
			my $nid = "$addr/$mask";
			my $intfip = $intf;
			foreach (split(/\./, $mask)) {
			    last if $_ ne 255;
			    $intfip =~ s/^\.?\d+//;
			}
			delete $colors{magenta};
			if (_maskip($addr, $mask) ne _maskip($intf, $mask)) {
			    $self->error($colors{magenta} =
			      "Transit network $addr in area $area ".
			      "at router $rid interface $intf ".
			      "not in network $nid.");
			    $intfip = $intf;
			}
			while (my($netrid,$nv) = each %$mv) {
			    my $ev = $nv->{$area}
			      or next;
			    delete $colors{brown};
			    delete $colors{tan};
			    if (! $ev->{attachrouters}{$rid}) {
				$self->error($colors{brown} =
				  "Transit link at router $rid not attached ".
				  "by network $nid in area $area.");
			    } elsif ($addr eq $intf && $netrid ne $rid) {
				$self->error($colors{tan} =
				  "Transit link at router $rid in area $area ".
				  "is designated but network $nid is not.");
			    }
			    my $dst = $ev->{graph}{N};
			    push @elements, { graph => {
				S         => $src,
				D         => $dst,
				headlabel => $intfip,
				style     => $style,
				taillabel => $metric,
			    }, colors => { %colors } };
			}
		    }
		}
	    }
	}
    }
    return $self->elements2graphs(@elements);
}

########################################################################
# RFC 2328
#                Type   Description
#                __________________________________________________
#                3      Connection to a stub network
########################################################################
# stubs => [ {
#        metric     => 'int',   # metric
#        netmask    => 'ipv4',  # Link Data
#                               # network's IP address mask
#        network    => 'ipv4',  # Link ID
#                               # IP network/subnet number
# ],
########################################################################
# $network = $network & $netmask
# $stubhash{$network}{$netmask}{$area}{$routerid} = {
#   graph  => { N => stub3, color => red, style => solid, }
#   hashes => [ { link hash } ]
# }
########################################################################

# take transit hash, net cluster hash, network hash
# detect inconsistencies and set colors
sub check_stub {
    my OSPF::LSDB::View $self = shift;
    my($netcluster) = @_;
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my %netsmv;
    while (my($addr,$av) = each %$nethash) {
	while (my($mask,$mv) = each %$av) {
	    my $net = _maskip($addr, $mask);
	    push @{$netsmv{$net}{$mask}}, $mv;
	}
    }

    my $stubhash = $self->{stubhash} or die "Uninitialized member";
    while (my($net, $nv) = each %$stubhash) {
	while (my($mask, $mv) = each %$nv) {
	    my %colors;
	    my $nid = "$net/$mask";
	    if ($netsmv{$net}{$mask}) {
		$self->error($colors{blue} =
		  "Stub network $nid is also network.");
	    }
	    delete $colors{orange};
	    if (keys %$mv > 1) {
		$self->error($colors{orange} =
		  "Stub network $nid in multiple areas.");
	    }
	    while (my($area, $ev) = each %$mv) {
		$colors{gray} = $area;
		delete $colors{green};
		if (keys %$ev > 1) {
		    $self->error($colors{green} =
		      "Stub network $nid in area $area at multiple routers.");
		}
		delete $colors{magenta};
		if ($netsmv{$net}{$mask} and my @otherareas =
		  grep { $_ ne $area } map { keys %$_ } map { values %$_ }
		  @{$netsmv{$net}{$mask}}) {
		    $self->error($colors{magenta} =
		      "Stub network $nid in area $area ".
		      "is also network in areas @otherareas.");
		}
		while (my($rid, $rv) = each %$ev) {
		    delete $colors{yellow};
		    if ($netsmv{$net}{$mask} and grep { $_->{$rid} }
		      @{$netsmv{$net}{$mask}}) {
			$self->error($colors{yellow} =
			  "Stub network $nid is also network at router $rid.");
		    }
		    %{$rv->{colors}} = %colors;
		    push @{$netcluster->{"$net/$mask"}}, $rv->{graph};
		}
	    }
	}
    }
}

# take stub hash, router id, area, link structure
# add new element to stub hash
sub add_stub_value {
    my OSPF::LSDB::View $self = shift;
    my($stubhash, $stubs, $stubareas, $index, $rid, $area, $link) = @_;
    my $addr = $link->{network};
    my $mask = $link->{netmask};
    my $net = _maskip($addr, $mask);
    $stubs->{$net}{$mask}++;
    $stubareas->{$net}{$mask}{$area}++;
    my $elem = $stubhash->{$net}{$mask}{$area}{$rid};
    if (! $elem) {
	$stubhash->{$net}{$mask}{$area}{$rid} = $elem = {};
	$elem->{graph} = {
	    N     => "stubnet". $$index++,
	    label => "$net\\n$mask",
	    shape => "ellipse",
	    style => "solid",
	};
    }
    push @{$elem->{hashes}}, $link;
}

# take hash containing stub network nodes
# return list of nodes
sub stub2nodes {
    my OSPF::LSDB::View $self = shift;
    my $stubhash = $self->{stubhash} or die "Uninitialized member";
    return $self->elements2graphs(map { values %$_ } map { values %$_ }
      map { values %$_ } values %$stubhash);
}

# take link hash, router hash
# return list of edges from router to stub network
sub stub2edges {
    my OSPF::LSDB::View $self = shift;
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $stubhash = $self->{stubhash} or die "Uninitialized member";
    my @elements;
    while (my($net,$nv) = each %$stubhash) {
	while (my($mask,$mv) = each %$nv) {
	    while (my($area,$ev) = each %$mv) {
		while (my($rid,$rv) = each %$ev) {
		    my %colors = (gray => $area);
		    my $src = $routehash->{$rid}{graph}{N};
		    my $nid = "$net/$mask";
		    if (@{$rv->{hashes}} > 1) {
			$self->error($colors{yellow} =
			  "Stub network $nid at router $rid ".
			  "has multiple entries in area $area.");
		    }
		    foreach my $link (@{$rv->{hashes}}) {
			my $dst = $rv->{graph}{N};
			my $addr = $link->{network};
			my @headlabel;
			delete $colors{magenta};
			if ($net ne $addr) {
			    $self->error($colors{magenta} =
			      "Stub network $nid address $addr ".
			      "is not network.");
			    my $intfip = $addr;
			    foreach (split(/\./, $mask)) {
				last if $_ ne 255;
				$intfip =~ s/^\.?\d+//;
			    }
			    @headlabel = (headlabel => $intfip);
			}
			my $metric = $link->{metric};
			push @elements, { graph => {
			    S         => $src,
			    D         => $dst,
			    @headlabel,
			    style     => "solid",
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
# RFC 2328
#       LS     LSA                LSA description
#       type   name
#       ________________________________________________________
#       2      Network-LSAs       Originated for broadcast
#                                 and NBMA networks by
#                                 the Designated Router. This
#                                 LSA contains the
#                                 list of routers connected
#                                 to the network. Flooded
#                                 throughout a single area only.
########################################################################
# networks => [
#       address     => 'ipv4',          # Link State ID
#       area        => 'ipv4',
#       attachments => [
#           routerid        => 'ipv4',  # Attached Router
#       ],
#       netmask     => 'ipv4',          # Network Mask
#       routerid    => 'ipv4',          # Advertising Router
# ],
########################################################################
# $network = $address & $netmask
# $nethash{$address}{$netmask}{$routerid}{$area} = {
#   graph         => { N => network1, color => red, style => bold, }
#   hashes        => [ { network hash } ]
#   attachrouters => { $attrid => 1 }
# }
# $nets{$network}{$netmask}++
# $netareas{$network}{$netmask}{$area}++
########################################################################

# take network hash, net cluster hash, net hash
# detect inconsistencies and set colors
sub check_network {
    my OSPF::LSDB::View $self = shift;
    my($netcluster) = @_;
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my $nets = $self->{nets} or die "Uninitialized member";
    my %colors;
    while (my($addr,$av) = each %$nethash) {
	delete $colors{magenta};
	if (keys %$av > 1) {
	    $self->error($colors{magenta} =
	      "Network $addr with multiple netmasks.");
	}
	while (my($mask,$mv) = each %$av) {
	    my $nid = "$addr/$mask";
	    my $net = _maskip($addr, $mask);
	    delete $colors{green};
	    if ($nets->{$net}{$mask} > 1) {
		$self->error($colors{green} =
		  "Network $nid not unique in network $net.");
	    }
	    delete $colors{blue};
	    if (keys %$mv > 1) {
		$self->error($colors{blue} =
		  "Network $nid at multiple routers.");
	    }
	    while (my($rid, $rv) = each %$mv) {
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
		    push @{$netcluster->{"$net/$mask"}}, $ev->{graph};
		}
	    }
	}
    }
}

# take network structure, net cluster hash
# return network hash
sub create_network {
    my OSPF::LSDB::View $self = shift;
    my($index) = @_;
    my %nethash;
    my %nets;
    my %netareas;
    foreach my $n (@{$self->{ospf}{database}{networks}}) {
	my $addr = $n->{address};
	my $mask = $n->{netmask};
	my $nid = "$addr/$mask";
	my $net = _maskip($addr, $mask);
	$nets{$net}{$mask}++;
	my $rid = $n->{routerid};
	my $area = $n->{area};
	$netareas{$net}{$mask}{$area}++;
	my $elem = $nethash{$addr}{$mask}{$rid}{$area};
	if (! $elem) {
	    $nethash{$addr}{$mask}{$rid}{$area} = $elem = {};
	    $elem->{graph} = {
		N     => "network". $$index++,
		label => "$net\\n$mask",
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
    $self->{netareas} = \%netareas;
}

# only necessary for ipv6
sub add_missing_network {
    my OSPF::LSDB::View $self = shift;
    my($index) = @_;
}

# take hash containing network nodes
# return list of nodes
sub network2nodes {
    my OSPF::LSDB::View $self = shift;
    my $nethash = $self->{nethash} or die "Uninitialized member";
    return $self->elements2graphs(map { values %$_ } map { values %$_ }
      map { values %$_ } values %$nethash);
}

# take network hash, router hash
# return list of edges from transit network to router
sub network2edges {
    my OSPF::LSDB::View $self = shift;
    my $nethash = $self->{nethash} or die "Uninitialized member";
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $transithash = $self->{transithash} or die "Uninitialized member";
    my @elements;
    while (my($addr,$av) = each %$nethash) {
	while (my($mask,$mv) = each %$av) {
	    my $nid = "$addr/$mask";
	    my $intfip = $addr;
	    foreach (split(/\./, $mask)) {
		last if $_ ne 255;
		$intfip =~ s/^\.?\d+//;
	    }
	    while (my($rid,$rv) = each %$mv) {
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
			    my $tv = $transithash->{$addr}{$area}{$arid};
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
			    my @taillabel;
			    if ($arid eq $rid) {
				# router is designated router
				$style = "bold";
				@taillabel = (taillabel => $intfip);
			    }
			    push @elements, { graph => {
				S     => $src,
				D     => $dst,
				style => $style,
				@taillabel,
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
				taillabel => $intfip,
			    }, colors => { %{$attcolors{$rid}} } };
			}
		    }
		}
	    }
	}
    }
    return $self->elements2graphs(@elements);
}

########################################################################
# RFC 2328
#       LS     LSA                LSA description
#       type   name
#       ________________________________________________________
#       3      Summary-LSAs       Originated by area border
#                                 routers, and flooded through-
#                                 out the LSA's associated
#                                 area. Each summary-LSA
#                                 describes a route to a
#                                 destination outside the area,
#                                 yet still inside the AS
#                                 (i.e., an inter-area route).
#                                 Type 3 summary-LSAs describe
#                                 routes to networks. Type 4
#                                 summary-LSAs describe
#                                 routes to AS boundary routers.
########################################################################
# summarys => [
#       address     => 'ipv4',  # Link State ID
#       area        => 'ipv4',
#       metric      => 'int',   # metric
#       netmask     => 'ipv4',  # Network Mask
#       routerid    => 'ipv4',  # Advertising Router
# ],
########################################################################
# $network = $address & $netmask
# $sumhash{$network}{$netmask} = {
#   graph    => { N => summary4, color => red, style => solid, }
#   hashes   => [ { summary hash } ]
#   arearids => { $area => { $routerid => 1 } }
# }
# $sums{$network}{$netmask}++;
########################################################################

# take summary hash, net cluster hash, network hash, stub hash
# detect inconsistencies and set colors
sub check_summary {
    my OSPF::LSDB::View $self = shift;
    my($netcluster) = @_;
    my $netareas = $self->{netareas} or die "Uninitialized member";
    my $stubareas = $self->{stubareas} or die "Uninitialized member";
    my $sumhash = $self->{sumhash} or die "Uninitialized member";
    while (my($net,$nv) = each %$sumhash) {
	while (my($mask,$mv) = each %$nv) {
	    my %colors;
	    my $nid = "$net/$mask";
	    my @areas = keys %{$mv->{arearids}};
	    if (@areas > 1) {
		$colors{black} = \@areas;
	    } else {
		$colors{gray} = $areas[0];
	    }
	    if (my @badareas = grep { $netareas->{$net}{$mask}{$_} } @areas) {
		$self->error($colors{blue} =
		  "Summary network $nid is also network in areas @badareas.");
	    }
	    if ($stubareas and
	      my @badareas = grep { $stubareas->{$net}{$mask}{$_} } @areas) {
		$self->error($colors{green} =
		  "Summary network $nid is also stub network ".
		  "in areas @badareas.");
	    }
	    $mv->{colors} = \%colors;
	    push @{$netcluster->{"$net/$mask"}}, $mv->{graph};
	}
    }
}

# take summary structure, net cluster hash, network hash, link hash
# return summary hash
sub create_summary {
    my OSPF::LSDB::View $self = shift;
    my $index = 0;
    my %sumhash;
    my %sums;
    foreach my $s (@{$self->{ospf}{database}{summarys}}) {
	my $addr = $s->{address};
	my $mask = $s->{netmask};
	my $nid = "$addr/$mask";
	my $net = _maskip($addr, $mask);
	$sums{$net}{$mask}++;
	my $rid = $s->{routerid};
	my $area = $s->{area};
	my $elem = $sumhash{$net}{$mask};
	if (! $elem) {
	    $sumhash{$net}{$mask} = $elem = {};
	    $elem->{graph} = {
		N     => "summary". $index++,
		label => "$net\\n$mask",
		shape => "ellipse",
		style => "dashed",
	    };
	}
	push @{$elem->{hashes}}, $s;
	$elem->{arearids}{$area}{$rid}++;
    }
    $self->{sumhash} = \%sumhash;
    $self->{sums} = \%sums;
}

# take hash containing summary nodes
# return list of nodes
sub summary2nodes {
    my OSPF::LSDB::View $self = shift;
    my $sumhash = $self->{sumhash} or die "Uninitialized member";
    return $self->elements2graphs(map { values %$_ } values %$sumhash);
}

# take summary hash, router hash
# return list of edges from summary network to router
sub summary2edges {
    my OSPF::LSDB::View $self = shift;
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $sumhash = $self->{sumhash} or die "Uninitialized member";
    my @elements;
    while (my($net,$nv) = each %$sumhash) {
	while (my($mask,$mv) = each %$nv) {
	    my $nid = "$net/$mask";
	    my $src = $mv->{graph} && $mv->{graph}{N};
	    foreach my $s (@{$mv->{hashes}}) {
		my $rid = $s->{routerid};
		my $dst = $routehash->{$rid}{graph}{N}
		  or die "No router graph $rid";
		my $addr = $s->{address};
		my $addrip = $addr;
		foreach (split(/\./, $mask)) {
		    last if $_ ne 255;
		    $addrip =~ s/^\.?\d+//;
		}
		my $area = $s->{area};
		my %colors = (gray => $area);
		if (! $routehash->{$rid}{areas}{$area}) {
		    $self->error($colors{orange} =
		      "Summary network $nid and router $rid ".
		      "not in same area $area.");
		}
		if ($mv->{arearids}{$area}{$rid} > 1) {
		    $self->error($colors{yellow} =
		      "Summary network $nid at router $rid ".
		      "has multiple entries in area $area.");
		}
		my $metric = $s->{metric};
		$s->{graph} = {
		    S         => $src,
		    D         => $dst,
		    headlabel => $metric,
		    style     => "dashed",
		    taillabel => $addrip,
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
# $sumaggr{$areaaggr}{$netaggr} = {
#   graph   => { N => summary5, color => black, style => dashed, }
#   routers => { $routerid => { $area => { $metric => [ { sum hash } ] } } }
# }
########################################################################

# take summary hash
# return summary aggregate
sub create_sumaggr {
    my OSPF::LSDB::View $self = shift;
    # $ridnets{$rid}{$network} = {
    #   color => orange,
    #   areas => { $area => { $metric => [ { sum hash } ] } }
    # }
    my $sumhash = $self->{sumhash} or die "Uninitialized member";
    my %ridareanets;
    while (my($net,$nv) = each %$sumhash) {
	while (my($mask,$mv) = each %$nv) {
	    my $nid = "$net/$mask";
	    # no not aggregate clustered graphs
	    next if $mv->{graph}{C};
	    my $colors = $mv->{colors};
	    # no not aggregate graphs with errors
	    next if grep { ! /^(gray|black)$/ } keys %$colors;
	    my $areaaggr = join('\n', sort _cmp_ip keys %{$mv->{arearids}});
	    foreach my $s (@{$mv->{hashes}}) {
		my $rid = $s->{routerid};
		my $area = $s->{area};
		my $metric = $s->{metric};
		my $elem = $ridareanets{$rid}{$areaaggr}{$nid};
		if (! $elem) {
		    $ridareanets{$rid}{$areaaggr}{$nid} = $elem = {
			colors => { %$colors },
		    };
		} elsif (! $elem->{colors}{gray} || ! $colors->{gray} ||
		  $elem->{colors}{gray} ne $colors->{gray}) {
		    push @{$elem->{colors}{black}},
		      (delete($elem->{colors}{gray}) || ()),
		      ($colors->{gray} || ()), @{$colors->{black} || []};
		}
		push @{$elem->{areas}{$area}{$metric}}, $s;
	    }
	    delete $mv->{graph};
	}
    }
    my $index = 0;
    my %sumaggr;
    while (my($rid,$rv) = each %ridareanets) {
	while (my($area,$av) = each %$rv) {
	    my $netaggr = join('\n', sort _cmp_ip_net keys %$av);
	    my $elem = $sumaggr{$netaggr};
	    if (! $elem) {
		$sumaggr{$netaggr} = $elem = {};
		$elem->{graph} = {
		    N     => "summaryaggregate". $index++,
		    label => $netaggr,
		    shape => "ellipse",
		    style => "dashed",
		};
	    }
	    while (my($nid,$nv) = each %$av) {
		my $colors = $nv->{colors};
		if (! $elem->{colors}) {
		    %{$elem->{colors}} = %$colors;
		} elsif (! $elem->{colors}{gray} || ! $colors->{gray} ||
		  $elem->{colors}{gray} ne $colors->{gray}) {
		    push @{$elem->{colors}{black}},
		      (delete($elem->{colors}{gray}) || ()),
		      ($colors->{gray} || ()), @{$colors->{black} || []};
		}
		while (my($area,$ev) = each %{$nv->{areas}}) {
		    while (my($metric,$ss) = each %$ev) {
			push @{$elem->{routers}{$rid}{$area}{$metric}}, @$ss;
		    }
		}
	    }
	}
    }
    $self->{sumaggr} = \%sumaggr;
}

# take hash containing summary aggregated nodes
# return list of nodes
sub sumaggr2nodes {
    my OSPF::LSDB::View $self = shift;
    my $sumaggr = $self->{sumaggr} or die "Uninitialized member";
    return $self->elements2graphs(values %$sumaggr);
}

# take summary aggregate
# return list of edges from summary aggregate networks to router
sub sumaggr2edges {
    my OSPF::LSDB::View $self = shift;
    my $sumaggr = $self->{sumaggr} or die "Uninitialized member";
    my @elements;
    while (my($netaggr,$nv) = each %$sumaggr) {
	my $src = $nv->{graph}{N};
	while (my($rid,$rv) = each %{$nv->{routers}}) {
	    while (my($area,$av) = each %$rv) {
		while (my($metric,$ss) = each %$av) {
		    my $aggrs;
		    foreach my $s (@$ss) {
			$s->{graph}{S} = $src;
			# no not aggregate graphs with errors
			if (grep { ! /^(gray|black)$/ } keys %{$s->{colors}}) {
			    push @elements, $s;
			} else {
			    delete $s->{graph}{taillabel};
			    $aggrs = $s;
			}
		    }
		    push @elements, $aggrs if $aggrs;
		}
	    }
	}
    }
    return $self->elements2graphs(@elements);
}

########################################################################
# RFC 2328
#       LS     LSA                LSA description
#       type   name
#       ________________________________________________________
#       4      Summary-LSAs       Originated by area border
#                                 routers, and flooded through-
#                                 out the LSA's associated
#                                 area. Each summary-LSA
#                                 describes a route to a
#                                 destination outside the area,
#                                 yet still inside the AS
#                                 (i.e., an inter-area route).
#                                 Type 3 summary-LSAs describe
#                                 routes to networks. Type 4
#                                 summary-LSAs describe
#                                 routes to AS boundary routers.
########################################################################
# boundarys => [
#       area        => 'ipv4',
#       asbrouter   => 'ipv4',  # Link State ID
#       metric      => 'int',   # metric
#       routerid    => 'ipv4',  # Advertising Router
# ],
########################################################################
# $boundhash{$asbrouter} = {
#   graph     => { N => boundary6, color => red, style => dashed, }
#   hashes    => [ { boundary hash } ]
#   arearids  => { $area => { $routerid => 1 }
#   aggregate => { $asbraggr => 1 } (optional)
# }
########################################################################

# take boundary hash
# detect inconsistencies and set colors
sub check_boundary {
    my OSPF::LSDB::View $self = shift;
    my $boundhash = $self->{boundhash} or die "Uninitialized member";
    while (my($asbr,$bv) = each %$boundhash) {
	my @areas = keys %{$bv->{arearids}};
	if (@areas > 1) {
	    $bv->{colors}{black} = \@areas;
	} else {
	    $bv->{colors}{gray} = $areas[0];
	}
    }
}

# take boundary structure
# return boundary hash
sub create_boundary {
    my OSPF::LSDB::View $self = shift;
    my $index = 0;
    my %boundhash;
    foreach my $b (@{$self->{ospf}{database}{boundarys}}) {
	my $asbr = $b->{asbrouter};
	my $rid = $b->{routerid};
	my $area = $b->{area};
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
}

# take hash containing boundary nodes
# return list of nodes
sub boundary2nodes {
    my OSPF::LSDB::View $self = shift;
    my $boundhash = $self->{boundhash} or die "Uninitialized member";
    return $self->elements2graphs(values %$boundhash);
}

# take boundary hash, router hash
# return list of edges from boundary router to router
sub boundary2edges {
    my OSPF::LSDB::View $self = shift;
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $boundhash = $self->{boundhash} or die "Uninitialized member";
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
	    my $metric = $b->{metric};
	    $b->{graph} = {
		S         => $src,
		D         => $dst,
		headlabel => $metric,
		style     => "dashed",
	    };
	    $b->{colors} = \%colors;
	    # in case of aggregation src is undef
	    push @elements, $b if $src;
	}
    }
    return $self->elements2graphs(@elements);
}

########################################################################
# $boundaggr{$asbraggr} = {
#   graph   => { N => boundary7, color => black, style => dashed, }
#   routers => { $routerid => { $area => { $metric => [ { bound hash } ] } } }
# }
########################################################################

# take boundary hash
# return boundary aggregate
sub create_boundaggr {
    my OSPF::LSDB::View $self = shift;
    # $ridasbrs{$rid}{$asbr} = {
    #   color => orange,
    #   areas => { $area => { $metric => [ { bound hash } ] } }
    # }
    my $boundhash = $self->{boundhash} or die "Uninitialized member";
    my %ridasbrs;
    while (my($asbr,$bv) = each %$boundhash) {
	# no not aggregate if ASBR has been deleted by create route
	next unless $bv->{graph};
	my $colors = $bv->{colors};
	# no not aggregate graphs with errors
	next if grep { ! /^(gray|black)$/ } keys %$colors;
	foreach my $b (@{$bv->{hashes}}) {
	    my $rid = $b->{routerid};
	    my $area = $b->{area};
	    my $metric = $b->{metric};
	    my $elem = $ridasbrs{$rid}{$asbr};
	    if (! $elem) {
		$ridasbrs{$rid}{$asbr} = $elem = {
		    colors => { %$colors },
		};
	    } elsif (! $elem->{colors}{gray} || ! $colors->{gray} ||
	      $elem->{colors}{gray} ne $colors->{gray}) {
		push @{$elem->{colors}{black}},
		  (delete($elem->{colors}{gray}) || ()),
		  ($colors->{gray} || ()), @{$colors->{black} || []};
	    }
	    push @{$elem->{areas}{$area}{$metric}}, $b;
	}
	delete $bv->{graph};
    }
    my $index = 0;
    my %boundaggr;
    while (my($rid,$rv) = each %ridasbrs) {
	my $asbraggr = join('\n', sort _cmp_ip keys %$rv);
	my $elem = $boundaggr{$asbraggr};
	if (! $elem) {
	    $boundaggr{$asbraggr} = $elem = {};
	    $elem->{graph} = {
		N     => "boundaryaggregate". $index++,
		label => $asbraggr,
		shape => "box",
		style => "dashed",
	    };
	}
	while (my($asbr,$bv) = each %$rv) {
	    $boundhash->{$asbr}{aggregate}{$asbraggr}++;
	    my $colors = $bv->{colors};
	    if (! $elem->{colors}) {
		%{$elem->{colors}} = %$colors;
	    } elsif (! $elem->{colors}{gray} || ! $colors->{gray} ||
	      $elem->{colors}{gray} ne $colors->{gray}) {
		push @{$elem->{colors}{black}},
		  (delete($elem->{colors}{gray}) || ()),
		  ($colors->{gray} || ()), @{$colors->{black} || []};
	    }
	    while (my($area,$ev) = each %{$bv->{areas}}) {
		while (my($metric,$bs) = each %$ev) {
		    push @{$elem->{routers}{$rid}{$area}{$metric}}, @$bs;
		}
	    }
	}
    }
    $self->{boundaggr} = \%boundaggr;
}

# take hash containing boundary aggregated nodes
# return list of nodes
sub boundaggr2nodes {
    my OSPF::LSDB::View $self = shift;
    my $boundaggr = $self->{boundaggr} or die "Uninitialized member";
    return $self->elements2graphs(values %$boundaggr);
}

# take boundary aggregate
# return list of edges from boundary aggregate routers to router
sub boundaggr2edges {
    my OSPF::LSDB::View $self = shift;
    my $boundaggr = $self->{boundaggr} or die "Uninitialized member";
    my @elements;
    while (my($asbraggr,$bv) = each %$boundaggr) {
	my $src = $bv->{graph}{N};
	while (my($rid,$rv) = each %{$bv->{routers}}) {
	    while (my($area,$av) = each %$rv) {
		while (my($metric,$bs) = each %$av) {
		    my $aggrb;
		    foreach my $b (@$bs) {
			$b->{graph}{S} = $src;
			# no not aggregate graphs with errors
			if (grep { ! /^(gray|black)$/ } keys %{$b->{colors}}) {
			    push @elements, $b;
			} else {
			    $aggrb = $b;
			}
		    }
		    push @elements, $aggrb if $aggrb;
		}
	    }
	}
    }
    return $self->elements2graphs(@elements);
}

########################################################################
# RFC 2328
#       LS     LSA                LSA description
#       type   name
#       ________________________________________________________
#       5      AS-external-LSAs   Originated by AS boundary
#                                 routers, and flooded through-
#                                 out the AS. Each
#                                 AS-external-LSA describes
#                                 a route to a destination in
#                                 another Autonomous System.
#                                 Default routes for the AS can
#                                 also be described by
#                                 AS-external-LSAs.
########################################################################
# externals => [
#       address     => 'ipv4',  # Link State ID
#       metric      => 'int',   # metric
#       forward     => 'ipv4',  # Forwarding address
#       netmask     => 'ipv4',  # Network Mask
#       routerid    => 'ipv4',  # Advertising Router
#       type        => 'int',   # bit E
# ],
########################################################################
# $network = $address & $netmask
# $externhash{$network}{$netmask} = {
#   graph   => { N => external8, color => red, style => dashed, }
#   hashes  => [ { ase hash } ]
#   routers => { $routerid => 1 }
# }
########################################################################

# take external hash, net cluster hash, network hash, stub hash, summary hash
# detect inconsistencies and set colors
sub check_external {
    my OSPF::LSDB::View $self = shift;
    my($netcluster) = @_;
    my $nets = $self->{nets} or die "Uninitialized member";
    my $stubs = $self->{stubs} or die "Uninitialized member";
    my $sums = $self->{sums};
    my $externhash = $self->{externhash} or die "Uninitialized member";
    while (my($net,$nv) = each %$externhash) {
	while (my($mask,$mv) = each %$nv) {
	    my %colors = (gray => "ase");
	    my $nid = "$net/$mask";
	    if ($nets->{$net}{$mask}) {
		$self->error($colors{blue} =
		  "AS external network $nid is also network.");
	    }
	    if ($stubs and $stubs->{$net}{$mask}) {
		$self->error($colors{green} =
		  "AS external network $nid is also stub network.");
	    }
	    if ($sums->{$net}{$mask}) {
		$self->error($colors{cyan} =
		  "AS external network $nid is also summary network.");
	    }
	    $mv->{colors} = \%colors;
	    push @{$netcluster->{"$net/$mask"}}, $mv->{graph};
	}
    }
}

# take external structure, net cluster hash, network hash, link hash
# return external hash
sub create_external {
    my OSPF::LSDB::View $self = shift;
    my $index = 0;
    my %externhash;
    foreach my $e (@{$self->{ospf}{database}{externals}}) {
	my $addr = $e->{address};
	my $mask = $e->{netmask};
	my $nid = "$addr/$mask";
	my $net = _maskip($addr, $mask);
	my $rid = $e->{routerid};
	my $elem = $externhash{$net}{$mask};
	if (! $elem) {
	    $externhash{$net}{$mask} = $elem = {};
	    $elem->{graph} = {
		N     => "external". $index++,
		label => "$net\\n$mask",
		shape => "egg",
		style => "solid",
	    };
	}
	push @{$elem->{hashes}}, $e;
	$elem->{routers}{$rid}++;
    }
    $self->{externhash} = \%externhash;
}

# take hash containing external nodes
# return list of nodes
sub external2nodes {
    my OSPF::LSDB::View $self = shift;
    my $externhash = $self->{externhash} or die "Uninitialized member";
    return $self->elements2graphs(map { values %$_ } values %$externhash);
}

# take external hash, router hash, boundary hash, boundary aggregate
# return list of edges from external network to router
sub external2edges {
    my OSPF::LSDB::View $self = shift;
    my $routehash = $self->{routehash} or die "Uninitialized member";
    my $boundhash = $self->{boundhash};
    my $boundaggr = $self->{boundaggr};
    my $externhash = $self->{externhash} or die "Uninitialized member";
    my @elements;
    while (my($net,$nv) = each %$externhash) {
	while (my($mask,$mv) = each %$nv) {
	    my $nid = "$net/$mask";
	    my $src = $mv->{graph}{N};
	    my %dtm;  # when dst is aggregated, aggregate edges
	    foreach my $e (@{$mv->{hashes}}) {
		my $rid = $e->{routerid};
		my $addr = $e->{address};
		my $addrip = $addr;
		foreach (split(/\./, $mask)) {
		    last if $_ ne 255;
		    $addrip =~ s/^\.?\d+//;
		}
		my $type = $e->{type};
		my $metric = $e->{metric};
		my %colors = (gray => "ase");
		if ($mv->{routers}{$rid} > 1) {
		    $self->error($colors{yellow} =
		      "AS external network $nid at router $rid ".
		      "has multiple entries.");
		}
		my $style = $type == 1 ? "solid" : "dashed";
		my %graph = (
		    S         => $src,
		    headlabel => $metric,
		    style     => $style,
		    taillabel => $addrip,
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
    my OSPF::LSDB::View $self = shift;
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
	my $netaggr = join('\n', sort _cmp_ip_net keys %$rv);
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

# take hash containing external aggregated nodes
# return list of nodes
sub externaggr2nodes {
    my OSPF::LSDB::View $self = shift;
    my $externaggr = $self->{externaggr} or die "Uninitialized member";
    return $self->elements2graphs(values %$externaggr);
}

# take external aggregate
# return list of edges from external aggregate network to router
sub externaggr2edges {
    my OSPF::LSDB::View $self = shift;
    my $externaggr = $self->{externaggr} or die "Uninitialized member";
    my @elements;
    while (my($netaggr,$nv) = each %$externaggr) {
	my $src = $nv->{graph}{N};
	my %dtm;
	while (my($rid,$rv) = each %{$nv->{routers}}) {
	    while (my($type,$tv) = each %$rv) {
		while (my($metric,$es) = each %$tv) {
		    foreach my $e (@$es) {
			while (my($dst,$elem) = each %{$e->{elems}}) {
			    my %graph = %{$elem->{graph}};
			    $graph{S} = $src;
			    delete $graph{taillabel};
			    my %colors = %{$elem->{colors}};
			    my $elem = {
				graph  => \%graph,
				colors => \%colors,
			    };
			    # no not aggregate graphs with errors
			    if (grep { ! /^(gray|black)$/ } keys %colors) {
				push @elements, $elem;
			    } else {
				$dtm{$dst}{$type}{$metric} = $elem;
			    }
			}
		    }
		}
	    }
	}
	push @elements, map { values %$_ } map { values %$_ } values %dtm;
    }
    return $self->elements2graphs(@elements);
}

# take cluster hash
# insert cluster into graphs referenced more than once
sub set_cluster {
    my OSPF::LSDB::View $self = shift;
    my($type) = @_;
    my $cluster = $self->{$type."cluster"} or die "Uninitialized member";
    while (my($id,$graphlist) = each %$cluster) {
	next if @$graphlist < 2;
	foreach (@$graphlist) {
	    $_->{C} = $id;
	}
    }
}

# take list of nodes ( { N => node, C => cluster, label => ... }, ... )
# return nodes of dot graph
sub graph_nodes {
    my $class = shift;
    my @nodes = @_;
    my $dot = "";
    foreach (@nodes) {
	my $cluster = $_->{C};
	$dot .= "\t";
	$dot .= "subgraph \"cluster $cluster\" { " if $cluster;
	$dot .= "$_->{N} [\n";
	while (my($k,$v) = each %$_) {
	    next if $k eq 'C' || $k eq 'N';
	    $dot .= "\t\t$k=\"$v\"\n";
	}
	$dot .= "\t]";
	$dot .= " }" if $cluster;
	$dot .= ";\n";
    }
    return $dot;
}

# take array containing elements, create color
# return nodes or edges of dot graph
sub elements2graphs {
    my OSPF::LSDB::View $self = shift;
    my @elements = @_;
    foreach my $elem (@elements) {
	my $graph = $elem->{graph} or next;
	my $color = $self->colors2string($elem->{colors});
	my $message = $elem->{colors}{$color};
	$graph->{color} = $color;
	$graph->{tooltip} = $message;
	if ($self->{todo}{warning}) {
	    if ($graph->{label}) {
		$graph->{label} .= '\n';
	    } else {
		$graph->{label} = "";
	    }
	    if ($self->{todo}{warning}{all}) {
		$graph->{label} .= join('\n', values %{$elem->{colors}});
	    } else {
		$graph->{label} .= $message;
	    }
	}
    }
    return map { $_->{graph} || () } @elements;
}

# take list of edges ( { S => srcNode , D => dstNode, label => ... }, ... )
# return edges of dot graph
sub graph_edges {
    my $class = shift;
    my @edges = @_;
    my $dot = "";
    foreach (@edges) {
	$dot .= "\t$_->{S} -> $_->{D} [\n";
	while (my($k,$v) = each %$_) {
	    next if $k eq 'S' || $k eq 'D';
	    $dot .= "\t\t$k=\"$v\"\n";
	}
	$dot .= "\t];\n";
    }
    return $dot;
}

# take lsdb structure, router id, todo hash
# return dot graph
sub graph_database {
    my OSPF::LSDB::View $self = shift;
    my $todo = $self->{todo};

    # convert ospf structure into separate hashes and create cluster hashes
    my $netindex = 0;
    $self->create_network(\$netindex);
    if ($todo->{intra}) {
	$self->create_intranetworks()			if $self->ipv6;
    }
    # add missing network may add graphs to nethash
    # must be called before add_transit_value in create_router
    $self->add_missing_network(\$netindex);
    my $routeindex = 0;
    $self->create_router(\$routeindex);
    if ($todo->{link}) {
	$self->create_link()				if $self->ipv6;
    }
    if ($todo->{intra}) {
	$self->create_intrarouters()			if $self->ipv6;
    }
    $self->create_summary() if $todo->{summary};
    $self->create_boundary() if $todo->{boundary};
    $self->create_external() if $todo->{external};

    # add missing router may add graphs to routehash
    # must be called before check_router
    $self->add_missing_router(\$routeindex);

    my %netcluster;
    my %transitcluster;
    $self->check_network(\%netcluster);
    $self->check_router();
    $self->check_transit(\%transitcluster);
    $self->check_stub(\%netcluster)			unless $self->ipv6;
    if ($todo->{link}) {
	$self->check_link()				if $self->ipv6;
    }
    if ($todo->{intra}) {
	$self->check_intrarouter()			if $self->ipv6;
	$self->check_intranetwork()			if $self->ipv6;
    }
    $self->check_summary(\%netcluster) if $todo->{summary};
    $self->check_boundary() if $todo->{boundary};
    $self->check_external(\%netcluster) if $todo->{external};
    $self->{netcluster} = \%netcluster;
    $self->{transitcluster} = \%transitcluster;

    # remove duplicate router may delete graphs from boundhash
    # must be called after check_boundary
    $self->remove_duplicate_router();

    # insert cluster with more than one entry into graphs
    if ($todo->{cluster}) {
	$self->set_cluster("net");
	$self->set_cluster("transit");
    }

    # graphs within clusters are not aggregated
    $self->create_sumaggr()
      if $todo->{summary} && $todo->{summary}{aggregate};
    $self->create_boundaggr()
      if $todo->{boundary} && $todo->{boundary}{aggregate};
    $self->create_externaggr()
      if $todo->{external} && $todo->{external}{aggregate};

    my @nodes;
    push @nodes, $self->router2nodes();
    push @nodes, $self->transit2nodes();
    push @nodes, $self->stub2nodes()			unless $self->ipv6;
    push @nodes, $self->network2nodes();
    if ($todo->{link}) {
	push @nodes, $self->link2nodes()		if $self->ipv6;
    }
    if ($todo->{intra}) {
	push @nodes, $self->intrarouter2nodes()		if $self->ipv6;
	push @nodes, $self->intranetwork2nodes()	if $self->ipv6;
    }
    if ($todo->{summary}) {
	push @nodes, $self->summary2nodes();
	push @nodes, $self->sumaggr2nodes()
	  if $todo->{summary}{aggregate};
    }
    if ($todo->{boundary}) {
	push @nodes, $self->boundary2nodes();
	push @nodes, $self->boundaggr2nodes()
	  if $todo->{boundary}{aggregate};
    }
    if ($todo->{external}) {
	push @nodes, $self->external2nodes();
	push @nodes, $self->externaggr2nodes()
	  if $todo->{external}{aggregate};
    }
    my $dot = $self->graph_nodes(@nodes);

    my @edges;
    push @edges, $self->router2edges("pointtopoint");
    push @edges, $self->transit2edges();
    push @edges, $self->stub2edges()			unless $self->ipv6;
    push @edges, $self->router2edges("virtual");
    push @edges, $self->network2edges();
    if ($todo->{link}) {
	push @edges, $self->link2edges()		if $self->ipv6;
    }
    if ($todo->{intra}) {
	push @edges, $self->intrarouter2edges()		if $self->ipv6;
	push @edges, $self->intranetwork2edges()	if $self->ipv6;
    }
    if ($todo->{summary}) {
	push @edges, $self->summary2edges();
	push @edges, $self->sumaggr2edges()
	  if $todo->{summary}{aggregate};
    }
    if ($todo->{boundary}) {
	push @edges, $self->boundary2edges();
	push @edges, $self->boundaggr2edges()
	  if $todo->{boundary}{aggregate};
    }
    if ($todo->{external}) {
	push @edges, $self->external2edges();
	push @edges, $self->externaggr2edges()
	  if $todo->{external}{aggregate};
    }
    $dot .= $self->graph_edges(@edges);

    return $dot;
}

# return dot default settings
sub graph_default {
    my $class = shift;
    my $dot = "";
    $dot .= "\tnode [ color=gray50 fontsize=14 ];\n";
    $dot .= "\tedge [ color=gray50 fontsize=8  ];\n";
    return $dot;
}

=pod

=over

=item $self-E<gt>L<graph>(%todo)

Convert the internal database into graphviz dot format.
The output for the dot program is returned as string.

The B<%todo> parameter allows to tune the displayed details.
It consists of the subkeys:

=over 8

=item B<boundary>

Display the summary AS boundary routers.
If the additional subkey B<aggregate> is given, multiple AS boundary
routers are aggregated in one node.

=item B<external>

Display the AS external networks.
If the additional subkey B<aggregate> is given, multiple AS external
networks are aggregated in one node.

=item B<cluster>

The same network is always displayed in the same rectangular cluster,
even if is belongs to different LSA types.

=item B<summary>

Display the summary networks.
If the additional subkey B<aggregate> is given, multiple networks
are aggregated in one node.

=item B<warnings>

Write the most severe warning about OSPF inconsistencies into the
label of the dot graph.
This warning determines also the color of the node or edge.
If the additional subkey B<all> is given, all warnings are added.

=back

=cut

# take ospf structure, todo hash
# return the complete dot graph
sub graph {
    my OSPF::LSDB::View $self = shift;
    %{$self->{todo}} = @_;
    $self->create_area_grays();
    my $dot = "digraph \"ospf lsdb\" {\n";
    $dot .= $self->graph_default();
    $dot .= $self->graph_database();
    $dot .= "}\n";
    return $dot;
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
	    label => 'stub\nnetwork',
	}, {
	    label => 'summary\nnetwork',
	    style => 'dashed',
	}, {
	    color => 'gray35',
	    label => 'AS external\nnetwork',
	    shape => 'egg',
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
	},
    );
    foreach (@routernodes) {
	$_->{shape} ||= 'box';
	$_->{style} ||= 'solid';
    }

    my $index = 0;
    my @edges = (
	{
	    headlabel => '.IP',
	    style     => 'solid',
	    taillabel => 'cost',
	}, {
	    style     => 'bold',
	    taillabel => '.IP',
	}, {
	    color     => 'gray35',
	    headlabel => 'cost',
	    style     => 'solid',
	    taillabel => '.IP',
	}, {
	    color     => 'gray35',
	    headlabel => 'cost',
	    style     => 'dashed',
	    taillabel => '.IP',
	},
    );
    for(my $i=0; $i<@edges; $i++) {
	$networknodes[$i]{N} = 'edgenetwork'. $index;
	$routernodes [$i]{N} = 'edgerouter'.  $index;
	$edges       [$i]{S} = 'edgenetwork'. $index;
	$edges       [$i]{D} = 'edgerouter'.  $index;
	$index++;
    }
    # swap arrow for cost .IP explanation
    ($edges[0]{D}, $edges[0]{S}) = ($edges[0]{S}, $edges[0]{D});

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
	}, {}, {},
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
	}, {
	    label => 'stub\nnetwork',
	    style => 'solid',
	    shape => 'ellipse',
	}, {},
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
	    label => 'link to\nstub network',
	}, {
	    label => 'virtual\nlink',
	    style => 'dotted',
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
	    taillabel => '.IP',
	}, {
	    headlabel => 'cost',
	    style     => 'dashed',
	}, {
	    color     => 'gray75',
	    headlabel => 'cost',
	    style     => 'dashed',
	}, {
	    color     => 'gray35',
	    headlabel => 'cost',
	    style     => 'solid',
	    taillabel => '.IP',
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

# return additional invisible edges to get a better layout for the legend
sub legend_rank {
    my $class = shift;
    my $dot = "";
    $dot .= "\trouter0 -> network0 -> edgerouter0";
    $dot .= " [ style=invis ];\n";
    $dot .= "\tedgenetwork0 -> linkrouter0";
    $dot .= " [ style=invis ];\n";
    $dot .= "\tlinkdst0 -> summarynetwork0";
    $dot .= " [ style=invis ];\n";
    return $dot;
}

# return legend default settings
sub legend_default {
    my $class = shift;
    my $dot = "";
    $dot .= $class->graph_default();
    return $dot;
}

=pod

=item OSPF::LSDB::View-E<gt>L<legend>()

Return a string of a dot graphic containing drawing and description
of possible nodes and edges.

=back

=cut

# return legend as dot graph
sub legend {
    my $class = shift;
    my $dot = "digraph \"ospf legend\" {\n";
    $dot .= $class->legend_default();
    $dot .= $class->legend_rank();
    $dot .= $class->legend_router();
    $dot .= $class->legend_network();
    $dot .= $class->legend_edge();
    $dot .= $class->legend_link();
    $dot .= $class->legend_summary();
    $dot .= "}\n";
    return $dot;
}

=pod

=head1 ERRORS

The methods die if any error occures.

Inconsistencies within the OSPF link state database are visualized
with different colors.
The error message may be printed into the graph as warnings.
All warnings may be optained with the L<get_errors> method.

=head1 SEE ALSO

L<OSPF::LSDB>,
L<OSPF::LSDB::View6>

L<ospf2dot>,
L<ospfview>

RFC 2328 - OSPF Version 2 - April 1998

=head1 AUTHORS

Alexander Bluhm

=cut

1;
