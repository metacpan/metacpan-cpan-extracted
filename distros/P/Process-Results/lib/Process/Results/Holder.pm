package Process::Results::Holder;
use strict;

# debug tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# version
our $VERSION = '0.2';


#------------------------------------------------------------------------------
# pod
#

=head1 NAME

Process::Results::Holder - methods for objects that hold Process::Results
objects.

=head1 SYNOPSIS

 package MyClass;
 use strict;
 use base 'Process::Results::Holder';
 
 my $object = MyClass->new
 my $results = MyClass->results;
 
 $object->error('error-id')

=head1 OVERVIEW

It's often convenient for an object to hold a Process::Results object.
Process::Results::Holder provides methods for handling a contained results
object. To add these methods to your class, simply extend
Process::Results::Holder:

 use base 'Process::Results::Holder';

The methods that are added to your class assume that you have or will put a
results object in the 'results' property of the object.

=head1 METHODS

=cut

#
# pod
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# results
#

=head2 results()

C<results()> returns the Process::Results object that is held by the holder.

 $results = $object->results();

If the results object exists in the 'results' property:

 $object->{'results'}

then it is returned. If it does not exist, then one is created, stored in the
'results' object, then returned.

=cut

sub results {
	my ($holder, %opts) = @_;
	
	# TESTING
	# println subname(); ##i
	
	# create object if necessary
	if (! $holder->{'results'}) {
		$holder->{'results'} = $holder->results_class->new();
	}
	
	# return
	return $holder->{'results'};
}
#
# results
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# messages
#

=head2 error(), warning(), note()

These methods do that same thing as their Process::Results counterparts: they
store messages in the results object. If the results object doesn't exist, it
is created.

=cut

sub error {
	my $holder = shift;
	return $holder->results->error(@_);
}

sub warning {
	my $holder = shift;
	return $holder->results->warning(@_);
}

sub note {
	my $holder = shift;
	return $holder->results->note(@_);
}
#
# messages
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# results_class
#

=head2 results_class()

This method returns the class name to use to create the results object. By
default it returns 'Process::Results'. Override this class if you would like
to use a custom results class.

=cut

sub results_class {
	return 'Process::Results';
}
#
# results_class
#------------------------------------------------------------------------------



# return
1;

__END__


#------------------------------------------------------------------------------
# closing pod
#

=head1 TERMS AND CONDITIONS

Copyright (c) 2016 by Miko O'Sullivan. All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. This software comes with NO WARRANTY of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>

=head1 VERSION

Version: 0.01

=head1 HISTORY

=over

=item * Version 0.02 Aug 15, 2016

Adding Process::Results::Holder to Process::Results.

=back

=cut

#
# closing pod
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# module info
# This info is used by a home-grown CPAN module builder. This info has no use
# in the wild.
#
{
	# include in CPAN distribution
	include : 1,
}
#
# module info
#------------------------------------------------------------------------------
