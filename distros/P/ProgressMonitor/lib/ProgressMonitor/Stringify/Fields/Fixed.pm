package ProgressMonitor::Stringify::Fields::Fixed;

use warnings;
use strict;

require ProgressMonitor::Stringify::Fields::AbstractField if 0;

use classes
  extends => 'ProgressMonitor::Stringify::Fields::AbstractField',
  new     => 'new',
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

sub render
{
	my $self       = shift;
# arguments not used...
#	my $state = shift;
#	my $tick       = shift;
#	my $totalTicks = shift;
#	my $clean = shift;

	return $self->_get_cfg->get_text;
}

sub change_text
{
	my $self = shift;
	my $newText = shift;
	my $filler = shift || ' ';
	
	my $w = $self->get_width;
	$newText = substr($newText . ($filler x $w), 0, $w);

	my $cfg = $self->_get_cfg;
	my $oldText = $cfg->get_text;

	$cfg->set_text($newText);
	
	return $oldText;
}

###

package ProgressMonitor::Stringify::Fields::FixedConfiguration;

use strict;
use warnings;

# Attributes
#	text
#		Set to any text that should be rendered
#
use classes
  extends => 'ProgressMonitor::Stringify::Fields::AbstractFieldConfiguration',
  attrs   => ['text'],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {%{$self->SUPER::defaultAttributeValues()}, text => ' '};
}

############################

=head1 NAME

ProgressMonitor::Stringify::Field::Fixed - a field implementation that renders a
fixed value.

=head1 SYNOPSIS

  # call someTask and give it a monitor to call us back
  #
  my $text = ProgressMonitor::Stringify::Fields::Fixed->new({text => 'Percent complete: '});
  my $pct = ProgressMonitor::Stringify::Fields::Percentage->new;
  someTask(ProgressMonitor::Stringify::ToStream->new({fields => [ $text, $pct ]});

=head1 DESCRIPTION

This is a fixed size field rendering a fixed value. Intended for use together with
other fields in order to provide explanatory text or similar.

Inherits from ProgressMonitor::Stringify::Fields::AbstractField.

=head1 METHODS

=over 2

=item new( $hashRef )

Configuration data:

=over 2

=item text (default => ' ')

The text to display. 

=back

=back

=over 2

=item change_text( $newText, [$filler] )

Change the text to display and returns the old text.

The filler is optional, and defaults to ' ' (space), and will be used to pad the passed in text to the assigned width of the field if its shorter.
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

1;    # End of ProgressMonitor::Stringify::Fields::Fixed
