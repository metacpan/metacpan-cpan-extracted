package Test::ACME2_Server;

use Test::Crypt;

use Net::ACME2::HTTP_Tiny;

use constant _CONTENT_TYPE_JSON => ( 'content-type' => 'application/json' );

use constant TOS_URL => 'http://the-terms-of-service/are/here';

my $nonce_counter = 0;

sub new {
    my ($class, %opts) = @_;

    my $self = bless \%opts, $class;

    $self->{'ca_class'} or die "need “ca_class”!";

    # For now, this is kept here. It’s feasible that future testing
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
                    die "$name should be boolean, not “$name”";
                }

                $response{$name} = $payload->{$name};
            }

            my $host = $self->{'ca_class'}->HOST();

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

sub DESTROY {
    my ($self) = @_;

    {
        no warnings 'redefine';
        *Net::ACME2::HTTP_Tiny::_base_request = $self->{'_base_request'};
    }

    return;
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

    my $todo_cr = $self->{'routing'}{$dispatch_key} or do {
        my @routes = keys %{ $opts{'routing'} };
        die "No routing for “$dispatch_key”! (@routes)";
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
