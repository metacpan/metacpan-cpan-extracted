#!/usr/bin/perl -w

=head1 NAME

Quizzer::Base - Quizzer Base Class

=cut

=head1 DESCRIPTION

Objects of this class may have any number of properties. These properties can
be read by calling the method with the same name as the property. If a
parameter is passed into the method, the property is set.

Properties can be made up and used on the fly; I don't care what you call
them.

Something similar to this should be a generic perl object in the base perl
distribution, since this is the most simple type of perl object. Until it is,
I'll use this. (Sigh)

=cut

package Quizzer::Base;
use strict;
use vars qw($AUTOLOAD);

my $VERSION='0.01';

=head2 new

Returns a new object of this class.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	bless ($self, $class);
	return $self;
}

=head2 any_other_method

Set/get a property.

=cut

sub AUTOLOAD {
	my $this=shift;
	my $property = $AUTOLOAD;
	$property =~ s|.*:||; # strip fully-qualified portion
	
	$this->{$property}=shift if @_;
	return $this->{$property};
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
