package Test::ACME2_Server;

use strict;
use warnings;

use Test::Crypt;

use JSON ();
use MIME::Base64 ();
use Crypt::Perl::PK ();

use Net::ACME2::HTTP_Tiny;

use constant _CONTENT_TYPE_JSON => ( 'content-type' => 'application/json' );

use constant TOS_URL => 'http://the-terms-of-service/are/here';

my $nonce_counter = 0;

sub new {
    my ($class, %opts) = @_;

    my $self = bless \%opts, $class;

    $self->{'ca_class'} or die "need 'ca_class'!";

    # For now, this is kept here. It's feasible that future testing
    # needs may prompt a desire to make it customizable.
    $self->{'routing'} = {
        ('GET:' . $self->{'ca_class'}->DIRECTORY_PATH()) => sub {
            my $host = $self->{'ca_class'}->HOST();

            return {
                status => 'HTTP_OK',
                headers => {
                    _CONTENT_TYPE_JSON(),
                },
                content => {
                    meta => {
                        termsOfService => TOS_URL(),
                    },

                    newNonce => "https://$host/my-new-nonce",
                    newAccount => "https://$host/my-new-account",
                    newOrder => "https://$host/my-new-order",
                    keyChange => "https://$host/my-key-change",
                    revokeCert => "https://$host/my-revoke-cert",
                },
            };
        },

        "HEAD:/my-new-nonce" => sub {
            return {
                status => 'HTTP_NO_CONTENT',
                headers => {
                    $self->_new_nonce_header(),
                },
            };
        },

        'POST:/my-new-account' => sub {
            my $args_hr = shift;

            my ($key_obj, $header, $payload) = Test::Crypt::decode_acme2_jwt_extract_key($args_hr->{'content'});

            my $is_ecc = $key_obj->isa('Crypt::Perl::ECDSA::PublicKey');
            my $pem_method = $is_ecc ? 'to_pem_with_curve_name' : 'to_pem';

            my $key_pem = $key_obj->$pem_method();

            # Validate EAB if the server requires it
            if ($self->{'eab_credentials'}) {
                my $eab = $payload->{'externalAccountBinding'}
                    or die "Server requires externalAccountBinding!";

                my $eab_header_hr = JSON::decode_json(
                    MIME::Base64::decode_base64url( $eab->{'protected'} )
                );

                my $eab_kid = $eab_header_hr->{'kid'}
                    or die "EAB missing kid!";

                my $mac_key = $self->{'eab_credentials'}{$eab_kid}
                    or die "Unknown EAB kid: $eab_kid";

                my $host = $self->{'ca_class'}->HOST();
                my $expected_url = "https://$host/my-new-account";

                die "EAB url mismatch!" if ($eab_header_hr->{'url'} || '') ne $expected_url;
                die "EAB must not have nonce!" if exists $eab_header_hr->{'nonce'};

                my ($eab_hdr, $eab_payload) = Test::Crypt::decode_eab_jws($eab, $mac_key);

                # EAB payload must be the account public key JWK
                my $outer_jwk = $header->{'jwk'};
                my $cmp_json = JSON->new()->canonical(1);
                die "EAB payload JWK mismatch!"
                    if $cmp_json->encode($eab_payload) ne $cmp_json->encode($outer_jwk);
            }

            my $status;
            if ($self->{'_registered_keys'}{$key_pem}) {
                $status = 'OK';
            }
            else {
                $self->{'_registered_keys'}{$key_pem} = 1;
                $status = 'CREATED';
            }

            my %response;

            for my $name ( Net::ACME2::newAccount_booleans() ) {
                next if !exists $payload->{$name};

                if (ref($payload->{$name}) ne ref( JSON::true )) {
                    die "$name should be boolean, not '$name'";
                }

                $response{$name} = $payload->{$name};
            }

            my $host = $self->{'ca_class'}->HOST();

            $response{'orders'} = "https://$host/account-orders";

            return {
                status => "HTTP_$status",
                headers => {
                    $self->_new_nonce_header(),
                    _CONTENT_TYPE_JSON(),
                    location => "https://$host/key/" . Digest::MD5::md5_hex($key_pem),
                },
                content => \%response,
            };
        },

        'POST:/account-orders' => sub {
            my $h = $self->{'ca_class'}->HOST();

            my @order_urls;
            for my $id (sort { $a <=> $b } keys %{ $self->{'_orders'} || {} }) {
                push @order_urls, "https://$h/order/$id";
            }

            return {
                status => 'HTTP_OK',
                headers => {
                    $self->_new_nonce_header(),
                    _CONTENT_TYPE_JSON(),
                },
                content => {
                    orders => \@order_urls,
                },
            };
        },

        'POST:/key' => sub {
            my $args_hr = shift;

            my $content_hr = JSON::decode_json($args_hr->{'content'});
            my $payload = JSON::decode_json(
                MIME::Base64::decode_base64url($content_hr->{'payload'})
            );

            my %response = (
                status => 'valid',
            );

            if (($payload->{'status'} || '') eq 'deactivated') {
                $response{'status'} = 'deactivated';
            }

            if ($payload->{'contact'}) {
                $response{'contact'} = $payload->{'contact'};
            }

            my $host = $self->{'ca_class'}->HOST();

            return {
                status => 'HTTP_OK',
                headers => {
                    $self->_new_nonce_header(),
                    _CONTENT_TYPE_JSON(),
                },
                content => \%response,
            };
        },

        ($opts{'enable_key_change'} ? (
        'POST:/my-key-change' => sub {
            my $args_hr = shift;

            # The outer JWS is already verified by _verify_nonce.
            # Parse it to get the inner JWS (the payload).
            my $outer_hr = JSON::decode_json($args_hr->{'content'});
            my $inner_jws_json = MIME::Base64::decode_base64url($outer_hr->{'payload'});

            # The inner JWS is a JSON-serialized JWS
            my $inner_hr = JSON::decode_json($inner_jws_json);
            my $inner_header = JSON::decode_json(
                MIME::Base64::decode_base64url($inner_hr->{'protected'})
            );
            my $inner_payload = JSON::decode_json(
                MIME::Base64::decode_base64url($inner_hr->{'payload'})
            );

            # Verify inner JWS signature using the new key from jwk header
            my $new_key_obj = Crypt::Perl::PK::parse_jwk($inner_header->{'jwk'});
            my $is_ecc = $new_key_obj->isa('Crypt::Perl::ECDSA::PublicKey');
            my $to_pem_method = $is_ecc ? 'to_pem_with_curve_name' : 'to_pem';

            Test::Crypt::verify(
                $new_key_obj->$to_pem_method(),
                "$inner_hr->{'protected'}.$inner_hr->{'payload'}",
                MIME::Base64::decode_base64url($inner_hr->{'signature'}),
            );

            # Store for test assertions
            $self->{'_last_key_change'} = {
                inner_header  => $inner_header,
                inner_payload => $inner_payload,
            };

            return {
                status => 'HTTP_OK',
                headers => {
                    $self->_new_nonce_header(),
                    _CONTENT_TYPE_JSON(),
                },
                content => {},
            };
        },
        ) : ()),

        'POST:/my-new-order' => sub {
            my $args_hr = shift;

            my $h = $self->{'ca_class'}->HOST();

            $self->{'_order_counter'} ||= 0;
            my $order_id = ++$self->{'_order_counter'};

            my $content_hr = JSON::decode_json($args_hr->{'content'});
            my $payload = JSON::decode_json(
                MIME::Base64::decode_base64url($content_hr->{'payload'})
            );

            my @authz_urls;
            for my $i (0 .. $#{ $payload->{'identifiers'} }) {
                push @authz_urls, "https://$h/authz/$order_id-$i";
            }

            $self->{'_orders'}{$order_id} = {
                status => 'pending',
                identifiers => $payload->{'identifiers'},
                authorizations => \@authz_urls,
                finalize => "https://$h/finalize/$order_id",
            };

            return {
                status => 'HTTP_CREATED',
                headers => {
                    $self->_new_nonce_header(),
                    _CONTENT_TYPE_JSON(),
                    location => "https://$h/order/$order_id",
                },
                content => $self->{'_orders'}{$order_id},
            };
        },

        'POST:/authz/1-0' => sub {
            my $args_hr = shift;
            my $h = $self->{'ca_class'}->HOST();

            # Check if this is a deactivation request
            my $content_hr = JSON::decode_json($args_hr->{'content'});
            my $payload_b64 = $content_hr->{'payload'};

            # Non-empty payload means it's a status update, not POST-as-GET
            if ($payload_b64 && $payload_b64 ne '') {
                my $payload = JSON::decode_json(
                    MIME::Base64::decode_base64url($payload_b64)
                );

                if ($payload->{'status'} && $payload->{'status'} eq 'deactivated') {
                    $self->{'_authz_deactivated'} = 1;
                }
            }

            my %extra_headers;
            if ($self->{'_retry_after_authz'}) {
                $extra_headers{'retry-after'} = $self->{'_retry_after_authz'};
            }
            return {
                status => 'HTTP_OK',
                headers => {
                    $self->_new_nonce_header(),
                    _CONTENT_TYPE_JSON(),
                    %extra_headers,
                },
                content => $self->_authz_content($h),
            };
        },

        'POST:/challenge/http-01/1' => sub {
            my $h = $self->{'ca_class'}->HOST();
            $self->{'_challenge_accepted'} = 1;

            return {
                status => 'HTTP_OK',
                headers => {
                    $self->_new_nonce_header(),
                    _CONTENT_TYPE_JSON(),
                },
                content => {
                    type => 'http-01',
                    url => "https://$h/challenge/http-01/1",
                    token => 'test-token-abc123',
                    status => 'valid',
                    validated => '2026-01-01T00:00:00Z',
                },
            };
        },

        'POST:/order/1' => sub {
            my $h = $self->{'ca_class'}->HOST();
            my $status = $self->{'_order_finalized'} ? 'valid' : 'pending';

            my $order = $self->{'_orders'}{1};
            $order->{'status'} = $status;

            if ($status eq 'valid') {
                $order->{'certificate'} = "https://$h/cert/1";
            }

            my %extra_headers;
            if ($self->{'_retry_after_order'}) {
                $extra_headers{'retry-after'} = $self->{'_retry_after_order'};
            }

            return {
                status => 'HTTP_OK',
                headers => {
                    $self->_new_nonce_header(),
                    _CONTENT_TYPE_JSON(),
                    %extra_headers,
                },
                content => $order,
            };
        },

        'POST:/finalize/1' => sub {
            my $h = $self->{'ca_class'}->HOST();
            $self->{'_order_finalized'} = 1;

            my $order = $self->{'_orders'}{1};
            $order->{'status'} = 'valid';
            $order->{'certificate'} = "https://$h/cert/1";

            return {
                status => 'HTTP_OK',
                headers => {
                    $self->_new_nonce_header(),
                    _CONTENT_TYPE_JSON(),
                },
                content => $order,
            };
        },

        'POST:/cert/1' => sub {
            my $h = $self->{'ca_class'}->HOST();

            return {
                status => 'HTTP_OK',
                headers => {
                    $self->_new_nonce_header(),
                    'content-type' => 'application/pem-certificate-chain',
                    'link' => [
                        "<https://$h/cert/1/alt/1>;rel=\"alternate\"",
                        "<https://$h/cert/1/alt/2>;rel=\"alternate\"",
                    ],
                },
                content => "-----BEGIN CERTIFICATE-----\nMIIBkTCB+wIJAL+FZZ...\n-----END CERTIFICATE-----\n",
            };
        },

        'POST:/cert/1/alt/1' => sub {
            return {
                status => 'HTTP_OK',
                headers => {
                    $self->_new_nonce_header(),
                    'content-type' => 'application/pem-certificate-chain',
                },
                content => "-----BEGIN CERTIFICATE-----\nALTERNATE-CHAIN-1...\n-----END CERTIFICATE-----\n",
            };
        },

        'POST:/cert/1/alt/2' => sub {
            return {
                status => 'HTTP_OK',
                headers => {
                    $self->_new_nonce_header(),
                    'content-type' => 'application/pem-certificate-chain',
                },
                content => "-----BEGIN CERTIFICATE-----\nALTERNATE-CHAIN-2...\n-----END CERTIFICATE-----\n",
            };
        },

        'POST:/my-revoke-cert' => sub {
            my $args_hr = shift;

            my ($key_obj, $header, $payload) = Test::Crypt::decode_acme2_jwt_extract_key($args_hr->{'content'});

            die "No 'certificate' in revoke payload!" if !$payload->{'certificate'};

            # Track whether the signing key differs from any registered account key
            my $is_ecc = $key_obj->isa('Crypt::Perl::ECDSA::PublicKey');
            my $pem_method = $is_ecc ? 'to_pem_with_curve_name' : 'to_pem';
            my $key_pem = $key_obj->$pem_method();

            $self->{'_last_revoke_used_cert_key'} = !$self->{'_registered_keys'}{$key_pem};
            $self->{'_last_revoke_reason'} = $payload->{'reason'};

            return {
                status => 'HTTP_OK',
                headers => {
                    $self->_new_nonce_header(),
                },
                content => '',
            };
        },
    };

    $opts{'_base_request'} = \&Net::ACME2::HTTP_Tiny::_base_request;

    {
        no warnings 'redefine';
        *Net::ACME2::HTTP_Tiny::_base_request = sub {
            my ($http, $method, $url, $args_hr) = @_;

            return $self->_handle_request($method, $url, $args_hr);
        };
    }

    return $self;
}

