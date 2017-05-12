package PIX::Object::protocol;

use strict;
use warnings;
use base qw( PIX::Object );
use Carp;

our $VERSION = '1.10';

=pod

=head1 NAME

PIX::Object::protocol - Class for "protocol" object-groups found in a PIX
config. A protocol group is used on access-lists to allow a line of an ACL to
have multiple protocols on it (ip, tcp, udp, gmp, ah, es, etc...).

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

	$self->{protocols} = [];				# protocols directly defined in this object group
	$self->{groups} = [];				# other groups that this object points to for protocols
	$self->{desc} = '';

	$self->_nextline;				# remove the first line 'object-group blah'
	while (defined(my $line = $self->_nextline)) {
#		print "$self->{name}: $line\n";
		if ($line =~ /\s*protocol-object (\S*)/) {
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

=item B<add($proto_or_grp, [$is_group])>

=over

Add a protocol or nested group to the object-group. If $is_group is true
then $proto_or_grp will be recorded as a nested hostgroup name, and not a
protocol name. Note: This logic is slightly different than the other
PIX::Object sub-classes.

=back

=cut
sub add {
	my ($self, $p, $is_group) = @_;
	if (!$is_group) {
		push(@{$self->{protocols}}, $p);
	} else {
		push(@{$self->{groups}}, $p);
	}
}

=item B<list( )>

=over

Returns a list of protocols from the object group. A plain list of protocol
names are returned.

=back

=cut
sub list {
	my $self = shift;
	my @list = @{$self->{protocols}};
	foreach my $name ($self->groups) {
		my $grp = $self->{walker}->obj($name) || next;
		push(@list, $grp->list);
	}
	return @list;
}

sub protocols { return wantarray ? @{$_[0]->{protocols}} : $_[0]->{protocols} }
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
