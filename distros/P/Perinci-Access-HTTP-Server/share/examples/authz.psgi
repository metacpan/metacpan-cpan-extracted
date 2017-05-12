#!/usr/bin/perl

# an example of doing authorization. currently done manually. there will be a
# middleware (currently unfinished) to allow creating an ACL configuration for
# this.
#
# the application recognizes two users: 'admin' (pass: 123) and 'user' (pass:
# 456). 'user' is not allowed to access functions whose name starts with 'gen_'.
#
# to run this app:
#
#   % plackup -Ilib examples/authz.psgi
#   HTTP::Server::PSGI: Accepting connections at http://0:5000/
#
# then access e.g. using:
#
#   % curl -u admin:123 http://localhost:5000/Perinci/Examples/gen_array?len=5 ; # OK
#   % curl -u user:456  http://localhost:5000/Perinci/Examples/noop; # OK
#   % curl -u user:456  http://localhost:5000/Perinci/Examples/gen_array; # 403

use 5.010;
use strict;
use warnings;

use Perinci::Access::Base::Patch::PeriAHS;
use Plack::Builder;
use Plack::Util::PeriAHS qw(errpage);

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
            return 1 if $user eq 'admin' && $pass eq '123';
            return 1 if $user eq 'user'  && $pass eq '456';
            return 0;
        },
    );

    enable(
        "PeriAHS::ParseRequest",
        #parse_path_info => $args{parse_path_info},
        #parse_form      => $args{parse_form},
        #parse_reform    => $args{parse_reform},
    );

    # authz
    enable(
        sub {
            my $app = shift;
            sub {
                my $env = shift;

                # do preprocessing
                my $rreq = $env->{'riap.request'};
                my $user = $env->{REMOTE_USER};
                return errpage($env, [403, 'Unauthorized'])
                    if $user ne 'admin' && $rreq->{uri} =~ m!/gen_[^/]+$!;

                my $res = $app->($env);
                # do post-processing
                $res;
            };
        },
    );

    enable "PeriAHS::Respond";
};

