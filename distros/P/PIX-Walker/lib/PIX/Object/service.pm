package PIX::Object::service;

use strict;
use warnings;
use base qw( PIX::Object );
use Carp;

our $VERSION = '1.10';


=pod

=head1 NAME

PIX::Object::service - Class for "service" object-groups found in a PIX config.

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

	$self->{debug} = 1;

	$self->{services} = [];				# services directly defined in this object group
	$self->{groups} = [];				# other groups that this object points to for services
	$self->{desc} = '';

	$self->_nextline;				# remove the first line 'object-group blah'
	while (defined(my $line = $self->_nextline)) {
		my ($type, $p1, $p2);
#		print "$self->{name}: $line\n";
		if ($line =~ /\s*port-object (eq|gt|lt|range) (\S+)\s*(\S*)/) {
			($type, $p1, $p2) = ($1, $2, $3);	# 'range' is handled automatically if it's present
			if ($type eq 'eq') {
				$p2 = $p1;
			} elsif ($type eq 'lt') {
				$p2 = $p1;
				$p1 = 0;
			} elsif ($type eq 'gt') {
				$p2 = 65535;
			}
			$p1 = $self->{walker}->portnum($p1);
			$p2 = $self->{walker}->portnum($p2);
			$self->add($p1, $p2);
		} elsif ($line =~ /^\s*group-object (\S+)/) {
			$self->add($1);
		} elsif ($line =~ /^\s*description (.+)/) {
			$self->{desc} = $1;
		} else {
			carp "$self->{name}: Unknown service object line: $line\n"; 
		}
	}
}

=item B<add($low_port_or_group, [$high_port])>

=over

Add a service port or nested group to the object-group. If $high_port is undef
then $low_port_or_group is assumed to be a nested hostgroup name. 

=back

=cut
sub add {
	my ($self, $p1, $p2) = @_;
	if (defined $p2) {
		push(@{$self->{services}}, [ $p1, $p2 ]);
	} else {
		push(@{$self->{groups}}, $p1);
	}
}

=item B<list( )>

=over

Returns a list of service ports from the object group. Each element in the
list is an arrayref. Each arrayref has: [ high_port, low_port ].

=back

=cut
sub list {
	my $self = shift;
	my @list = @{$self->{services}};
	foreach my $name ($self->groups) {
		my $grp = $self->{walker}->obj($name) || next;
		push(@list, $grp->list);
	}
	return @list;
}

=item B<matchport( )>

=over

Searches the services within our group for the PORT given. Deligates out to
nested groups and maintains the state of the trace.

Returns the name of the of the object-group that matches the PORT (which
evaluates to true). This is usually called from the PIX::Accesslist::Line
object instead of directly.

=back

=cut
sub matchport {
	my ($self, $portstr, $trace) = @_;
	my $port = $self->{walker}->portnum($portstr);
	my $idx = 0;

	# first search our defined services.
	#print "searching services in $self->{name} ...\n" if $self->{debug};
	foreach my $p (@{$self->{services}}) {
		$idx++;
		if ($port >= $p->[0] and $port <= $p->[1]) {
			push(@$trace, $self->{name}, $idx, 0) if defined $trace;
			return $self->{name};
		}
	}

	# search all nested groups, if any.
	#print "searching groups in $self->{name} (" . (join(',', @{$self->{groups}})) . ")...\n" if $self->{debug} and scalar @{$self->{groups}};
	foreach my $name (@{$self->{groups}}) {
		my $grp = $self->{walker}->obj($name) || next;
		my $localtrace = [ $self->{name}, 0, 0 ];
		next unless $grp->type eq 'service';
		my $found = $grp->matchport($port, $localtrace);
		if ($found) {
			push(@$trace, @$localtrace) if defined $trace;
			return $grp->{name};
		}
	}

	return 0;
}

sub services { return wantarray ? @{$_[0]->{services}} : $_[0]->{services} }
sub groups { return wantarray ? @{$_[0]->{groups}} : $_[0]->{groups} }

=item B<enumerate([$compact=0])>

=over

Returns a list of ports that the object-group encompasses. If $compact is true
then ranges are condensed into a smaller list, ie: 1-1024,80,81,80,443

=back

=cut
sub enumerate {
	my $self = shift;
	my $compact = shift;
	my @list = ();
	for (my $i=0; $i < @{$self->{services}}; $i++) {
		my $low = $self->{services}[$i][0];
		my $high = $self->{services}[$i][1];
		if ($compact) {
			push(@list, $low eq $high ? $low : "$low-$high");
		} else {
			for (my $j=$low; $j <= $high; $j++) {
				push(@list, $j);
			}
		}
	}
	foreach my $name ($self->groups) {
		my $grp = $self->{walker}->obj($name) || next;
		push(@list, $grp->enumerate($compact));
	}
	@list = sort { (split(/-/, $a))[0] <=> (split(/-/, $b))[0] } @list;
	return @list;
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
