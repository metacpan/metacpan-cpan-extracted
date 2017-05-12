#  Copyright 2013 Digital River, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

package Net::MyCommerce::API::Token;

use strict;
use warnings;

use Net::MyCommerce::API::Client;

=head1 NAME
 
Net::MyCommerce::API::Token
 
=head1 VERSION
 
version 1.0.1
 
=cut
 
our $VERSION = '1.0.1';

=head1 METHODS

=head2 new ( access => $access, vendor => $vendor, credentials => { id => $id, secret => $secret } );

  access: 'vendor' or 'affiliate'
  vendor: vendor id (only needed for access=affiliate)
  id:     MyCommerce vendor or affiliate ID
  secret: API secret appropriate to type of resource object requested

=cut

sub new {
  my ($pkg, %args) = @_;
  my $prefix = $args{prefix} || '/api';
  my $access = $args{access} || 'vendor';
  my $scope  = $args{scope};
  my $params = {};
  if ($access eq 'affiliate') {
    $params->{vendor_id} = $args{vendor};
  } elsif ($access ne 'vendor') {
    $params->{grant_type} = 'client_credentials';
    $params->{scope} = $scope;
  }
  my $path = join("/",$prefix, $access, 'token');
  $path =~ s#/v\d+##;
  $args{token} = { 
    id      => 0, 
    expires => 0, 
    access  => $access, 
    scope   => $scope, 
    vendor  => $access eq 'affiliate' ? $args{vendor} : '',
  };
  $args{client} = Net::MyCommerce::API::Client->new(
    host          => $args{host} || 'https://api.mycommerce.com',
    path          => $path,
    credentials   => $args{credentials} || {},
    method        => 'POST',
    params        => $params,
    timeout       => $args{timeout},
    getJSON       => 1,
    sendJSON      => 0,
  );
  return bless { %args }, $pkg;
}

=head2 lookup ()

Use cached token if not yet expired; otherwise request new token from token service

=cut

sub lookup {
  my ($self) = @_;
  if ($self->{token}{id} && $self->{token}{expires} > time() + 60) {
    return $self->_token_cache();
  }
  my ($error, $result) = $self->{client}->request();
  if ($error) {
    return $self->_token_error($error);
  } elsif ($result->{content}{access_token}) {
    $self->{token}{id}      = $result->{content}{access_token};
    $self->{token}{expires} = $result->{content}{expires_in} + time();
    return $self->_token_new();
  } else { 
    return _token_error('missing token');
  }
}

=head2 reset ()

clear cached token; necessary if resource API returns an 'invalid_token' error

=cut

sub reset {
  my ($self, %args) = @_;
  $self->{token}{id}      = 0;
  $self->{token}{expires} = 0;
  return ('');
}

# Private Methods

sub _token_cache {
  my ($self) = @_;
  return ('',$self->{token});
}

sub _token_new {
  my ($self) = @_;
  return ('',$self->{token});
}

sub _token_error {
  my ($self, $error) = @_;
  $error ||= 'unknown error';
  return ($error);
}

1;
