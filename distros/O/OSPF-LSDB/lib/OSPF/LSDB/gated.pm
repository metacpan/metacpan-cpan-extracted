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

B<OSPF::LSDB::gated> - parse B<gated> OSPF link state database

=head1 SYNOPSIS

use OSPF::LSDB::gated;

my $gated = OSPF::LSDB::gated-E<gt>L<new>();

my $gated = OSPF::LSDB::gated-E<gt>L<new>(ssh => "user@host");

$gated-E<gt>L<parse>(%todo);

=head1 DESCRIPTION

The B<OSPF::LSDB::gated> module parses the OSPF part of a B<gated>
dump file and fills the B<OSPF::LSDB> base object.
An existing F<gated_dump> file can be given or it can be created
dynammically.
In the latter case B<sudo> is invoked if permissions are not
sufficient to run B<gdc dump>.
If the object has been created with the C<ssh> argument, the specified
user and host are used to login and run B<gdc dump> there.

There is only one public method:

=cut

package OSPF::LSDB::gated;
use base 'OSPF::LSDB';
use File::Slurp;
use Regexp::Common;
use fields qw(
    dump
);

# add a Regexp::Common regep that recognizes short IP addresses
my $IPunitdec = q{(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})};
my $IPdefsep  = '[.]';
Regexp::Common::pattern
  name    => [qw (net sIPv4)],
  create  => "(?k:$IPunitdec(?:$IPdefsep$IPunitdec){0,3})",
  ;

# add a Regexp::Common regep that recognizes time in 0:00:00 format
my $time60 = q{(?:[0-6]?[0-9])};
Regexp::Common::pattern
  name    => [qw (time)],
  create  => "(?k:(?:[0-9]+:)?$time60:$time60|(?:$time60:)?$time60)",
  ;

# shortcut
my $IP   = qr/$RE{net}{IPv4}{-keep}/;
my $SIP  = qr/$RE{net}{sIPv4}{-keep}/;
my $TIME = qr/$RE{time}{-keep}/;
my $DEC  = qr/([0-9]+)/;
my $NUM  = qr/$RE{num}{dec}{-keep}/;
my $HEX  = qr/$RE{num}{hex}{-keep}/;
my $OO   = qr/(On|Off)/;
my $TAG  = qr/(?:$DEC|Invalid tag: $HEX)/;

# convert short IP to long IP
sub _s2lIP($) {
    my $ip = $_[0].".0.0.0";
    $ip =~ /^$RE{net}{IPv4}{-keep}/;
    return $1;
}

# convert time to seconds
sub _time2sec($) {
    my @a = split(/:/, "0:0:".$_[0]);
    return 60*(60*$a[-3] + $a[-2]) + $a[-1];
}

# convert On/Off to boolean 0/1
sub _oo2bool($) { $_[0] eq "On" ? 1 : $_[0] eq "Off" ? 0 : undef }

sub get_dump {
    my OSPF::LSDB::gated $self = shift;
    my $file = $_[0] || "/var/tmp/gated_dump";
    if (-e $file) {
	my @cmd = ("mv", "-f", $file, "$file.old");
	unshift @cmd, "sudo" if $> != 0;
	system(@cmd);
    }
    my @cmd = qw(gdc dump);
    if ($self->{ssh}) {
	unshift @cmd, "ssh", $self->{ssh};
    } else {
	unshift @cmd, "sudo" if $> != 0;
    }
    system(@cmd)
      and die "Command '@cmd' failed: $?\n";
    sleep(1);  # XXX when is gated finished ?
    if ($self->{ssh}) {
	@cmd = ("ssh", $self->{ssh}, "cat", $file);
	@{$self->{dump}} = `@cmd`;
	die "Command '@cmd' failed: $?\n" if $?;
    } else {
	@{$self->{dump}} = read_file($file);
    }
}

