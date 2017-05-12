#!/usr/bin/perl
# Parse::DNS::Zone - DNS Zone File Parser
#
# Copyright (c) 2009-2011, 2013, 2015 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=pod

=head1 NAME

Parse::DNS::Zone - DNS Zone File Parser

=head1 SYNOPSIS

 use Parse::DNS::Zone;

 my $pdz = Parse::DNS::Zone->new(
 	zonefile=>'db.example',
 	origin=>'example.org.',
 );

 my $a_rr = $pdz->get_rdata(name=>'foo', rr=>'A');
 my $mx_rr = $pdz->get_rdata(name=>'@', rr=>'MX'); # Get the origin's MX

 # Getting SOA values
 my $mname = $pdz->get_mname();
 my $rname = $pdz->get_rname();
 my $serial = $pdz->get_serial();
 # ... etc ...

=head1 DESCRIPTION

B<Parse::DNS::Zone> parses a zonefile, used to define a DNS Zone
and gives you the information therein, via an object oriented
interface. Parse::DNS::Zone doesn't validate rrdata, except for
SOA, and is used to 1) validate the basic structure of the file
and 2) extract rdata so you can parse it and validate it yourself.

Parse::DNS::Zone supports the zone file format as described in
RFC 1034:

=over 4

=item * $INCLUDE

=item * $ORIGIN

=item * $TTL (as described in RFC 2308)

=back

Parse::DNS::Zone does not support $GENERATE in this version.

=cut

use 5.010;
package Parse::DNS::Zone;
our $VERSION = '0.60';
use warnings;
use strict;
use File::Basename;
use File::Spec;
use Carp;

=head1 CONSTRUCTOR

=head2 Parse::DNS::Zone->new( ARGS )

=over 4

=item B<Required Arguments>

=over 4

=item * B<origin>

Origin

=back

And additionally, exactly one of the following:

=over 4

=item * B<zonefile>

Path to the zonefile being parsed

=item * B<zonestr>

The zone, as a string.

=back

=item B<Optional Arguments>

=over 4

=item * B<require_soa>

If set to a true value, the parser will whine and die if
the zonefile doesn't contain a SOA record. (Default: yes)

=item * B<basepath>

Specify a basepath, from which included relative zonefiles
should be available. If used with the B<zonefile> parameter,
this defaults to the directory in which the zonefile is in.
For $INCLUDEs to work when passing the zone in as a string,
this needs to be specified.

=item * B<append_origin>

If set to a true value, the parser will append the origin
to all unqualified domain names (in certain record types,
currently: CNAME, MX, NS, AFSDB, PTR). If some record
types are missing from this list, please report that as a
bug. (Default: no)

This feature do run the risk of becoming stale if new
record types are introduced. But if you run into problems,
don't hesitate to report it!

=back

=back

=cut

