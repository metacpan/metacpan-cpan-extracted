package ProgressMonitor::Stringify::Fields::Counter;

use warnings;
use strict;

use ProgressMonitor::State;
require ProgressMonitor::Stringify::Fields::AbstractField if 0;

# Attributes:
#	overflow
#		Precomputed string to show when the field overflows
#	unknown
#		Precomputed string to show when the field is unknown
#	index
#		Keeps track of which idle delimiter should be rendered
#	lastCount
#		The previous count string (to trigger idle rendering)
#
use classes
  extends  => 'ProgressMonitor::Stringify::Fields::AbstractField',
  new      => 'new',
  attrs_pr => ['overflow', 'unknown', 'index', 'lastLeft', 'lastRight'];

sub new
{
	my $class = shift;
	my $cfg   = shift;

	my $self = $class->SUPER::_new($cfg, $CLASS);

	$cfg = $self->_get_cfg;

	my $digits = $cfg->get_digits;
	my $delim  = $cfg->get_delimiter;

	# compute the width depending on what will be rendered
	#
	$self->_set_width($digits + ($cfg->get_showTotal ? length($delim) + $digits : 0));

	$self->{$ATTR_overflow}  = $cfg->get_overflowCharacter x $digits;
	$self->{$ATTR_unknown}   = $cfg->get_unknownCharacter x $digits;
	$self->{$ATTR_index}     = 0;
	$self->{$ATTR_lastLeft}  = '';
	$self->{$ATTR_lastRight} = '';

	return $self;
}

sub render
{
	my $self       = shift;
	my $state      = shift;
	my $ticks      = shift;
	my $totalTicks = shift;
	my $clean      = shift;

	my $cfg         = $self->_get_cfg;
	my $hasOverflow = 0;
	my $digits      = $cfg->get_digits;

	# first render the left part, but show overflow if it gets too large
	#
	my $l = sprintf("%.*u", $digits, $ticks);
	if (length($l) > $digits)
	{
		$l           = $self->{$ATTR_overflow};
		$hasOverflow = 1;
	}

	my $delim = '';
	my $r     = '';

	if ($cfg->get_showTotal)
	{
		# now render the right part, and watch for overflow
		#
		$r = defined($totalTicks) ? sprintf("%.*u", $digits, $totalTicks) : $self->{$ATTR_unknown};
		if (length($r) > $digits)
		{
			$r           = $self->{$ATTR_overflow};
			$hasOverflow = 1;
		}

		# unless we're requested to be clean and if there was overflow, or no
		# change in the left/right parts), twirl the idle sequence
		#
		$delim = $cfg->get_delimiter;
		if ($state != STATE_DONE)
		{
			if (!$clean && ($hasOverflow || ($l eq $self->{$ATTR_lastLeft} && $r eq $self->{$ATTR_lastRight})))
			{
				my $seq = $cfg->get_idleDelimiterSequence;
				$delim = $seq->[$self->{$ATTR_index}++ % @$seq];
			}
		}
	}

	$self->{$ATTR_lastLeft}  = $l;
	$self->{$ATTR_lastRight} = $r;

	return "$l$delim$r";
}

###

package ProgressMonitor::Stringify::Fields::CounterConfiguration;

use strict;
use warnings;

# Attributes
#	digits	(integer)
#		The number of digits in the counter field (and the total)
#	delimiter (string)
#		The delimiter between counter and total
#	idleDelimiterSequence (array ref with strings)
#		The sequence of states that the delimiter should show when nothing else
#		moves (note: defining this to [<delimiter>] effectively turns off idle twirl)
#	overflowCharacter (character)
#		The character to use if the field overflows (e.g. digits are 2 and counter is 100)
#	unknownCharacter (character)
#		The character to use for the total if undef (unknown)
#	showTotal (boolean)
#		Whether total field should be shown (this includes delimiter, and if no
#		total, then no delimiter, then no idle delimiter twirl)
#
use classes
  extends => 'ProgressMonitor::Stringify::Fields::AbstractFieldConfiguration',
  attrs   => ['digits', 'delimiter', 'idleDelimiterSequence', 'overflowCharacter', 'unknownCharacter', 'showTotal'],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {
			%{$self->SUPER::defaultAttributeValues()},
			digits                => 5,
			delimiter             => '/',
			idleDelimiterSequence => ['\\', '/'],
			overflowCharacter     => '#',
			unknownCharacter      => '?',
			showTotal             => 1,
		   };
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues;

	X::Usage->throw("digits must be > 0")                   if $self->get_digits < 1;
	X::Usage->throw("overflowCharacter must have length 1") if length($self->get_overflowCharacter) != 1;
	X::Usage->throw("unknownCharacter must have length 1")  if length($self->get_unknownCharacter) != 1;
	X::Usage->throw("delimiter must have a length")         if length($self->get_delimiter) < 1;
	my $seq = $self->get_idleDelimiterSequence;
	X::Usage->throw("idleDelimiterSequence must be an array") unless ref($seq) eq 'ARRAY';
	my $len = length($self->get_delimiter);
	for (@$seq)
	{
		X::Usage->throw("all idleDelimiterSequence elements must have same length as delimiter") if length($_) != $len;
	}

	return;
}

############################

=head1 NAME

ProgressMonitor::Stringify::Field::Counter - a field implementation that renders progress
as a counter.

=head1 SYNOPSIS

  # call someTask and give it a monitor to call us back
  #
  my $counter = ProgressMonitor::Stringify::Fields::Counter->new;
  someTask(ProgressMonitor::Stringify::ToStream->new({fields => [ $counter ]});

=head1 DESCRIPTION

This is a fixed size field representing progress as a counter with or without the total
displayed alongside, e.g. '00512/03000' meaning 512 ticks completed out of 3000.

Inherits from ProgressMonitor::Stringify::Fields::AbstractField.

=head1 METHODS

=over 2

=item new( $hashRef )

Configuration data:

=over 2

=item digits (default => 5)

The number of digits it should use. With the default it can thus indicate up 
to '99999'. Values above that will be printed using the overflow character.

=item delimiter (default => '/')

The delimiter string between the current and total values.

=item idleDelimiterSequence (default => ['\\', '/'])

When progress is made but with tick count not advancing, this sequence is used
to show that something is happening. It should be a list of strings with each string
having the same length as the delimiter. As idle work is done, the sequence will 
be stepped through, but immediately revert to the regular delimiter as soon as 
a tick is detected.

=item overflowCharacter (default => '#')  

The character to be used when the value is to large to fit using the given amount
of digits.

=item unknownCharacter (default => '?')

The character to use when the total is unknown.

=item showTotal (default => 1)

Turns on or off the total display. With no total displayed, no delimiter displayed 
and hence, no idleness shown either.

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

1;    # End of ProgressMonitor::Stringify::Fields::Counter
