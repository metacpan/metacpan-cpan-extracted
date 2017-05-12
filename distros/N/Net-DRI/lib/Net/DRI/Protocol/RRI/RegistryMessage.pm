## Domain Registry Interface, RRI Registry messages commands (DENIC-11)
##
## Copyright (c) 2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
##                    All rights reserved.
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
#########################################################################################

package Net::DRI::Protocol::RRI::RegistryMessage;

use strict;

use DateTime::Format::ISO8601 ();

use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::RRI::RegistryMessage - RRI Registry messages commands (DENIC-11) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/project/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
           retrieve => [ \&pollreq, \&parse_poll ],
           delete   => [ \&pollack ],
         );

 return { 'message' => \%tmp };
}

sub pollack
{
 my ($rri, $msgid) = @_;
 my $mes = $rri->message();
 $mes->command(['msg', 'delete', $mes->ns->{msg}->[0], {msgid => $msgid}]);
}

sub pollreq
{
 my ($rri,$msgid)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('In RRI, you can not specify the message id you want to retrieve') if defined($msgid);
 my $mes = $rri->message();
 $mes->command(['msg', 'queue-read', $mes->ns->{msg}->[0]]);
 $mes->cltrid(undef);
}

## We take into account all parse functions, to be able to parse any result
sub parse_poll
{
 my ($po, $otype, $oaction, $oname, $rinfo) = @_;
 my $mes = $po->message();
 return unless $mes->is_success();
 my $msgdata = $mes->get_content('message', $mes->ns('msg'));
 return unless ($msgdata);

 my $msgid = $msgdata->getAttribute('msgid');
 my $rd = {};
 if (defined($msgid) && $msgid)
 {
  $rinfo->{message}->{session}->{last_id} = $msgid;
  $rd = $rinfo->{message}->{$msgid}; ## already partially filled by Message::parse()
 }

 $rd->{id} = $msgid;
 $rd->{lang} = 'en';
 $rd->{qdate} = DateTime::Format::ISO8601->new()->
	parse_datetime($msgdata->getAttribute('msgtime'));
 $rd->{objtype} = 'domain';

 my $el = $msgdata->getFirstChild();
 while ($el)
 {
  my @doms = $el->getElementsByTagNameNS($mes->ns('msg'), 'domain');
  my @news = $el->getElementsByTagNameNS($mes->ns('msg'), 'new');
  my @olds = $el->getElementsByTagNameNS($mes->ns('msg'), 'old');
  my $dom = $doms[0];
  my $exp;
  my $new = '';
  my $old = '';
  my $action = $rd->{action} = $el->localname() || $el->nodeName();

  $rd->{action} =~ s/[A-Z]\w*$//g;

  if ($dom)
  {
   my @hndls = $dom->getElementsByTagNameNS($mes->ns('msg'), 'handle');
   my @exps = $dom->getElementsByTagNameNS($mes->ns('msg'), 'expire');
   my $hndl = $hndls[0];

   $rd->{objid} = $hndl->getFirstChild()->getData() if (@hndls);
   $rd->{exDate} = DateTime::Format::ISO8601->new()->
	parse_datetime($hndl->getFirstChild()->getData()) if (@exps);
  }

  $new = $news[0]->getFirstChild()->getData() if (@news);
  $old = $olds[0]->getFirstChild()->getData() if (@olds);
  $rd->{clID} = $new if (length($new));

  if ($rd->{action} eq 'chprov')
  {
   my $act = lc($rd->{action});
   $act =~ s/^chprov//g;

   $rd->{content} = 'Received ' . $act . ' for ' . $rd->{objid} .
	' from ' . ($act eq 'start' || $act eq 'reminder' || $act eq 'end' ?
		$new : $old);
  }
  elsif ($action eq 'expireWarning')
  {
   $rd->{content} = $rd->{objid} . ' will expire on ' .
	$rd->{exDate}->ymd . ' at ' . $rd->{exDate}->hms;
  }
  elsif ($action eq 'expire')
  {
   $rd->{content} = $rd->{objid} . ' expired on ' .
	$rd->{exDate}->ymd . ' at ' . $rd->{exDate}->hms;
  }

  $el = $el->nextSibling();
 }

 $rinfo->{message}->{$msgid} = $rd;

 return;
}

####################################################################################################
1;