sub new {
	my $class = shift;
	my $self = {
		require_soa => 1,
		append_origin => 0,
		@_
	};

	if (not defined $self->{zonestr} and defined $self->{zonefile}) {
		$self->{zonestr} = _load_zonefile($self->{zonefile});
	}
	if (not defined $self->{zonestr}) {
		croak("You need to specify either zonestr or zonefile");
	}

	# default basepath is dirname($zonefile)
	if (not exists $self->{basepath}) {
		$self->{basepath} = dirname($self->{zonefile}) if
			defined $self->{zonefile};
	}

	# append trailing .
	$self->{origin} .= '.' if($self->{origin}=~/[^[^\.]$/);
	bless($self, $class);

	_parse($self);

	if($self->{require_soa} &&
	   (!exists $self->{zone}{$self->{origin}}{soa})) {
		croak("No SOA in zonefile");
	}

	_parse_soa($self);

	return $self;
}

=head1 METHODS

=head2 General

=head3 $pdz->get_rdata(name=>$name, rr=>$rr, n=>$n, field=>$field)

Is used to get the data associated with a specific name and rr
type. The $name can be as the name appears in the zonefile, or a
fqdn (with trailing .) as long as it is tracked by the zonefile.
If the n argument is specified, the n:th RR in the RRset is
returned. Otherwise, you'll get a complete list of the RRset if
you're in list context, or the first RR if you're in scalar
context.

The $field is the particular component of the resource record to
return.  It defaults to 'val', which is the actual value of the
record. Other possibilities are 'class' (e.g. "IN") and 'ttl'.

=cut

sub get_rdata {
	my $self = shift;
	my $h = {
		field=>'rdata',
		@_,
	};

	my ($name, $rr, $field, $n) = @{$h}{qw(name rr field n)};

	$name=~s/^\@$/$self->{origin}/g;
	$name=~s/\.\@\./\.$self->{origin}/g;
	$name=~s/\.\@$/\.$self->{origin}/g;
	$name=~s/\@\.$/\.$self->{origin}/g;
	$name .= ".$self->{origin}" if(($name ne $self->{origin}) &&
	                               (!($name=~/\.$/)));

	return $self->{zone}{lc $name}{lc $rr}{lc $field}[$n] if defined $n;
	return @{$self->{zone}{lc $name}{lc $rr}{lc $field}} if wantarray;
	return $self->{zone}{lc $name}{lc $rr}{lc $field}[0];
}

=head3 $pdz->exists($name)

Returns a true value if the name exists, and false otherwise.

=cut

sub exists {
	my $self = shift;
	my $name = shift;

	$name=~s/^\@$/$self->{origin}/g;
	$name=~s/\.\@\./\.$self->{origin}/g;
	$name=~s/\.\@$/\.$self->{origin}/g;
	$name=~s/\@\.$/\.$self->{origin}/g;
	$name .= ".$self->{origin}" if(($name ne $self->{origin}) &&
	                               (!($name=~/\.$/)));

	return exists $self->{zone}{lc $name};
}

=head3 $pdz->get_rrs($name)

Returns a list with all RR types for a specific name

=cut

sub get_rrs {
	my $self = shift;
	my $name = shift;
	my @rrs;

	$name=~s/^\@$/$self->{origin}/g;
	$name=~s/\.\@\./\.$self->{origin}/g;
	$name=~s/\.\@$/\.$self->{origin}/g;
	$name=~s/\@\.$/\.$self->{origin}/g;
	$name .= ".$self->{origin}" if(($name ne $self->{origin}) &&
	                               (!($name=~/\.$/)));

	foreach my $k (keys %{$self->{zone}{lc $name}}) {
		push @rrs, $k;
	}

	return @rrs;
}

=head3 $pdz->get_dupes(name=>$name, rr=>$rr)

Returns how many RRs of a given type is defined for $name. For a simple
setup with a single RR for $name, this will return 1. If you have some
kind of load balancing or other scheme using multiple RRs of the same
type this sub will return the number of "dupes".

=cut

sub get_dupes {
	my $self = shift;
	my $h = {
		@_,
	};

	my $name = $h->{name};
	my $rr = $h->{rr};

	$name=~s/^\@$/$self->{origin}/g;
	$name=~s/\.\@\./\.$self->{origin}/g;
	$name=~s/\.\@$/\.$self->{origin}/g;
	$name=~s/\@\.$/\.$self->{origin}/g;
	$name .= ".$self->{origin}" if(($name ne $self->{origin}) &&
	                               (!($name=~/\.$/)));

	return int(@{$self->{zone}{lc $name}{lc $rr}{rdata}});
}

=head3 $pdz->get_names( )

Returns a list with all names specified in the zone

=cut

sub get_names {
	my $self = shift;
	my @names;

	foreach my $n (keys %{$self->{zone}}) {
		push @names, $n;
	}

	return @names;
}

=head2 SOA

=head3 $pdz->get_mname( )

Returns the MNAME part of the SOA.

=cut

sub get_mname {
	my $self = shift;
	return $self->{soa}{mname};
}

=head3 $pdz->get_rname( parse=>{0,1} )

Return the RNAME part of the SOA. If parse is set to a value
other than 0, the value will be interpreted to show an
emailaddress. (default: 0)

=cut

sub get_rname {
	my $self = shift;
	my %p = (
		parse=>0,
		@_
	);

	my $ret = $self->{soa}{rname};
	if($p{parse}) {
		my ($user,$host)=$self->{soa}{rname}=~/^([^\.]+)\.(.*)$/;
		$ret = "$user\@$host";
	}

	return $ret;
}

=head3 $pdz->get_serial( )

Return the SERIAL value of a SOA.

=cut

sub get_serial {
	my $self = shift;
	return $self->{soa}{serial};
}

=head3 $pdz->get_refresh( )

Return the REFRESH value of a SOA

=cut

sub get_refresh {
	my $self = shift;
	return $self->{soa}{refresh};
}

=head3 $pdz->get_retry( )

Return the RETRY value of a SOA

=cut

sub get_retry {
	my $self = shift;
	return $self->{soa}{retry};
}

=head3 $pdz->get_expire( )

Return the EXPIRE value of a SOA

=cut

sub get_expire {
	my $self = shift;
	return $self->{soa}{expire};
}

=head3 $pdz->get_minimum( )

Return the MINIMUM value of a SOA

=cut

sub get_minimum {
	my $self = shift;
	return $self->{soa}{minimum};
}

# Is used to populate the zone hash used internally.
sub _parse {
	my $self = shift;

	my %zone = $self->_parse_zone(
		zonestr => $self->{zonestr},
		origin => $self->{origin},
	);

	undef $self->{zone};
	$self->{zone}={%zone};
}

sub _load_zonefile {
	my $file = shift;
	open(my $zonefh, $file) or croak("Could not open $file: $!");
	return do { local $/; <$zonefh> }; # slurp
}

# Is used internally to parse a zone from a filename. will do some
# recursion for the $include, so a procedural implementation is needed
sub _parse_zone {
	my $self = shift;
	# $def_class and $def_ttl are only given when called for included zones
	my %opts = @_;

	my $origin = $opts{origin} // $self->{origin};

	my $zonestr = $opts{zonestr};
	if (not defined $zonestr and exists $opts{zonefile}) {
		$zonestr = _load_zonefile($opts{zonefile});
	}

	my ($def_class, $def_ttl);
	if ($opts{included}) {
		($def_class, $def_ttl) = @{\%opts}{qw(default_class default_ttl)};

	}
	my $zonepath = $self->{basepath};

	my $mrow;
	my $prev;
	my %zone;

	my $zentry = qr/^
		(\S+)\s+ # name
		(
			(?: (?: IN | CH | HS ) \s+ \d+ \s+ ) |
			(?: \d+ \s+ (?: IN | CH | HS ) \s+ ) |
			(?: (?: IN | CH | HS ) \s+ ) |
			(?: \d+ \s+ ) |
		)? # <ttl> <class> or <class> <ttl>
		(\S+)\s+ # type
		(.*) # rdata
	$/ix;

	for (split /\n/, $zonestr) {
		chomp;

		# Strip away any quoted strings; they should not be parsed in
		# the same way as the rest of the zonefile. Replace the strings
		# with placeholders. The real strings are kept in @strs, and
		# we'll replace them with the real strings again soon.
		($_, my @strs) = _strip_quotes($_);

		# Strip comments.
		s/(?<!\\);.*$//;
		next if /^\s*$/;

		# Normalize in-line whitespace
		s/\s+/ /g;

		s/^\@ /$origin /g;
		s/ \@ / $origin /g;
		s/ \@$/ $origin/g;

		# Re-add the real strings again.
		$_ = _unstrip_quotes($_, @strs);

		# handles mutlirow entries, with ()
		if($mrow) {
			$mrow.=$_;

			next if(! /\)/);

			# End of multirow
			$mrow=~s/[\(\)]//g;
			$mrow=~s/\n//mg;
			$mrow=~s/\s+/ /g;
			$mrow .= "\n";

			$_ = $mrow;
			undef $mrow;
		} elsif(/^.*\([^\)]*$/) {
			# Start of multirow
			$mrow.=$_;
			next;
		}

		if(/^ /) {
			s/^/$prev/;
		}

		$origin = $1, next if(/^\$ORIGIN ([\w\-\.]+)\s*$/i);
		$def_ttl = $1, next if(/^\$TTL (\d+)\s*$/i);
		if(/^\$INCLUDE (\S+)(?: (\S+))?\s*(?:;.*)?$/i) {
			my $subo=defined $2?$2:$origin;

			my $zfile = $1;
			if($1 !~ m/^\//) {
				$zfile = File::Spec->catfile($zonepath, $zfile);
			}

			my %subz = $self->_parse_zone(
				zonefile => $zfile,
				included => 1,
				origin => $subo,
				default_class => $def_class,
				default_ttl => $def_ttl,
			);

			foreach my $k (keys %subz) {
				$zone{$k}=$subz{$k};
			}
			next;
		}

		my($name,$ttlclass,$type,$rdata) = /$zentry/;

		$rdata =~ s/\s+$//g;

		my($ttl, $class);
		if(defined $ttlclass) {
			($ttl) = $ttlclass=~/(\d+)/o;
			($class) = $ttlclass=~/(CH|IN|HS)/io;

			$ttlclass=~s/\d+//;
			$ttlclass=~s/(?:CH|IN|HS)//;
			$ttlclass=~s/\s//g;
			if($ttlclass) {
				carp "bad rr: $_ (ttlclass: $ttlclass)";
				next;
			}
		}

		$ttl = defined $ttl ? $ttl : $def_ttl;
		$class = defined $class ? $class : $def_class;
		$def_class = $class;

		next if (!$name || !$type || !$rdata);

		if(not defined $def_class) {
			carp("no class is set");
			next;
		}

		if(not defined $ttl) {
			carp("no ttl is set");
			next;
		}

		$prev=$name;
		$name = _fqdnize($name, $origin);

		if($self->{append_origin} and
		   $type =~ /^(?:cname|afsdb|mx|ns)$/i and
		   $rdata ne $origin and $rdata !~ /\.$/) {
			$rdata.=".$origin";
		}

		push(@{$zone{lc $name}{lc $type}{rdata}}, $rdata);
		push(@{$zone{lc $name}{lc $type}{ttl}}, $ttl);
		push(@{$zone{lc $name}{lc $type}{class}}, $class);
	}

	return %zone;
}

