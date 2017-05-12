#!/usr/bin/perl

# $Id: ASPath.pm,v 1.10 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::File::ASPathRule;

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
 my $str = $match->value;
 $str =~ s/ /_/g;
 return 'ip as-path access-list ' . $name . ' ' . $this->action_str . ($str eq '' ? '' : ' ' . $str) . "\n";
}

## End of Net::ACL::File::ASPathRule ##

package Net::ACL::File::ASPath;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance ##

@ISA     = qw( Net::ACL::File::Standard );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::File::Standard;
use Carp;

## Net::ACL::File Class Auto Registration Code ##

Net::ACL::File->add_listtype('as-path-list',__PACKAGE__,'ip as-path access-list');

## Public Object Methods ##

sub loadmatch
{
 my ($this,$line) = @_;
 croak "Configuration line format error in line: '$line'"
	unless $line =~ /^ip as-path access-list ([^ ]+) (permit|deny)(.*)$/i;
 my ($name,$action,$data) = ($1,$2,$3);
 $data =~ s/^ //;
 $data =~ s/_/ /g;
 my $rule = new Net::ACL::File::ASPathRule(
	Action	=> $action
	);
 $rule->add_match($rule->autoconstruction('Match','Net::ACL::Match::Regexp','Regexp',0,$data));
 $this->add_rule($rule);
 $this->name($name);
}

## POD ##

=pod

=head1 NAME

Net::ACL::File::ASPath - AS-path access-lists loaded from configuration string.

=head1 DESCRIPTION

This module extends the Net::ACL::File::Standard class to handle
community-lists. See L<Net::ACL::File::Standard|Net::ACL::File::Standard> for details.

=head1 SEE ALSO

Net::ACL, Net::ACL::File, Net::ACL::Standard

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End of Net::ACL::File::ASPath ##

1;
