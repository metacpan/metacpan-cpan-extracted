## Domain Registry Interface, .CAT Domain EPP extension commands
##
## Copyright (c) 2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CAT::Domain;

use strict;

use Email::Valid;
use Net::DRI::Util;
use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CAT::Domain - .CAT EPP Domain extension commands for Net::DRI

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

Copyright (c) 2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>.
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
          create            => [ \&create, undef ],
          update            => [ \&update, undef ],
          info              => [ undef, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:dx="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('puntcat_domain')));
}

sub add_name_variant
{
 my ($d)=@_;
 my @n;

 foreach my $n ((ref($d) eq 'ARRAY')? @{$d} : ($d))
 {
  Net::DRI::Exception::usererr_invalid_parameters($n.' in name_variant attribute must be an XML token between 1 & 255 chars in length') unless Net::DRI::Util::xml_is_token($n,1,255);
  push @n,['dx:nameVariant',$n];
 }

 return @n;
}

sub add_lang
{
 my ($d)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('lang attribute must be an XML language') unless (($d eq '') || Net::DRI::Util::xml_is_language($d));
 return ['dx:language',$d];
}

sub add_maintainer
{
 my ($d)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('maintainer attribute must be an XML token not more than 128 chars long') unless Net::DRI::Util::xml_is_token($d,undef,128);
 return ['dx:maintainer',$d];
}

sub add_intended_use
{
 my ($d)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('intended_use must be a string between 1 and 1000 chars long') unless (''.$d && (length($d) <= 1000));
 return ['dx:intendedUse',$d];
}

