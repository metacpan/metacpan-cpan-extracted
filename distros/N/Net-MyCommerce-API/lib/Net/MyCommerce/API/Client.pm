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

package Net::MyCommerce::API::Client;

use strict;
use warnings;

use Encode qw( decode_utf8 );
use JSON::Parse qw( json_to_perl );
use JSON::XS;
use MIME::Base64;
use REST::Client;
use Try::Tiny;
use URI::Escape qw( uri_escape );

=head1 NAME
 
Net::MyCommerce::API::Client
 
=head1 VERSION
 
version 1.0.1
 
=cut
 
our $VERSION = '1.0.1';
 
=head1 METHODS

=head2 new

REST::Client wrapper used by  Net::MyCommerce::API::Token and Net::MyCommerce::API::Resource

=cut 

sub new {
  my ($pkg, %args) = @_;
  $args{client} = REST::Client->new(%args);
  $args{timeout} ||= 60;
  return bless { %args }, $pkg;
}

=head2 request (%opts) 

  %opns:

    path:    (required) full path or array ref with path elements;  exclude prefix
    params:  (optional) query params
    headers: (optional) headers


  my $client = Net::MyCommerce::API::Client->new(%args);
  my ($error, $result) = $client->request(%opts);
  my $content = $result->{content};
  my $status_code = $result->{status_code};
  my $headers = $result->{headers};

=cut

sub request {
  my ($self, %opts) = @_;
  $self->{client}->request($self->_parse_options(%opts));
  return $self->_parse_response($self->{client}->{_res});
}

# Private Methods

sub _parse_path {
  my ($self, %opts) = @_;
  my $prefix = $opts{prefix} || $self->{prefix} || '';
  my $path   = $opts{path}   || $self->{path};
  my $params = $opts{params} || $self->{params} || {};
  if (ref($path) eq 'ARRAY') {
    my $newpath = join("/", @$path);
    $path = $newpath;
  }
  if (keys %$params > 0) {
    my @list = ();
    foreach my $n (sort keys %$params) {
      push @list, join("=", $n, uri_escape($params->{$n}));
    }
    $path .= '?' . join("&", @list);
  }
  $opts{path} = $prefix . $path;
  return %opts;
}

sub _parse_data {
  my ($self, %opts) = @_;
  if ($opts{method} =~ /^(POST|PUT)$/) {
    $opts{data} = encode_json($opts{data}) if $self->{sendJSON};
  } else {
    $opts{data} = '';
  }
  return %opts;
}

sub _parse_headers {
  my ($self, %opts) = @_;
  my $headers = $opts{headers} || $self->{headers} || {};
  if ($self->{credentials}{id} && 
      $self->{credentials}{secret}) {
    my $auth = join(":", $self->{credentials}{id}, $self->{credentials}{secret});
    chomp( $headers->{Authorization} = 'Basic ' . encode_base64($auth) );
  } elsif ($opts{token_id}) {
    $headers->{Authorization} = 'Bearer ' . $opts{token_id};
  }
  if ($opts{method} =~ /^(POST|PUT)$/) {
    if ($self->{sendJSON}) {
      $headers->{'Content-type'} = 'application/json;charset=UTF-8';
    } else {
      $headers->{'Content-type'} = 'application/x-www-form-urlencoded';
    }
  }
  $opts{headers} = $headers;
  return %opts;
}

sub _parse_options {
  my ($self, %opts) = @_;
  $opts{method} ||= $self->{method} || 'GET';
  %opts = $self->_parse_path(%opts);
  %opts = $self->_parse_data(%opts);
  %opts = $self->_parse_headers(%opts);
  return ($opts{method}, $opts{path}, $opts{data}, $opts{headers});
}

sub _parse_response {
  my ($self, $response) = @_;
  if ($response) {
    my $error   = '';
    my $result  = {};
    my $content = $response->content;
    try {
      if ($content) {
        $content = decode_utf8($content);
        $content = json_to_perl($content) if $self->{getJSON};
      } else {
        $content = {} if $self->{getJSON};
      }
    } catch {
      $content =~ s/\s+/ /g;;
      $error = $_ . " [" . $content . "]";
    };
    if (ref($content) eq 'HASH') {
      my $errmsg = $content->{error} || '';
      $errmsg .= ": " . $content->{error_code} if $content->{error_code};
      $errmsg .= ": " . $content->{error_description} if $content->{error_description};
      $error ||= $errmsg;
    }
    if ($response->code =~ /^[345]/) {
      $error ||= "status code " . $response->code;
    }
    $result->{content} = $content;
    $result->{status_code} = $response->code;
    $result->{headers} = $response->headers;
    return ($error, $result);
  }
  return ("no response", {});
}


1;
