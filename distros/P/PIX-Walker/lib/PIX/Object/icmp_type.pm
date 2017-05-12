package PIX::Object::icmp_type;

use strict;
use warnings;
use base qw( PIX::Object );
use Carp;

our $VERSION = '1.10';

our $ICMP_TYPES = {
	# Cisco PIX/ASA firewalls define the following aliases for various ICMP
	# type codes. Values defined from:
	# http://www.iana.org/assignments/icmp-parameters
	'alternate-address' 	=> 6,
	'conversion-error' 	=> 31,
	'echo' 			=> 8,
	'echo-reply' 		=> 0,
	'information-reply' 	=> 16,
	'information-request' 	=> 15,
	'mask-reply' 		=> 18,
	'mask-request' 		=> 17,
	'mobile-redirect' 	=> 32,
	'parameter-problem' 	=> 12,
	'redirect' 		=> 5,
	'router-advertisement' 	=> 9,
	'router-solicitation' 	=> 10,
	'source-quench' 	=> 4,
	'time-exceeded' 	=> 11,
	'timestamp-reply' 	=> 14,
	'timestamp-request' 	=> 13,
	'traceroute' 		=> 30,
	'unreachable' 		=> 3
};

=pod

=head1 NAME

PIX::Object::icmp_type - Class for "icmp-type" object-groups found in a PIX
config.

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

	$self->{icmptypes} = [];			# icmp-types directly defined in this object group
	$self->{groups} = [];				# other groups that this object points to for icmptypes
	$self->{desc} = '';

	$self->_nextline;				# remove the first line 'object-group blah'
	while (defined(my $line = $self->_nextline)) {
		if ($line =~ /\s*icmp-object (\S*)/) {
			$self->add($1);
		} elsif ($line =~ /^\s*group-object (\S+)/) {
			$self->add($1, 1);
		} elsif ($line =~ /^\s+description (.+)/) {
			$self->{desc} = $1;
		} else {
			carp "$self->{name}: Unknown protocol object line: $line\n"; 
		}
	}
}

=item B<add($icmp_or_grp, [$is_icmp])>

=over

Add an icmp-type or nested group to the object-group. If $is_group is true
then $icmp_or_grp will be recorded as a nested hostgroup name, and not an icmp
type name. Note: This logic is slightly different than the other PIX::Object
sub-classes.

=back

=cut
sub add {
	my ($self, $icmp_or_group, $is_group) = @_;
	if (!$is_group) {
		push(@{$self->{icmptypes}}, $self->icmp_alias($icmp_or_group));
	} else {
		push(@{$self->{groups}}, $icmp_or_group);
	}
}

=item B<enumerate( )>

=over

Returns a list of icmp types that the object-group encompasses.

=back

=cut
sub enumerate {
	my $self = shift;
	my @list = @{$self->{icmptypes}};
	foreach my $name ($self->groups) {
		my $grp = $self->{walker}->obj($name) || next;
		push(@list, $grp->enumerate);
	}
	return sort { $a <=> $b } @list;
}

=item B<icmp_alias( )>

=over

Returns the ICMP Type code that matches the alias given, or the unmodified
alias if no known alias matches. See $PIX::Object::icmp_type::ICMP_TYPES for
a list of avaliable aliases that cisco defines.

=back

=cut
sub icmp_alias {
	my ($self, $type) = @_;
	return exists $ICMP_TYPES->{$type} ? $ICMP_TYPES->{$type} : $type;
}


=item B<list( )>

=over

Returns a list of icmp types from the object group. A plain list of icmp types
are returned.

=back

=cut
sub list {
	my $self = shift;
	my @list = @{$self->{icmptypes}};
	foreach my $name ($self->groups) {
		my $grp = $self->{walker}->obj($name) || next;
		push(@list, $grp->list);
	}
	return @list;
}

=item B<matchicmp( )>

=over

Alias for B<matchport()>.

=back

=cut
sub matchicmp {
	my $self = shift;
	return $self->matchport(@_);
}

=item B<matchport( )>

=over

Searches the icmp types within our group for the TYPE given. Deligates out to
nested groups and maintains the state of the trace.

Returns the name of the of the object-group that matches the TYPE (which
evaluates to true). This is usually called from the PIX::Accesslist::Line
object instead of directly.

=back

=cut
sub matchport {
	my ($self, $portstr, $trace) = @_;
	my $port = $self->icmp_alias($portstr);
	my $idx = 0;

	# first search our defined icmp types
	#print "searching icmp types in $self->{name} ...\n" if $self->{debug};
	foreach my $p (@{$self->{icmptypes}}) {
		$idx++;
		if ($port eq $p) {
			push(@$trace, $self->{name}, $idx, 0) if defined $trace;
			return $self->{name};
		}
	}

	# search all nested groups, if any.
	#print "searching groups in $self->{name} (" . (join(',', @{$self->{groups}})) . ")...\n" if $self->{debug} and scalar @{$self->{groups}};
	foreach my $name (@{$self->{groups}}) {
		my $grp = $self->{walker}->obj($name) || next;
		my $localtrace = [ $self->{name}, 0, 0 ];
		next unless $grp->type eq $self->type;
		my $found = $grp->matchport($port, $localtrace);
		if ($found) {
			push(@$trace, @$localtrace) if defined $trace;
			return $grp->{name};
		}
	}

	return 0;
}

sub icmptypes { return wantarray ? @{$_[0]->{icmptypes}} : $_[0]->{icmptypes} }
sub groups { return wantarray ? @{$_[0]->{groups}} : $_[0]->{groups} }

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
