#!/usr/bin/env perl

package main v0.1.0;

use Pcore -forktmpl;
use <: $module_name :>;
use <: $module_name ~ "::Const qw[]" :>;

sub CLI {
    return {
        opt => {
            devel => {    #
                desc    => 'Run in development mode.',
                default => 0,
            },
        },
    };
}

# load app config
my $cfg = P->cfg->read( "$ENV->{DATA_DIR}/cfg.yaml", params => { DATA_DIR => $ENV->{DATA_DIR} } );

my $app = <: $module_name :>->new(
    {                     #
        cfg => {

            # DB
            db => $cfg->{db},

            # SERVER
            server => {    # passed directly to the Pcore::HTTP::Server constructor
                listen => '/var/run/<: $dist_path :>.sock',
                ssl    => 0,
            },

            # ROUTER
            router => {    # passed directly to the Pcore::App::Router
                '*' => undef,

                # 'host1.com' => 'Test::App::App1',
                # 'host2.com' => 'Test::App::App2',
            },

            # NODE
            node => {
                server => $cfg->{node}->{server},
                listen => $cfg->{node}->{listen},
            },

            # API
            api => {
                backend => $cfg->{db},
                node    => {
                    workers => undef,
                    argon   => {
                        argon2_time        => 3,
                        argon2_memory      => '64M',
                        argon2_parallelism => 1,
                    },
                },
            },
        },
        devel => $ENV->{cli}->{opt}->{devel},
    },
);

my $cv = P->cv;

$app->run;

$app->start_nginx;

$cv->recv;

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 7                    | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 32                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=cut
