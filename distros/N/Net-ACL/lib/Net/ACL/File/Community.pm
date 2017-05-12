#!/usr/bin/perl

# $Id: Community.pm,v 1.11 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::File::CommunityRule;

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
 my $str = defined $match ? join(' ',@{$match->value}) : '';
 return 'ip community-list ' . $name . ' ' . $this->action_str . ($str eq '' ? '' : ' ' . $str) . "\n";
}

## End of Net::ACL::File::CommunityRule ##

package Net::ACL::File::Community;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance ##

@ISA     = qw( Net::ACL::File::Standard );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::File::Standard;
use Carp;

## Net::ACL::File Class Auto Registration Code ##

Net::ACL::File->add_listtype('community-list',__PACKAGE__,'ip community-list');

## Public Object Methods ##

sub loadmatch
{
 my ($this,$line) = @_;
 croak "Configuration line format error in line: '$line'"
	unless $line =~ /^ip community-list ([^ ]+) (permit|deny)(.*)$/i;
 my ($name,$action,$data) = ($1,$2,$3);
 $data =~ s/^ //;
 my $rule = new Net::ACL::File::CommunityRule(
	Action	=> $action
	);
 $rule->add_match($rule->autoconstruction('Match','Net::ACL::Match::Member','Member',0,[split(/ /,$data)]))
 	unless $data eq '';
 $this->add_rule($rule);
 $this->name($name);
}

## POD ##

=pod

=head1 NAME

Net::ACL::File::Community - Community-lists loaded from configuration string.

=head1 DESCRIPTION

This module extends the Net::ACL::File::Standard class to handle
community-lists. See L<Net::ACL::File::Standard|Net::ACL::File::Standard> for
details.

=head1 SEE ALSO

Net::ACL, Net::ACL::File, Net::ACL::Standard

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End of Net::ACL::File::Community ##

1;
