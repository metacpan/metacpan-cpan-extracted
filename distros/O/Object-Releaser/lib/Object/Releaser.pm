package Object::Releaser;
use strict;

# debugging tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# version
our $VERSION = '0.12';

=head1 NAME

Object::Releaser -- Remove properties from an object when the releaser goes out of scope.

=head1 SYNOPSIS

Remove all hash reference elements:

 $object = {a=>1, b=>2, c=>3};
 $releaser = Object::Releaser->new($object);
 undef $releaser;
 # object still exists but has no elements

Remove only hash reference elements a and b:

 $object = {a=>1, b=>2, c=>3};
 $releaser = Object::Releaser->new($object);
 $releaser->set_keys(qw{a b});
 undef $releaser;
 # object has element c but not a and b

Cancel the release, don't release anything:

 $object = {a=>1, b=>2, c=>3};
 $releaser = Object::Releaser->new($object);
 $releaser->dismiss();
 undef $releaser;
 # object is not changed

=head1 DESCRIPTION

Object::Releaser provides the ability to delete all or some of the elements
from a hash reference when the releaser goes out of scope.  This is done by
creating the releaser, passing in the object to be released as the sole
argument:

 $releaser = Object::Releaser->new($object);

When $releaser goes out of scope, all elements in $object are deleted.

If you only want specific elements deleted, set those elements with
$releaser->set_keys().  So, for example, the following lines set the releaser
to delete elements a and b from the object, but not any other elements:

 $releaser = Object::Releaser->new($object);
 $releaser->set_keys(qw{a b});

=head1 ALTERNATIVES

Object::Destroyer provides very similar functionality.  It provides for more
complex situations and has greater flexibility.  Object::Releaser fulfills one
simple function: deleting elements from a hashref.

If you just want to avoid circular references, you might want to use weaken in
the Scalar::Util module (which is built into Perl as of version 5.6.0).

=head1 INSTALLATION

Array::OneOf can be installed with the usual routine:

 perl Makefile.PL
 make
 make test
 make install

=head1 METHODS

=cut



#------------------------------------------------------------------------------
# new
#

=head2 new

Creates an Object::Releaser object. The single argument is the object to be
released when $releaser goes out of scope:

 $releaser = Object::Releaser->new($object);

If you do nothing else, then all elements in $object will be deleted when
$releaser goes out of scope.

=cut

sub new {
	my ($class, $object) = @_;
	my $releaser = bless {}, $class;
	
	# store object
	$releaser->{'object'} = $object;
	
	# return
	return $releaser;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# set_keys
#

=head2 set_keys

Tells the releaser to only delete specified keys from the object.  For example,
the code:

 $releaser->set_keys(qw{a b});

sets the releaser so that only elements C<a> and C<b> are deleted.

=cut

sub set_keys {
	my ($releaser, @keys) = @_;
	$releaser->{'keys'} = \@keys;
}
#
# set_keys
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# delete_all
#

=head2 delete_all

C<delete_all> does the opposite of C<set_keys>: it sets the releaser to delete
all keys from the target object.  Use C<delete_all> if you previously used
C<set_keys> to set deletion for specific keys, but now want to go back to
deleting all keys:

 $releaser = Object::Releaser->new($object);
 $releaser->set_keys(qw{a b});
 $releaser->delete_all();

=cut

sub delete_all {
	my ($releaser) = @_;
	delete $releaser->{'keys'};
}
#
# delete_all
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# dismiss
#
sub dismiss {
	my ($releaser, $dismiss) = @_;
	
	# if $dismiss is defined, use that value
	if (defined $dismiss)
		{ $releaser->{'dismiss'} = $dismiss }
	
	# else set to true
	else
		{ $releaser->{'dismiss'} = 1 }
	
	# return
	return $releaser->{'dismiss'};
}
#
# dismiss
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# DESTROY
#
sub DESTROY {
	my ($releaser) = @_;
	my $object = $releaser->{'object'};
	
	# if no object, return
	$object or return;
	
	# if dismissed, return
	if ($releaser->{'dismiss'})
		{ return }
	
	# if keys are defined, delete only those keys
	if ($releaser->{'keys'}) {
		foreach my $key (@{$releaser->{'keys'}})
			{ delete $object->{$key} }
	}
	
	# else release all properties
	else {
		foreach my $key (keys %$object)
			{ delete $object->{$key} }
	}
}
#
# DESTROY
#------------------------------------------------------------------------------



# return true
1;

__END__

=head1 TERMS AND CONDITIONS

Copyright (c) 2013 by Miko O'Sullivan.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>


=head1 VERSION

=over

=item Version 0.10    February 17, 2013

Initial release

=item Version 0.11    February 21, 2013

Fixed bug: incorrect number of test in test plan.

=item Version 0.12    April 25, 2014

Fixed error in META.yml.


=back

=cut