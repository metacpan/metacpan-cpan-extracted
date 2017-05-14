package ProgressMonitor::AbstractStatefulMonitor;

use warnings;
use strict;

use ProgressMonitor::Exceptions;
use ProgressMonitor::State;
use ProgressMonitor::SetMessageFlags;

require ProgressMonitor if 0;

use classes
  extends       => 'ProgressMonitor',
  class_methods => ['_new'],
  methods       => {render => 'ABSTRACT',},
  attrs_pr      => [
			   'cfg',     'canceled',       'state',        'totalTicks',  'ticks', 'multiplier',
			   'message', 'prepareMessage', 'beginMessage', 'tickMessage', 'endMessage',
			  ],
  throws => ['X::ProgressMonitor::InvalidState', 'X::ProgressMonitor::TooManyTicks', 'X::ProgressMonitor::UnknownSetMessageFlag',],
  ;

sub begin
{
	my $self       = shift;
	my $totalTicks = shift;

	# it is allowed to call begin directly if there's no preparatory
	# work to be done - so we call prepare if not already done
	#
	my $state = $self->_get_state;
	$self->prepare if $state == STATE_NEW;

	# enter the active state, signalling 'prepare complete'
	#
	$self->__shiftState(STATE_PREPARING, STATE_ACTIVE);

	# record the total ticks that can be expected
	# (may be undef, signalling 'unknown')
	#
	$self->{$ATTR_totalTicks} = $totalTicks;

	# check for the presence of a 'begin' message...
	#
	#
	if ($self->{$ATTR_beginMessage})
	{
		$self->_set_message($self->{$ATTR_beginMessage});
		$self->{$ATTR_beginMessage} = undef;
	}

	# conclude with a rendering of this state
	#
	$self->render;

	return;
}

sub end
{
	my $self = shift;

	# it is allowed to call end *directly* if there's no work
	# to be done at all - so we call begin if not already done
	#
	my $state = $self->_get_state;
	$self->begin if $state == STATE_NEW || $state == STATE_PREPARING;

	# going to the end state from the active state
	#
	$self->__shiftState(STATE_ACTIVE, STATE_DONE);

	# automatically complete the ticks, if requested
	#
	$self->{$ATTR_ticks} = $self->{$ATTR_totalTicks} if ($self->{$ATTR_cfg}->get_completeAtEnd);
	
	# check for the presence of an 'end' message...
	#
	#
	if ($self->{$ATTR_endMessage})
	{
		$self->_set_message($self->{$ATTR_endMessage});
		$self->{$ATTR_endMessage} = undef;
	}

	# ensure a final rendering is performed
	#

	$self->render;

	return;
}

sub isCanceled
{
	my $self = shift;

	# return the cancellation state
	#
	return $self->{$ATTR_canceled};
}

sub prepare
{
	my $self = shift;

	# this is the first state transition after creation - signal prep stage
	#
	$self->__shiftState(STATE_NEW, STATE_PREPARING);

	# check for the presence of a 'prepare' message...
	#
	#
	if ($self->{$ATTR_prepareMessage})
	{
		$self->_set_message($self->{$ATTR_prepareMessage});
		$self->{$ATTR_prepareMessage} = undef;
	}

	# render this state
	#
	$self->render;

	return;
}

sub setCanceled
{
	my $self = shift;

	# set the cancellation status
	# only advisory - the client must call isCanceled actively
	#
	$self->{$ATTR_canceled} = shift() ? 1 : 0;

	return;
}

sub setMessage
{
	my $self = shift;
	my $msg  = shift;
	my $when = shift || SM_NOW;

	if ($when == SM_NOW)
	{
		$self->_set_message($msg);
		$self->render;
	}
	elsif ($when == SM_PREPARE)
	{
		$self->{$ATTR_prepareMessage} = $msg;
	}
	elsif ($when == SM_BEGIN)
	{
		$self->{$ATTR_beginMessage} = $msg;
	}
	elsif ($when == SM_TICK)
	{
		$self->{$ATTR_tickMessage} = $msg;
	}
	elsif ($when == SM_END)
	{
		$self->{$ATTR_endMessage} = $msg;
	}
	else
	{
		X::ProgressMonitor::UnknownSetMessageFlag->throw("Unknown value: $when");
	}

	return;
}

