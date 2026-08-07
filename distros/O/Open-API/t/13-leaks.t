#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;
use Open::API::Plack;

# Compile/validate/destroy cycles hold RSS flat: the keepalive AV owns every
# SV in the table (including the JSF handles), so DESTROY must release the
# lot. A generous threshold keeps this stable across allocators.

plan skip_all => 'no ps for RSS on this platform'
    unless $^O =~ /darwin|linux|bsd/i;

sub rss_kb {
    my $r = `ps -o rss= -p $$`;
    $r =~ s/\s+//g;
    return $r || 0;
}

my $SPEC = "$FindBin::Bin/spec/petstore.json";

# warm up allocator + caches
for (1 .. 100) {
    my $api = Open::API->new(spec => $SPEC);
    $api->validate_request('getPet', { path => { petId => '5' } });
}

my $before = rss_kb();
for (1 .. 500) {
    my $api = Open::API->new(spec => $SPEC);
    my ($ok)  = $api->validate_request('getPet', { path => { petId => '5' } });
    my ($bad) = $api->validate_request('getPet', { path => { petId => 'x' } });
    my $plack = Open::API::Plack->new(api => $api);
    $plack->handlers(getPet => sub { { id => 1 } })
          ->security({})
          ->max_body_size(1024);
    my $app = $plack->to_app;
    open my $in, '<', \(my $b = '') or die;
    $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/pets/5',
             QUERY_STRING => '', 'psgi.input' => $in });
    die 'validate broke' unless $ok && !$bad;
}
my $after = rss_kb();

my $growth = $after - $before;
diag("RSS before=$before kB after=$after kB growth=$growth kB (500 cycles)");
cmp_ok($growth, '<', 4096, 'less than 4 MB growth over 500 full cycles');

done_testing();
