use strict;
use warnings;
use Test::More;
use PAD::Plugin::Markdown;
use Plack::Request;

my $request = Plack::Request->new({ PATH_INFO => '/t/test.md' });

my $plugin = PAD::Plugin::Markdown->new(
    plugin  => 'PAD::Plugin::Markdown',
    extra   => 'foo',
    request => $request,
);

isa_ok $plugin, 'PAD::Plugin::Markdown';

is_deeply { %$plugin }, {
    plugin  => 'PAD::Plugin::Markdown',
    extra   => 'foo',
    request => $request,
};

is $plugin->relative_path, 't/test.md';

my $res  = $plugin->execute;
my $body = delete $res->[2];

is_deeply $res, [
    200,
    ['Content-Type' => 'text/html; charset=UTF-8'],
];

like $body->[0], qr|<h1>head</h1>|;

done_testing;

