## Domain Registry Interface, Registry Driver for .PT
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
#########################################################################################

package Net::DRI::DRD::PT;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use DateTime;
use Net::DRI::Util;
use Net::DRI::Data::Contact::FCCN;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

__PACKAGE__->make_exception_for_unavailable_operations(qw/contact_check contact_delete contact_transfer contact_transfer_start contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse message_retrieve message_delete message_waiting message_count/);

=pod

=head1 NAME

Net::DRI::DRD::PT - FCCN .PT Registry driver for Net::DRI

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

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=1;
 $self->{info}->{contact_i18n}=1; ## LOC only
 bless($self,$class);
 return $self;
}

sub periods      { return map { DateTime::Duration->new(years => $_) } (1,3,5); }
sub name         { return 'FCCN'; }
sub tlds         { return qw/pt net.pt org.pt edu.pt int.pt publ.pt com.pt nome.pt/; }
sub object_types { return ('domain','contact'); }
sub profile_types { return qw/epp whois/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::FCCN',{})            if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.nic.pt'},'Net::DRI::Protocol::Whois',{}) if $type eq 'whois';
 return;
}

sub set_factories
{
 my ($self,$po)=@_;
 $po->factories('contact',sub { return Net::DRI::Data::Contact::FCCN->new(@_); });
}

####################################################################################################

## We can not start a transfer, if domain name has already been transfered less than 15 days ago.
sub verify_duration_transfer
{
 my ($self,$ndr,$duration,$domain,$op)=@_;
 ($duration,$domain,$op)=($ndr,$duration,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return 0 unless ($op eq 'start'); ## we are not interested by other cases, they are always OK
 my $rc=$self->domain_info($ndr,$domain,{hosts=>'none'});
 return 1 unless ($rc->is_success());
 my $trdate=$ndr->get_info('trDate');
 return 0 unless ($trdate && $trdate->isa('DateTime'));

 my $now=DateTime->now(time_zone => $trdate->time_zone()->name());
 my $cmp=DateTime->compare($now,$trdate+DateTime::Duration->new(days => 15));
 return ($cmp == 1)? 0 : 1; ## we must have : now > transferdate + 15days
 ## we return 0 if OK, anything else if not
}

####################################################################################################

sub domain_renounce
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'renounce');
 return $ndr->process('domain','renounce',[$domain,$rd]);
}

####################################################################################################
1;