sub last_key_change {
    my ($self) = @_;
    return $self->{'_last_key_change'};
}

sub DESTROY {
    my ($self) = @_;

    {
        no warnings 'redefine';
        *Net::ACME2::HTTP_Tiny::_base_request = $self->{'_base_request'};
    }

    return;
}

sub set_retry_after {
    my ($self, %opts) = @_;

    $self->{'_retry_after_authz'} = $opts{'authz'};
    $self->{'_retry_after_order'} = $opts{'order'};

    return;
}

sub _authz_content {
    my ($self, $host) = @_;

    my $status = $self->{'_authz_deactivated'} ? 'deactivated'
               : $self->{'_challenge_accepted'} ? 'valid'
               : 'pending';

    return {
        status => $status,
        identifier => { type => 'dns', value => 'example.com' },
        challenges => [
            {
                type => 'http-01',
                url => "https://$host/challenge/http-01/1",
                token => 'test-token-abc123',
                status => $status,
            },
            {
                type => 'dns-01',
                url => "https://$host/challenge/dns-01/1",
                token => 'test-token-dns456',
                status => $status,
            },
        ],
    };
}

sub _verify_nonce {
    my ($self, $args_hr) = @_;

    my $content_hr = JSON::decode_json($args_hr->{'content'});
    my $headers_hr = JSON::decode_json( MIME::Base64::decode_base64url( $content_hr->{'protected'} ) );

    my $nonce = $headers_hr->{'nonce'};

    if (!$nonce) {
        die "No nonce given!";
    }

    delete $self->{'_nonces'}{$nonce} or do {
        die "Unrecognized nonce! ($nonce)";
    };

    return;
}

