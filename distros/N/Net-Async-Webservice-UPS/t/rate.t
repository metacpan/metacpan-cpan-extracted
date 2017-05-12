#!perl
use strict;
use warnings;
use 5.010;
use lib 't/lib';
use Test::Most;
use Net::Async::Webservice::UPS;
use Net::Async::Webservice::UPS::Package;
use File::Spec;
use Sub::Override;
use Test::Net::Async::Webservice::UPS;
use Test::Net::Async::Webservice::UPS::TestCache;
eval { require IO::Async::Loop; require Net::Async::HTTP }
    or do {
        plan(skip_all=>'this test only runs with IO::Async and Net::Async::HTTP');
        exit(0);
    };

my $loop = IO::Async::Loop->new;

my $orig_post = \&Net::Async::Webservice::UPS::post;
my @calls;
my $new_post = Sub::Override->new(
    'Net::Async::Webservice::UPS::post',
    sub {
        push @calls,[@_];
        $orig_post->(@_);
    }
);

my $cache = Test::Net::Async::Webservice::UPS::TestCache->new();

my $ups = Net::Async::Webservice::UPS->new({
    config_file => Test::Net::Async::Webservice::UPS->conf_file,
    cache => $cache,
    loop => $loop,
});

my $package =
    Net::Async::Webservice::UPS::Package->new({
        length => 34,
        width => 24,
        height => 1.5,
        weight => 1,
        measurement_system => 'english',
    });

ok($package, 'packages can be created');

my $argpack = {
    from => 15241,
    to => 48823,
    packages => $package,
    mode => 'rate',
    service => 'GROUND',
};

my $services = $ups->request_rate($argpack)->get;
ok($services && @{$services->services},'got answer');
cmp_deeply(\@calls,
           [[ ignore(),re(qr{/Rate$}),ignore() ]],
           'one call to the service');

my $services2 = $ups->request_rate($argpack)->get;
ok($services2 && @{$services2->services},'got answer again');
cmp_deeply($services2,$services,'the same answer');
cmp_deeply(\@calls,
           [[ ignore(),re(qr{/Rate$}),ignore() ]],
           'still only one call to the service');

done_testing();
