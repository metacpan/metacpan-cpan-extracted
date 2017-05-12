
package Net::Simplify::SimplifyApi;

=head1 NAME

Net::Simplify::SimplifyApi - Simplify Commerce module for API requests

=head1 SEE ALSO

L<Net::Simplify>,
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

use Net::Simplify;
use Net::Simplify::Constants;
use Net::Simplify::Jws;

use JSON;
use URI::Encode qw(uri_encode);
use REST::Client;
use Mozilla::CA;
use MIME::Base64 qw(encode_base64url);
use Carp;

sub send_api_request {

    my ($class, $domain, $op, $params, $auth) = @_;

    _check_auth($auth);

    my $url = _build_url($domain, $op, $params, $auth);

    my $jws_payload;
    eval {
        $jws_payload = encode_json($params) if defined $params;
    };
    if ($@) {
        croak(Net::Simplify::BadRequestException->new("Error encoding parameters as JSON: " . $@));
    }
       
    my $jws_message = Net::Simplify::Jws->encode($url, $jws_payload, $auth);

    my $user_agent = "Perl-SDK/${Net::Simplify::Constants::VERSION}";
    if (defined $Net::Simplify::user_agent) {
        $user_agent .= " ${Net::Simplify::user_agent}";
    }

    my $headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'User-Agent' => $user_agent
    };

    my $method;
    my $payload = undef;
    if ($op eq 'create') {
        $method = 'POST';
        $payload = $jws_message;
    } elsif ($op eq 'update') {
        $method = 'PUT';
        $payload = $jws_message;
    } elsif ($op eq 'find') {
        $method = 'GET';
        $headers->{Authorization} = "JWS ${jws_message}";
    } elsif ($op eq 'list') {
        $method = 'GET';
        $headers->{Authorization} = "JWS ${jws_message}";
    } elsif ($op eq 'delete') {
        $method = 'DELETE';
        $headers->{Authorization} = "JWS ${jws_message}";
    }

    my $client = REST::Client->new();
    $client->request($method, $url, $payload, $headers);

    my $code = $client->responseCode();

    if ($code == 200) {
        my $response = $client->responseContent();

        my $result;
        eval {
            $result = decode_json $response;
        };
        if ($@) {
            croak(Net::Simplify::SystemException->new("Error decoding JSON response data: " . $@. "Response message: " . $response));
        }

        return $result;

    } else {
        my $response = $client->responseContent();

        my $error;
        eval {
            $error = decode_json $response;
        };
        if ($@) {
            croak(Net::Simplify::SystemException->new("Error decoding JSON error data: " . $@ . "Response message: " . $response));
        }
        if ($code >= 300 && $code < 400) {
            croak(Net::Simplify::BadRequestException->new("Unexpected response code returned from API, have you got the correct URL?", $code));
        } elsif ($code == 400) {
            croak(Net::Simplify::BadRequestException->new("Bad request", $code, $error));
        } elsif ($code == 401) {
            croak(Net::Simplify::AuthenticationException->new("You are not authorized to make this request, are you using the correct keys?", $code, $error));
        } elsif ($code == 404) {
            croak(Net::Simplify::ObjectNotFoundException->new("Object not found", $code, $error));
        } elsif ($code == 405) {
            croak(Net::Simplify::NotAllowedException->new("Operation not allowed", $code, $error));
        } elsif ($code < 500) {            
            croak(Net::Simplify::BadRequestException->new("Bad request", $code));
        } else {
            croak(Net::Simplify::SystemException->new("An unexpected error has been rased for an API request", $code, $error));            
        }
    }
}

