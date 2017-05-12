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

package Net::MyCommerce::API::Resource;

use strict;
use warnings;
use Net::MyCommerce::API::Client;
use Net::MyCommerce::API::Token;

=pod 

=head1 NAME
 
Net::MyCommerce::API::Resource
 
=head1 VERSION
 
version 1.0.1
 
=cut
 
our $VERSION = '1.0.1';
 
=head1 METHODS

=head2 new (%args)

Create a new resource object.

  $args{timeout}: timeout in seconds

=cut

sub new {
  my ($pkg, %args) = @_;
  $args{client} = Net::MyCommerce::API::Client->new(
    host     => $args{host} || 'http://api.mycommerce.com',
    prefix   => $args{prefix} || '/api/v1',
    timeout  => $args{timeout} || 60,
    sendJSON => 1,
    getJSON  => 1,
  );
  $args{token} = Net::MyCommerce::API::Token->new(%args);
  return bless { %args }, $pkg;
}

=head2 request (%opts)

Generic resource request call.

  my $resource = Net::MyCommerce::API::Resource->new();
  my ($error, $result) = $resource->request( path => $path, params => $params );
  if ($error) {
     print "Error occurred: $error\n";
  } else {
    my $content = $result->{content}; 
    my $status_code = $result->{status_code};
    my $headers => $result->{headers};
  }

=cut

sub request {
  my ($self, %opts) = @_;
  my ($terror, $token) = $self->{token}->lookup();
  if ($terror) {
    $self->{token}->reset();
    return ($terror, {});
  }
  $opts{token_id} = $token->{id};
  my ($error, $result) = $self->{client}->request(%opts);
  $result ||= {};
  $result->{content} ||= {};
  $result->{status_code} ||= 0;
  if ($result->{content}{error} && $result->{content}{error} eq 'invalid_token') {
    $self->{token}->reset();
    $error = 'token no longer valid';
  }
  return ($error, $result);
}

1;