sub add_puntcat_extension
{
 my ($rd)=@_;
 my @n;
 return @n unless (defined($rd) && (ref($rd) eq 'HASH') && keys(%$rd));

 if (exists($rd->{name_variant}) && defined($rd->{name_variant}))
 {
  push @n,add_name_variant($rd->{name_variant});
 }

 push @n,add_lang($rd->{lang})             if (exists($rd->{lang}) && defined($rd->{lang}));
 push @n,add_maintainer($rd->{maintainer}) if (exists($rd->{maintainer}) && defined($rd->{maintainer}));

 Net::DRI::Exception::usererr_insufficient_parameters('ens block is mandatory, since intendeduse are mandatory') unless (exists($rd->{ens}) && defined($rd->{ens}) && (ref(($rd->{ens})) eq 'HASH'));
 my %ens=%{$rd->{ens}};
 my @ens;

 if (exists($ens{auth}) && defined($ens{auth}))
 {
  my %auth=(ref($ens{auth}) eq 'HASH')? (key => $ens{auth}->{key}, id => $ens{auth}->{id} ) : (id => $ens{auth});
  Net::DRI::Exception::usererr_insufficient_parameters('in ens auth block, id is mandatory') unless (exists($auth{id}) && defined($auth{id}));
  Net::DRI::Exception::usererr_invalid_parameters('id in ens auth block must be XML token between 1 and 20 chars long') if !Net::DRI::Util::xml_is_token($auth{id},1,20);
  Net::DRI::Exception::usererr_invalid_parameters('key in ens auth block must be XML token between 1 and 20 chars long') if (exists($auth{key}) && !Net::DRI::Util::xml_is_token($auth{key},1,20));
  push @ens,['dx:auth',\%auth];
 }

 if (exists($ens{sponsor}) && defined($ens{sponsor}))
 {
  my @e;
  foreach my $e ((ref($ens{sponsor}) eq 'ARRAY')? @{$ens{sponsor}} : ($ens{sponsor}))
  {
   Net::DRI::Exception::usererr_invalid_parameters("sponsor value $e in ens block must be a valid email address") unless (defined($e) && Net::DRI::Util::xml_is_token($e,1,undef) && Email::Valid->rfc822($e));
   push @e,['dx:sponsor',$e];
  }
  Net::DRI::Exception::usererr_invalid_parameters('there must be either 1 or 3 sponsors') unless (@e==1 || @e==3);
  push @ens,['dx:sponsoring',@e];
 }
 
 if (exists($ens{ref_url}) && defined($ens{ref_url}))
 {
  Net::DRI::Exception::usererr_invalid_parameters('ref_url in ens auth block must be XML token between 1 and 255 chars long') unless Net::DRI::Util::xml_is_token($ens{ref_url},1,255);
  push @ens,['dx:refURL',$ens{ref_url}];
 }

 if (exists($ens{registration_type}) && defined($ens{registration_type}))
 {
  Net::DRI::Exception::usererr_invalid_parameters('registration_type in ens auth block must be XML token between 1 and 128 chars long') unless Net::DRI::Util::xml_is_token($ens{registration_type},1,128);
  push @ens,['dx:registrationType',$ens{registration_type}];
 }

 Net::DRI::Exception::usererr_insufficient_parameters('intended_use in ens auth block is mandatory') unless (exists($ens{intended_use}) && defined($ens{intended_use}));
 push @ens,add_intended_use($ens{intended_use});

 push @n,['dx:ens',@ens] if @ens;
 return @n;
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my @n=add_puntcat_extension($rd);
 return unless @n;

 my $eid=build_command_extension($mes,$epp,'dx:create');
 $mes->command_extension($eid,\@n);
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();
 my (@tmp,@n);

 if ($todo->types('name_variant'))
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only name_variant add/del available for domain') if grep { ! /^(?:add|del)$/ } $todo->types('name_variant');

  @tmp=add_name_variant($todo->add('name_variant'));
  push @n,['dx:add',@tmp] if @tmp;
  @tmp=add_name_variant($todo->del('name_variant'));
  push @n,['dx:rem',@tmp] if @tmp;
 }

 @tmp=();

 if ($todo->types('lang'))
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only lang set available for domain') if grep { $_ ne 'set' } $todo->types('lang');
  push @tmp,add_lang($todo->set('lang'));
 }
 if ($todo->types('maintainer'))
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only maintainer set available for domain') if grep { $_ ne 'set' } $todo->types('maintainer');
  push @tmp,add_maintainer($todo->set('maintainer'));
 }
 if ($todo->types('intended_use'))
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only intended_use set available for domain') if grep { $_ ne 'set' } $todo->types('intended_use');
  push @tmp,add_intended_use($todo->set('intended_use'));
 }

 push @n,['dx:chg',@tmp] if @tmp;

 return unless @n;
 my $eid=build_command_extension($mes,$epp,'dx:update');
 $mes->command_extension($eid,\@n);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('puntcat_domain','infData');
 return unless $infdata;

 my $c=$infdata->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'nameVariant')
  {
   push @{$rinfo->{domain}->{$oname}->{name_variant}},$c->getFirstChild()->getData();
  } elsif ($name eq 'language')
  {
   $rinfo->{domain}->{$oname}->{lang}=$c->getFirstChild()->getData();
  } elsif ($name eq 'maintainer')
  {
   $rinfo->{domain}->{$oname}->{maintainer}=$c->getFirstChild()->getData();
  } elsif ($name eq 'ens')
  {
   my %ens;
   my $cc=$c->getFirstChild();
   while($cc)
   {
    next unless ($cc->nodeType() == 1); ## only for element nodes
    my $name2=$cc->localname() || $cc->nodeName();
    next unless $name2;
    if ($name2 eq 'auth')
    {
     $ens{auth}={ id => $cc->getAttribute('id') };
    } elsif ($name2 eq 'sponsoring')
    {
     $ens{sponsor}=[ map { $_->getFirstChild()->getData() } $cc->getChildrenByTagNameNS($mes->ns('puntcat_domain'),'sponsor') ]; 
    } elsif ($name2 eq 'refURL')
    {
     $ens{ref_url}=$cc->getFirstChild()->getData();
    } elsif ($name2 eq 'registrationType')
    {
     $ens{registration_type}=$cc->getFirstChild()->getData();
    } elsif ($name2 eq 'intendedUse')
    {
     $ens{intended_use}=$cc->getFirstChild()->getData();
    }
   } continue { $cc=$cc->getNextSibling(); }
   $rinfo->{domain}->{$oname}->{ens}=\%ens;
  }
 } continue { $c=$c->getNextSibling(); }
}

####################################################################################################
1;
