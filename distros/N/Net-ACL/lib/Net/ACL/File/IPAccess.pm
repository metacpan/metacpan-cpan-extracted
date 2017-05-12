#!/usr/bin/perl

# $Id: IPAccess.pm,v 1.10 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::File::IPAccessRule;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance ##

@ISA     = qw( Net::ACL::Rule );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::Rule;
use Carp;

## Public Object Methods ##

sub asconfig
{ # Don't check data - expect them to be constructed the right way!
 my $this = shift;
 my $name = shift;
 my $match = $this->{_match}->[0];
 my $net = $match->net if defined $match;
 my $str = '';
 $str = $net->base if defined $net;
 $str .= ' ' . $net->hostmask if defined $net && $net->bits != 32;
 $str = 'any' if defined $net && $net->bits == 0;
 return 'access-list ' . $name . ' ' . $this->action_str . ($str eq '' ? '' : ' ' . $str) . "\n";
}

## End of Net::ACL::File::IPAccessRule ##

package Net::ACL::File::IPAccess;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance ##

@ISA     = qw( Net::ACL::File::Standard );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::File::Standard;
use Carp;

## Net::ACL::File Class Auto Registration Code ##

Net::ACL::File->add_listtype('access-list',__PACKAGE__,'access-list');

## Public Object Methods ##

sub loadmatch
{
 my ($this,$lines) = @_;

 foreach my $line ($lines =~ /\n./ ? $lines->all : $lines) # For some reasons we got more then one!
  {
   $line =~ s/ +/ /g;
   next if $line =~ /^access-list (\d{3}) /i;
   croak "Configuration line format error in line: '$line'"
	unless $line =~ /^access-list ([^ ]+) (permit|deny)(.*)$/i;
   my ($name,$action,$data) = ($1,$2,$3);
   $data =~ s/^ //;
   $data =~ s/ /#/;
   my $rule = new Net::ACL::File::IPAccessRule(
	Action	=> $action
	);
   $rule->add_match($rule->autoconstruction('Match','Net::ACL::Match::IP','IP',0,$data));
   $this->add_rule($rule);
   $this->name($name);
  };
}

## POD ##

=pod

=head1 NAME

Net::ACL::File::IPAccess - IP access-lists loaded from configuration string.

=head1 DESCRIPTION

This module extends the Net::ACL::File::Standard class to handle
community-lists. See L<Net::ACL::File::Standard|Net::ACL::File::Standard> for
details.

=head1 SEE ALSO

Net::ACL, Net::ACL::File, Net::ACL::Standard

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End of Net::ACL::File::IPAccess ##

1;
