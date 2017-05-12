## Domain Registry Interface, AFNIC EPP Notifications
##
## Copyright (c) 2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AFNIC::Notifications;

use strict;
use warnings;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AFNIC::Notifications - AFNIC (.FR/.RE) EPP Notifications for Net::DRI

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

Copyright (c) 2008,2009 Patrick Mevzek <netdri@dotandco.com>.
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
 my %tmp=(
           review_zonecheck => [ undef, \&parse_zonecheck ],
           review_identification => [ undef, \&parse_identification ],
         );

 return { 'message' => \%tmp };
}

####################################################################################################

sub parse_zonecheck
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 return unless $mes->node_msg(); ## this is the <msg> node in the EPP header

 ## For now there is no namespace
 #my $zc=$mes->node_msg()->getChildrenByTagNameNS($mes->ns('frnic'),'resZC');
 my $zc=$mes->node_msg()->getChildrenByTagName('resZC');
 return unless $zc->size();
 $zc=$zc->shift();
 return unless ($zc->getAttribute('type') eq 'plain-text'); ## we do not know what to do with other types

 $rinfo->{domain}->{$oname}->{review_zonecheck}=$zc->textContent(); ## a blob for now
 $rinfo->{domain}->{$oname}->{action}='review_zonecheck';
 $rinfo->{domain}->{$oname}->{exist}=1;

 return;
}

sub parse_identification
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $idt=$mes->get_extension('frnic','ext');
 return unless defined $idt;

 my $ns=$mes->ns('frnic');
 $idt=Net::DRI::Util::xml_traverse($idt,$ns,'resData','idtData');
 return unless defined $idt;

 my $c;
 if (defined($c=Net::DRI::Util::xml_traverse($idt,$ns,'contact')))
 {
  my ($co,$oname,@reasons);
  foreach my $el (Net::DRI::Util::xml_list_children($c))
  {
   my ($name,$node)=@$el;
   if ($name eq 'id')
   {
    $oname=$node->textContent();
    $rinfo->{contact}->{$oname}->{action}='review_identification';
    $rinfo->{contact}->{$oname}->{exist}=1;
    $co=$po->create_local_object('contact')->srid($oname);
    $rinfo->{contact}->{$oname}->{self}=$co;
   } elsif ($name eq 'identificationProcess')
   {
    $rinfo->{contact}->{$oname}->{process}=$node->getAttribute('s');
   } elsif ($name eq 'legalEntityInfos')
   {
    foreach my $subel (Net::DRI::Util::xml_list_children($node))
    {
     my ($subname,$subnode)=@$subel;
     if ($subname eq 'idStatus')
     {
      $co->id_status($subnode->textContent());
     } elsif ($subname eq 'legalStatus')
     {
      $co->legal_form($subnode->getAttribute('s'));
     } elsif ($subname=~m/^(?:siren|VAT|trademark)$/)
     {
      $subname='legal_id' if $subname eq 'siren';
      $subname=lc($subname);
      $co->$subname($subnode->textContent());
     }
    }
   } elsif ($name eq 'idtReason')
   {
    push @{$rinfo->{contact}->{$oname}->{reasons}},$node->textContent();
   }
  }

  return;
 }

 if (defined($c=Net::DRI::Util::xml_traverse($idt,$ns,'domain')))
 {
  my $oname=lc(Net::DRI::Util::xml_child_content($c,$ns,'name'));
  $rinfo->{domain}->{$oname}->{action}='review_identification';
  $rinfo->{domain}->{$oname}->{exist}=1;
  $rinfo->{domain}->{$oname}->{status}=$po->create_local_object('status')->add(Net::DRI::Protocol::EPP::Util::parse_status(Net::DRI::Util::xml_traverse($c,$ns,'status')));
  $rinfo->{domain}->{$oname}->{contact}=$po->create_local_object('contactset')->set($po->create_local_object('contact')->srid(Net::DRI::Util::xml_child_content($c,$ns,'registrant')),'registrant');
  return;
 }

 return;
}

####################################################################################################
1;
