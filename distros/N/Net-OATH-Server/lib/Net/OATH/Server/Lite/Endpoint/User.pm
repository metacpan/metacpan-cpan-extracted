package Net::OATH::Server::Lite::Endpoint::User;
use strict;
use warnings;
use overload
    q(&{})   => sub { shift->psgi_app },
    fallback => 1;

use Try::Tiny qw/try catch/;
use Plack::Request;
use Params::Validate;
use JSON::XS qw/decode_json encode_json/;
use Convert::Base32 qw/encode_base32/;

use Net::OATH::Server::Lite::Error;
use Net::OATH::Server::Lite::User;

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
        my $code = 200;

        my $data_handler = $self->{data_handler}->new(request => $request);
        Net::OATH::Server::Lite::Error->throw(
            code => 500,
            error => q{server_error},
        ) unless ($data_handler && $data_handler->isa(q{Net::OATH::Server::Lite::DataHandler}));

        # HTTP method MUST be POST
        Net::OATH::Server::Lite::Error->throw() unless ($request->method eq q{POST});

        # content MUST be JSON
        my $content = {};
        eval {
            $content = decode_json($request->content) if $request->content;
        };
        Net::OATH::Server::Lite::Error->throw() if $@;

        unless (defined $content->{method} &&
                ($content->{method} eq q{create} ||
                 $content->{method} eq q{read} ||
                 $content->{method} eq q{update} ||
                 $content->{method} eq q{delete})) {
            Net::OATH::Server::Lite::Error->throw(
                description => q{method not found},
            );
        }

        my $user;
        if ($content->{method} eq q{create}) {
            ($code, $user) = Net::OATH::Server::Lite::User->create($data_handler, $content);
        }

        if ($content->{method} eq q{read}) {
            ($code, $user) = Net::OATH::Server::Lite::User->read($data_handler, $content);
        }

        if ($content->{method} eq q{update}) {
            ($code, $user) = Net::OATH::Server::Lite::User->update($data_handler, $content);
        }

        if ($content->{method} eq q{delete}) {
            ($code, $user) = Net::OATH::Server::Lite::User->delete($data_handler, $content);
        }

        my $params = ($content->{method} eq q{delete}) ? {} :
                     _create_response_from_user($user);

        return $request->new_response($code,
            [ "Content-Type"  => "application/json;charset=UTF-8",
              "Cache-Control" => "no-store",
              "Pragma"        => "no-cache" ],
            [ encode_json($params) ]);
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

sub _create_response_from_user {
    my ($user) = @_;
    return unless ($user && $user->isa(q{Net::OATH::Server::Lite::Model::User}));

    return {
        id        => $user->id,
        secret    => encode_base32($user->secret),
        type      => $user->type,
        algorithm => $user->algorithm,
        digits    => $user->digits,
        counter   => $user->counter,
        period    => $user->period,
    };
}

1;
