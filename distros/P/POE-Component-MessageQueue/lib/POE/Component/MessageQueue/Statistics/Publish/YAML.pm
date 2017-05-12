# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package POE::Component::MessageQueue::Statistics::Publish::YAML;
use strict;
use warnings;
use base qw(POE::Component::MessageQueue::Statistics::Publish);
use Best [ qw(YAML::Syck YAML) ], qw(Dump);
use File::Temp;
use File::Copy qw(move);

sub publish_file
{
	my ($self, $filename) = @_;

	# Be friendly to people who might be reading the file
	my $fh = File::Temp->new(UNLINK => 0);
	my %h = %{ $self->{statistics}->{statistics} };
	eval {
		$fh->print( Dump( { %h, generated => scalar localtime } ) );
		$fh->flush;
		move($fh->filename, $filename) or die "Failed to rename $fh to $filename: $!";
	};
	if (my $e = $@) {
		$fh->unlink_on_destroy( 1 ) if $fh;
		die $e;
	}
}

sub publish_handle
{
	my ($self, $handle) = @_;
	$handle->print( Dump( $self->{statistics}->{statistics} ) );
}

1;

__END__

=head1 NAME

POE::Component::MessageQueue::Statistics::Publish::YAML - Publish Statistics In YAML Format

=head1 SYNOPSIS

	use POE::Component::MessageQueue::Statistics;
	use POE::Component::MessageQueue::Statistics::Publish::YAML;

	# This is initialized elsewhere
	my $stats   = POE::Component::MessageQueue::Statistics->new();

	my $publish = POE::Component::MessageQueue::Statistics::Publish::YAML->new(
		output => \*STDOUT, 
		statistics => $stats
	);
	$publish->publish();

=head1 DESCRIPTION

This module dumps the statistics information in YAML format

=head1 SEE ALSO

L<POE::Component::MessageQueue::Statistics>,
L<POE::Component::MessageQueue::Statistics::Publish>

=head1 AUTHOR

Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=cut
