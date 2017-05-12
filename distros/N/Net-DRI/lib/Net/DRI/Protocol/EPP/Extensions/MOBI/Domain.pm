## Domain Registry Interface, .MOBI Domain EPP extension commands
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

package Net::DRI::Protocol::EPP::Extensions::MOBI::Domain;

use strict;

use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::MOBI::Domain - .MOBI EPP Domain extension commands for Net::DRI

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
          create => [ \&create, undef ],
          update => [ \&update, undef ],
          info   => [ undef, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub add_maintainer_url
{
 my ($mes,$tag,$url)=@_;
 my $eid=$mes->command_extension_register($tag,sprintf('xmlns:mobi="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('mobi')));
 $mes->command_extension($eid,['mobi:maintainerUrl',$url]);
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{maintainer_url}) && $rd->{maintainer_url});
 add_maintainer_url($mes,'mobi:create',$rd->{maintainer_url});
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 if (grep { ! /^(?:set)$/ } $todo->types('maintainer_url'))
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only maintainer_url set available for domain');
 }

 return unless $todo->set('maintainer_url');
 add_maintainer_url($mes,'mobi:update',$todo->set('maintainer_url'));
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('mobi','infData');
 return unless $infdata;

 my $c=$infdata->getChildrenByTagNameNS($mes->ns('mobi'),'maintainerUrl');
 return unless ($c && $c->size()==1);

 $rinfo->{domain}->{$oname}->{maintainer_url}=$c->shift()->getFirstChild()->getData();
}

####################################################################################################
1;
