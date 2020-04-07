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
                negated => 1,
            },
        },
    };
}

my $env = {};

my $app = <: $module_name :>->new( $ENV->{cli}->{opt}->{devel}, $env );

my $cv = P->cv;

$app->run;

$app->run_nginx;

$cv->recv;

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 7                    | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=cut
