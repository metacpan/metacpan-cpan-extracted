# -*- mode: perl; -*-
#
# Base object for the Gnumeric spreadsheet reader.
#
# Documentation below "__END__".
#
# [created.  -- rgr, 6-Feb-23.]
#

package Spreadsheet::Gnumeric::Base;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.2';

sub define_instance_accessors {
    my ($class, @accessors) = @_;

    no strict 'refs';
    for my $method (@accessors) {
	my $field = '_' . $method;
	*{$class . '::' . $method} = sub {
	    my $self = shift;
	    @_ ? $self->{$field} = shift : $self->{$field};
	};
    }
}

sub new {
    my ($class, @options) = @_;

    my $self = bless({ }, $class);
    while (@options) {
	my ($slot, $value) = (shift(@options), shift(@options));
	$self->$slot($value)
	    if $self->can($slot);
    }
    return $self;
}

1;

__END__

=head1 Gnumeric::Base

Base object class for representing Gnumeric objects.

=head2 Accessors and methods

=head3 define_instance_accessors

Class method, given a list of accessor names, defines a method for
each that accesses the instance slot if called without arguments and
sets the slot if called with a single argument.  This should be
invoked in a BEGIN block near the top of the subclass definition, so
that Perl knows that these methods are defined.

=head3 new

Constructs a new object instance by blessing an empty hashref with the
initial class arg, then treating the remaining arguments as
keyword/value slot initializers, sending the first value of each pair
as the method with the second value as its argument if the new object
handles the method.

=head1 AUTHOR

Bob Rogers C<< <rogers@rgrjr.com> >>

=cut
