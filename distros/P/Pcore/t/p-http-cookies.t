#!/usr/bin/env perl

package main v0.1.0;

use Pcore;
use Test::More;
use Pcore::HTTP::Cookies;
use Pcore::Util::URI::Host;

my $test_data = {
    set_cover_domain => [    #
        [ 'www.aaa.ru', '.aaa.ru',      1 ],    # allow to set cover cookie to !pub. suffix
        [ 'www.aaa.ru', '.www.aaa.ru',  1 ],    # allow to set cover cookie to !pub. suffix
        [ 'www.aaa.ru', '.ru',          0 ],
        [ 'www.aaa.ru', 'bbb.ru',       0 ],    # permit to set cover cookie to not cover domain
        [ 'www.aaa.ru', 'a.www.aaa.ru', 0 ],    # permit to set cover cookie to not cover domain

        [ 'www.ck', 'ck',      0 ],             # permit to set cover cookie to pub. suffix
        [ 'www.ck', '.www.ck', 1 ],             # alow to set cover cookie

        # set cover cookie from pub. suffix url
        [ 'aaa.ck', '.ck',     0 ],             # permit to set cover cookie to pub. suffix
        [ 'aaa.ck', '.aaa.ck', 0 ],             # permit to set cover cookie from pub. suffix
        [ 'aaa.ck', 'aaa.ck',  1 ],             # allow to set origin cookie from pub. suffix
    ],
    get_cookies => [                            #
        [ 'www.aaa.ru', ['1;domain=;path='],       'www.aaa.ru', [qw[1]] ],
        [ 'www.aaa.ru', ['2;domain=;path='],       'www.aaa.ru', [qw[1 2]] ],
        [ 'www.aaa.ru', ['3;domain=aaa.ru;path='], 'www.aaa.ru', [qw[1 2 3]] ],
        [ 'www.aaa.ru', [], 'ccc.www.aaa.ru', [qw[3]] ],

        # compute.amazonaws.com only covers itself, since it's a public suffix;
        # amazonaws.com covers amazonaws.com, www.amazonaws.com, foo.www.amazonaws.com, and compute.amazonaws.com;
        # amazonaws.com does not cover foo.compute.amazonaws.com;

        [ 'compute.amazonaws.com', ['4;domain=compute.amazonaws.com'], 'compute.amazonaws.com', [qw[4]] ],
        [ 'amazonaws.com',         ['5;domain=amazonaws.com'],         'amazonaws.com',         [qw[5]] ],
        [ 'amazonaws.com', [], 'www.amazonaws.com',             [qw[5]] ],
        [ 'amazonaws.com', [], 'foo.www.amazonaws.com',         [qw[5]] ],
        [ 'amazonaws.com', [], 'compute.amazonaws.com',         [qw[4 5]] ],
        [ 'amazonaws.com', [], 'foo.compute.amazonaws.com',     [] ],
        [ 'amazonaws.com', [], 'www.foo.compute.amazonaws.com', [] ],

        # expired cookie
        [ 'amazonaws.com', [ '5;domain=amazonaws.com;expires=' . P->date->now_utc->minus_days(1)->to_http_date ], 'compute.amazonaws.com', [qw[4]] ],
    ],
};

our $TESTS = $test_data->{set_cover_domain}->@* + $test_data->{get_cookies}->@*;

plan tests => $TESTS;

set_cover_domain();

get_cookies();

sub set_cover_domain {
    for my $args ( $test_data->{set_cover_domain}->@* ) {
        state $i = 0;

        my $c = Pcore::HTTP::Cookies->new;

        $c->parse_cookies( 'http://' . $args->[0], ["1=2;domain=$args->[1]"] );

        unless ( ( exists $c->{cookies}->{ $args->[1] } ? 1 : 0 ) == $args->[2] ) {
            say {$STDERR_UTF8} dump $c->{cookies};
        }

        ok( ( exists $c->{cookies}->{ $args->[1] } ? 1 : 0 ) == $args->[2], 'set_cover_domain_' . $i++ . '_' . $args->[1] );
    }

    return;
}

sub get_cookies {
    delete Pcore::Util::URI::Host->pub_suffixes->{'amazonaws.com'};

    my $c = Pcore::HTTP::Cookies->new;

    for my $args ( $test_data->{get_cookies}->@* ) {
        state $i = 0;

        $c->parse_cookies( 'http://' . $args->[0], $args->[1] );

        my $index->@{ map {"$_="} $args->[3]->@* } = ();

        my $cookies->@{ ( $c->get_cookies("http://$args->[2]") // [] )->@* } = ();

        if ( !keys $index->%* ) {
            if ( !keys $cookies->%* ) {
                ok( 1, 'get_cookies_' . $i++ );
            }
            else {
                ok( 0, 'get_cookies_' . $i++ );
            }
        }
        else {
            if ( !keys $cookies->%* ) {
                say {$STDERR_UTF8} dump { expect => [ sort keys $index->%* ], got => [ sort keys $cookies->%* ], cookies => $c->{cookies} };

                ok( 0, 'get_cookies_' . $i++ );
            }
            else {
                my $match = 1;

                # compare
                for ( keys $index->%*, keys $cookies->%* ) {
                    if ( !exists $index->{$_} || !exists $cookies->{$_} ) {
                        $match = 0;

                        last;
                    }
                }

                if ( !$match ) {
                    say {$STDERR_UTF8} dump { expect => [ sort keys $index->%* ], got => [ sort keys $cookies->%* ], cookies => $c->{cookies} };

                    ok( 0, 'get_cookies_' . $i++ );
                }
                else {
                    ok( 1, 'get_cookies_' . $i++ );
                }
            }
        }
    }

    return;
}

done_testing $TESTS;

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 45                   | ValuesAndExpressions::ProhibitLongChainsOfMethodCalls - Found method-call chain of length 4                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=cut
