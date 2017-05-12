package Net::Simplify::Event;

=head1 NAME

Net::Simplify::Event - Simplify Commerce webhook event class

=head1 SYNOPSIS

  use Net::Simplify;

  $Net::Simplify::public_key = 'YOUR PUBLIC KEY';
  $Net::Simplify::private_key = 'YOUR PRIVATE KEY';

  my $payload = 'YOUR WEBHOOK EVENT PAYLOAD';
  my $event = Net::Simplify::Event->create({payload => $payload});
  printf "event name %s\n", $event->{name};

  my $data = $event->{data};

=head1 DESCRIPTION

=head2 METHODS

=head3 create(%params, $auth)

Creates an Event object from a payload sent to a webhook endpoint.  The parameters are:

=over 4

=item C<%params>

Parameters for constructing the event object.  Valid keys are:

=over 4

=item C<payload>

The JWS message payload posted to your webhook endpoint (required)

=item C<url>

The URL for the webhook (optional, if present it must match the URL registered for the webhook).

=back

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back

=head1 SEE ALSO

L<Net::Simplify>,
L<Net::Simplify::Authentication>,
L<http://www.simplify.com>

=head1 VERSION

1.5.0

=head1 LICENSE

Copyright (c) 2013 - 2016 MasterCard International Incorporated
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of 
conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of 
conditions and the following disclaimer in the documentation and/or other materials 
provided with the distribution.
Neither the name of the MasterCard International Incorporated nor the names of its 
contributors may be used to endorse or promote products derived from this software 
without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING 
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

=cut

use 5.006;
use strict;
use warnings FATAL => 'all';

use Net::Simplify::Domain;

our @ISA = qw(Net::Simplify::Domain);

sub create {
    my ($class, $params, $auth) = @_;

    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->decode_event($params, $auth);

    $class->SUPER::new($result->{event}, $auth);
}


1;
