package Test::ACMEServer;

# cpanel - t/lib/Cpanel/TestObj/ACMEServer.pm     Copyright(c) 2016 cPanel, Inc.
#                                                           All rights reserved.
# copyright@cpanel.net                                         http://cpanel.net
# This code is subject to the cPanel license. Unauthorized copying is prohibited

use strict;
use warnings;

use parent qw( Test::Class );

use FindBin;
use lib "$FindBin::Bin/lib";

use Call::Context ();
use Digest::SHA ();
use File::Slurp ();
use File::Temp ();
use JSON ();

use Test::Crypt ();

sub _DIRECTORY {
    my $host = t::Net::ACME::MockService::_HOST();

    my %dir;
    for my $ep (qw( new-authz new-cert new-reg )) {
        $dir{$ep} = "https://$host/mock-acme/mock-$ep";
    }

    return \%dir;
}

sub _decode_jwt {
    my ($jwt, $key) = @_;

    Call::Context::must_be_list();

    return Test::Crypt::decode_jwt(
        key => $key,
        token         => $jwt,
    );
}

sub _with_mocked_http_request {
    my ($self, $acme_key, $endpoints_hr, $todo_as_client_cr ) = @_;

    no warnings 'redefine';
    local *HTTP::Tiny::request = sub {
        my (undef, $method, $url, $args_hr) = @_;

        my ($schema, $host, $after_host) = ($url =~ m<\A([^:]+)://([^/]+)(?:/(.*))?>);

        $after_host ||= q<>;

        my @matching_endpoints = grep { "$method:$after_host" =~ m<\Q$_\E> } keys %$endpoints_hr;
        my $longest = (sort { length $a <=> length $b } @matching_endpoints)[-1];

        my $postdata = $args_hr->{'content'};
        my ( $header, $payload ) = $postdata ? _decode_jwt($postdata, $acme_key) : ();

        my $rest_calls_ar = $self->_load_file_json( $self->{'_rest_calls_file'} );

        local $ENV{'REQUEST_URI'} = "/$after_host";
        local $ENV{'REQUEST_METHOD'} = $method;
        $ENV{'REQUEST_METHOD'} =~ tr<a-z><A-Z>;

        push @$rest_calls_ar, {
            ENV  => {
                (map { $_ => $ENV{$_} } qw( REQUEST_URI  REQUEST_METHOD ) ),
                HTTPS => ($schema eq 'https' ? 'on' : q<>),
            },
            POST => $postdata,
        };

        $self->_dump_file_json( $self->{'_rest_calls_file'}, $rest_calls_ar );

        my ($status, $reason, $headers_hr, $content);

        if (!$longest) {
            ($status, $reason) = ( 404, 'Not Found (cP)' );
        }
        elsif ( $method eq 'post' ) {
            if ( !$self->_check_nonce( $header->{'nonce'} ) ) {
                diag explain [ "bad nonce in PID $$", $header->{'nonce'} ];
                ($status, $reason) = ( 400, 'Bad nonce (cP)' );
            }
        }

        if (!$status) {
            ($status, $reason, $headers_hr, $content) = $endpoints_hr->{$longest}->($header, $payload);
        }

        my $nonce = Digest::SHA::sha256_hex( $$ . time . rand );
        $self->_add_nonce($nonce);

        $headers_hr->{'replay-nonce'} = $nonce;

        if (ref $content) {
            $content = JSON::encode_json($content);
        }

        #Normalize hash keys
        $headers_hr->{lc $_} = delete $headers_hr->{$_} for keys %$headers_hr;

        return {
            method => $method,
            url => $url,
            status => $status,
            reason => $reason,
            content => $content,
            headers => $headers_hr,
        };
    };

    return $todo_as_client_cr->();
}

sub _dump_file_json {
    my ($self, $path, $struct) = @_;

    File::Slurp::write_file( $path, JSON::encode_json($struct) );

    return;
}

sub _load_file_json {
    my ($self, $path) = @_;

    return JSON::decode_json( File::Slurp::read_file( $path ) );
}

#----------------------------------------------------------------------

sub _do_acme_server {
    my ( $self, $acme_key, $todo_as_client_cr, ) = @_;

    my $reg_dir = $self->{'_registrations_dir'};

    $self->_with_mocked_http_request(
        $acme_key,
        {
            'get:directory' => sub { return $self->_server_send_directory() },

            'get:terms' => sub {
                return( 200, 'OK', { Location => 'http://the.terms' } );
            },

            'post:reg' => sub {
                my ( $header, $payload ) = @_;

                my ($reg_index) = ( $ENV{'REQUEST_URI'} =~ m<.+/(.+)> );

                if ( -e "$reg_dir/$reg_index" ) {
                    my $reg = $self->_load_file_json("$reg_dir/$reg_index");

                    for my $rp (qw( contact agreement )) {
                        next if !exists $payload->{$rp};
                        $reg->{$rp} = $payload->{$rp};
                    }

                    $self->_dump_file_json( "$reg_dir/$reg_index", $reg );

                    return(
                        202 => 'Accepted',
                        {},
                        $reg,
                    );
                }
                else {
                    return(
                        400 => 'No registration (cP)',
                        {},
                        q<>,
                    );
                }
            },

            'post:mock-acme/mock-new-reg' => sub {
                my ( $header, $payload ) = @_;

                my $reg_index = Digest::SHA::sha256_hex( join( '.', @{ $header->{'jwk'} }{ 'n', 'e' } ) );

                my $host = t::Net::ACME::MockService::_HOST();
                my $reg_url = "https://$host/reg/$reg_index";

                if ( -e "$reg_dir/$reg_index" ) {
                    return(
                        409 => 'Already! (cP)',
                        {
                            Location => $reg_url,
                        },
                    );
                }
                else {
                    my $reg_data = {
                        key     => $header->{'jwk'},
                        contact => $payload->{'contacts'},
                    };

                    $self->_dump_file_json( "$reg_dir/$reg_index", $reg_data );

                    return (
                        201 => 'Created',
                        {
                            Location => $reg_url,
                            Link     => '<http://cp-terms>;rel="terms-of-service"',
                        },
                        $reg_data,
                    );
                }
            },

            'post:mock-acme/mock-new-authz' => sub {
                my ( $header, $payload ) = @_;

                my $domain = $payload->{'identifier'}{'value'};

                return(
                    201 => 'Created',
                    {
                        Location => 'https://authz/' . rand,
                    },
                    {
                        status     => 'pending',
                        identifier => $payload->{'identifier'},
                        challenges => [
                            {
                                type  => 'weird-01',
                                uri   => 'https://doesnt/matter',
                                token => 'weird_token',
                            },
                            {
                                type  => 'http-01',
                                uri   => 'https://http/challenge',
                                token => 'http_challenge_token',
                            },
                        ],

                        combinations => [ [0], [1] ],
                    },
                );
            },
        },
        $todo_as_client_cr,
    );

    return;
}

sub _reset_server : Tests(setup) {
    my ($self) = @_;

    #Store the nonces on disk … but is this necessary?
    $self->{'_nonce_path'} = File::Temp::tempdir(CLEANUP => 1) . '/nonce';

    (undef, $self->{'_rest_calls_file'}) = File::Temp::tempfile(CLEANUP => 1);
    $self->_dump_file_json( $self->{'_rest_calls_file'}, [] );

    return;
}

#TODO: Make this more flexible, and refactor it to a separate module.
#sub _do_json_rest_server {
#    my ( $self, %opts ) = @_;
#
#    die 'Don’t do “process_http_request” with this!' if $opts{'process_http_request'};
#
#    my $endpoints_hr = $opts{'endpoints_hr'} or die 'Need “endpoints_hr”!';
#
#    $self->{'_rest_calls_file'} = $self->tempfile();
#    Cpanel::JSON::DumpFile( $self->{'_rest_calls_file'}, [] );
#
#    #We have to store the nonces on disk because Net::Server::HTTP sometimes
#    #reuses the same process.
#    local $self->{'_nonce_path'} = $self->tempdir() . '/nonce';
#
#    $opts{'process_http_request'} = sub {
#        my ( $http_self, $handle, $postdata ) = @_;
#
#        my $rest_calls_ar = Cpanel::JSON::LoadFile( $self->{'_rest_calls_file'} );
#
#        push @$rest_calls_ar, {
#            ENV  => \%ENV,
#            POST => $postdata,
#        };
#
#        Cpanel::JSON::DumpFile( $self->{'_rest_calls_file'}, $rest_calls_ar );
#
#        my ( $header, $payload ) = $postdata ? _decode_jwt($postdata) : ();
#
#        if ( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
#            if ( !$self->_check_nonce( $header->{'nonce'} ) ) {
#                diag explain [ "bad nonce in PID $$", $header->{'nonce'} ];
#                $self->_server_send_response( 400, reason => 'Bad nonce (cP)' );
#                return;
#            }
#        }
#
#        for my $ep ( keys %$endpoints_hr ) {
#            if ( $ENV{'REQUEST_URI'} =~ qr<\A/$ep> ) {
#                return $endpoints_hr->{$ep}->( $self, $postdata, $header, $payload );
#            }
#        }
#
#        $self->_server_send_response(404);
#    };
#
#    return $self->_do_ssl_server(%opts);
#}

sub _server_send_directory {
    my ($self) = @_;

    return (
        200 => 'OK',
        {},
        $self->_DIRECTORY(),
    );
}

sub _get_rest_calls {
    my ($self, $acme_key) = @_;

    die 'list!' if !wantarray;

    my @requests = @{ $self->_load_file_json( $self->{'_rest_calls_file'} ) };

    for my $r (@requests) {
        next if !$r->{'POST'};
        $r->{'POST'} = [ _decode_jwt( $r->{'POST'}, $acme_key ) ];
    }

    return @requests;
}

#sub _server_send_response {
#    my ( $self, $status, %opts ) = @_;
#
#    my $nonce = Digest::SHA::sha256_hex( $$ . time . rand );
#    $self->_add_nonce($nonce);
#
#    $opts{'headers_ar'} ||= [];
#    push @{ $opts{'headers_ar'} }, 'Replay-Nonce' => $nonce;
#
#    return $self->SUPER::_server_send_response( $status, %opts );
#}

#NB: ACME’s replay protection works thus:
#   - each server response includes a nonce
#   - each request must include ONE of the nonces that have been sent
#   - once used, a nonce can’t be reused
#
#This is subtly different from what was originally in mind (i.e., that
#each request must use the most recently sent nonce). It implies that GET
#requests do not need to send nonces, though each GET response will
#include a nonce that may be used.
sub _add_nonce {
    my ( $self, $nonce ) = @_;

    my $nonces_hr = ( -s $self->{'_nonce_path'} ) ? $self->_load_file_json( $self->{'_nonce_path'} ) : {};

    $nonces_hr->{$nonce} = 1;

    $self->_dump_file_json( $self->{'_nonce_path'}, $nonces_hr );

    return;
}

sub _check_nonce {
    my ( $self, $nonce ) = @_;

    my $nonces_hr = $self->_load_file_json( $self->{'_nonce_path'} );

    my $val = delete $nonces_hr->{$nonce};

    $self->_dump_file_json( $self->{'_nonce_path'}, $nonces_hr );

    return $val;
}

#----------------------------------------------------------------------

package t::Net::ACME::MockService;

use parent qw( Net::ACME );

sub _HOST {
    return 'some.far.away.host';
}

1;
