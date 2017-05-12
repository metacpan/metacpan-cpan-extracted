## Domain Registry Interface, AFNIC (.FR/.RE) Contact EPP extension commands
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

package Net::DRI::Protocol::EPP::Extensions::AFNIC::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AFNIC::Contact - AFNIC (.FR/.RE) EPP Contact extensions for Net::DRI

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
          create  => [ \&create, \&create_parse ],
          update => [ \&update, undef ],
          info       => [ undef, \&info_parse ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:frnic="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('frnic')));
}

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

## validate() has been called
 my @n;
 if ($contact->legal_form()) # PM
 {
  my @d;
  Net::DRI::Exception::usererr_insufficient_parameters('legal_form data mandatory') unless ($contact->legal_form());
  Net::DRI::Exception::usererr_invalid_parameters('legal_form_other data mandatory if legal_form=other') if (($contact->legal_form() eq 'other') && !$contact->legal_form_other());
  push @d,['frnic:legalStatus',{s => $contact->legal_form()},$contact->legal_form() eq 'other'? $contact->legal_form_other() : ''];
  push @d,['frnic:siren',$contact->legal_id()] if $contact->legal_id();
  push @d,['frnic:VAT',$contact->vat()] if $contact->vat();
  push @d,['frnic:trademark',$contact->trademark()] if $contact->trademark();
  my $jo=$contact->jo();
  if (defined($jo) && (ref($jo) eq 'HASH'))
  {
   my @j;
   push @j,['frnic:waldec',$jo->{waldec}] if exists $jo->{waldec};
   push @j,['frnic:waldec',$contact->legal_id()] if (defined $contact->legal_id() && defined $contact->legal_form_other() && $contact->legal_form_other() eq 'asso'); ## not sure API ok
   push @j,['frnic:decl',$jo->{date_declaration}];
   push @j,['frnic:publ',{announce=>$jo->{number},page=>$jo->{page}},$jo->{date_publication}];
   push @d,['frnic:asso',@j];
  }
  push @n,['frnic:legalEntityInfos',@d];
 } else # PP
 {
  push @n,['frnic:list','restrictedPublication'] if (defined $contact->disclose() && $contact->disclose() eq 'N');
  my @d;
  my $b=$contact->birth();
  Net::DRI::Exception::usererr_insufficient_parameters('birth data mandatory') unless ($b && (ref($b) eq 'HASH') && exists($b->{date}) && exists($b->{place}));
  push @d,['frnic:birthDate',(ref($b->{date}))? $b->{date}->strftime('%Y-%m-%d') : $b->{date}];
  if ($b->{place}=~m/^[A-Z]{2}$/i) ## country not France
  {
   push @d,['frnic:birthCc',$b->{place}];
  } else
  {
   my @p=($b->{place}=~m/^\s*(\S.*\S)\s*,\s*(\S.+\S)\s*$/);
   push @d,['frnic:birthCity',$p[1]];
   push @d,['frnic:birthPc',$p[0]];
   push @d,['frnic:birthCc','FR'];
  }
  push @n,['frnic:individualInfos',@d];
  push @n,['frnic:firstName',$contact->firstname()];
 }

 my $eid=build_command_extension($mes,$epp,'frnic:ext');
 $mes->command_extension($eid,['frnic:create',['frnic:contact',@n]]);
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_extension('frnic','ext');
 return unless defined $credata;

 my $ns=$mes->ns('frnic');
 $credata=Net::DRI::Util::xml_traverse($credata,$ns,'resData','creData');
 return unless defined $credata;

 $oname=$rinfo->{contact}->{$oname}->{id}; ## take into account true ID (the one returned by the registry)
 foreach my $el (Net::DRI::Util::xml_list_children($credata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'nhStatus')
  {
   $rinfo->{contact}->{$oname}->{new_handle}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('new'));
  } elsif ($name eq 'idStatus')
  {
   $rinfo->{contact}->{$oname}->{identification}=$c->textContent();
  }
 }
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $dadd=$todo->add('disclose');
 my $ddel=$todo->del('disclose');
 return unless ($dadd || $ddel);

 my @n;
 push @n,['frnic:add',['frnic:list',$dadd]] if $dadd;
 push @n,['frnic:rem',['frnic:list',$ddel]] if $ddel;
 my $eid=build_command_extension($mes,$epp,'frnic:ext');
 $mes->command_extension($eid,['frnic:update',['frnic:contact',@n]]);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('frnic','ext');
 return unless defined $infdata;

 my $ns=$mes->ns('frnic');
 $infdata=Net::DRI::Util::xml_traverse($infdata,$ns,'resData','infData','contact');
 return unless defined $infdata;

 my $co=$rinfo->{contact}->{$oname}->{self};
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'firstName')
  {
   $co->firstname($c->textContent());
  } elsif ($name eq 'list')
  {
   $co->disclose($c->textContent() eq 'restrictedPublication'? 'N' : 'Y');
  } elsif ($name eq 'individualInfos')
  {
    my %b;
    foreach my $sel (Net::DRI::Util::xml_list_children($c))
    {
     my ($nn,$cc)=@$sel;
     if ($nn eq 'idStatus')
     {
      $rinfo->{contact}->{$oname}->{identification}=$cc->textContent();
     } elsif ($nn eq 'birthDate')
     {
      $b{date}=$cc->textContent();
     } elsif ($nn eq 'birthCity')
     {
      $b{place}=$cc->textContent();
     } elsif ($nn eq 'birthPc')
     {
      $b{place}=sprintf('%s, %s',$cc->textContent(),$b{place});
     } elsif ($nn eq 'birthCc')
     {
      my $v=$cc->textContent();
      $b{place}=$v unless ($v eq 'FR');
     }
    }
    $co->birth(\%b);
  } elsif ($name eq 'legalEntityInfos')
  {
   foreach my $sel (Net::DRI::Util::xml_list_children($c))
   {
    my ($nn,$cc)=@$sel;
    if ($nn eq 'legalStatus')
    {
     $co->legal_form($cc->getAttribute('type'));
     my $v=$cc->textContent();
     $co->legal_form_other($v) if $v;
    } elsif ($nn eq 'siren')
    {
     $co->legal_id($cc->textContent());
    } elsif ($nn eq 'trademark')
    {
     $co->trademark($cc->textContent());
    } elsif ($nn eq 'asso')
    {
     my %jo;
     my $ccc=$cc->getChildrenByTagNameNS($mes->ns('frnic'),'decl');
     $jo{date_declaration}=$ccc->get_node(1)->textContent() if ($ccc->size());
     $ccc=$cc->getChildrenByTagNameNS($mes->ns('frnic'),'publ');
     if ($ccc->size())
     {
      my $p=$ccc->get_node(1);
      $jo{number}=$p->getAttribute('announce');
      $jo{page}=$p->getAttribute('page');
      $jo{date_publication}=$p->textContent();
     }
     $co->jo(\%jo);
    }
   }
  }
 }

 return;
}

####################################################################################################
1;
