#!/usr/bin/env perl

use strict;
use warnings;

use Log::Any::Adapter ( 'Stdout', log_level => 'debug' );
use Template::Resolver;
use Test::More tests => 6;

BEGIN { use_ok('Template::Resolver') }

sub resolver {
    return Template::Resolver->new(@_);
}

is( resolver(
        {   employees => [
                {   name   => 'Bob',
                    awards => [
                        { type => 'BEST',          received => 2 },
                        { type => 'PARTICIPATION', received => 12 }
                    ]
                },
                {   name   => 'Jane',
                    awards => [
                        { type => 'BEST',          received => 7 },
                        { type => 'PARTICIPATION', received => 5 }
                    ]
                },
            ]
        }
        )->resolve(
        key     => 'T',
        content => '${T<EMP>:{employees}}'
            . '${T<EMP.ix>}. ${T{<EMP>.name}}:' . "\n"
            . '${T<AWD>:{<EMP>.awards}}'
            . '   ${T<AWD.ix>}: ${T{<EMP>.name}} got ${T{<AWD>.received}} ${T{<AWD>.type}} awards'
            . "\n"
            . '${T<AWD>:end}'
            . '${T<EMP>:end}'
        ),
    "0. Bob:\n"
        . "   0: Bob got 2 BEST awards\n"
        . "   1: Bob got 12 PARTICIPATION awards\n"
        . "1. Jane:\n"
        . "   0: Jane got 7 BEST awards\n"
        . "   1: Jane got 5 PARTICIPATION awards\n",
    'Simple placeholder'
);

is( resolver(
        {   employees => {
                'Bob' => {
                    awards => {
                        BEST          => { received => 2 },
                        PARTICIPATION => { received => 12 }
                    }
                },
                'Jane' => {
                    awards => {
                        BEST          => { received => 7 },
                        PARTICIPATION => { received => 5 }
                    }
                },
            }
        }
        )->resolve(
        key     => 'T',
        content => '${T<EMP>:{employees}}'
            . '${T<EMP.key>}:' . "\n"
            . '${T<AWD>:{<EMP>.awards}}'
            . '   ${T<EMP.key>} got ${T{<AWD>.received}} ${T<AWD.key>} awards' . "\n"
            . '${T<AWD>:end}'
            . '${T<EMP>:end}'
        ),
    "Bob:\n"
        . "   Bob got 2 BEST awards\n"
        . "   Bob got 12 PARTICIPATION awards\n"
        . "Jane:\n"
        . "   Jane got 7 BEST awards\n"
        . "   Jane got 5 PARTICIPATION awards\n",
    'Simple placeholder'
);

is( resolver(
        {   employees => {
                'Bob' => {
                    awards => {
                        BEST          => { received => 2 },
                        PARTICIPATION => { received => 12 }
                    }
                },
                'Jane' => {
                    awards => {
                        BEST          => { received => 7 },
                        PARTICIPATION => { received => 5 }
                    }
                },
            }
        }
        )->resolve(
        key     => 'T',
        content => '${T<EMP>:{employees}}'
            . 'TEAM ${T_perl{("<EMP.key>" eq "Bob") ? "BUBBA" : "GUMP"}}:' . "\n"
            . '${T<AWD>:{<EMP>.awards}}'
            . '   ${T<EMP.key>} got ${T_perl{(property("<AWD>.received") > 5) ? "many" : "few"}} ${T<AWD.key>} awards'
            . "\n"
            . '${T<AWD>:end}'
            . '${T<EMP>:end}'
        ),
    "TEAM BUBBA:\n"
        . "   Bob got few BEST awards\n"
        . "   Bob got many PARTICIPATION awards\n"
        . "TEAM GUMP:\n"
        . "   Jane got many BEST awards\n"
        . "   Jane got few PARTICIPATION awards\n",
    'Simple placeholder'
);

is( resolver( { a => { value => '_VALUE_' } } )
        ->resolve( key => 'T', content => 'A${T{a.value}}A' ),
    'A_VALUE_A',
    'Simple placeholder'
);

is( resolver(
        {   web => {
                context_path => '/foo',
                hostname     => 'example.com',
                https        => 1,
                port         => 8443
            }
        },
        additional_transforms => {
            web_url => sub {
                my ( $self, $value ) = @_;

                my $url =
                    $self->_property("$value.https")
                    ? 'https://'
                    : 'http://';

                $url .= $self->_property("$value.hostname")
                    || croak("hostname required for web_url");

                my $port = $self->_property("$value.port");
                $url .= ":$port" if ($port);

                $url .= $self->_property("$value.context_path") || '';

                return $url;
            }
        }
        )->resolve( key => 'T', content => 'A${T_web_url{web}}A' ),
    'Ahttps://example.com:8443/fooA',
    'Custom transformer'
);
