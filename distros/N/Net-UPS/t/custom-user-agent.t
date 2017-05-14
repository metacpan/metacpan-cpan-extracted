#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Net::UPS;
use Data::Dump 'pp';

subtest 'default values' => sub {
    my $ups = Net::UPS->new(
        'user','pass','accesskey',
    );
    cmp_deeply(
        $ups->ssl_options,
        {
            SSL_verify_mode => 1,
            SSL_verifycn_scheme => 'www',
            SSL_ca => [ ignore() ],
            SSL_ca_file => ignore(),
        },
        'ssl_options'
    );

    cmp_deeply(
        $ups->user_agent,
        all(
            isa('LWP::UserAgent'),
            listmethods(
                ssl_opts => superbagof('SSL_ca_file'),
            ),
        ),
        'user_agent, with SSL options set',
    );
};

subtest 'custom SSL options' => sub {
    my $ups = Net::UPS->new(
        'user','pass','accesskey',{
            ssl_options => { foo => 'bar' },
        }
    );
    cmp_deeply(
        $ups->ssl_options,
        { foo => 'bar' },
        'ssl_options'
    );

    cmp_deeply(
        $ups->user_agent,
        all(
            isa('LWP::UserAgent'),
            listmethods(
                ssl_opts => superbagof('foo'),
            ),
        ),
        'user_agent, with SSL options set',
    );
};

subtest 'custom user agent' => sub {
    my $ups = Net::UPS->new(
        'user','pass','accesskey',{
            ssl_options => { foo => 'bar' },
            user_agent => do {bless {},'Something'},
        }
    );
    cmp_deeply(
        $ups->ssl_options,
        { foo => 'bar' },
        'ssl_options'
    );

    cmp_deeply(
        $ups->user_agent,
        isa('Something'),
        'user_agent, *without* SSL options set',
    );
};

done_testing();
