package ProgressMonitor::AbstractConfiguration;

use warnings;
use strict;

use Scalar::Util qw(blessed);

# declare the class
#
use classes
  new           => 'new',
  class_methods => ['ensureCfgObject',],
  methods       => ['defaultAttributeValues', 'checkAttributeValues',],
  clone         => 'classes::clone',
  throws        => ['X::Usage',],
  ;

sub new
{
	# get an empty object
	#
	my $self = classes::new_only(shift);

	# initilize it based on the defaults, overlaid with params to us
	#
	classes::init_args($self, %{$self->defaultAttributeValues}, @_);

	# now let the object check that all is ok
	#
	$self->checkAttributeValues;

	return $self;
}

sub defaultAttributeValues
{
	# just return an empty hash
	#
	return {};
}

sub checkAttributeValues
{
	# yep, to us it looks ok! :-)
	#
	return;
}

# class method to help an incoming cfg object to be of the right sort
# as well as cloned if necessary
#
sub ensureCfgObject
{
	my $obj    = shift;
	my $cfgPkg = shift;

	# the cfg package name should always end in this...
	#
	$cfgPkg .= "Configuration";

	if (blessed($obj) && $obj->isa($cfgPkg))
	{
		# clone a passed cfg to ensure it won't change
		#
		return $obj->clone;
	}
	elsif (ref($obj) eq 'HASH' || !defined($obj))
	{
		# get a new cfg, possibly initialized by a hash
		#
		return $cfgPkg->new($obj ? %$obj : ());
	}

	X::Usage->throw("not a hash or $cfgPkg object: $obj");
}

############################

=head1 NAME

ProgressMonitor::AbstractConfiguration - a base class for all configuration objects

=head1 SYNOPSIS

    package SomeClass;

    use classes
    ...

    sub new
    {
        ...
        my $cfg = shift;

        $cfg = ProgressMonitor::AbstractConfiguration::ensureCfgObject($cfg, __PACKAGE__);

        do_something_with($cfg->get_someValue);
        ...
    }

    ...

    ###

    package SomeClassConfiguration;

    use classes
        extends => 'ProgressMonitor::AbstractConfiguration',
        attrs   => ['someValue'],
    ;

    sub defaultAttributeValues
    {
        my $self = shift;

        return {%{$self->SUPER::defaultAttributeValues()}, someValue => 42 };
    }

    sub checkAttributeValues
    {
        my $self = shift;

        $self->SUPER::checkAttributeValues();

        X::Usage->throw("someValue is not a multiple of 42") if $self->get_value % 42;

        return;
    }

=head1 DESCRIPTION

This is the base class for configuration data as used by (almost) all classes
in this package. The intent is that all 'real' classes have a parallel
configuration class where such objects holds the values used to configure the
real object.

The main reason for this strategy started out as a way to reuse some of the 
'classes' mechanisms for example with automatic getters/setters, but still not
expose such methods on the real object. This style also allows a user to create
a configuration object and pass it in to several objects - the configuration
will be cloned to avoid the user changing values (they may have been used for
calculations to set other values - changing them might invalidate such
calculations and make things hopelessly confused...).

In practice, creating configuration objects directly is uncommon (?) as the
real objects will automatically convert an anonymous hash to an object of the
right kind (naming of the class is important - add 'Configuration' to the real
class name).

To reuse, you typically only override the defaultAttributeValues and checkAttributeValues
methods.

=head1 METHODS

=over 2

=item new( value1 => data1, value2 => data2, ... )

The constructor for a configuration. Note that this method typically should be
treated as 'final' and not be overridden. 

Pass in a hash list with the values you want to set. Throws X::UnknownAttr if an unknown
attribute is passed or X::Usage if a value is deemed incorrect. 

=item defaultAttributeValues

Takes no arguments, should return a hash reference with results from calling SUPER
overlaid with default values for your attributes (and possibly for the SUPER values
if desired).

=item checkAttributeValues

The implementation of this should check that the values for the attributes are
'correct', whatever that entails for your object.

In case of incorrectness, throw X::Usage with a relevant message.

=item ensureCfgObject( $hashRefOrCfgObject, $packageName)

This is a static helper method typically called from the contructor of the 'real'
object and will ensure a hash ref is converted into a configuration object or a
configuration object is properly cloned.

=back

=head1 TODO

Perhaps this class should provide a simple mechanism for storing/loading data
from/to persistence?

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

1;    # End of ProgressMonitor::AbstractConfiguration