sub tick
{
	my $self  = shift;
	my $ticks = shift;

	# this method can be called during either prep or active states
	#
	$self->__assertAnyState([STATE_PREPARING, STATE_ACTIVE]);

	# STATE_PREPARING is implicitly 'unknown', thus any supplied ticks are
	# ignored unless we're in the active state
	#
	if ($self->{$ATTR_state} == STATE_ACTIVE)
	{
		# ...but even in active state, there may have been 'unknown' indicated
		#
		if (defined($self->{$ATTR_totalTicks}))
		{
			# to avoid silly rounding errors at the end we round the tick number down by a small margin
			#
			my $m = $self->{$ATTR_multiplier};
			$self->{$ATTR_ticks} += (int($ticks * $m + 1) / $m) if ($ticks && $ticks >= 0);

			# complain if we get too many ticks
			#
			X::ProgressMonitor::TooManyTicks->throw("$self->{$ATTR_ticks} exceeds $self->{$ATTR_totalTicks}")
			  if int($self->{$ATTR_ticks}) > int($self->{$ATTR_totalTicks});
		}
		else
		{
			# for 'unknown', we inc the ticks by one, the renderer may be interested in displaying the number of calls for example
			#
			$self->{$ATTR_ticks}++;
		}
	}

	# check for the presence of a 'tick' message...
	#
	#
	if ($self->{$ATTR_tickMessage})
	{
		$self->_set_message($self->{$ATTR_tickMessage});
		$self->{$ATTR_tickMessage} = undef;
	}

	# render is always called!
	#
	$self->render;

	return;

}

### protected

sub _get_cfg
{
	my $self = shift;

	return $self->{$ATTR_cfg};
}

sub _get_state
{
	my $self = shift;

	return $self->{$ATTR_state};
}

sub _get_ticks
{
	my $self = shift;

	return $self->{$ATTR_ticks};
}

sub _get_totalTicks
{
	my $self = shift;

	return $self->{$ATTR_totalTicks};
}

sub _get_message
{
	my $self = shift;

	return $self->{$ATTR_message};
}

sub _set_message
{
	my $self = shift;
	my $msg  = shift;

	$self->{$ATTR_message} = $msg;
}

# the protected ctor
#
sub _new
{
	my $self   = classes::new_only(shift);
	my $cfg    = shift;
	my $cfgPkg = shift;

	# make sure we have a (populated) cfg object
	#
	$cfg = $self->{$ATTR_cfg} = ProgressMonitor::AbstractConfiguration::ensureCfgObject($cfg, $cfgPkg);

	# initialize the rest
	#
	$self->{$ATTR_state}          = STATE_NEW;
	$self->{$ATTR_canceled}       = 0;
	$self->{$ATTR_ticks}          = 0;
	$self->{$ATTR_totalTicks}     = undef;
	$self->{$ATTR_multiplier}     = 0 + ("1" . "0" x $cfg->get_resolution);
	$self->{$ATTR_message}        = undef;
	$self->{$ATTR_prepareMessage} = undef;
	$self->{$ATTR_beginMessage}   = undef;
	$self->{$ATTR_tickMessage}    = undef;
	$self->{$ATTR_endMessage}     = undef;

	return $self;
}

### private

# assert that our state is the one expected
#
sub __assertState
{
	my $self  = shift;
	my $state = shift;

	$self->__assertAnyState([$state]);

	return;
}

# assert that our state is any one of the provided
#
sub __assertAnyState
{
	my $self   = shift;
	my $states = shift;

	my $match = 0;
	$match += ($self->{$ATTR_state} == $_) ? 1 : 0 for (@$states);
	X::ProgressMonitor::InvalidState->throw($self->{$ATTR_state}) unless $match;

	return;
}

