## Domain Registry Interface, ASIA IPR extension
##
## Copyright (c) 2007,2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ASIA::IPR;

use strict;

use DateTime::Format::ISO8601;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ASIA::IPR - .ASIA EPP IPR extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt> and
E<lt>http://oss.bdsprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
           create =>		[ \&create, \&create_parse ],
	   info =>		[ undef, \&parse ]
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

############ Transform commands

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 if (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{ipr}))
 {
  my @iprdata;
  push(@iprdata, ['ipr:name', $rd->{ipr}->{name}])
	if (exists($rd->{ipr}->{name}));
  push(@iprdata, ['ipr:ccLocality', $rd->{ipr}->{cc}])
	if (exists($rd->{ipr}->{cc}));
  push(@iprdata, ['ipr:number', $rd->{ipr}->{number}])
	if (exists($rd->{ipr}->{number}));
  push(@iprdata, ['ipr:appDate', $rd->{ipr}->{appDate}->ymd()])
	if (exists($rd->{ipr}->{appDate}) &&
	ref($rd->{ipr}->{appDate}) eq 'DateTime');
  push(@iprdata, ['ipr:regDate', $rd->{ipr}->{regDate}->ymd()])
	if (exists($rd->{ipr}->{regDate}) &&
	ref($rd->{ipr}->{regDate}) eq 'DateTime');
  push(@iprdata, ['ipr:class', int($rd->{ipr}->{class})])
	if (exists($rd->{ipr}->{class}));
  push(@iprdata, ['ipr:entitlement', $rd->{ipr}->{entitlement}])
	if (exists($rd->{ipr}->{entitlement}));
  push(@iprdata, ['ipr:form', $rd->{ipr}->{form}])
	if (exists($rd->{ipr}->{form}));
  push(@iprdata, ['ipr:type', $rd->{ipr}->{type}])
	if (exists($rd->{ipr}->{type}));
  push(@iprdata, ['ipr:preVerified', $rd->{ipr}->{preVerified}])
	if (exists($rd->{ipr}->{preVerified}));

  my $eid=$mes->command_extension_register('ipr:create',sprintf('xmlns:ipr="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ipr')));
  $mes->command_extension($eid,[@iprdata]);
 }
}

sub create_parse
{
 my ($po, $otype, $oaction, $oname, $rinfo) = @_;
 my $mes = $po->message();
 my $infdata = $mes->get_extension('asia','creData');
 my $c;

 return unless ($infdata);

 $c = $infdata->getElementsByTagNameNS($mes->ns('asia'), 'domainRoid');
 $rinfo->{$otype}->{$oname}->{roid} = $c->shift()->getFirstChild()->getData()
	if ($c);
}

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('ipr','infData');
 my $ipr = {};
 my $c;

 return unless ($infdata);
 my $pd=DateTime::Format::ISO8601->new();
 my $ns=$mes->ns('ipr');
 $c = $infdata->getElementsByTagNameNS($ns, 'name');
 $ipr->{name} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS($ns, 'ccLocality');
 $ipr->{cc} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS($ns, 'number');
 $ipr->{number} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS($ns, 'appDate');
 $ipr->{appDate} =$pd->parse_datetime ($c->shift()->getFirstChild()->getData()) if ($c);
 $c = $infdata->getElementsByTagNameNS($ns, 'regDate');
 $ipr->{regDate} = $pd->parse_datetime($c->shift()->getFirstChild()->getData()) if ($c);
 $c = $infdata->getElementsByTagNameNS($ns, 'class');
 $ipr->{class} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS($ns, 'entitlement');
 $ipr->{entitlement} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS($ns, 'form');
 $ipr->{form} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS($ns, 'preVerified');
 $ipr->{preVerified} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS($ns, 'type');
 $ipr->{type} = $c->shift()->getFirstChild()->getData() if ($c);
 $rinfo->{$otype}->{$oname}->{ipr} = $ipr;
}

####################################################################################################
1;
