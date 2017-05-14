package ProgressMonitor::Stringify::Fields::Bar;

use warnings;
use strict;

use ProgressMonitor::Exceptions;
require ProgressMonitor::Stringify::Fields::AbstractDynamicField if 0;

# Attributes:
#	innerWidth
#		The computed width of the bar itself
#	idleTravellerIndex
#		The location to write the 'traveller' when total is unknown
#	idleSpinnerIndex
#		The next spinner in the sequence to use when resolution is too small
#	allEmpty
#		A precomputed bar that is empty
#	lastFiller
#		The last string to fill the bar (to detect resolution issues)
#
use classes
  extends  => 'ProgressMonitor::Stringify::Fields::AbstractDynamicField',
  new      => 'new',
  attrs_pr => ['innerWidth', 'idleTravellerIndex', 'idleSpinnerIndex', 'allEmpty', 'lastFiller', 'inited'],
  throws   => ['X::ProgressMonitor::InsufficientWidth'],
  ;

sub new
{
	my $class = shift;
	my $cfg   = shift;

	my $self = $class->SUPER::_new($cfg, $CLASS);

	$cfg = $self->_get_cfg;

	# compute the width, taking into account all the user choices
	#
	my $minWidth = $cfg->get_minWidth;
	my $width    =
	  length($cfg->get_leftWall) + $cfg->get_idleLeftSpace + length($cfg->get_idleTraveller) + $cfg->get_idleRightSpace +
	  length($cfg->get_rightWall);
	$width = $minWidth if $minWidth > $width;
	X::ProgressMonitor::InsufficientWidth->throw($width) if ($width > $cfg->get_maxWidth);

	$self->_set_width($width);

	# init the instance vars not affected by width
	#
	$self->{$ATTR_idleTravellerIndex} = 0;
	$self->{$ATTR_idleSpinnerIndex}   = 0;
	$self->{$ATTR_lastFiller}         = $cfg->get_fillCharacter;
	$self->{$ATTR_inited}             = 0;

	return $self;
}

sub widthChange
{
	my $self = shift;

	my $cfg = $self->_get_cfg;

	# recompute some vars
	#
	my $innerWidth = $self->get_width - length($cfg->get_leftWall) - length($cfg->get_rightWall);
	$self->{$ATTR_innerWidth} = $innerWidth;
	$self->{$ATTR_allEmpty}   = $cfg->get_emptyCharacter x $innerWidth;

	return;
}

sub render
{
	my $self       = shift;
	my $state      = shift;
	my $tick       = shift;
	my $totalTicks = shift;
	my $clean      = shift;

	my $cfg = $self->_get_cfg;

	my $iw  = $self->{$ATTR_innerWidth};
	my $bar = $self->{$ATTR_allEmpty};
	if (defined($totalTicks))
	{
		# the total is known, so compute how much filler we need to indicate the ratio
		#
		my $ratio = defined($totalTicks) && $totalTicks > 0 ? ($tick / $totalTicks) : 0;
		my $filler = $cfg->get_fillCharacter x ($ratio * $iw);
		substr($bar, 0, length($filler), $filler);

		# unless we're requested to be 'clean' and in case the filler is the
		# same as last time (and we're not full), twirl the spinner
		#
		if (!$clean && $ratio < 1 && $filler eq $self->{$ATTR_lastFiller})
		{
			my $lf  = length($filler);
			my $seq = $cfg->get_idleSpinnerSequence;
			substr($bar, ($lf == 0 ? 0 : $lf - 1), 1, $seq->[$self->{$ATTR_idleSpinnerIndex}++ % @$seq]);
		}
		$self->{$ATTR_lastFiller} = $filler;
	}
	else
	{
		if (!$self->{$ATTR_inited})
		{
			# first call, do nothing
			#
			$self->{$ATTR_inited} = 1;
		}
		else
		{
			# total is unknown (or we're still in prep mode)
			# run the traveller in round robin in the bar
			#
			my $begin = $self->{$ATTR_idleTravellerIndex}++ % $iw;
			my $it    = $cfg->get_idleTraveller;
			for (0 .. (length($it) - 1))
			{
				substr($bar, $begin, 1, substr($it, $_, 1));
				$begin = 0 if ++$begin >= $iw;
			}
		}
	}

	return $cfg->get_leftWall . $bar . $cfg->get_rightWall;
}