sub parse_links {
    my OSPF::LSDB::gated $self = shift;
    my($router, @lines) = @_;
    my %typename = (
	"Router"      => "pointtopoint",
	"Transit net" => "transit",
	"Stub net"    => "stub",
	"Virtual"     => "virtual",
    );
    my $type;
    my $l;
    foreach (@lines) {
	if (/Type: ([\w ]+)\s+Cost: $DEC$/) {
	    defined($type = $typename{$1})
	      or die "Unknown link type: $1\n";
	    $l = { metric => $2 };
	    push @{$router->{$type.'s'}}, $l;
	} elsif (/RouterID: $SIP\s+Address: $SIP$/) {
	    if ($type eq "pointtopoint" || $type eq "virtual") {
		$l->{routerid}  = _s2lIP($1);
		$l->{interface} = _s2lIP($2);
	    } else {
		die "$_ Bad line for link type $type.\n";
	    }
	} elsif (/DR: $SIP\s+Address: $SIP$/) {
	    if ($type eq "transit") {
		$l->{address}   = _s2lIP($1);
		$l->{interface} = _s2lIP($2);
	    } else {
		die "$_ Bad line for link type $type.\n";
	    }
	} elsif (/Network: $SIP\s+NetMask: $SIP$/) {
	    if ($type eq "stub") {
		$l->{network} = _s2lIP($1);
		$l->{netmask} = _s2lIP($2);
	    } else {
		die "$_ Bad line for link type $type.\n";
	    }
	} else {
	    die "$_ Unknown link line.\n";
	}
    }
}

sub parse_router {
    my OSPF::LSDB::gated $self = shift;
    my @lines = @_;
    my %router;
    my($section, @link_lines);
    foreach (@lines) {
	if (/^\w/) {
	    undef $section;
	}
	if (/^AdvRtr: $SIP\s+Len: $DEC\s+Age: $TIME\s+Seq: $HEX$/) {
	    $router{routerid} = _s2lIP($1);
	    $router{age}      = _time2sec($3);
	    $router{sequence} = "0x$4";
	} elsif (/^RouterID: $SIP\s+Area Border: $OO\s+AS Border: $OO$/) {
	    $section = "link";
	    $router{router}  = _s2lIP($1);
	    $router{bits}{B} = _oo2bool($2);
	    $router{bits}{E} = _oo2bool($3);
	    $router{bits}{V} = 0;  # XXX need gated dump with virtual link
	} elsif (/^Nexthops\b/) {
	    $section = "nexthop";
	} elsif (s/^\t//) {
	    if ($section eq "link") {
		push @link_lines, $_;
	    } elsif ($section eq "nexthop") {
		# not part of LSDB, redundant in gated dump
	    } else {
		die "$_ No router section.\n";
	    }
	} else {
	    die "$_ Unknown router line.\n";
	}
    }
    $self->parse_links(\%router, @link_lines);
    return \%router;
}

sub parse_network {
    my OSPF::LSDB::gated $self = shift;
    my @lines = @_;
    my %network;
    my($section);
    foreach (@lines) {
	if (/^\w/) {
	    undef $section;
	}
	if (/^AdvRtr: $SIP\s+Len: $DEC\s+Age: $TIME\s+Seq: $HEX$/) {
	    $network{routerid} = _s2lIP($1);
	    $network{age}      = _time2sec($3);
	    $network{sequence} = "0x$4";
	} elsif (/^Router: $SIP\s+Netmask: $SIP\s+Network: $SIP$/) {
	    $network{address} = _s2lIP($1);
	    $network{netmask} = _s2lIP($2);
	} elsif (/^Attached Router: $SIP$/) {
	    push @{$network{attachments}}, { routerid => _s2lIP($1) };
	} elsif (/^Nexthops\b/) {
	    $section = "nexthop";
	} elsif (s/^\t//) {
	    if ($section eq "nexthop") {
		# not part of LSDB, redundant in gated dump
	    } else {
		die "$_ No network section.\n";
	    }
	} else {
	    die "$_ Unknown network line.\n";
	}
    }
    return \%network;
}

