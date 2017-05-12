#!/usr/bin/perl

# an example of requiring authentication. run script e.g. using:
#
#   % plackup -Ilib examples/auth.psgi
#   HTTP::Server::PSGI: Accepting connections at http://0:5000/
#
# then access e.g. using:
#
#   % curl -u admin:123 http://localhost:5000/Perinci/Examples/gen_array?-riap-action=meta
#   % curl -u admin:123 'http://localhost:5000/Perinci/Examples/gen_array?len=5&-riap-fmt=json'

use 5.010;
use strict;
use warnings;

use Perinci::Access::Base::Patch::PeriAHS;
use Plack::Builder;

use Perinci::Examples;

my $app = builder {
    #enable(
    #    "PeriAHS::LogAccess",
    #    dest => $riap_access_log_path
    #);

    #enable "PeriAHS::CheckAccess";

    enable(
        "Auth::Basic",
        authenticator => sub {
            my ($user, $pass) = @_;
            return $user eq 'admin' && $pass eq '123';
        },
    );

    enable(
        "PeriAHS::ParseRequest",
        #parse_path_info => $args{parse_path_info},
        #parse_form      => $args{parse_form},
        #parse_reform    => $args{parse_reform},
    );

    enable "PeriAHS::Respond";
};