###

package ProgressMonitor::Stringify::Fields::BarConfiguration;

use strict;
use warnings;

use classes
  extends => 'ProgressMonitor::Stringify::Fields::AbstractDynamicFieldConfiguration',
  attrs   => [
			'emptyCharacter', 'fillCharacter', 'leftWall',       'rightWall',
			'idleTraveller',  'idleLeftSpace', 'idleRightSpace', 'idleSpinnerSequence'
		   ],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {
			%{$self->SUPER::defaultAttributeValues()},
			emptyCharacter      => '.',
			fillCharacter       => '*',
			leftWall            => '[',
			rightWall           => ']',
			idleTraveller       => '==>',
			idleLeftSpace       => 1,
			idleRightSpace      => 1,
			idleSpinnerSequence => ['-', '\\', '|', '/'],
		   };
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues;

	X::Usage->throw("length of leftWall can not be less than 0")   if length($self->get_leftWall) < 0;
	X::Usage->throw("length of rightWall can not be less than 0")  if length($self->get_rightWall) < 0;
	X::Usage->throw("length of emptyCharacter must have length 1") if length($self->get_emptyCharacter) != 1;
	X::Usage->throw("length of fillCharacter must have length 1")  if length($self->get_fillCharacter) != 1;
	X::Usage->throw("idleLeftSpace can not be less than 0")        if $self->get_idleLeftSpace < 0;
	X::Usage->throw("idleRightSpace can not be less than 0")       if $self->get_idleRightSpace < 0;
	my $seq = $self->get_idleSpinnerSequence;
	X::Usage->throw("idleSpinnerSequence must be an array") unless ref($seq) eq 'ARRAY';
	for (@$seq)
	{
		X::Usage->throw("all idleSpinnerSequence elements must have length of 1") if length($_) != 1;
	}

	return;
}

###########################

=head1 NAME

ProgressMonitor::Stringify::Field::Bar - a field implementation that renders progress
as a bar.

=head1 SYNOPSIS

  # call someTask and give it a monitor to call us back
  #
  my $bar = ProgressMonitor::Stringify::Fields::Bar->new;
  someTask(ProgressMonitor::Stringify::ToStream->new({fields => [ $bar ]});

=head1 DESCRIPTION

This is a dynamic field representing progress as a bar typically of this form:
"[###....]" etc. It will consume as much room as it can get unless limited by maxWidth.

It is very configurable in terms of what it prints. By default it will also do 
useful things to indicate 'idle' progress, i.e. either no ticks advanced, but still
tick is called, or just 'unknown' work.

Inherits from ProgressMonitor::Stringify::Fields::AbstractDynamicField.

=head1 METHODS

=over 2

=item new( $hashRef )

Configuration data:

=over 2

=item emptyCharacter (default => '.')

The character that should be used to indicate an empty location in the bar.

=item fillCharacter (default => '#')

The character that should be used to indicate a full location in the bar.

=item leftWall (default => '[')

The string that should be used to indicate the left wall of the bar. This can
be set to an empty string if you don't want a wall.

=item rightWall (default => ']')

The string that should be used to indicate the right wall of the bar. This can
be set to an empty string if you don't want a wall.

=item idleTraveller (default => '==>')

The string that should be used as a moving piece in order to indicate progress
for totals that are unknown.

=item idleLeftSpace (default => 1)

Amount of characters that should be allocated to the left of the idleTraveller.
This is necessary to insure that the idleTraveller has at least some room to travel
in.  

=item idleLeftRight (default => 1)

Amount of characters that should be allocated to the right of the idleTraveller.
This is necessary to insure that the idleTraveller has at least some room to travel
in.

=item idleSpinnerSequence (default => ['-', '\\', '|', '/'])

This should be a reference to a list of characters that should be used in sequence
for ticks that doesn't advance the bar, but we still want to show that something
is happening. If you do not wish this to happen at all, set to a single element list
with the fillCharacter.

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

1;    # End of ProgressMonitor::Stringify::Fields::Bar