sub parse_summary {
    my OSPF::LSDB::gated $self = shift;
    my @lines = @_;
    my %summary;
    my($section);
    foreach (@lines) {
	if (/^\w/) {
	    undef $section;
	}
	if (/^AdvRtr: $SIP\s+Len: $DEC\s+Age: $TIME\s+Seq: $HEX$/) {
	    $summary{routerid} = _s2lIP($1);
	    $summary{age}      = _time2sec($3);
	    $summary{sequence} = "0x$4";
	} elsif
	  (/^LSID: $SIP\s+Network: $SIP\s+Netmask: $SIP\s+Cost: $DEC$/){
	    $summary{address} = _s2lIP($1);
	    $summary{netmask} = _s2lIP($3);
	    $summary{metric}  = $4;
	} elsif (/^Nexthops\b/) {
	    $section = "nexthop";
	} elsif (s/^\t//) {
	    if ($section eq "nexthop") {
		# not part of LSDB, redundant in gated dump
	    } else {
		die "$_ No summary section.\n";
	    }
	} else {
	    die "$_ Unknown summary line.\n";
	}
    }
    return \%summary;
}

sub parse_boundary {
    my OSPF::LSDB::gated $self = shift;
    my @lines = @_;
    my %boundary;
    my($section);
    foreach (@lines) {
	if (/^\w/) {
	    undef $section;
	}
	if (/^AdvRtr: $SIP\s+Len: $DEC\s+Age: $TIME\s+Seq: $HEX$/) {
	    $boundary{routerid} = _s2lIP($1);
	    $boundary{age}      = _time2sec($3);
	    $boundary{sequence} = "0x$4";
	} elsif (/^RouterID: $SIP\s+Cost: $DEC$/){
	    $boundary{asbrouter} = _s2lIP($1);
	    $boundary{metric}  = $2;
	} elsif (/^Nexthops\b/) {
	    $section = "nexthop";
	} elsif (s/^\t//) {
	    if ($section eq "nexthop") {
		# not part of LSDB, redundant in gated dump
	    } else {
		die "$_ No boundary section.\n";
	    }
	} else {
	    die "$_ Unknown boundary line.\n";
	}
    }
    return \%boundary;
}

sub parse_area {
    my OSPF::LSDB::gated $self = shift;
    my($area, @lines) = @_;
    my %typename = (
	Stub   => [ "stubs" ],  # not an RFC LSA type, redundant in gated dump
	Router => [ routers   => \&parse_router   ],
	SumNet => [ summarys  => \&parse_summary  ],
	SumASB => [ boundarys => \&parse_boundary ],
	Net    => [ networks  => \&parse_network  ],
    );
    my($lsdb, $type, @type_lines);
    foreach (@lines) {
	if (/^Link State Database:/) {
	    die "$_ Duplicate LSDB.\n" if $lsdb;
	    $lsdb = 1;
	} elsif ($lsdb) {
	    if (/^Retransmission List:$/) {
		$type
		  or die "Retransmission without LSA type\n";
		warn "Retransmission list for $type->[0]\n";
	    }
	    if (! /^\t/ && @type_lines) {
		if ($type && $type->[1]) {
		    my($name, $lsaparser) = @$type;
		    my $lsa = $lsaparser->($self, @type_lines);
		    $lsa->{area} = $area;
		    push @{$self->{ospf}{database}{$name}}, $lsa;
		}
		undef @type_lines;
		undef $type;
	    }
	    if (s/^(\w+)\t//) {
		$type = $typename{$1}
		  or die "Unknown LSA type: $1\n";
		push @type_lines, $_;
	    } elsif(s/\t//) {
		$type
		  or die "No LSA type\n";
		push @type_lines, $_;
	    } elsif (/^Retransmission List:$/) {
		$type = [ "retransmission" ];
	    } elsif(/^$/) {
		undef $type;
	    } else {
		die "$_ Unknown LSA line.\n";
	    }
	}
    }
    if (@type_lines) {
	die "Unprocessed LSA lines:\n", @type_lines;
    }
}

