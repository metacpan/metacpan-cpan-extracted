use strict;
use warnings;
use Test::More;
use Test::Requires qw(
    LWP::UserAgent
    LWP::Protocol::PSGI
);

use PAD;

my $pad = PAD->new(plugin => 'PAD::Plugin::Static', extra => 'foo');

isa_ok $pad, 'PAD';

is_deeply { %$pad }, {
    plugin => 'PAD::Plugin::Static',
    args   => {
        plugin => 'PAD::Plugin::Static',
        extra  => 'foo',
    }
};

is $pad->plugin, 'PAD::Plugin::Static';

subtest request => sub {
    LWP::Protocol::PSGI->register($pad->psgi_app);
    my $ua = LWP::UserAgent->new;

    like $ua->get('http://localhost')->content, qr|<title>Index of /</title>|;
    like $ua->get('http://localhost/Changes')->content, qr|Revision history|;
};

done_testing;
