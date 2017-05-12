#
# Copyright 2007, 2008 Paul Driver <frodwith@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package POE::Component::MessageQueue::IDGenerator::UUID;
use Moose;
with qw(POE::Component::MessageQueue::IDGenerator);

use Data::UUID;

has 'generator' => (
	is => 'ro',
	default => sub { Data::UUID->new() },
);

sub generate 
{
	my ($self) = @_;
	# We could return something more compact (like a b64string) but that would
	# screw with Storage::Filesystem, and anyone else that doesn't like special
	# characters.
	return $self->generator->create_str();
}

1;

=head1 NAME

POE::Component::MessageQueue::IDGenerator::UUID - UUID generator.

=head1 DESCRIPTION

This is a concrete implementation of the Generator interface for creating
message IDs.  It uses standards compliant UUIDs, which according to Data::UUID
are guaranteed to be unique until 3500 C.E., though I'm not sure how it knows
that.

=head1 SEE ALSO

L<Data::UUID>

=head1 AUTHOR

Paul Driver <frodwith@gmail.com>
