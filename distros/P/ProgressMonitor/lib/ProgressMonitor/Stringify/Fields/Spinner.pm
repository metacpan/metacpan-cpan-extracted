package ProgressMonitor::Stringify::Fields::Spinner;

use warnings;
use strict;

require ProgressMonitor::Stringify::Fields::AbstractField if 0;

# Attributes:
#	index
#		Keeps track of which part of the spinner should be rendered this iteration
#
use classes
  extends  => 'ProgressMonitor::Stringify::Fields::AbstractField',
  new      => 'new',
  attrs_pr => ['index',];

sub new
{
	my $class = shift;
	my $cfg   = shift;

	my $self = $class->SUPER::_new($cfg, $CLASS);

	$cfg = $self->_get_cfg;

	$self->{$ATTR_index} = 0;
	$self->_set_width(length($cfg->get_sequence->[0]));

	return $self;
}

sub render
{
	my $self       = shift;
# arguments not used...
#	my $state = shift;
#	my $ticks      = shift;
#	my $totalTicks = shift;
#	my $clean = shift;

	my $seq = $self->_get_cfg->get_sequence;
	return $seq->[$self->{$ATTR_index}++ % @$seq];
}

###

package ProgressMonitor::Stringify::Fields::SpinnerConfiguration;

use strict;
use warnings;

# Attributes
#	sequence (array ref with strings)
#		For every rendition the next string will be printed in a round-robin
#		fashion. Note that all strings must be of equal length. Default is a single
#		character spinner, but consider ['OOO', 'XXX'] or
#		['>....', '.>...', '..>..', '...>.', '....>'] as fun variations. I'm sure you
#		can come up with others :-). And of course, ['Hello'] just devolves to
#		the same effect as the Fixed field...
#
use classes
  extends => 'ProgressMonitor::Stringify::Fields::AbstractFieldConfiguration',
  attrs   => ['sequence'],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {%{$self->SUPER::defaultAttributeValues()}, sequence => ['-', '\\', '|', '/']};
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues;

	my $seq = $self->get_sequence;
	X::Usage->throw("sequence must be an array") unless ref($seq) eq 'ARRAY';
	my $len = length($seq->[0]);
	for (@$seq)
	{
		X::Usage->throw("all sequence elements must have same length") if length($_) != $len;
	}

	return;
}

############################

=head1 NAME

ProgressMonitor::Stringify::Field::Spinner - a field implementation that renders progress
as a spinner.

=head1 SYNOPSIS

  # call someTask and give it a monitor to call us back
  #
  my $spinner = ProgressMonitor::Stringify::Fields::Spinner->new;
  someTask(ProgressMonitor::Stringify::ToStream->new({fields => [ $spinner ]});

=head1 DESCRIPTION

This is a fixed size field representing progress as sequence of strings to display while work
is progressing.

Inherits from ProgressMonitor::Stringify::Fields::AbstractField.

=head1 METHODS

=over 2

=item new( $hashRef )

Configuration data:

=over 2

=item sequence (default => ['-', '\\', '|', '/'])

The sequence of strings to alternate between. All strings must be of the same length.

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

1;    # End of ProgressMonitor::Stringify::Fields::Spinner