# move from one state to another
#
sub __shiftState
{
	my $self     = shift;
	my $state    = shift;
	my $newState = shift;

	$self->__assertState($state);
	$self->{$ATTR_state} = $newState;

	return;
}

###

package ProgressMonitor::AbstractStatefulMonitorConfiguration;

use strict;
use warnings;

# The configuration class for the above class
#
#	resolution
#		Allow the user to set the number of decimals when rounding.
#		Unlikely to ever need changing...
#
use classes
  extends => 'ProgressMonitor::AbstractConfiguration',
  attrs   => ['resolution', 'completeAtEnd'],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {%{$self->SUPER::defaultAttributeValues()}, resolution => 8, completeAtEnd => 1};
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues;

	X::Usage->throw("resolution must be positive") if $self->get_resolution < 0;

	return;
}

############################

=head1 NAME

ProgressMonitor::AbstractStatefulMonitor - a reusable/abstract monitor implementation
keeping track of state

=head1 SYNOPSIS

  ...
  use classes
    extends  => 'ProgressMonitor::AbstractStatefulMonitor',
    new      => 'new',
    ...
  ;

  sub new
  {
    my $class = shift;
    my $cfg   = shift;

    my $self = $class->SUPER::_new($cfg, $CLASS);

    ...
  }

  sub render
  {
    my $self = shift;
	
    ...
  }

=head1 DESCRIPTION

This class implements the fully abstract ProgressMonitor interface and is what
generally should be used as a base. It deals with tracking the state changes
and cancellation and calls the subclass through 'render' at appropriate
times. It is strict and throws exceptions if misused.

When extended it provides several accessors for 'protected' data, i.e. only for
the use of subclasses. These accessors are prefixed with '_'.

Subclassing this normally entails only defining the render method.

See L<ProgressMonitor> for the general description of a progress monitor behavior
with regard to state etc.

Inherits from ProgressMonitor.

=head1 METHODS

=over 2

=item begin( $totalTicks )

Enters the active state from the preparing state, setting the total ticks that
should be reached, or use undef to indicate that the number of ticks is unknown.

Throws X::InvalidState for an incorrect calling sequence. 

=item end

Enters the done state from the active state, and the monitor can then not be used again.

Throws X::InvalidState for an incorrect calling sequence.

=item isCanceled

Returns the cancellation flag.

=item prepare

Enters the preparing state from the new state, and the monitor can now be used
while the code is figuring out how many ticks it will need for the active state.

Throws X::ProgressMonitor::InvalidState for an incorrect calling sequence.

=item setCanceled( $boolean )

Sets the cancellation flag.

=item tick( $ticks )

Advances the tick count towards the total tick count (depending on if its is in
the preparing state or if the total is unknown).

Throws X::ProgressMonitor::TooManyTicks if the tick count exceeds the total.

=back

=head1 PROTECTED METHODS

=over 2

=item _new( $hashRef, $package )

The constructor, needs to be called by subclasses.

Configuration data:
  resolution (default => 8)
    Should not needed to be used. Makes sure to round the results down to the given size
    decimals so as to avoid wacky floating point rounding errors when using inexact
    floating point values in calculations (this happens when using subtasks).

  completeAtEnd (default => 1)
    Will automatically add any ticks not performed when end is called.

=item _get_cfg

Returns the configuration object.

=item _get_state

Returns the current state value.

=item _get_ticks

Returns the current tick value.

=item _get_totalTicks

Returns the total tick value.  

=back

=head1 AUTHOR

Kenneth Olwing, C<< <knth at cpan.org> >>

=head1 BUGS

I wouldn't be surprised! If you can come up with a minimal test that shows the
problem I might be able to take a look. Even better, send me a patch.

Please report any bugs or feature requests to
C<bug-progressmonitor at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ProgressMonitor>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find general documentation for this module with the perldoc command:

    perldoc ProgressMonitor

=head1 ACKNOWLEDGEMENTS

Thanks to my family. I'm deeply grateful for you!

=head1 COPYRIGHT & LICENSE

Copyright 2006,2007 Kenneth Olwing, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of ProgressMonitor::AbstractStatefulMonitor
