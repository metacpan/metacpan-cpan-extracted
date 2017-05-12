package Net::OATH::Server::Lite::Endpoint::Login;
use strict;
use warnings;
use overload
    q(&{})   => sub { shift->psgi_app },
    fallback => 1;

use Try::Tiny qw/try catch/;
use Plack::Request;
use Params::Validate;
use JSON::XS qw/decode_json encode_json/;

use Net::OATH::Server::Lite::Login;
use Net::OATH::Server::Lite::Error;

sub new {
    my $class = shift;
    my %args = Params::Validate::validate(@_, {
        data_handler => 1,
    });
    my $self = bless {
        data_handler   => $args{data_handler},
    }, $class;
    return $self;
}

sub data_handler {
    my ($self, $handler) = @_;
    $self->{data_handler} = $handler if $handler;
    $self->{data_handler};
}

sub psgi_app {
    my $self = shift;
    return $self->{psgi_app}
        ||= $self->compile_psgi_app;
}

sub compile_psgi_app {
    my $self = shift;

    my $app = sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        my $res; try {
            $res = $self->handle_request($req);
        } catch {
            # Internal Server Error
            warn $_;
            $res = $req->new_response(500);
        };
        return $res->finalize;
    };

    return $app;
}

sub handle_request {
    my ($self, $request) = @_;

    my $res = try {

        # DataHandler
        my $data_handler = $self->{data_handler}->new(request => $request);
        Net::OATH::Server::Lite::Error->throw(
            code => 500,
            error => q{server_error},
        ) unless ($data_handler && $data_handler->isa(q{Net::OATH::Server::Lite::DataHandler}));

        # REQUEST_METHOD
        Net::OATH::Server::Lite::Error->throw()
            unless ($request->method eq q{POST});

        my $params;
        eval {
            $params = decode_json($request->content);
        };
        Net::OATH::Server::Lite::Error->throw() unless $params;

        my ($is_valid, $user) = Net::OATH::Server::Lite::Login->is_valid_user($data_handler, $params);

        if ($is_valid) {
            my $response_params = {
                id => $user->id,
            };
            return $request->new_response(200,
                [ "Content-Type"  => "application/json;charset=UTF-8",
                  "Cache-Control" => "no-store",
                  "Pragma"        => "no-cache" ],
                [ encode_json($response_params) ]);
        } else {
            Net::OATH::Server::Lite::Error->throw(
                code => 400,
                description => q{invalid password},
            );
        }

    } catch {
        if ($_->isa("Net::OATH::Server::Lite::Error")) {
            my $error_params = {
                error => $_->error,
            };
            $error_params->{error_description} = $_->description if $_->description;

            return $request->new_response($_->code,
                [ "Content-Type"  => "application/json;charset=UTF-8",
                  "Cache-Control" => "no-store",
                  "Pragma"        => "no-cache" ],
                [ encode_json($error_params) ]);
        } else {
            die $_;
        }
    };
}

1;
