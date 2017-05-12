## Domain Registry Interface, IRIS Core functions
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

package Net::DRI::Protocol::IRIS::Core;

use strict;
use warnings;

use Carp;
use Net::DRI::Protocol::ResultStatus;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::IRIS::Core - IRIS Core (RFC3981) functions for Net::DRI

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

our %ERRORS=(insufficientResources => 2400,
             invalidName => 2005,
             invalidSearch => 2306,
             queryNotSupported => 2101,
             limitExceeded => 2201,
             nameNotFound => 2303,
             permissionDenied => 2200,
             bagUnrecognized => 2005,
             bagUnacceptable => 2005,
             bagRefused => 2306,
            );


sub parse_error
{
 my ($node)=@_; ## $node should be a topmost <resultSet> to be able to catch all errors type
 my $c=$node->getFirstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname();
  next unless (defined $name && $name);
  next if ($name eq 'answer' || $name eq 'additional');
  carp('Got unknown error <'.$name.'>, please report') unless exists($ERRORS{$name});
  my (@i,$msg,$lang);
  foreach my $expl ($c->getChildrenByTagNameNS($c->namespaceURI(),'explanation'))
  {
   if (! defined $msg) { ($lang,$msg)=($expl->getAttribute('language'),$expl->textContent()); }
   push @i,sprintf('[%s] %s',$expl->getAttribute('language'),$expl->textContent());
  }
  ## We have only one error element at most, so break here if we found one
  return Net::DRI::Protocol::ResultStatus->new('iris',$name,exists($ERRORS{$name})? $ERRORS{$name} : 'GENERIC_ERROR',0,$msg,$lang,\@i);
 } continue { $c=$c->getNextSibling(); }
 return Net::DRI::Protocol::ResultStatus->new_generic_success();
}

## RFC4991 §6 §7
sub parse_authentication
{
 my ($node)=@_; ## $node should be a topmost <resultSet> to be able to catch all errors type
 my (@i,$msg,$lang);

 my $c=$node->getFirstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname();
  next unless (defined $name && $name);
  next unless ($name eq 'authenticationSuccess' || $name eq 'authenticationFailure');

  foreach my $expl ($c->getChildrenByTagNameNS($c->namespaceURI(),'description'))
  {
   if (! defined $msg) { ($lang,$msg)=($expl->getAttribute('language'),$expl->textContent()); }
   push @i,sprintf('[%s] %s',$expl->getAttribute('language'),$expl->textContent());
  }
  last;
 } continue { $c=$c->getNextSibling(); }

 return ($msg,$lang,\@i);
}

####################################################################################################
1;
