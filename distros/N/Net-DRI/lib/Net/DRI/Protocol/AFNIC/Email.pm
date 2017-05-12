## Domain Registry Interface, AFNIC Email Protocol
##
## Copyright (c) 2006,2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::AFNIC::Email;

use strict;

use base qw(Net::DRI::Protocol);

use Email::Valid;

use Net::DRI::Exception;
use Net::DRI::Protocol::AFNIC::Email::Message;
use Net::DRI::Data::Contact::AFNIC;

our $VERSION=do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::AFNIC::Email - AFNIC Email Protocol for Net::DRI

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

Copyright (c) 2006,2008,2009 Patrick Mevzek <netdri@dotandco.com>.
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
 my ($c,$drd,$rp)=@_;
 my $clientid=$rp->{username};
 my $clientpw=$rp->{password};
 my $emailfrom=$rp->{email_from};

 Net::DRI::Exception::usererr_insufficient_parameters('client id must be defined') unless $clientid;
 Net::DRI::Exception::usererr_insufficient_parameters('client password must be defined') unless $clientpw;
 Net::DRI::Exception::usererr_insufficient_parameters('from email must be defined') unless $emailfrom;
 Net::DRI::Exception::usererr_invalid_parameters($emailfrom.' is not a valid email address') unless Email::Valid->rfc822($emailfrom);

 my $self=$c->SUPER::new();
 $self->name('afnic_email');
 $self->version($VERSION);

 foreach my $o (qw/ns contact/) { $self->capabilities('domain_update',$o,['set']); } ## no registrant, as there is a separate trade() call
 
 $self->factories('message',sub { my $m=Net::DRI::Protocol::AFNIC::Email::Message->new(@_); $m->client_auth({id => $clientid, pw => $clientpw}); $m->email_from($emailfrom); return $m; });
 $self->factories('contact',sub { return Net::DRI::Data::Contact::AFNIC->new(); });
 $self->_load();
 return $self;
}

sub _load
{
 my ($self)=@_;

 my @class=map { 'Net::DRI::Protocol::AFNIC::Email::'.$_ } ('Domain');

 $self->SUPER::_load(@class);
}

####################################################################################################
1;
