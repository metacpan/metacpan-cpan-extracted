## Domain Registry Interface, EURid (.EU) policy on reserved names
##
## Copyright (c) 2005-2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::EURid;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Util;
use Net::DRI::Exception;
use DateTime::Duration;

our $VERSION=do { my @r=(q$Revision: 1.14 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_transfer_query domain_transfer_accept domain_transfer_refuse domain_renew contact_check contact_check_multi contact_transfer contact_transfer_start contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse/);

=pod

=head1 NAME

Net::DRI::DRD::EURid - EURid (.EU) policies for Net::DRI

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

Copyright (c) 2005-2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

#####################################################################################

our %CCA2_EU=map { $_ => 1 } qw/AT BE BG CZ CY DE DK ES EE FI FR GR GB HU IE IT LT LU LV MT NL PL PT RO SE SK SI AX GF GI GP MQ RE/;
our %LANGA2_EU=map { $_ => 1 } qw/bg cs da de el en es et fi fr ga hu it lt lv mt nl pl pt ro sk sl sv/;

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
sub name     { return 'EURid'; }
sub tlds     { return ('eu'); }
sub object_types { return ('domain','contact','nsgroup'); }
sub profile_types { return qw/epp das whois das-registrar whois-registrar/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{remote_host=>'epp.registry.tryout.eu',remote_port=>33128},'Net::DRI::Protocol::EPP::Extensions::EURid',{}) if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{remote_host=>'das.eu'},'Net::DRI::Protocol::DAS',{no_tld=>1})                                              if $type eq 'das';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.eu'},'Net::DRI::Protocol::Whois',{})                                                   if $type eq 'whois';
 return ('Net::DRI::Transport::Socket',{remote_host=>'das.registry.eu'},'Net::DRI::Protocol::DAS',{no_tld=>1})                                     if $type eq 'das-registrar';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.registry.eu'},'Net::DRI::Protocol::Whois',{})                                          if $type eq 'whois-registrar';
 return;
}

######################################################################################

## See terms_and_conditions_v1_0_.pdf, Section 2.2.ii
sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1,
                                               my_tld => 1,
                                               min_length => 2,
                                               no_double_hyphen_except_idn => 1, ## temporary bypass for IDNs
                                               no_country_code => 1,
                                              });
}

sub domain_undelete
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'undelete');

 my $rc=$ndr->process('domain','undelete',[$domain,$rd]);
 return $rc;
}

sub domain_transfer_quarantine
{
 my ($self,$ndr,$domain,$op,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'transfer_quarantine');
 Net::DRI::Exception::usererr_invalid_parameters('Transfer from quarantine operation must be start or stop') unless ($op=~m/^(?:start|stop)$/);

 my $rc;
 if ($op eq 'start')
 {
  $rc=$ndr->process('domain','transferq_request',[$domain,$rd]);
 } elsif ($op eq 'stop')
 {
  $rc=$ndr->process('domain','transferq_cancel',[$domain,$rd]);
 }
 return $rc;
}

sub domain_transfer_quarantine_start { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer_quarantine($ndr,$domain,'start',$rd); }
sub domain_transfer_quarantine_stop  { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer_quarantine($ndr,$domain,'stop',$rd); }


sub domain_trade_start
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'trade');

 my $rc=$ndr->process('domain','trade_request',[$domain,$rd]);
 return $rc;
}

sub domain_trade_stop
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'trade');

 my $rc=$ndr->process('domain','trade_cancel',[$domain,$rd]);
 return $rc;
}

sub domain_reactivate
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'reactivate');

 my $rc=$ndr->process('domain','reactivate',[$domain,$rd]);
 return $rc;
}

sub domain_check_contact_for_transfer
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'check_contact_for_transfer');

 my $rc=$ndr->process('domain','check_contact_for_transfer',[$domain,$rd]);
 return $rc;
}

sub registrar_info
{
 my ($self,$ndr)=@_;
 my $rc=$ndr->process('registrar','info');
 return $rc;
}

sub domain_remind
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'remind');

 my $rc=$ndr->process('domain','remind',[$domain,$rd]);
 return $rc;
}

#################################################################################################################
1;
