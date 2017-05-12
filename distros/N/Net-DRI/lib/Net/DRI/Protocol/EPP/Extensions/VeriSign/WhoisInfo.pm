## Domain Registry Interface, EPP Whois Info (EPP-Whois-Info-Ext.pdf)
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::WhoisInfo;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::WhoisInfo - EPP Whois Info (EPP-Whois-Info-Ext.pdf) for Net::DRI

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
           info => [ \&info, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $wi;
 if (Net::DRI::Util::has_key($rd,'whois_info'))
 {
  $wi=$rd->{whois_info};
 } else
 {
  my $def=$epp->default_parameters();
  if (Net::DRI::Util::has_key($def,'whois_info'))
  {
   $wi=$def->{whois_info};
  } else
  {
   Net::DRI::Exception::usererr_insufficient_parameters('Whois Info must be provided');
  }
 }
 Net::DRI::Exception::usererr_invalid_parameters('Whois Info must be true/false/1/0') unless Net::DRI::Util::xml_is_boolean($wi);
 
 my $eid=$mes->command_extension_register('whoisInf:whoisInf','xmlns:whoisInf="http://www.verisign.com/epp/whoisInf-1.0" xsi:schemaLocation="http://www.verisign.com/epp/whoisInf-1.0 whoisInf-1.0.xsd"');
 $mes->command_extension($eid,['whoisInf:flag',$wi]);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('http://www.verisign.com/epp/whoisInf-1.0','whoisInfData');
 return unless $infdata;

 my %w;
 my $c=$infdata->getFirstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;
  if ($name eq 'registrar')
  {
   $w{registrar}=$c->getFirstChild()->getData();
  } elsif ($name eq 'whoisServer')
  {
   $w{whois_server}=$c->getFirstChild()->getData();
  } elsif ($name eq 'url')
  {
   $w{url}=$c->getFirstChild()->getData();
  } elsif ($name eq 'irisServer')
  {
   $w{iris_server}=$c->getFirstChild()->getData();
  }
 } continue { $c=$c->getNextSibling(); }

 $rinfo->{domain}->{$oname}->{whois_info}=\%w;
}

####################################################################################################
1;
