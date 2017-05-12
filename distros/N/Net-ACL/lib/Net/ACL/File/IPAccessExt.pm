#!/usr/bin/perl

# $Id: IPAccessExt.pm,v 1.11 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::File::IPAccessExtRule;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance ##

@ISA     = qw( Net::ACL::IPAccessExtRule );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::IPAccessExtRule qw( :index );
use Carp;

## Public Object Methods ##

sub asconfig
{ # Don't check data - expect them to be constructed the right way!
 my $this = shift;
 my ($proto,$from,$to) = ('n/a','n/a','n/a');
 foreach my $match (@{$this->{_match}})
  {
   if ($match->index == ACL_EIA_PROTO)
    {
     $proto = $match->value;
    }
   elsif ($match->index == ACL_EIA_FROM)
    {
     $from = $this->_getaddr($match->net);
    }
   elsif ($match->index == ACL_EIA_TO)
    {
     $to = $this->_getaddr($match->net);
    };
  };
 return ' ' . $this->action_str . " $proto $from $to\n";
}

## Private object methods ##

sub _getaddr
{
 my ($this,$net) = @_;
 return defined $net
	? ($net->bits == 32
		? 'host ' . $net->base
		: ($net->bits == 0
			? 'any'
			: $net->base . ' ' . $net->hostmask))
	: '';
}

## End of Net::ACL::File::IPAccessExtRule ##

package Net::ACL::File::IPAccessExt;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance ##

@ISA     = qw( Net::ACL::File::Standard );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::File::Standard;
use Net::ACL::IPAccessExtRule qw( :index );
use Carp;

## Net::ACL::File Class Auto Registration Code ##

Net::ACL::File->add_listtype('extended-access-list',__PACKAGE__,'ip access-list extended');

## Public Object Methods ##

sub loadmatch
{
 my ($this,$lines,$super) = @_;

 $lines = $lines->subs ? $lines->subs : $lines;

 foreach my $line ($lines =~ /\n./ ? $lines->all : $lines)
  {
   $line =~ s/ +/ /g;
   croak "Configuration line format error in line: '$line'"
	unless $line =~ /^ (permit|deny) ([^ ]+) (.*)$/i;
   my ($action,$proto,$data) = ($1,$2,$3);
   $data =~ s/^ //;
   my @data = split(/ /,$data);
   my $from = shift(@data);
   if ($from eq 'host')
    {
     $from = shift(@data);
    }
   else
    {
     $from .= ' ' . shift(@data) unless ($from eq 'any');
    };
   my $to = shift(@data);
   if ($to eq 'host')
    {
     $to = shift(@data);
    }
   else
    {
     $to .= ' ' . shift(@data) unless ($to eq 'any');
    };
   $to =~ s/ /#/;
   $from =~ s/ /#/;
   my $rule = new Net::ACL::File::IPAccessExtRule(
	Action	=> $action
	);
   $rule->add_match($rule->autoconstruction('Match','Net::ACL::Match::Scalar','Scalar',ACL_EIA_PROTO,$proto));
   $rule->add_match($rule->autoconstruction('Match','Net::ACL::Match::IP','IP',ACL_EIA_FROM,$from));
   $rule->add_match($rule->autoconstruction('Match','Net::ACL::Match::IP','IP',ACL_EIA_TO,$to));
   $this->add_rule($rule);
   $this->name($1)
	if ! defined($this->name)
	 && $super =~ /ip access-list extended (.*)$/;
  }
}

sub asconfig
{
 my $this = shift;
 return "ip access-list extended " . $this->name . "\n" . $this->SUPER::asconfig(@_) . "!\n";
}

## POD ##

=pod

=head1 NAME

Net::ACL::File::IPAccessExt - Extended IP access-lists loaded from configuration string.

=head1 DESCRIPTION

This module extends the Net::ACL::File::Standard class to handle
community-lists. See L<Net::ACL::File::Standard|Net::ACL::File::Standard> for
details.

=head1 SEE ALSO

Net::ACL, Net::ACL::File, Net::ACL::Standard, Net::ACL::IPAccessExtRule

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End of Net::ACL::File::IPAccessExt ##

1;
