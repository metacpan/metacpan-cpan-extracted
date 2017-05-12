## Domain Registry Interface, RRP Status
##
## Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::RRP::Core::Status;

use base qw!Net::DRI::Data::StatusList!;

use Net::DRI::Exception;
use strict;

our $VERSION=do { my @r=(q$Revision: 1.7 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::RRP::Core::Status - RRP Status for Net::DRI

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

Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut


#######################################################################################

sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;

 my $self=$class->SUPER::new('rrp','2.0');
 bless($self,$class);

 my %s=('delete'   => 'REGISTRAR-LOCK',
        'update'   => 'REGISTRAR-LOCK',
        'transfer' => 'REGISTRAR-LOCK',
        'publish'  => 'REGISTRAR-HOLD',
       );
 $self->_register_pno(\%s);

 my $msg=shift;
 return $self unless defined($msg);

 if (ref($msg) eq 'Net::DRI::Protocol::RRP::Message')
 {
  my @s=$msg->entities('status');
  $self->add(@s) if (@s);
 } else
 {
  Net::DRI::Exception::err_invalid_parameters();
 }

 return $self;
}

sub is_active    { return shift->has_any('ACTIVE'); }
sub is_published { return ! shift->has_any('REGISTRY-HOLD','REGISTRAR-HOLD'); }
sub is_pending   { return shift->has_any('REGISTRY-DELETE-NOTIFY','PENDINGRESTORE','PENDINGDELETE','PENDINGTRANSFER'); }
sub is_linked    { return shift->has_any('REGISTRY-DELETE-NOTIFY'); }
sub can_update   { return ! shift->has_any('REGISTRY-LOCK','REGISTRY-HOLD','REGISTRAR-HOLD','REGISTRAR-LOCK','REGISTRY-DELETE-NOTIFY','PENDINGRESTORE','PENDINGDELETE','PENDINGTRANSFER'); }
sub can_transfer { return shift->can_update(); }
sub can_delete   { return shift->can_update(); }
sub can_renew    { return ! shift->has_any('REGISTRY-DELETE-NOTIFY','REDEMPTIONPERIOD','PENDINGRESTORE','PENDINGDELETE','PENDINGTRANSFER'); }

#######################################################################################
1;
