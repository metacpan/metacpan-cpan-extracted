package ProgressMonitor::Stringify::Fields::ETA;

use warnings;
use strict;

use ProgressMonitor::State;
require ProgressMonitor::Stringify::Fields::AbstractField if 0;

use Time::HiRes qw(time);

use constant MINUTE => 60;
use constant HOUR   => 60 * MINUTE;
use constant DAY    => 24 * HOUR;

no strict 'refs';
use classes
  extends  => 'ProgressMonitor::Stringify::Fields::AbstractField',
  new      => 'new',
  attrs_pr => ['start', 'index', 'lastHH', 'lastMM', 'lastSS', 'lastDelim', 'lastTime', 'lastLeft'],
  ;

sub new
{
	my $class = shift;
	my $cfg   = shift;

	my $self = $class->SUPER::_new($cfg, $CLASS);

	$cfg = $self->_get_cfg;

	# we only wish to portray up to 23:59:49 at this point
	#
	my $delim    = $cfg->get_mainDelimiter;
	my $delimLen = length($delim);
	$self->_set_width(2 + $delimLen + 2 + $delimLen + 2);

	my $ofc = $cfg->get_unknownCharacter;
	$self->{$ATTR_start}     = 0;
	$self->{$ATTR_index}     = 0;
	$self->{$ATTR_lastHH}    = $self->{$ATTR_lastMM} = $self->{$ATTR_lastSS} = "$ofc$ofc";
	$self->{$ATTR_lastDelim} = $delim;
	$self->{$ATTR_lastTime}  = 0;
	$self->{$ATTR_lastLeft}  = 0;

	return $self;
}

sub render
{
	my $self       = shift;
	my $state      = shift;
	my $ticks      = shift;
	my $totalTicks = shift;
	my $clean      = shift;

	my $now            = time;
	my $timeSinceStart = $now - $self->{$ATTR_start};
	my $cfg            = $self->_get_cfg;
	my $hh             = $self->{$ATTR_lastHH};
	my $mm             = $self->{$ATTR_lastMM};
	my $ss             = $self->{$ATTR_lastSS};
	my $delim          = $self->{$ATTR_lastDelim};

	if (!$self->{$ATTR_start})
	{
		# this is the first call - just render 'unknown'
		#
		$self->{$ATTR_start} = $self->{$ATTR_lastTime} = $now;
	}
	else
	{

		if ($state == STATE_DONE)
		{
			my $ofc = $cfg->get_unknownCharacter;
			$hh = $mm = $ss = "$ofc$ofc";
			($hh, $mm, $ss) = $self->__fmtHMS($timeSinceStart) if $timeSinceStart < DAY;
		}
		else
		{
			# to avoid too much flickering, only update at the given rate
			#
			if ($now >= $self->{$ATTR_lastTime} + $cfg->get_maxUpdateRate)
			{
				# flicker delimiter
				#
				my $seq = $cfg->get_idleDelimiterSequence;
				$delim = $seq->[$self->{$ATTR_index}++ % @$seq];

				# try to ensure we have some information to predict on
				#
				my $ratio = defined($totalTicks) && $totalTicks > 0 ? $ticks / $totalTicks : 0;
				if ($ratio > $cfg->get_waitForRatio)
				{
					my $left = int($timeSinceStart * ((1 - $ratio) / $ratio));
					$left = DAY if $left > DAY;
					if ($clean || $left != $self->{$ATTR_lastLeft})
					{
						($hh, $mm, $ss) = $self->__fmtHMS($left);
						$delim = $cfg->get_mainDelimiter;
					}
					$self->{$ATTR_lastLeft} = $left;
				}
				$self->{$ATTR_lastTime} = $now;
			}
		}
	}

	$self->{$ATTR_lastHH}    = $hh;
	$self->{$ATTR_lastMM}    = $mm;
	$self->{$ATTR_lastSS}    = $ss;
	$self->{$ATTR_lastDelim} = $delim;
	return sprintf("%s%s%s%s%s", $hh, $delim, $mm, $delim, $ss);
}

sub completed
{
	my $self = shift;

	# We're done - report the actual time it took
	# but check for overflow
	#
	my $cfg = $self->_get_cfg;
	my $ofc = $cfg->get_unknownCharacter;
	my ($hh, $mm, $ss);
	$hh = $mm = $ss = "$ofc$ofc";
	my $timeSinceStart = time - $self->{$ATTR_start};
	($hh, $mm, $ss) = $self->__fmtHMS($timeSinceStart) if $timeSinceStart < DAY;
	my $delim = $cfg->get_mainDelimiter;

	return sprintf("%s%s%s%s%s", $hh, $delim, $mm, $delim, $ss);
}

sub __fmtHMS
{
	my $self = shift;
	my $time = shift;

	my $fmt = '%02u';
	my $hh  = sprintf($fmt, int($time / DAY));
	my $mm  = sprintf("%02u", int(($time % DAY) / MINUTE));
	my $ss  = sprintf("%02u", $time % MINUTE);

	return ($hh, $mm, $ss);
}

###

package ProgressMonitor::Stringify::Fields::ETAConfiguration;

use strict;
use warnings;

no strict 'refs';
use classes
  extends => 'ProgressMonitor::Stringify::Fields::AbstractFieldConfiguration',
  attrs   => ['unknownCharacter', 'mainDelimiter', 'idleDelimiterSequence', 'waitForRatio', 'maxUpdateRate'],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {
			%{$self->SUPER::defaultAttributeValues()},
			unknownCharacter      => '-',
			mainDelimiter         => ':',
			idleDelimiterSequence => [' ', ':'],
			waitForRatio          => 0.01,
			maxUpdateRate         => 1,
		   };
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues;

	X::Usage->throw("unknownCharacter should have a length of 1") unless length($self->get_unknownCharacter) == 1;
	my $seq = $self->get_idleDelimiterSequence;
	X::Usage->throw("idleDelimiterSequence must be an array") unless ref($seq) eq 'ARRAY';
	my $len = length($self->get_mainDelimiter);
	for (@$seq)
	{
		X::Usage->throw("all idleDelimiterSequence elements must have same length as mainDelimiter") if length($_) != $len;
	}
	X::Usage->throw("0 < waitForRatio <= 1") if ($self->get_waitForRatio < 0 || $self->get_waitForRatio > 1);
	X::Usage->throw("maxUpdateRate can not be negative") if $self->get_waitForRatio < 0;

	return;
}

############################

=head1 NAME

ProgressMonitor::Stringify::Field::ETA - a field implementation that renders progress
as a time-to-completion.

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

	@@TODO@@

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

You can find documentation for this module with the perldoc command.

    perldoc ProgressMonitor

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ProgressMonitor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ProgressMonitor>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ProgressMonitor>

=item * Search CPAN

L<http://search.cpan.org/dist/ProgressMonitor>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to my family. I'm deeply grateful for you!

=head1 COPYRIGHT & LICENSE

Copyright 2006,2007 Kenneth Olwing, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of ProgressMonitor::Stringify::Fields::ETA
