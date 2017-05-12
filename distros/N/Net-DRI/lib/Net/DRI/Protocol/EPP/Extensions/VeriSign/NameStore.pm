## Domain Registry Interface, EPP NameStore Extension for Verisign
##
## Copyright (c) 2006,2008,2009 Rony Meyer <perl@spot-light.ch>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::NameStore;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.7 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };
our $NS='http://www.verisign-grs.com/epp/namestoreExt-1.1';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::NameStore - VeriSign EPP NameStore Extension for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@spot-light.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHORS

Rony Meyer, E<lt>perl@spot-light.chE<gt>
Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006,2008 Rony Meyer <perl@spot-light.ch>.
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
 # domain functions
 my %tmpDomain = (
           check  =>           [ \&add_namestore_ext, \&parse ],
           check_multi  =>     [ \&add_namestore_ext, \&parse ],
           info   =>           [ \&add_namestore_ext, \&parse_error ],
           transfer_query  =>  [ \&add_namestore_ext, \&parse_error ],
           create =>           [ \&add_namestore_ext, \&parse_error ],
           delete =>           [ \&add_namestore_ext, \&parse_error ],
           renew =>            [ \&add_namestore_ext, \&parse_error ],
           transfer_request => [ \&add_namestore_ext, \&parse_error ],
           transfer_cancel  => [ \&add_namestore_ext, \&parse_error ],
           transfer_answer  => [ \&add_namestore_ext, \&parse_error ],
           update =>           [ \&add_namestore_ext, \&parse_error ],
         );

 # host functions
 my %tmpHost = (
           create       => [ \&add_namestore_ext, \&parse_error ],
           check        => [ \&add_namestore_ext, \&parse ],
           check_multi  => [ \&add_namestore_ext, \&parse ],
           info         => [ \&add_namestore_ext, \&parse_error ],
           delete       => [ \&add_namestore_ext, \&parse_error ],
           update       => [ \&add_namestore_ext, \&parse_error ],
         );

 # contact functions
 my %tmpContact = (
           create       => [ \&add_namestore_ext, \&parse_error ],
           check        => [ \&add_namestore_ext, \&parse ],
           check_multi  => [ \&add_namestore_ext, \&parse ],
           info         => [ \&add_namestore_ext, \&parse_error ],
           delete       => [ \&add_namestore_ext, \&parse_error ],
           update       => [ \&add_namestore_ext, \&parse_error ],
         );

 
 return { 'domain' => \%tmpDomain,
          'host'   => \%tmpHost,
          'contact'=> \%tmpContact,
        };
}

####################################################################################################

########### Add the NameStore Extenstion to all domain & host commands

sub add_namestore_ext
{
 my $epp=shift(@_);
 my $domain=shift(@_);
 my $rd=pop(@_);
 my $mes=$epp->message();
 my $defprod=$epp->default_parameters()->{subproductid};

 my $eid=$mes->command_extension_register('namestoreExt:namestoreExt',sprintf('xmlns:namestoreExt="%s" xsi:schemaLocation="%s namestoreExt-1.1.xsd"',$NS,$NS));

 if (Net::DRI::Util::has_key($rd,'subproductid') && $rd->{subproductid})
 {
  $mes->command_extension($eid,['namestoreExt:subProduct',$rd->{subproductid}]);
  return;
 }

 unless ($defprod eq '_auto_')
 {
  $mes->command_extension($eid,['namestoreExt:subProduct',$defprod]);
  return;
 }

 ## We do not know what will happen in case of check_multi with multiple TLDs
 my $ext='dotCOM';
 $domain=$domain->[0] if (ref($domain) eq 'ARRAY');
 $ext='dotNET' if ($domain=~m/\.net$/i);
 $ext='dotCC' if ($domain=~m/\.cc$/i);
 $ext='dotTV' if ($domain=~m/\.tv$/i);
 $ext='dotBZ' if ($domain=~m/\.bz$/i);
 $ext='dotJOBS' if ($domain=~m/\.jobs$/i);

 $mes->command_extension($eid,['namestoreExt:subProduct',$ext]);
}

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 parse_error($po,$otype,$oaction,$oname,$rinfo);
 return unless $mes->is_success();

 my $infdata=$mes->get_extension($NS,'namestoreExt');
 return unless $infdata;
 my $c=$infdata->getChildrenByTagNameNS($NS,'subProduct');
 return unless $c;

 $rinfo->{$otype}->{$oname}->{subproductid}=$c->shift()->getFirstChild()->getData();
}

sub parse_error
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();

 ## Parse namestoreExt in case of errors
 return unless $mes->result_code() == 2306;

 my $data=$mes->get_extension($NS,'nsExtErrData');
 return unless $data;
 $data=$data->shift()->getChildrenByTagNameNS($NS,'msg');
 return unless $data;
 $data=$data->shift();

 ## We add it to the latest status extra_info seen.
 $mes->add_to_extra_info({from => 'verisign:namestoreExt', type => 'text', message => $data->textContent(), code => $data->getAttribute('code')});
}

#########################################################################################################
1;