sub send_auth_request {
    my ($class, $params, $context, $auth) = @_;

    _check_auth($auth);

    if (defined $auth->access_token) {
        croak(Net::Simplify::IllegalArgumentException->new("authentication object should not contain access token for Oauth requests"));
    }

    my $url = $Net::Simplify::oauth_base_url . "/" . $context;

    my $payload = join('&', map { $_ . '=' . uri_encode($params->{$_})} keys %$params);

    my $jws_message = Net::Simplify::Jws->encode($url, $payload, $auth);

    my $client = REST::Client->new();

    my $user_agent = "Perl-SDK/${Net::Simplify::Constants::VERSION}";
    if (defined $Net::Simplify::user_agent) {
        $user_agent .= " ${Net::Simplify::user_agent}";
    }

    my $headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'User-Agent' => $user_agent
    };

    $client->request('POST', $url, $jws_message, $headers);

    my $code = $client->responseCode();

    if ($code == 200) {
        my $response = $client->responseContent();

        my $result;
        eval {
            $result = decode_json $response;
        };
        if ($@) {
            croak(Net::Simplify::SystemException->new("Error decoding JSON response data: " . $@ . "Response Message: " . $response));
        }

        return $result;

    } else {

        if ($code >= 300 && $code < 400) {
            croak(Net::Simplify::BadRequestException->new("Unexpected response code returned from OAuth API, have you got the correct URL?", $code));
        } elsif ($code >= 400 && $code < 500) {
            
            my $error;
            eval {
                $error = decode_json $client->responseContent();
            };
            if ($@) {
                croak(Net::Simplify::SystemException->new("Error decoding JSON error data: " . $@ . "Response: Message " . $client->responseContent()));
            }
            my $error_code = $error->{error};
            my $error_desc = $error->{error_description};

            if ($error_code eq 'invalid_request') {
                croak(Net::Simplify::BadRequestException->new('', $code, _get_oauth_error("Error during OAuth request", $error_code, $error_desc)));
            } elsif ($error_code eq 'access_denied') {
                croak(Net::Simplify::AuthenticationException->new('', $code, _get_oauth_error("Access denied for OAuth request", $error_code, $error_desc)));
            } elsif ($error_code eq 'invalid_client') {
                croak(Net::Simplify::AuthenticationException->new('', $code, _get_oauth_error("Invalid client ID in OAuth request", $error_code, $error_desc)));

            } elsif ($error_code eq 'unauthorized_client') {
                croak(Net::Simplify::AuthenticationException->new('', $code, _get_oauth_error("Unauthorized client in OAuth request", $error_code, $error_desc)));

            } elsif ($error_code eq 'unsupported_grant_type') {
                croak(Net::Simplify::BadRequestException->new('', $code, _get_oauth_error("Unsupported grant type in OAuth request", $error_code, $error_desc)));
            } elsif ($error_code eq 'invalid_scope') {
                croak(Net::Simplify::BadRequestException->new('', $code, _get_oauth_error("Invalid scope in OAuth request", $error_code, $error_desc)));
            } else {
                croak(Net::Simplify::BadRequestException->new('', $code, _get_oauth_error("Unknown OAuth error", $error_code, $error_desc)));
            }
        } else {
            croak(Net::Simplify::SystemException->new("An unexpected error has been raised for an OAuth request", $code));
        }
    }
}

sub _get_oauth_error {
    my ($msg, $error_code, $error_desc) = @_;

    my $error = {
        error => {
            code => 'oauth_error',
            message => "${msg}, error code '${error_code}', description '${error_desc}'"
        }
    };
    
    $error;            
}
        

sub get_authentication {
    my ($class, $auth) = @_;

    $auth = Net::Simplify::Authentication->create() unless defined $auth;

    if (! $auth->isa('Net::Simplify::Authentication')) {
        croak(Net::Simplify::IllegalArgumentException->new("authentication object is not a Net::Simplify::Authentication object"));
    }
    
    $auth;
}


sub decode_event {
    my ($class, $params, $auth) = @_;

    _check_auth($auth);
    _check_param($params, 'payload');

    Net::Simplify::Jws->decode($params->{payload}, $params->{url}, $auth);
}


sub is_live_key {
    my ($class, $public_key) = @_;

    _is_live_key($public_key);
}


sub _check_auth {
    my ($auth) = @_;

    if (!defined $auth->{public_key}) {
        croak(Net::Simplify::IllegalArgumentException->new("No public key"));
    }

    if (!defined $auth->{private_key}) {
        croak(Net::Simplify::IllegalArgumentException->new("No private key"));
    }
}


sub _check_param {
    my ($params, $name) = @_;

    if (!defined($params->{$name})) {
        croak(Net::Simplify::IllegalArgumentException->new("Missing paramater '${name}'"));
    }
}
        

sub _build_url {

    my ($domain, $op, $params, $auth) = @_;
    my $url;
    eval{
        $url = $Net::Simplify::api_base_sandbox_url;
        if (_is_live_key($auth->public_key)) {
            $url = $Net::Simplify::api_base_live_url;
        }
        if ($op eq 'find' || $op eq 'update' || $op eq 'delete') {
            my $id = $params->{id};
            $url .= "/${domain}/${id}"
        } else {
            $url .= "/${domain}"
        }

        if ($op eq 'list' && defined $params) {
            my @P = ();

            if (defined $params->{offset}) {
                my $v = $params->{offset};
                push(@P, uri_encode("offset=${v}"));
            }
            if (defined $params->{max}) {
                my $v = $params->{max};
                push(@P, uri_encode("max=${v}"));
            }
            if (defined $params->{sorting}) {
                while (my ($k, $v) = each(%{$params->{sorting}})) {
                    push(@P, uri_encode("sorting[${k}]=${v}"));
                }
            }
            if (defined $params->{filter}) {
                while (my ($k, $v) = each(%{$params->{filter}})) {
                    push(@P, uri_encode("filter[${k}]=${v}"));
                }
            }
            $url .= "?" . join('&', @P) if @P;
        }
    };
    if ($@) {
        croak(Net::Simplify::BadRequestException->new("Error building requests URL from parameters: " . $@));
    }

    $url;
}


sub _is_live_key {
    my ($public_key) = @_;

    $public_key =~ /^lvpb_/;
}


1;
