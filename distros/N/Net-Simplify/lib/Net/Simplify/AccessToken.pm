package Net::Simplify::AccessToken;

=head1 NAME

Net::Simplify::AccessToken - Simplify Commerce OAuth access token

=head1 SYNOPSIS

  use Net::Simplify;

  my $auth_code = "YOUR AUTH CODE";
  my $redirect_uri = "YOUR REDIRECT URI";

  my $token = Net::Simplify::AccessToken->create($auth_code, $redirect_uri);
  printf "Access token %s\n", $token->access_token;

  # Create Authentication object using the access token
  my $auth = Net::Simplify::Authentication->create({
        public_key => 'YOUR PUBLIC_KEY',
        private_key => 'YOUR PRIVATE KEY',
        access_token => $token->access_token
  });

  # Create a payment using the OAuth credentials
  my $payment = Net::Simplify::Payment->create({...}, $auth);


=head1 DESCRIPTION

Access tokens provide a way of performing operations on behalf of another user.  To create
an access token an authentication code is required.  Once the access token has been created
the access token value can be used to construct an L<Net::Simplify::Authentication>
object which can be passed to API calls.

=head2 METHODS

=head3 create($auth_code, $redirect_uri, $auth) 

Creates an AccessToken object.  The parameters are:

=over 4

=item C<$auth_code>

The authentication code obtained during the OAuth login process.

=item C<$redirect_uri>

The redirect URI for the OAuth login process.  This must match the registered value.

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back

=head3 refresh()

Refresh the token obtaining new access and refresh tokens.  Authentication is done
using the same credentials used when the AccessToken was created.

=head3 revoke()

Revokes the access token.  Authentication is done using the same credentials used when the AccessToken was created.

=head3 access_token($value)

Returns the current value of the access token.
If the $value parameter is passed in it is used to set the value of the access token.


=head3 refresh_token($value)

Returns the current value of the refresh token.
If the $value parameter is passed in it is used to set the value of the refresh token.

=head3 expires_in($value)


Returns the period in seconds since the access token was created or refreshed to when
the token expires.
If the $value parameter is passed in it is used to set the value of the expiry.

=head1 SEE ALSO

L<Net::Simplify>,
L<Net::Simplify::Authentication>,
L<http://www.simplify.com>

=head1 VERSION

1.6.0

=head1 LICENSE

Copyright (c) 2013 - 2022 MasterCard International Incorporated
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

use Carp;

sub create {
    my ($class, $auth_code, $redirect_uri, $auth) = @_;

    my $params = {
        grant_type => 'authorization_code',
        code => $auth_code,
        redirect_uri => $redirect_uri
    };

    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_auth_request($params, 'token', $auth);

    $class->SUPER::new($result, $auth);
}

sub refresh {
    my ($self) = @_;

    my $auth = $self->{_authentication};

    my $rt = $self->{refresh_token};
    if (!defined $rt) {
        croak(Net::Simplify::IllegalArgumentException->new("refresh token value is missing from access token object"));
    }
    
    my $params = {
        grant_type => 'refresh_token',
        refresh_token => $rt
    };

    my $result = Net::Simplify::SimplifyApi->send_auth_request($params, 'token', $auth);
        
    $self->merge($result);
}

sub revoke {
    my ($self) = @_;

    my $auth = $self->{_authentication};

    my $at = $self->{access_token};
    if (!defined $at) {
        croak(Net::Simplify::IllegalArgumentException->new("access token value is missing from access token object"));
    }
    
    my $params = {
        token => $at
    };

    my $result = Net::Simplify::SimplifyApi->send_auth_request($params, 'revoke', $auth);
        
    $self->clear();
}

sub access_token {
    my ($self, $v) = @_;

    $self->{access_token} = $v if defined $v;

    $self->{access_token};
}

sub refresh_token {
    my ($self, $v) = @_;

    $self->{refresh_token} = $v if defined $v;

    $self->{refresh_token};
}

sub expires_in {
    my ($self, $v) = @_;

    $self->{expires_in} = $v if defined $v;

    $self->{expires_in};
}


1;