sub _new_nonce_header {
    my ($self) = @_;

    my $new_nonce = "nonce-$nonce_counter";
    $self->{'_nonces'}{$new_nonce} = 1;

    $nonce_counter++;

    return 'replay-nonce' => $new_nonce;
}

sub _verify_content_type {
    my ($self, $args_hr) = @_;

    my $ctype = $args_hr->{'headers'}{'content-type'};
    if ($ctype ne 'application/jose+json') {
        die "Wrong content-type ($ctype)";
    }

    return;
}

sub _handle_request {
    my ($self, $method, $url, $args_hr) = @_;

    if ($method eq 'POST') {
        $self->_verify_content_type($args_hr);
        $self->_verify_nonce($args_hr);
    }

    my $host = $self->{'ca_class'}->HOST();
    my $dir_path = $self->{'ca_class'}->DIRECTORY_PATH();

    my $uri = URI->new($url);
    die "Must be https! ($url)" if $uri->scheme() ne 'https';
    die "Wrong host! ($url)" if $uri->host() ne $host;

    my $path = $uri->path();

    my $dispatch_key = "$method:$path";

    my $todo_cr = $self->{'routing'}{$dispatch_key};

    if (!$todo_cr) {
        for my $route (keys %{ $self->{'routing'} }) {
            if (index($dispatch_key, $route) == 0) {
                $todo_cr = $self->{'routing'}{$route};
                last;
            }
        }
    }

    $todo_cr or do {
        my @routes = sort keys %{ $self->{'routing'} };
        die "No routing for '$dispatch_key'! (@routes)";
    };

    my $resp_hr = $todo_cr->($args_hr);

    $resp_hr->{'status'} = HTTP::Status->can( $resp_hr->{'status'} )->();
    $resp_hr->{'reason'} = HTTP::Status::status_message( $resp_hr->{'status'} );
    $resp_hr->{'success'} = HTTP::Status::is_success($resp_hr->{'status'});
    $resp_hr->{'uri'} = $url;

    ref && ($_ = JSON::encode_json($_)) for $resp_hr->{'content'};

    return $resp_hr;
};

1;
