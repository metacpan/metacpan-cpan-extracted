#!/usr/bin/perl

# $Id: Prefix.pm,v 1.11 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::File::PrefixRule;

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
 my $str = $net->base . '/' . $net->bits if defined $net;
 my $ext = $match->mode ? ' ' . $match->mode . ' ' . $match->size : '';
 my $seq = $this->seq;
 $seq = defined $seq ? " seq $seq" : '';
 return 'ip prefix-list '.$name.$seq.' '.$this->action_str.($str eq '' ?'':" $str") . "$ext\n";
}

## End of Net::ACL::File::PrefixRule ##

package Net::ACL::File::Prefix;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance ##

@ISA     = qw( Net::ACL::File::Standard );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::File::Standard;
use Carp;

## Net::ACL::File Class Auto Registration Code ##

Net::ACL::File->add_listtype('prefix-list',__PACKAGE__,'ip prefix-list');

## Public Object Methods ##

sub loadmatch
{
 my ($this,$lines) = @_;

 foreach my $line ($lines->single ? $lines : $lines->get) # For some reasons we got more then one!
  {
   croak "Configuration line format error in line: '$line'"
	unless $line =~ /^ip prefix-list ([^ ]+) (?:seq (\d+) |)(permit|deny|description)(.*)$/i;
   my ($name,$seq,$action,$data) = ($1,$2,$3,$4);
   return if $action eq 'description';
   $data =~ s/^ //;
   my $rule = new Net::ACL::File::PrefixRule(
	Action	=> $action,
	Seq	=> $seq
	);
   $rule->add_match($rule->autoconstruction('Match','Net::ACL::Match::Prefix','Prefix',0,$data));
   $this->add_rule($rule);
   $this->name($name);
  };
}

## POD ##

=pod

=head1 NAME

Net::ACL::File::Prefix - Prefix-lists loaded from configuration string.

=head1 DESCRIPTION

This module extends the Net::ACL::File::Standard class to handle
prefix-lists. See L<Net::ACL::File::Standard|Net::ACL::File::Standard> for
details.

=head1 SEE ALSO

Net::ACL, Net::ACL::File, Net::ACL::Standard

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End of Net::ACL::File::Prefix ##

1;
