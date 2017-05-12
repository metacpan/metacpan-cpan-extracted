use strict;
use warnings;
use lib 'lib';
use HTTP::Engine;
use String::TT qw/strip tt/;
use Net::OpenID::Consumer::Lite;
use Net::HTTPS;

my $port = shift || 1978;
my $host = shift || '127.0.0.1';

my $OP_MAP = +{
    mixi     => 'https://mixi.jp/openid_server.pl',
    livedoor => 'https://auth.livedoor.com/openid/server',
};

local $Net::OpenID::Consumer::Lite::IGNORE_SSL_ERROR = 1;

sub res {
    HTTP::Engine::Response->new(
        @_
    );
}

HTTP::Engine->new(
    interface => {
        module => 'ServerSimple',
        args   => {
            host => $host,
            port => $port,
        },
        request_handler => sub {
            my $req = shift;
            if ($req->params->{check}) {
                # do login(step 2)
                my $op = $req->params->{op} or die "missing parameter";
                my $server_url = $OP_MAP->{$op};
                my $check_url = Net::OpenID::Consumer::Lite->check_url(
                    $server_url,
                    "http://${host}:$port/?back=1",
                    {
                        "http://openid.net/extensions/sreg/1.1" => { required => join( ",", qw/email nickname/ ) }
                    }
                );
                return res(
                    status  => 302,
                    headers => {
                        Location => $check_url,
                    },
                );
            } elsif ($req->params->{back}) {
                # handle OP server response(step 3)
                warn "your SSL Socket class is $Net::HTTPS::SSL_SOCKET_CLASS\n";
                Net::OpenID::Consumer::Lite->handle_server_response(
                    $req->params() => (
                        not_openid => sub {
                            die "Not an OpenID message";
                        },
                        setup_required => sub {
                            my $setup_url = shift;
                            return res(
                                status  => 302,
                                headers => {
                                    Location => $setup_url,
                                },
                            );
                        },
                        cancelled => sub {
                            return res(
                                status  => 200,
                                body    => '<div style="color:red">user cancelled</div>',
                            );
                        },
                        verified => sub {
                            my $vident = shift;
                            my $ident = do {
                                my @lines;
                                while (my ($key, $val) = each %$vident) {
                                    push @lines, "$key => $val";
                                }
                                "<pre>" . join("\n", @lines) . "</pre>";
                            };
                            return res(
                                status  => 200,
                                body    => qq{<div style="color:blue">verified</div> $ident},
                            );
                        },
                        error => sub {
                            my $err = shift;
                            die($err);
                        },
                    )
                );
            } else {
                # select OP(step 1)
                return res(
                    status  => 200,
                    body    => tt strip q{
                        <!doctype html>
                        <h1>OP list</h1>
                        <ul>
                        [% FOR op IN OP_MAP.keys %]
                        <li><a href="/?check=1&op=[% op | url %]">login by [% op | html %]</a></li>
                        [% END %]
                        </ul>
                    }
                );
            }
        },
    },
)->run;

