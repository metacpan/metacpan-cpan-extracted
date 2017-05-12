## Domain Registry Interface, IRIS DCHK (RFC5144)
##
## Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
####################################################################################################

package Net::DRI::Protocol::IRIS::DCHK::Domain;

use strict;

use Carp;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::IRIS::Core;

use DateTime::Format::ISO8601;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::IRIS::DCHK::Domain - IRIS DCHK (RFC5144) Domain Commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( info  => [ \&info, \&info_parse ] );
## $tmp{info_multi}=$tmp{info};
 return { 'domain' => \%tmp };
}

sub build_command
{
 my ($ns,$domain)=@_;
 my @dom=(ref($domain))? @$domain : ($domain);
 Net::DRI::Exception->die(1,'protocol/IRIS',2,'Domain name needed') unless @dom;
 foreach my $d (@dom)
 {
  Net::DRI::Exception->die(1,'protocol/IRIS',2,'Domain name needed') unless defined($d) && $d;
  Net::DRI::Exception->die(1,'protocol/IRIS',10,'Invalid domain name: '.$d) unless Net::DRI::Util::is_hostname($d);
 }

 ## TODO: entityClass may also be IDN for Unicode domain names ## §3.1.2
 ##return [ map { { registryType => $ns, entityClass => 'domain-name', entityName => $_ } } @dom ] ;
 return [ map { { registryType => 'dchk1', entityClass => 'domain-name', entityName => $_ } } @dom ] ; ## Both registryType forms should work, but currently only this one works
}

sub info
{
 my ($p,$domain)=@_;
 my $mes=$p->message();
 $mes->search(build_command($mes->ns('dchk1'),$domain));
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success(); ## ?
 return unless $mes->results(); ## a nodeList of resultSet nodes

 foreach my $cd ($mes->results()->get_nodelist())
 {
  carp('For domain '.$oname.' got a node <additional>, please report') if $cd->getChildrenByTagNameNS($mes->ns('iris1'),'additional')->size(); ## TODO
  $rinfo->{domain}->{$oname}->{result_status}=Net::DRI::Protocol::IRIS::Core::parse_error($cd); ## a ResultStatus instance, either a generic success, or a specific error
  $rinfo->{domain}->{$oname}->{action}='info';
  $rinfo->{domain}->{$oname}->{exist}=0;

  my $c=$cd->getChildrenByTagNameNS($mes->ns('iris1'),'answer');
  next unless $c->size();
  $c=$c->get_node(1)->getChildrenByTagNameNS($mes->ns('dchk1'),'domain');
  next unless $c->size();
  ## We do not use attributes authority/entityClass/entityName/registryType, they should be the same as what we sent
  $c=$c->get_node(1);
  my $temp=$c->hasAttribute('temporaryReference')? Net::DRI::Util::xml_parse_boolean($c->getAttribute('temporaryReference')) : 0;
  $c=$c->getFirstChild();
  my $pd=DateTime::Format::ISO8601->new();
  my ($domain,@s);
  while($c)
  {
   next unless ($c->nodeType() == 1); ## only for element nodes
   my $n=$c->localname() || $c->nodeName();
   if ($n eq 'domainName') ## we do not use <idn> for now
   {
    $domain=lc($c->textContent());
    $rinfo->{domain}->{$domain}->{action}='info';
    $rinfo->{domain}->{$domain}->{exist}=1;
   } elsif ($n eq 'status')
   {
    ## We take everything below as a status node, which allows us to handle all non RFC5144 defined statuses
    my $cc=$c->getFirstChild();
    while($cc)
    {
     next unless ($cc->nodeType() == 1); ## only for element nodes
     push @s,parse_status($cc,$pd);
    } continue { $cc=$cc->getNextSibling(); }
   } elsif ($n eq 'registrationReference')
   {
    carp('For domain '.$domain.' got a node <registrationReference>, please report');
   } elsif ($n eq 'createdDateTime')
   {
    $rinfo->{domain}->{$domain}->{crDate}=$pd->parse_datetime($c->textContent());
   } elsif ($n eq 'initialDelegationDateTime')
   {
    $rinfo->{domain}->{$domain}->{idDate}=$pd->parse_datetime($c->textContent());
   } elsif ($n eq 'expirationDateTime')
   {
    $rinfo->{domain}->{$domain}->{exDate}=$pd->parse_datetime($c->textContent());
   } elsif ($n eq 'lastDatabaseUpdateDateTime')
   {
    $rinfo->{domain}->{$domain}->{duDate}=$pd->parse_datetime($c->textContent());
   } elsif ($n eq 'seeAlso' || $n eq 'iris:seeAlso')
   {
    carp('For domain '.$domain.' got a node <'.$n.'>, please report');
   }
  } continue { $c=$c->getNextSibling(); }

  $rinfo->{domain}->{$domain}->{temporary}=$temp;
  my $s=$po->create_local_object('status')->add(@s);
  $rinfo->{domain}->{$domain}->{exist}=0 if $s->has_any(qw/nameNotFound invalidName/);
  $rinfo->{domain}->{$domain}->{status}=$s;
 } ## end of foreach on each resultSet
}

sub parse_status ## §3.1.1.1
{
 my ($node,$pd)=@_;
 my %tmp=(name => $node->localname() );
 my $ns=$node->namespaceURI();

 my $c=$node->getChildrenByTagNameNS($ns,'appliedDate'); ## 0..1
 $tmp{applied_date}=$pd->parse_datetime($c->get_node(1)->textContent()) if $c->size();

 $c=$node->getChildrenByTagNameNS($ns,'ticket'); ## 0..unbounded
 $tmp{tickets}=[ map { $_->textContent() } $c->get_nodelist() ] if $c->size();

 $c=$node->getChildrenByTagNameNS($ns,'description'); ## 0..unbounded
 if ($c->size())
 {
  my @t=map { { lang => $_->getAttribute('language'), msg => $_->textContent() } } $c->get_nodelist();
  $tmp{description}=\@t;

  ## Useful fallback to mimick EPP ?
  $tmp{lang}=$t[0]->{lang};
  $tmp{msg}=$t[0]->{msg};
 }

 $c=$node->getChildrenByTagNameNS($ns,'description'); ## 0..unbounded ; not defined by RFC5144
 $tmp{substatus}=[ map { { authority => $_->getAttribute('authority'), content => $_->toString(0) } } $c->get_nodelist() ] if $c->size();

 foreach my $a (qw/actor disposition scope/)
 {
  next unless $node->hasAttribute($a);
  $tmp{$a}=$node->getAttribute($a);
 }

 return \%tmp;
}

####################################################################################################
1;
