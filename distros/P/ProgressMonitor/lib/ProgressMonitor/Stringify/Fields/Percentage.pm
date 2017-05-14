package ProgressMonitor::Stringify::Fields::Percentage;

use warnings;
use strict;

use constant PERCENT       => '%';
use constant DECIMAL_POINT => '.';

require ProgressMonitor::Stringify::Fields::AbstractField if 0;

# Attributes:
#	unknown
#		Precomputed string when total is undef (unknown)
#
use classes
  extends  => 'ProgressMonitor::Stringify::Fields::AbstractField',
  new      => 'new',
  attrs_pr => ['unknown'];

sub new
{
	my $class = shift;
	my $cfg   = shift;

	my $self = $class->SUPER::_new($cfg, $CLASS);

	$cfg = $self->_get_cfg;

	my $dec = $cfg->get_decimals;
	$self->_set_width(3 + ($dec ? 1 : 0) + $dec + 1);

	$self->{$ATTR_unknown} =
	  $cfg->get_unknownCharacter x 3 . ($dec ? DECIMAL_POINT : '') . ($dec ? $cfg->get_unknownCharacter x $dec : '') . PERCENT;

	return $self;
}

sub render
{
	my $self       = shift;
	my $state      = shift;
	my $ticks      = shift;
	my $totalTicks = shift;
	my $clean      = shift;

	return $self->{$ATTR_unknown} unless defined($totalTicks);

	my $cfg       = $self->_get_cfg;
	my $dec       = $cfg->get_decimals;
	my $pct       = defined($totalTicks) && $totalTicks > 0 ? ($ticks / $totalTicks) * 100 : 0;
	my $rendition = $dec ? sprintf("%*.*f%s", 4 + $dec, $dec, $pct, PERCENT) : sprintf("%3u%s", int($pct), PERCENT);
	my $fc        = $cfg->get_fillCharacter;
	$rendition =~ s/ /$fc/g;

	return $rendition;
}

###

package ProgressMonitor::Stringify::Fields::PercentageConfiguration;

use strict;
use warnings;

# Attributes
#	decimals
#		The number of decimals on the percentage
#	unknownCharacter
#		The character to use when the total is unknown
#	fillCharacter
#		The character to use instead of a space (i.e. ' 50%' vs '100%')
#
use classes
  extends => 'ProgressMonitor::Stringify::Fields::AbstractFieldConfiguration',
  attrs   => ['decimals', 'unknownCharacter', 'fillCharacter'],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {
			%{$self->SUPER::defaultAttributeValues()},
			decimals         => 2,
			unknownCharacter => '?',
			fillCharacter    => ' ',
		   };
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues;

	X::Usage->throw("decimals can not be negative")        if $self->get_decimals < 0;
	X::Usage->throw("unknownCharacter must have length 1") if length($self->get_unknownCharacter) != 1;
	X::Usage->throw("fillCharacter must have length 1")    if length($self->get_fillCharacter) != 1;

	return;
}

############################

=head1 NAME

ProgressMonitor::Stringify::Field::Percentage - a field implementation that
renders progress as a percentage.

=head1 SYNOPSIS

  # call someTask and give it a monitor to call us back
  #
  my $pct = ProgressMonitor::Stringify::Fields::Percentage->new;
  someTask(ProgressMonitor::Stringify::ToStream->new({fields => [ $pct ]});

=head1 DESCRIPTION

This is a fixed size field representing progress as a percentage, e.g. ' 52.34 %'.

Inherits from ProgressMonitor::Stringify::Fields::AbstractField.

=head1 METHODS

=over 2

=item new( $hashRef )

Configuration data:

=over 2

=item decimals (default => 2)

The number of decimals on the percentage.

=item unknownCharacter (default => '?')

The character to use when the total is unknown.

=item fillCharacter (default => ' ')

The character to use for the space reserved for the 10 & 100 location when they are still 0. 

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

1;    # End of ProgressMonitor::Stringify::Fields::Percentage
