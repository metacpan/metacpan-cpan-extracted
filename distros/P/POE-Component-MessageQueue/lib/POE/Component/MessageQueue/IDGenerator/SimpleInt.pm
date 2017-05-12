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

package POE::Component::MessageQueue::IDGenerator::SimpleInt;
use Moose;
with qw(POE::Component::MessageQueue::IDGenerator);

has 'filename' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has 'last_id' => (
	is      => 'rw',
	isa     => 'Num',
	default => 0,
	traits  => ['Counter'],
	handles => {
		'inc_last_id'   => 'inc',
		'dec_last_id'   => 'dec',
		'reset_last_id' => 'reset',
	}
);

sub BUILD
{
	my $self = shift;
	my $filename = $self->filename;

	if (-e $filename) 
	{
		open my $in, '<', $filename || 
			die "Couldn't open $filename for reading: $!";	
		my $line = <$in>;
		close $in;
		chomp $line;
		die "$filename didn't contain a number." unless ($line =~ /^\d+$/);
		$self->last_id(0 + $line);
	}
	else
	{
		open my $out, '>', $filename ||
			die "Couldn't touch $filename: $!";
		close $out;
		$self->reset_last_id();
	}
}

sub generate 
{
	my ($self) = @_;
	$self->inc_last_id();
	my $id = $self->last_id;
	return "$id";
}

sub DESTROY 
{
	my $self = shift;
	my $fn = $self->filename;
	open my $out, '>', $fn ||
		die "Couldn't reopen $fn to write last ID!";
	my $id = $self->last_id;
	print $out "$id\n";
	close $out;
}

1;

=head1 NAME

POE::Component::MessageQueue::IDGenerator::SimpleInt - Simple integer IDs.

=head1 DESCRIPTION

This is a concrete implementation of the Generator interface for creating
message IDs.  It simply increments an integer, and makes some attempt to
remember what the last one it used was across runs. 

=head1 AUTHOR

Paul Driver <frodwith@gmail.com>
