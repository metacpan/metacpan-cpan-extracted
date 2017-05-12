## Domain Registry Interface, .BE (DNSBE) policies for Net::DRI
##
## Copyright (c) 2006,2007,2008,2009,2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::BE;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

our $VERSION=do { my @r=(q$Revision: 1.10 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_transfer_stop domain_transfer_query domain_transfer_accept domain_transfer_refuse domain_renew contact_check contact_check_multi contact_transfer message_retrieve message_delete message_waiting message_count/);

=pod

=head1 NAME

Net::DRI::DRD::BE - .BE (DNSBE) policies for Net::DRI

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

Copyright (c) 2006,2007,2008,2009,2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

#####################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=1;
 $self->{info}->{contact_i18n}=1; ## LOC only
 bless($self,$class);
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1); }
sub name     { return 'DNSBE'; }
sub tlds     { return ('be'); }
sub object_types { return ('domain','contact','nsgroup'); }
sub profile_types { return qw/epp das/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::DNSBE',{})                  if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.dns.be'},'Net::DRI::Protocol::DAS',{no_tld=>1}) if $type eq 'das';
 return;
}

######################################################################################
## From §2 of Enduser_Terms_And_Conditions_fr_v3.1.pdf
sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{ check_name => 1,
                                                my_tld => 1,
                                                min_length => 2,
                                                no_double_hyphen => 1,
                                              });
}

sub domain_undelete
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'undelete');

 my $rc=$ndr->process('domain','undelete',[$domain,$rd]);
 return $rc;
}

sub domain_transfer_quarantine_start
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'transfer_quarantine');

 my $rc=$ndr->process('domain','transferq_request',[$domain,$rd]);
 return $rc;
}

sub domain_trade_start
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'trade');

 my $rc=$ndr->process('domain','trade_request',[$domain,$rd]);
 return $rc;
}

sub domain_reactivate
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'reactivate');

 my $rc=$ndr->process('domain','reactivate',[$domain,$rd]);
 return $rc;
}

#################################################################################################################
1;
