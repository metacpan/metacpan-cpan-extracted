package ProgressMonitor::Stringify::Fields::Dynamic;

use warnings;
use strict;

use ProgressMonitor::Exceptions;
require ProgressMonitor::Stringify::Fields::AbstractDynamicField if 0;

use classes
  extends  => 'ProgressMonitor::Stringify::Fields::AbstractDynamicField',
  new      => 'new',
  attrs_pr => ['rendering',],
  ;

sub new
{
	my $class = shift;
	my $cfg   = shift;

	my $self = $class->SUPER::_new($cfg, $CLASS);

	$cfg = $self->_get_cfg;

	$self->_set_width(length($cfg->get_text));

	return $self;
}

sub widthChange
{
	my $self = shift;

	my $cfg = $self->_get_cfg;

	# recompute some vars
	#
	my $w = $self->get_width;
	my $txt = $cfg->get_text;
	$self->{$ATTR_rendering} = $txt . ($cfg->get_fillCharacter x ($w - length($txt))); 	

	return;
}

sub render
{
	my $self       = shift;
# arguments not used...
#	my $state = shift;
#	my $tick       = shift;
#	my $totalTicks = shift;
#	my $clean = shift;

	return $self->{$ATTR_rendering};
}

sub change_text
{
	my $self = shift;
	my $newText = shift;

	my $w = $self->get_width;
	my $cfg = $self->_get_cfg;
	
	my $oldText = $self->{$ATTR_rendering};

	$self->{$ATTR_rendering} = substr($newText . ($cfg->get_fillCharacter x $w), 0, $w); 	
	
	return $oldText;
}

###

package ProgressMonitor::Stringify::Fields::DynamicConfiguration;

use strict;
use warnings;

# Attributes
#	text
#		Set to any text that should be rendered
#   fillCharacter
#		Set to the filler used to fill out the dynamic width
#
use classes
  extends => 'ProgressMonitor::Stringify::Fields::AbstractDynamicFieldConfiguration',
  attrs   => ['text', 'fillCharacter'],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {%{$self->SUPER::defaultAttributeValues()}, text => '', fillCharacter => ' '};
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues;

	X::Usage->throw("length of fillCharacter must have length 1")  if length($self->get_fillCharacter) != 1;

	return;
}

############################

=head1 NAME

ProgressMonitor::Stringify::Field::Dynamic - a field implementation that renders a
fixed value in a dynamic space, filling out remaining places.

=head1 SYNOPSIS

TBW

=head1 DESCRIPTION

This is a dynamic size field rendering a fixed value, but filling out to adapt to
dynamically allocated space. Intended for use together with
other fields in order to provide explanatory text or similar, while also being good overlaid
messages and give as much space as possible.

Inherits from ProgressMonitor::Stringify::Fields::AbstractField.

=head1 METHODS

=over 2

=item new( $hashRef )

Configuration data:

=over 2

=item text (default => '')

The text to display. 

=item filler (default => ' ')

The filler. 

=back

=back

=over 2

=item change_text( $newText)

Change the text to display and returns the old text.

The passed in text will be padded to the assigned width of the field if its shorter using the 'fillCharacter'.
If it's too long, it will be cut.

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

1;    # End of ProgressMonitor::Stringify::Fields::Dynamic
