package Net::Simplify::Authentication;


=head1 NAME

Net::Simplify::Authentication - Simplify Commerce authentication class

=head1 SYNOPSIS

  use Net::Simplify;

  my $auth = Net::Simplify::Authentication->create({
      public_key => 'YOUR PUBLIC KEY',
      private_key => 'YOUR PRIVATE KEY'
  });
  
  my $payment = Net::Simplify::Payment->create({...}, $auth);

=head1 DESCRIPTION

=head3 create(%params)

Creates an authentication object using values in the C<params> hash.  The authencation 
object contains three values: C<public_key>, C<private_key> and C<access_token>.  The
public and private keys are used for all API requests and the access token is required
for all OAuth API requests (see L<Net::Simplify::AccessToken>).

If C<%params> contains C<public_key> this value is used to set the object's public key otherwise 
the value is taken from the global C<$Net::Simplify::public_key>. 
If C<%params> contains C<private_key> this value is used to set the object's private key otherwise 
the value is taken from the global C<$Net::Simplify::private_key>. 

=head3 public_key()

Returns the value of this object's public_key.

=head3 private_key()

Returns the value of this object's private_key.

=head3 access_token()

Returns the value of this object's access token.

=head1 SEE ALSO

L<Net::Simplify>,
L<Net::Simplify::AccessToken>,
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

sub create {

    my ($class, $params) = @_;
    
    my $self = {};
    $self->{public_key} = $params->{public_key} if defined $params->{public_key};
    $self->{private_key} = $params->{private_key} if defined $params->{private_key};
    $self->{access_token} = $params->{access_token} if defined $params->{access_token};

    $self->{public_key} = $Net::Simplify::public_key unless defined $self->{public_key};
    $self->{private_key} = $Net::Simplify::private_key unless defined $self->{private_key};

    bless $self, $class
}

sub public_key {
    my ($self, $v) = @_;

    $self->{public_key} = $v if defined $v;

    $self->{public_key};
}

sub private_key {
    my ($self, $v) = @_;

    $self->{private_key} = $v if defined $v;

    $self->{private_key};
}

sub access_token {
    my ($self, $v) = @_;

    $self->{access_token} = $v if defined $v;

    $self->{access_token};
}

1;
