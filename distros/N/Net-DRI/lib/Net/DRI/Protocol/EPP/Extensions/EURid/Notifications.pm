## Domain Registry Interface, EURid Registrar EPP extension notifications
## (introduced in release 5.6 october 2008)
##
## Copyright (c) 2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::EURid::Notifications;

use strict;
use warnings;

use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::Notifications - EURid EPP Notifications Handling for Net::DRI

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

Copyright (c) 2009 Patrick Mevzek <netdri@dotandco.com>.
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
          notification => [ undef, \&parse ],
         );

 return { 'message' => \%tmp };
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $poll=$mes->get_response('eurid','pollRes');
 return unless defined $poll;

 my $action;
 foreach my $el (Net::DRI::Util::xml_list_children($poll))
 {
  my ($name,$c)=@$el;
  if ($name eq 'action')
  {
   $action=lc($c->textContent());
  } elsif ($name eq 'domainname')
  {
   $oname=$c->textContent();
  } elsif ($name eq 'returncode')
  {
   $rinfo->{domain}->{$oname}->{return_code}=$c->textContent();
  } elsif ($name eq 'type')
  {
   $action.='_'.lc($c->textContent());
  }
 }

 $rinfo->{domain}->{$oname}->{action}=$action;
 $rinfo->{domain}->{$oname}->{exist}=1;
 $rinfo->{domain}->{$oname}->{result}=($action=~m/^confirm_/)? 1 : 0; ## TODO: is this a good test ?
}

####################################################################################################
1;
