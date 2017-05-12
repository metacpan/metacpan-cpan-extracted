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

package POE::Component::MessageQueue::Storage::Generic::Base;
use Moose::Role;

# Exclude log cause we have our own - we want to call our setted postback.
with 'POE::Component::MessageQueue::Storage' => { -excludes => 'log' };

sub log
{
	my $self = shift;;
	$self->log_function->(@_) if $self->has_log_function;
	return;
}

has 'log_function' => (
	is        => 'rw',
	writer    => 'set_log_function',
	predicate => 'has_log_function',
);

sub ignore_signals
{
	my ($self, @signals) = @_;
	$SIG{$_} = 'IGNORE' foreach (@signals);
}

1;