sub _strip_quotes {
	local $_ = shift;
	my $qstr = qr/(".*?(?<!\\)")/;
	my @strs = /$qstr/g;

	for my $str (keys @strs) {
		s/\Q$strs[$str]\E/"\$str[$str]"/;
	}

	return $_, @strs;
}

sub _unstrip_quotes {
	return shift =~ s/"\$str\[([0-9]+)\]"/$_[$1]/gr;
}

sub _fqdnize {
	my ($name, $origin) = @_;

	$origin //= '.';
	$origin .= '.' unless $origin =~ /\.$/;

	return $name if $name =~ /\.$/;
	return "$name." if $origin eq '.';
	return "$name.$origin";
}

# Is used to parse the SOA and build the soa hash as used
# internally..
sub _parse_soa {
	my $self = shift;
	my $soa_rd = get_rdata($self, (name=>"$self->{origin}", rr=>'SOA'));
	my($mname,$rname,$serial,$refresh,$retry,$expire,$minimum)=
		$soa_rd=~/^(\S+) (\S+) (\d+) (\d+) (\d+) (\d+) (\d+)\s*$/;

	$self->{soa}{mname}=$mname;
	$self->{soa}{rname}=$rname;
	$self->{soa}{serial}=$serial;
	$self->{soa}{refresh}=$refresh;
	$self->{soa}{retry}=$retry;
	$self->{soa}{expire}=$expire;
	$self->{soa}{minimum}=$minimum;
}

1;

=head1 SEE ALSO

RFC 1034, RFC 1035, Bind Administrator's Guide

=head1 AVAILABILITY

Latest stable version is available on CPAN. Current development
version is available on https://github.com/olof/Parse-DNS-Zone, and
this is the I<preferred> place to report issues.

=head1 COPYRIGHT

 Copyright (c) 2009-2011, 2013, 2015 - Olof Johansson <olof@cpan.org>

All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
