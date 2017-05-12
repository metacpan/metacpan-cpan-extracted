#
# Copyright 2007-2010 David Snopek <dsnopek@gmail.com>
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

package POE::Component::MessageQueue::Logger;
use Moose;
use POE::Kernel;

my $LEVELS = {
	debug     => 0,
	info      => 1,
	notice    => 2,
	warning   => 3,
	error     => 4,
	critical  => 5,
	alert     => 6,
	emergency => 7
};

has 'level' => (
	is => 'rw',
	default => 3,
);

has 'logger_alias' => (
	is        => 'rw',
	writer    => 'set_logger_alias',
	predicate => 'has_logger_alias',
);

has 'log_function' => (
	is        => 'rw',
	writer    => 'set_log_function',
	predicate => 'has_log_function',
);

sub log
{
	my ($self, $type, $msg) = @_;

	if ( not defined $msg )
	{
		$msg  = $type;
		$type = 'info';
	}

	if ( $self->has_log_function )
	{
		$self->log_function->( $type, $msg );
	}
	elsif ( $self->has_logger_alias )
	{
		$poe_kernel->post($self->logger_alias, $type, "$msg\n" );
	}
	elsif ($LEVELS->{$type} >= $self->level )
	{
		print STDERR "$msg\n";
	}
}

sub shutdown
{
	my $self = shift;

	if ($self->has_logger_alias)
	{
		$poe_kernel->signal( $self->logger_alias, 'TERM' );
	}
}

1;

