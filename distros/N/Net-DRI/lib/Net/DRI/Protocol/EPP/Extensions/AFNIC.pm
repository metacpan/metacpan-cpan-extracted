## Domain Registry Interface, AFNIC (.FR/.RE) EPP extensions
## From http://www.afnic.fr/data/divers/public/afnic-epp-rc1.pdf (2008-06-30)
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

package Net::DRI::Protocol::EPP::Extensions::AFNIC;

use strict;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::AFNIC;
use Net::DRI::Protocol::EPP::Extensions::AFNIC::Status;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AFNIC - AFNIC (.FR/.RE) EPP extensions for Net::DRI

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

sub setup
{
 my ($self,$rp)=@_;
 $self->ns({frnic=>['http://www.afnic.fr/xml/epp/frnic-1.0','frnic-1.0.xsd']});
 $self->capabilities('domain_update','registrant',undef); ## a trade is required
 $self->capabilities('contact_update','status',undef); ## No changes in status possible for .FR contacts
 $self->capabilities('contact_update','disclose',['add','del']);
 $self->factories('contact',sub { return Net::DRI::Data::Contact::AFNIC->new(); });
 $self->factories('status',sub { return Net::DRI::Protocol::EPP::Extensions::AFNIC::Status->new(); });
 $self->default_parameters({domain_create => { ns => undef } }); ## No nameservers allowed during domain create
 return;
}

sub core_contact_types { return ('admin','tech'); } ## No billing contact in .FR
sub default_extensions { return qw/AFNIC::Domain AFNIC::Contact AFNIC::Notifications GracePeriod/; }

####################################################################################################
1;
