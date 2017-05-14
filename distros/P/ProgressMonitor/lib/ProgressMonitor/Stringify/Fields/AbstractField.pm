package ProgressMonitor::Stringify::Fields::AbstractField;

use warnings;
use strict;

# Attributes:
#	width
#		The width the field will use at this point. Note that dynamic fields will
#		adjust this value as they get more width
#	cfg
#		The configuration object
#
use classes
  new           => 'ABSTRACT',
  class_methods => ['_new'],
  methods       => {
			  isDynamic => 'isDynamic',
			  render    => 'ABSTRACT',
			 },
  attrs_ro => ['width',],
  attrs_pr => ['cfg'],
  ;

sub isDynamic
{
	# by default, fields are fixed
	#
	return 0;
}

### PROTECTED

sub _set_width
{
	my $self = shift;
	my $w    = shift;

	$self->{$ATTR_width} = $w;

	return;
}

# protected ctor
#
sub _new
{
	my $self   = classes::new_only(shift);
	my $cfg    = shift;
	my $cfgPkg = shift;

	# make sure we have a cfg object
	#
	$self->{$ATTR_cfg} = ProgressMonitor::AbstractConfiguration::ensureCfgObject($cfg, $cfgPkg);

	# initialize the rest
	#
	$self->{$ATTR_width} = 0;

	return $self;
}

sub _get_cfg
{
	my $self = shift;

	return $self->{$ATTR_cfg};
}

###

package ProgressMonitor::Stringify::Fields::AbstractFieldConfiguration;

use strict;
use warnings;

require ProgressMonitor::AbstractConfiguration if 0;

# declare the configuration class for the above class, this is just a starting
# point to derive from as needed
#
use classes
  extends => 'ProgressMonitor::AbstractConfiguration',
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {%{$self->SUPER::defaultAttributeValues()},};
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues;

	return;
}

############################

=head1 NAME

ProgressMonitor::Stringify::Fields::AbstractField - A reusable/abstract field
implementation for stringify progress.

=head1 SYNOPSIS

  ...
  use classes
    extends  => 'ProgressMonitor::Stringify::Fields::AbstractField',
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

This class is a base class for fields for stringified feedback.

When extended it provides some accessors for 'protected' data, i.e. only for
the use of subclasses. These accessors are prefixed with '_'.

Subclassing this normally entails only defining the render method.

=head1 METHODS

=over 2

=item render( $ticks, $totalTicks )

Called with the current tick count, and the total tick count. Should return 
with an appropriate string corresponding to the tick vs totalTick values.

This implementation is abstract, must be reimplemented.

=item isDynamic

Should return true if the field is dynamic. Automatically handled by inheriting
from the AbstractDynamicField.

=back

=head1 PROTECTED METHODS

=over 2

=item _new( $hashRef, $package )

The constructor, needs to be called by subclasses.

Configuration data:
  (none)

=item _get_cfg

Returns the configuration object.

=item _set_width

Set the width of the field.

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

1;    # End of ProgressMonitor::Stringify::Fields::AbstractField
