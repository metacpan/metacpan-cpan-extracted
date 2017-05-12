#!/usr/bin/perl

# $Id: Prefix.pm,v 1.9 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::Match::Prefix;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance and Versioning ##

@ISA     = qw( Net::ACL::Match::IP );
$VERSION = '0.07';

## Module Imports ##

use Carp;
use Net::ACL::Match::IP;
use Net::ACL::Rule qw( :rc );
use Scalar::Util qw(blessed);
use Net::Netmask;

## Public Class Methods ##

sub new
{
 my $proto = shift;
 my $class = ref $proto || $proto;
 my $size;
 my $mode = 0;
 my @arg = @_;
 if ($arg[$#arg] =~ s/\W*([gl]e)\W+(\d+)$//i)
  {
   $mode = lc($1);
   $size = $2;
   pop(@arg) if $arg[$#arg] eq '';
  };
 # How to do this with out hardcoding name? This doesn't work!
 # my $this = SUPER::new(@arg);
 my $this = new Net::ACL::Match::IP(@arg);
 $this->{_size} = $size;
 $this->{_mode} = $mode;
 return bless($this,$class);
};

## Public Object Methods ##

sub match
{
 my $this = shift;
 my $other = $_[$this->index];
 $other = (blessed $other && $other->isa('Net::Netmask')) ? $other : new Net::Netmask($other);

 unless ($this->{_mode})
  { # Normal mode of operation!
   return ($this->{_net}->base eq $other->base)
     && ($this->{_net}->bits == $other->bits) ? ACL_MATCH : ACL_NOMATCH;
  };
 return ACL_NOMATCH unless $this->{_net}->match($other->base); # Not within!
 return ACL_NOMATCH if $this->{_net}->bits > $other->bits; # Larger then this!
 return ACL_MATCH if $this->{_size} == $other->bits; # Right size!
 return ($this->{_size} < $other->bits) == ($this->{_mode} eq 'ge') ? ACL_MATCH : ACL_NOMATCH;
}

sub mode
{
 my $this = shift;
 $this->{_mode} = @_ ? (shift =~ /([lg]e)/ ? $1 : 0) : $this->{_mode};
 return $this->{_mode};
}

sub size
{
 my $this = shift;
 $this->{_size} = @_ ? shift : $this->{_size};
 return $this->{_size};
}

## POD ##

=pod

=head1 NAME

Net::ACL::Match::Prefix - Class matching IP network prefixes.

=head1 SYNOPSIS

    use Net::ACL::Match::Prefix;

    # Constructor
    $match = new Net::ACL::Match::Prefix('10.0.0.0/8');
    $match = new Net::ACL::Match::Prefix('10.0.0.0/8 ge 25');

    # Accessor Methods
    $rc = $match->match('10.0.0.0/16'); # ACL_NOMATCH
    $rc = $match->match('127.0.0.0/8'); # ACL_NOMATCH
    $rc = $match->match('10.0.0.0/8');  # ACL_MATCH

=head1 DESCRIPTION

This module is just a wrapper of the Net::Netmask module to allow it to
operate automatically with L<Net::ACL::Rule|Net::ACL::Rule>.

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::ACL::Match::Prefix object

    $match = new Net::ACL::Match::Prefix(0,'10.0.0.0/8');

This is the constructor for Net::ACL::Match::Prefix objects. It returns a
reference to the newly created object. The first argument is the argument
number of the match function that should be matched.

Normally the remaining arguments is parsed directly to the constructor of
Net::Netmask. However if the last argument matches /(le|ge) \d+$/, the suffix
will be removed before the Net::Netmask constructor is called and the digits
will be used only allow prefixes greater then or equal (ge) OR less then or
equal (le) then that prefix length to match.

=back

=head1 ACCESSOR METHODS

=over 4

=item match()

The method uses Net::Netmask to verify that the base address and the size of
the prefixes are the same.

=item mode()

This method returns the mode of the prefix match object. The mode could be
either 0 (normal), C<le> for less then or equal compare, or C<ge> for
greater then or equal compare. If called with a value, the mode is
changed to that value.

=item size()

This method returns the size of the prefix to be matched if mode is C<le> or
C<ge>. If called with a value, the size is changed to that value.

=back

=head1 EXAMPLES

     my $norm = new Net::ACL::Match::Prefix(0,'10.0.0.0/8');
     my $ge24 = new Net::ACL::Match::Prefix(0,'10.0.0.0/8 ge 24');
     my $le24 = new Net::ACL::Match::Prefix(0,'10.0.0.0/8 1e 24');

     $norm->match('10.0.0.0/8')  == ACL_MATCH
     $ge24->match('10.0.0.0/8')  == ACL_MATCH
     $le24->match('10.0.0.0/8')  == ACL_MATCH
     $norm->match('10.1.0.0/16') == ACL_NOMATCH
     $ge24->match('10.1.0.0/16') == ACL_MATCH
     $le24->match('10.1.0.0/16') == ACL_MATCH

=head1 SEE ALSO

Net::Netmask, Net::ACL,
Net::ACL::Rule, Net::ACL::Match::IP, Net::ACL::Match

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::Match::Prefix ##
 
1;
