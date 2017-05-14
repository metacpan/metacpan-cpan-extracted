package ProgressMonitor::Stringify::Fields::AbstractDynamicField;

use warnings;
use strict;

require ProgressMonitor::Stringify::Fields::AbstractField if 0;

use classes
  extends => 'ProgressMonitor::Stringify::Fields::AbstractField',
  methods => {grabExtraWidth => 'grabExtraWidth', widthChange => 'ABSTRACT'},
  ;

sub isDynamic
{
	my $self = shift;

	# we're only dynamic if the stated maxWidth is greater than our current width
	#
	return $self->get_width < $self->_get_cfg->get_maxWidth;
}

sub grabExtraWidth
{
	my $self       = shift;
	my $extraWidth = shift;

	my $cfg = $self->_get_cfg;

	# take as much width we can from the given one, but respect the max
	#
	my $width    = $self->get_width;
	my $maxWidth = $cfg->get_maxWidth;
	while ($extraWidth && $width < $maxWidth)
	{
		$width++;
		$extraWidth--;
	}

	$self->_set_width($width);

	return $extraWidth;
}

### PROTECTED

# override the width setter, and notify that the width has been changed
#
sub _set_width
{
	my $self = shift;

	$self->SUPER::_set_width(@_);

	$self->widthChange;
	
	return;
}

###

package ProgressMonitor::Stringify::Fields::AbstractDynamicFieldConfiguration;

use strict;
use warnings;

# Attributes:
#	minWidth
# 		The minimum width the field should use. This may however be too small
# 		for the fields 'minimum computed width' which can depend on many other
#		settings and thus this value is raised as needed.
#	maxWidth
#		The maximum width the field should use, regardless if it is given more.
#		Defaults to a very large value
#
use classes
  extends => 'ProgressMonitor::Stringify::Fields::AbstractFieldConfiguration',
  attrs   => ['minWidth', 'maxWidth',],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {
			%{$self->SUPER::defaultAttributeValues()},
			minWidth => 0,
			maxWidth => 1 << 31,
		   };
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues;

	my $minWidth = $self->get_minWidth;
	X::Usage->throw("minWidth must be positive")                     if $minWidth < 0;
	X::Usage->throw("maxWidth must be greater or equal to minWidth") if $self->get_maxWidth < $minWidth;

	return;
}

############################

=head1 NAME

ProgressMonitor::Stringify::Fields::AbstractDynamicField - A reusable/abstract
dynamic field implementation for stringify progress.

=head1 DESCRIPTION

Inherits from ProgressMonitor::Stringify::Fields::AbstractField. See that for more
information; this class signals participation in the dynamic width negotiation
protocol as utilized by ProgressMonitor::Stringify::AbstractMonitor and subclasses.

Inherit from this class if you wish to dynamically adjust your field width to grab
as much as possible.

=head1 METHODS

=over 2

=item grabExtraWidth( $extraWidth )

Called with extra width available. Consume all or part of this by updating the
inherited width attribute and return the width not used.

This method may be called multiple times in order to fairly distribute extra width
across several dynamic fields

=item isDynamic

Returns true as long as the current width is less than maxWidth.

=item widthChange

Notification that the width has changed, thus giving the field a chance to recompute
some of its attributes as needed.

=back

=head1 PROTECTED METHODS

=over 2

=item _new( $hashRef, $package )

The constructor, needs to be called by subclasses.

Configuration data:

=over 2

=item minWidth (default => 0)

The minimum width this field should use.

=item maxWidth

The maximum width this field should use.

=back

=item _set_width( $newWidth )

Calls SUPER and then widthChange.

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

1;    # End of ProgressMonitor::Stringify::Fields::AbstractDynamicField
