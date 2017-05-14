package ProgressMonitor::Stringify::ToCallback;

use warnings;
use strict;

require ProgressMonitor::Stringify::AbstractMonitor if 0;

use classes
  extends => 'ProgressMonitor::Stringify::AbstractMonitor',
  new     => 'new',
  ;

sub new
{
	my $class = shift;
	my $cfg   = shift;

	my $self = $class->SUPER::_new($cfg, $CLASS);

	return $self;
}

sub render
{
	my $self = shift;

	# call the tick callback with the normal rendering
	# unless the message callback is set, then don't render message
	# and pass that separately to the msg callback
	#
	my $cfg    = $self->_get_cfg;
	my $tcb    = $cfg->get_tickCallback;
	my $mcb    = $cfg->get_messageCallback;
	my $cancel = $tcb->($self->_toString($mcb ? 0 : 1));
	if ($mcb)
	{
		my $msg = $self->_get_message;
		$mcb->($msg) if $msg;
	}
	$self->setCanceled($cancel) unless $self->isCanceled;

	return;
}

sub setErrorMessage
{
	my $self = shift;
	my $msg  = $self->SUPER::setErrorMessage(shift());

	my $emcb = $self->_get_cfg->get_errorMessageCallback;
	$emcb->($msg) if $emcb;
}

###

package ProgressMonitor::Stringify::ToCallbackConfiguration;

use strict;
use warnings;

# Attributes:
#	callback (code ref)
#		The callback will be called with the rendered string and should return a
# 		boolean, which will be used to set the cancellation status with.
use classes
  extends => 'ProgressMonitor::Stringify::AbstractMonitorConfiguration',
  attrs   => ['tickCallback', 'messageCallback', 'errorMessageCallback'],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {
			%{$self->SUPER::defaultAttributeValues()},
			tickCallback => sub { X::Usage->throw("missing tickCallback"); 1; },
			messageCallback      => undef,
			errorMessageCallback => undef,
		   };
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues();

	X::Usage->throw("tickCallback is not a code ref") unless ref($self->get_tickCallback) eq 'CODE';

	my $mcb = $self->get_messageCallback;
	X::Usage->throw("messageCallback is not a code ref") if ($mcb && ref($mcb) ne 'CODE');

	my $emcb = $self->get_errorMessageCallback;
	X::Usage->throw("errorMessageCallback is not a code ref") if ($emcb && ref($emcb) ne 'CODE');

	X::Usage->throw("maxWidth not set") unless $self->get_maxWidth;

	return;
}

############################

=head1 NAME

ProgressMonitor::Stringify::ToCallback - a monitor implementation that provides
stringified feedback to a callback.

=head1 SYNOPSIS

  ...
  # call someTask and give it a monitor to call us back
  # on callback, just do something unimaginative (print it...:-) and return 0 (don't cancel)
  #
  someTask(ProgressMonitor::Stringify::ToCallback->new({fields => [ ... ], tickCallback => sub { print "GOT: ", shift(), "\n"; 0; });

=head1 DESCRIPTION

This is a concrete implementation of a ProgressMonitor. It will send the stringified
feedback to a callback (code ref) supplied by the user.

Inherits from ProgressMonitor::Stringify::AbstractMonitor.

=head1 METHODS

=over 2

=item new( $hashRef )

Note that the maxWidth must be set explicitly.

Configuration data:

=over 2

=item tickCallback

A code reference to an anonymous sub. For each rendering tick, it will be called
with the rendered string as the argument. The return value will be used to 
set the cancellation status.

=item messageCallback

A code reference that will be called specifically with the current message.
Note that setting this changes the behavior of tickCallback; normally,
tickCallback will receive the rendered string including any message.
However, by setting messageCallback, the message will be skipped during
rendition of the ordinary fields. Also, if this is set, the strategy used
is of no importance.

=item errorMessageCallback

A code reference that will be called with the current error message.

=back

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

1;    # End of ProgressMonitor::Stringify::ToCallback
