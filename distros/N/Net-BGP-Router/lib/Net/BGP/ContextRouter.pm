#!/usr/bin/perl

# $Id: ContextRouter.pm,v 1.3 2003/06/02 11:58:05 unimlo Exp $

package Net::BGP::ContextRouter;


use strict;
use Carp;
use vars qw( $VERSION );

## Inheritance and Versioning ##

$VERSION = '0.04';

use Net::BGP::Router;

sub new
{
 my $proto = shift || __PACKAGE__;
 my $class = ref $proto || $proto;

 my $this = {
	_contexts     => {}
    };

 while ( defined(my $arg = shift) )
  {
   my $value = shift;
   croak "unrecognized argument $arg\n";
  };

 bless($this, $class);
 return $this;
}

sub context
{
 my ($this,$context) = @_;
 $this->{_contexts}->{$context} = new Net::BGP::Router(Name => $context)
   unless defined($this->{_contexts}->{$context});
 return $this->{_contexts}->{$context};
}

sub add_peer
{
 my ($this,$context,$peer,$dir,$acl) = @_;
 $this->context($context)->add_peer($peer,$dir,$acl);
}

sub remove_peer
{
 my ($this,$context,@args) = @_;
 $this->context($context)->remove_peer(@args);
}

sub set_policy
{
 my ($this,$context,@args) = @_;
 $this->context($context)->set_policy(@args);
}

sub remove_context
{
 my ($this,$context) = @_;
 delete $this->{_context}->{$context};
}

=pod

=head1 NAME

Net::BGP::ContextRouter - A Multiple Context BGP Router

=head1 SYNOPSIS

    use Net::BGP::ContextRouter;

    # Constructor
    $crouter = new Net::BGP::ContextRouter();

    # Accessor Methods
    $router = $crouter->context($context);

    $crouter->add_peer($context,$peer,'both',$acl);
    $crouter->remove_peer($context,$peer,'both');
    $crouter->set_policy($context,$policy);
    $crouter->set_policy($context,$peer,'in',$acl);


=head1 DESCRIPTION

This module implements a multiple-context BGP router using the 
L<Net::BGP::Router|Net::BGP::Router> object.

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::BGP::ContextRouter object

    $router = new Net::BGP::ContextRouter();

This is the constructor for Net::BGP::ContextRouter object. It returns a
reference to the newly created object. No arguments are allowed.

=back

=head1 ACCESSOR METHODS

=over 4

=item context()

Return a given context. If the context doesn't exist, it will be created.
The argument is the name of the context. The Net::BGP::Router object
representing the context is returned.

=item add_peer()

=item remove_peer()

=item set_policy()

Just like Net::BGP::Router->add_peer() but with the context name as the first
argument.

=back

=head1 SEE ALSO

Net::BGP::Router, Net::BGP, Net::BGP::Policy

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End of Net::BGP::ContextRouter ##

1;