sub parse_externals {
    my OSPF::LSDB::gated $self = shift;
    my @lines = @_;
    my @externals;
    my($section);
    foreach (@lines) {
	if (/^\w/) {
	    undef $section;
	}
	if (/^AdvRtr: $SIP\s+Len: $DEC\s+Age: $TIME\s+Seq: $HEX$/) {
	    push @externals, {
		routerid => _s2lIP($1),
		age      => _time2sec($3),
		sequence => "0x$4",
	    };
	} elsif
	  (/^LSID: $SIP\s+Network: $SIP\s+Netmask: $SIP\s+Cost: $DEC$/){
	    $externals[-1]{address} = _s2lIP($1);
	    $externals[-1]{netmask} = _s2lIP($3);
	    $externals[-1]{metric}  = $4;
	} elsif (/^Type: ([1-2])\s+Forward: $SIP\s+Tag: $TAG\b/) {
	    $externals[-1]{type}    = $1;
	    $externals[-1]{forward} = _s2lIP($2);
	} elsif (/^Nexthops\b/) {
	    $section = "nexthop";
	} elsif (/^Retransmission List:$/) {
	    $section = "retransmission";
	    warn "Retransmission list for external\n";
	} elsif (s/^\t//) {
	    if ($section eq "nexthop") {
		# not part of LSDB, redundant in gated dump
	    } elsif ($section eq "retransmission") {
		# not part of LSDB, internal gated information
	    } else {
		die "$_ No external section.\n";
	    }
	} elsif (/^$/) {
	    undef $section;
	} else {
	    die "$_ Unknown external line.\n";
	}
    }
    $self->{ospf}{database}{externals} = \@externals;
}

sub parse_lsdb {
    my OSPF::LSDB::gated $self = shift;
    my($area_lines, $external_lines) = @_;
    foreach my $area (@{$self->{ospf}{self}{areas}}) {
	$self->parse_area($area, @{$area_lines->{$area}});
    }
    $self->parse_externals(@$external_lines);
}

sub parse_ospf {
    my OSPF::LSDB::gated $self = shift;
    my @lines = @_;
    my(%section, %area_lines, @external_lines);
    my($routerid, @areas);
    foreach (@lines) {
	if (/^\w/) {
	    undef %section;
	    if (/^RouterID: $SIP\s+/) {
		$routerid = _s2lIP($1);
	    } elsif (/^Area $SIP:/) {
		my $area = _s2lIP($1);
		push @areas, $area;
		$section{area} = $area;
	    } elsif (/^AS Externals\s+/) {
		$section{external} = 1;
	    }
	} else {
	    s/^\t//;
	    if ($section{area}) {
		push @{$area_lines{$section{area}}}, $_;
	    } elsif ($section{external}) {
		push @external_lines, $_;
	    }
	}
    }
    $self->{ospf}{self}{routerid} = $routerid
      or die "No router id.\n";
    $self->{ospf}{self}{areas} = \@areas;
    $self->parse_lsdb(\%area_lines, \@external_lines);
}

=pod

=over 4

=item $self-E<gt>L<parse>(%todo)

This function takes a hash describing how the OSPF LSDB can be
obtained.
The bool value of C<dump> specifies wether the dump file should be
created dynamically by calling B<gdc dump>.
The C<file> parameter contains the path to the F<gated_dump> file,
it defaults to F</var/tmp/gated_dump>.
The dump file may contain more than one instance of the gated memory
dump separated by form feeds.
If the numeric B<skip> paremeter is set, that many dumps from the
beginning of the file are skipped and the next one is used.

The complete OSPF link state database is stored in the B<ospf> field
of the base class.

=back

=cut

sub parse {
    my OSPF::LSDB::gated $self = shift;
    my %todo = @_;
    if ($todo{dump}) {
	$self->get_dump($todo{file});
    } else {
	@{$self->{dump}} = read_file($todo{file});
    }
    my $skip = $todo{skip} + 1 if $todo{skip};
    my($task, @ospf_lines);
    my $n = 0;
    foreach (@{$self->{dump}}) {
	$n++;
	if ($skip) {
	    if (/^\f$/) {
		$skip--;
	    }
	    next;
	}
	if (/^\w/) {
	    undef $task;
	}
	if (/^Task (\w+):/) {
	    $task = lc($1);
	} elsif (/^Done$/) {
	    last;
	} elsif (defined $task) {
	    s/^\t//;
	    if ($task eq "ospf") {
		push @ospf_lines, $_;
	    }
	}
    }
    if ($n < @{$self->{dump}}) {
	warn "More data in gated dump.\n";
    }
    $self->parse_ospf(@ospf_lines);
    $self->{ospf}{ipv6} = 0;
}

=pod

This module has been tested with gated 3.6.
If it works with other versions is unknown.

=head1 ERRORS

The methods die if any error occurs.

=head1 SEE ALSO

L<OSPF::LSDB>

L<gated2yaml>

=head1 AUTHORS

Alexander Bluhm

=cut

1;
