## Domain Registry Interface, CentralNic Registry Driver
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

package Net::DRI::DRD::CentralNic;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use DateTime;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::CentralNic - CentralNic (.LA .EU.COM .UK.COM etc.) Registry driver for Net::DRI

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
 $self->{info}->{host_as_attr}=0;
 $self->{info}->{contact_i18n}=2;       ## INT only
 bless($self,$class);
 return $self;
}

sub periods      { return map { DateTime::Duration->new(years => $_) } (2..10); }
sub name         { return 'CentralNic'; }
sub tlds         { return (qw/la uk.net se.net gb.net/,map { $_.'.com' } qw/eu uk us cn de jpn kr no za br ar ru sa se hu gb qc uy ae/); } ## see https://www.centralnic.com/names/domains
sub object_types { return ('domain','ns','contact'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CentralNic',{}) if $type eq 'epp';
 return;
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1,
                                               my_tld => 1,
                                               min_length => 3,
                                              });
}

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

sub verify_duration_renew
{
 my ($self,$ndr,$duration,$domain,$curexp)=@_;
 ($duration,$domain,$curexp)=($ndr,$duration,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));
 return 0 unless (defined($duration) && defined($curexp) && UNIVERSAL::isa($curexp,'DateTime'));
 my $newexp=$curexp+$duration; ## New expiration
 my $max=DateTime->new(year => 2037, month => 1, day => 1, time_zone => $curexp->time_zone()->name());
 my $cmp=DateTime->compare($newexp,$max);
 return 2 unless ($cmp == -1); ## we must have curexp+duration < 2037
 return 0; ## everything ok
}

####################################################################################################

sub domain_release
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'release');

 return $ndr->process('domain','release',[$domain,$rd]);
}

####################################################################################################
1;
