package PIX::Object::network;

use strict;
use warnings;
use base qw( PIX::Object );
use Carp;

our $VERSION = '1.10';


=pod

=head1 NAME

PIX::Object::network - Class for "network" object-groups found in a PIX config.

=head1 SYNOPSIS

This is a subclass of PIX::Object that maintains a single object-group as read
from a firewall config. You can list and search for elements in the list.

=head1 SEE ALSO

B<PIX::Object>

=head1 METHODS

=over

=cut

sub _init {
	my $self = shift;
	$self->SUPER::_init;

	$self->{debug} = 0;

	$self->{networks} = [];				# networks directly defined in this object group
	$self->{groups} = [];				# other groups that this object points to for networks
	$self->{desc} = '';

	$self->_nextline;				# remove the first line 'object-group blah'
	while (defined(my $line = $self->_nextline)) {
		my ($ip, $mask);
		if ($line =~ /\s*network-object (\S+) (\S+)/) {
			($ip, $mask) = ($1, $2);
			if ($ip eq 'host') {
				$ip = $mask;
				$mask = '255.255.255.255';
			}
			$ip = $self->alias($ip);
			$self->add($ip, $mask);
		} elsif ($line =~ /^\s*group-object (\S+)/) {
			$self->add($1);
		} elsif ($line =~ /^\s*description (.+)/) {
			$self->{desc} = $1;
		} else {
			carp "$self->{name}: Unknown network object line: $line\n"; 
		}
	}
}

=item B<add($ip_or_grp, [$mask])>

=over

Add a network or nested group to the object-group. If $mask is undef then
$ip_or_grp is assumed to be a nested hostgroup name.

=back

=cut
sub add {
	my ($self, $ip_or_grp, $mask) = @_;
	my ($first, $last, $bits);
	if (defined $mask) {
		$bits = ipnumbits($mask);
		$first = ip2int($ip_or_grp);
		$last = ip2int(ipbroadcast($first, $bits));
		push(@{$self->{networks}}, [ $first, $last, $bits ]);
	} else {
		push(@{$self->{groups}}, $ip_or_grp);
	}
}

=item B<list([$raw])>

=over

Returns a list of networks from the object group. Normally a plain list of
CIDR blocks are returned, however, if $raw is true then a list of array
references are returned instead. Each arrayref has: [ first_ip, last_ip, bits ].
The IP's are 32bit integers.

=back

=cut
sub list {
	my $self = shift;
	my $raw = shift || 0;	# if true, the raw list is returned instead of CIDR blocks
	my @list = ();

	for (my $i=0; $i<@{$self->{networks}}; $i++) {
		if ($raw) {
			# add each network as a raw list [ first, last, bits ]
			push(@list, $self->{networks}[$i]);
		} else {
			# add each network as a CIDR block or host
			push(@list, int2ip($self->{networks}[$i][0]) .
				($self->{networks}[$i][2] ne '32'
					? '/' . $self->{networks}[$i][2]
					: ''
				)
			);
		}
	}

	foreach my $name ($self->groups) {
		my $grp = $self->{walker}->obj($name) || next;
		push(@list, $grp->list($raw));
	}

	return @list;
}

=item B<matchip( )>

=over

Searches the networks within our group for the IP given. Deligates out to nested
groups and maintains the state of the trace.

Returns the name of the of the object-group that matches the IP (which evaluates
to true). This is usually called from the PIX::Accesslist::Line object instead
of directly.

=back

