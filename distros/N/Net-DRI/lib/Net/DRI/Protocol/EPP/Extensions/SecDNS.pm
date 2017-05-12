## Domain Registry Interface, EPP DNS Security Extensions (RFC4310)
##
## Copyright (c) 2005,2006,2007,2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::SecDNS;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.8 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };
our $NS='urn:ietf:params:xml:ns:secDNS-1.0';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::SecDNS - EPP DNS Security Extensions (RFC4310) for Net::DRI

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

Copyright (c) 2005,2006,2007,2008,2009 Patrick Mevzek <netdri@dotandco.com>.
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
           info   => [ undef, \&info_parse ],
           create => [ \&create, undef ],
           update => [ \&update, undef ],
         );

 return { 'domain' => \%tmp };
}

sub capabilities_add { return (['domain_update','secdns',['add','del','set']],['domain_update','secdns_urgent',['set']]); }

####################################################################################################

sub format_secdns
{
 my $e=shift;

 my @mk=grep { ! Net::DRI::Util::has_key($e,$_) } qw/keyTag alg digestType digest/;
 Net::DRI::Exception::usererr_insufficient_parameters('Attributes missing: '.join(@mk)) if @mk;
 Net::DRI::Exception::usererr_invalid_parameters('keyTag must be 16-bit unsigned integer: '.$e->{keyTag}) unless Net::DRI::Util::verify_ushort($e->{keyTag});
 Net::DRI::Exception::usererr_invalid_parameters('alg must be an unsigned byte: '.$e->{alg}) unless Net::DRI::Util::verify_ubyte($e->{alg});
 Net::DRI::Exception::usererr_invalid_parameters('digestType must be an unsigned byte: '.$e->{digestType}) unless Net::DRI::Util::verify_ubyte($e->{digestType});
 Net::DRI::Exception::usererr_invalid_parameters('digest must be hexadecimal: '.$e->{digest}) unless Net::DRI::Util::verify_hex($e->{digest});

 my @c;
 push @c,['secDNS:keyTag',$e->{keyTag}];
 push @c,['secDNS:alg',$e->{alg}];
 push @c,['secDNS:digestType',$e->{digestType}];
 push @c,['secDNS:digest',$e->{digest}];

 if (exists($e->{maxSigLife}))
 {
  Net::DRI::Exception::usererr_invalid_parameters('maxSigLife must be a positive integer: '.$e->{maxSigLife}) unless Net::DRI::Util::verify_int($e->{maxSigLife},1);
  push @c,['secDNS:maxSigLife',$e->{maxSigLife}];
 }
 if (exists($e->{key_flags}) && exists($e->{key_protocol}) && exists($e->{key_alg}) && exists($e->{key_pubKey}))
 {
  Net::DRI::Exception::usererr_invalid_parameters('key_flags mut be a 16-bit unsigned integer: '.$e->{key_flags}) unless Net::DRI::Util::verify_ushort($e->{key_flags});
  Net::DRI::Exception::usererr_invalid_parameters('key_protocol must be an unsigned byte: '.$e->{key_protocol}) unless Net::DRI::Util::verify_ubyte($e->{key_protocol});
  Net::DRI::Exception::usererr_invalid_parameters('key_alg must be an unsigned byte: '.$e->{key_alg}) unless Net::DRI::Util::verify_ubyte($e->{key_alg});
  Net::DRI::Exception::usererr_invalid_parameters('key_pubKey must be a non empty base64 string: '.$e->{key_pubKey}) unless Net::DRI::Util::verify_base64($e->{key_pubKey},1);
 
  my @cc;
  push @cc,['secDNS:flags',$e->{key_flags}];
  push @cc,['secDNS:protocol',$e->{key_protocol}];
  push @cc,['secDNS:alg',$e->{key_alg}];
  push @cc,['secDNS:pubKey',$e->{key_pubKey}];
  push @c,['secDNS:keyData',@cc];
 }

 return @c;
}

####################################################################################################
########### Query commands

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension($NS,'infData');
 return unless defined $infdata;

 my @ds;
 foreach my $el ($infdata->getChildrenByTagNameNS($NS,'dsData'))
 {
  my %n;
  foreach my $sel (Net::DRI::Util::xml_list_children($el))
  {
   my ($name,$c)=@$sel;
   if ($name=~m/^(keyTag|alg|digestType|digest|maxSigLife)$/)
   {
    $n{$1}=$c->textContent();
   } elsif ($name eq 'keyData')
   {
    foreach my $tel (Net::DRI::Util::xml_list_children($c))
    {
     my ($name2,$cc)=@$tel;
     if ($name2=~m/^(flags|protocol|alg|pubKey)$/)
     {
      $n{'key_'.$1}=$cc->textContent();
     }
    }
   }
  }
  push @ds,\%n;
 }

 $rinfo->{domain}->{$oname}->{secdns}=\@ds;
}

############ Transform commands

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

## Deactivated by suggestion of Elias Sidenbladh 2006-09
## Net::DRI::Exception::usererr_insufficient_parameters('One or more secDNS data block must be provided') unless (exists($rd->{secdns}) && (ref($rd->{secdns}) eq 'ARRAY') && @{$rd->{secdns}});
 return unless (exists($rd->{secdns}) && (ref($rd->{secdns}) eq 'ARRAY') && @{$rd->{secdns}});

 my $eid=$mes->command_extension_register('secDNS:create','xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.0 secDNS-1.0.xsd"');
 my @n=map { ['secDNS:dsData',format_secdns($_)] } (@{$rd->{secdns}});
 $mes->command_extension($eid,\@n);
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $toadd=$todo->add('secdns');
 my $todel=$todo->del('secdns');
 my $toset=$todo->set('secdns');
 my $urgent=$todo->set('secdns_urgent');

 my @def=grep { defined } ($toadd,$todel,$toset);
 return unless @def; ## no updates asked
 Net::DRI::Exception::usererr_invalid_parameters('Only add or del or chg is possible, not more than one of them') if (@def>1);

 my $urg=(defined($urgent) && $urgent)? 'urgent="1" ' : '';
 my $eid=$mes->command_extension_register('secDNS:update',$urg.'xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.0 secDNS-1.0.xsd"');

 my @n;
 push @n,['secDNS:add',map { ['secDNS:dsData',format_secdns($_)] } (ref($toadd) eq 'ARRAY')? @$toadd : ($toadd)] if (defined($toadd));
 push @n,['secDNS:chg',map { ['secDNS:dsData',format_secdns($_)] } (ref($toset) eq 'ARRAY')? @$toset : ($toset)] if (defined($toset));

 if (defined($todel))
 {
  my @nn;
  foreach my $e ((ref($todel) eq 'ARRAY')? @$todel : ($todel))
  {
   $e=$e->{keyTag} if (ref($e) eq 'HASH');
   Net::DRI::Exception::usererr_invalid_parameters('keyTag must be 16-bit unsigned integer: '.$e) unless Net::DRI::Util::verify_ushort($e);
   push @nn,['secDNS:keyTag',$e];
  }
  push @n,['secDNS:rem',@nn];
 }

 $mes->command_extension($eid,\@n);
}

####################################################################################################
1;
