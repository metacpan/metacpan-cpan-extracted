# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.
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

package POE::Component::MessageQueue::Statistics::Publish;
use strict;
use warnings;
use POE;
use IO::Handle;

sub spawn
{
	my $class = shift;
	my $self = $class->new(
		alias    => 'MQ-Publish',
		interval => 10,
		@_
	);

	$self->{statistics}->add_publisher($self);
	$self->{session} = POE::Session->create(
		heap => {},
		inline_states => {
			'_start' => sub {
				$_[KERNEL]->alias_set( $self->{alias} );
				$_[KERNEL]->yield('publish');
			},
			'publish' => sub {
				# gets called on a regular interval
				my ($kernel, $heap) = @_[KERNEL, HEAP];
				my $alarm = $heap->{publish_alarm};
				$kernel->alarm_remove($alarm) if $alarm;

				$self->publish();

				$heap->{publish_alarm} = 
					$kernel->alarm_set('publish', time() + $self->{interval});
			},
			'shutdown' => sub {
				my ($kernel, $heap) = @_[KERNEL, HEAP];
				my $alarm = $heap->{publish_alarm};
				$kernel->alarm_remove($alarm) if $alarm;
				$self->publish();	
				# Cut off circular references. 
				delete @{$self}{qw(statistics session)};
			},
		}
	);
}

sub new
{
	my $class = shift;
	my $self  = bless { @_ }, $class; # XXX - hack
	$self;
}

sub publish
{
	my $self = shift;
	my $output = $self->{output};
	my $ref = ref $output;

	if (! $ref) { # simple string. a filename
		$self->publish_file( $output );
	} elsif ($ref eq 'CODE') {
		$self->publish_code( $output );
	} elsif ($ref eq 'GLOB' || $output->can('print')) {
		$self->publish_handle( $output );
	} else {
		# don't know what it is. subclasses may detect that we were
		# unable to determine the output type by checking for flase
		# return values from this subroutine
		return ();
	}

	return 1;
}

sub shutdown
{
	my $self = shift;
	POE::Kernel->post($self->{session}, 'shutdown');
} 

1;

__END__

=head1 NAME

POE::Component::MessageQueue::Statistics::Publish - Base Statistics Publish Class

=head1 METHODS

=head2 new(%args)

Creates a new instance. You must pass in an instance of POE::Component::MessageQueue::Statistics, and an output destination

	# initialized elsewhere
	my $stats   = POE::Component::MessageQueue::Statistics->new;

	my $publish = POE::Component::MessageQueue::Statistics::Publish::YAML->new(
		output => \*STDERR,
		statistics => $stats,
		interval => 10, # dump every 10 seconds
	);

=head2 publish()

Publishes the current state of the statistics. This is actually a dispatcher
that dispatches to the appropriate method calls (described below) that are
specific to a particular output type.

Your subclass should implement the appropriate methods (output types) that
you want to support.

=head2 publish_file($filename)

Receives a filename to dump the statistics.

=head2 publish_handle($handle)

Receives a handle to dump the statistics.

=head2 publish_code($code)

Receives a subroutine reference. Your code should simply pass the result
output to $code and execute it:

	sub publish_code
	{
		my ($self, $code) = @_;
		my $output = ....; # generate output here
		$code->( $output );
	}

=head1 SEE ALSO

L<POE::Component::MessageQueue::Statistics>,
L<POE::Component::MessageQueue::Statistics::Publish::YAML>

=head1 AUTHOR

Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=cut