=cut
sub matchip {
	my ($self, $ip, $trace) = @_;
	my $ipint = ip2int($ip);
	my $found = undef;
	my $idx = 0;

	# first search our defined networks.
	#print "searching networks in $self->{name} ...\n";
	foreach my $net (@{$self->{networks}}) {
		$idx++;
		if ($ipint >= $net->[0] and $ipint <= $net->[1]) {
			push(@$trace, $self->{name}, $idx, int2ip($net->[0]) . "/" . $net->[2]) if defined $trace;
			return $self->{name};
		}
	}

	# search all nested groups, if any.
	$idx = 0;
	#print "searching groups in $self->{name} (" . (join(',', @{$self->{groups}})) . ")...\n" if @{$self->{groups}};
	foreach my $name (@{$self->{groups}}) {
		$idx++;
		my $grp = $self->{walker}->obj($name) || next;
		my $localtrace = [ $self->{name}, 0, 0 ];
		next unless $grp->type eq 'network';
		my $found = $grp->matchip($ip, $localtrace);
		if ($found) {
			push(@$trace, @$localtrace) if defined $trace;
			return $grp->{name};
		}
	}
	
	return undef;
}

#=item B<networks( )>
#
#=over
#
#Returns the internal list of networks. In scalar context an arrayref is
#returned.
#
#B<Note:> use the "list()" method instead of this one.
#
#=back
#
#=cut
sub networks { return wantarray ? @{$_[0]->{networks}} : $_[0]->{networks} }

#=item B<groups( )>
#
#=over
#
#Returns a raw list of nested object-groups. In scalar context an arrayref is
#returned.
#
#=back
#
#=cut
sub groups { return wantarray ? @{$_[0]->{groups}} : $_[0]->{groups} }

#=item B<remove($ip, [$mask])>
#
#=over
#
#Remove a network from the object-group.
#
#=back
#
#=cut
sub remove {
	die("remove() not implemented");
	#my ($self, $ip, $mask) = @_;
	#my ($first, $last, $bits);
	#$bits = ipnumbits($mask);
	#$first = ip2int($ip);
	#$last = ip2int(ipbroadcast($first, $bits));
	#push(@{$self->{networks}}, [ $first, $last, $bits ]);
}


# 32bit IP math routines below are helper functions to convert IP addresses
# these are not class methods

sub ip2int {
	my ($ip) = split(/[:\/]/, shift);		# strip off any port or CIDR bits
	my ($i1,$i2,$i3,$i4) = split(/\./, $ip);
	return ($i4) | ($i3 << 8) | ($i2 << 16) | ($i1 << 24);
}

sub int2ip {
	my $num = shift;
	return join(".", 
		($num & 0xFF000000) >> 24,
		($num & 0x00FF0000) >> 16,
		($num & 0x0000FF00) >> 8,
		($num & 0x000000FF)
	);
}

sub ipnetmask {
	my $bits = shift;
	return '0.0.0.0' unless $bits;
	my $num = 0xFFFFFFFF;
	my $mask = ($num >> (32 - $bits)) << (32 - $bits);
	return int2ip($mask);
}

sub ipwildmask {
	my $bits = shift;
	my $num = ip2int( ipnetmask($bits) );
	$num = $num ^ 0xFFFFFFFF;
	return int2ip($num);
}

sub ipbroadcast {
	my ($num, $bits) = @_;
	my @ip = split(/\./, int2ip($num));
	my @wc = split(/\./, ipwildmask($bits));
	my $bc = "";
	for (my $i=0; $i < 4; $i++) { $ip[$i] += $wc[$i]; }
	return join(".",@ip);
}

sub ipnumbits {
	my ($mask) = @_;
	my $bits = unpack('B32', pack('N', ip2int($mask)));
	return scalar grep { $_ eq '1' } split(//, $bits);
}


1;

=pod

=head1 AUTHOR

Jason Morriss <lifo 101 at - gmail dot com>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-pix-walker at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PIX-Walker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

    perldoc PIX::Walker

    perldoc PIX::Accesslist
    perldoc PIX::Accesslist::Line

    perldoc PIX::Object
    perldoc PIX::Object::network
    perldoc PIX::Object::service
    perldoc PIX::Object::protocol
    perldoc PIX::Object::icmp_type

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Jason Morriss, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
