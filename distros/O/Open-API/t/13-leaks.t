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

# The 3.0 up-converter builds a whole second document at load, so every SV it
# allocates needs an owner or this is where it shows up.
{
    my $SPEC30 = "$FindBin::Bin/spec/petstore-3.0.json";
    for (1 .. 100) { Open::API->new(spec => $SPEC30) }   # warm up

    my $b30 = rss_kb();
    for (1 .. 500) {
        my $api = Open::API->new(spec => $SPEC30);
        my ($ok) = $api->validate_request('getPet', { path => { petId => '5' } });
        $api->check_response('getPet',
            [200, ['Content-Type' => 'application/json'],
             ['{"id":1,"name":"Rex","tag":null}']]);
        die 'validate broke' unless $ok;
    }
    my $a30 = rss_kb();
    my $g30 = $a30 - $b30;
    diag("3.0 RSS before=$b30 kB after=$a30 kB growth=$g30 kB (500 cycles)");
    cmp_ok($g30, '<', 4096, 'the 3.0 up-converter leaks nothing measurable');
}

# The discriminator expansion allocates a chain per discriminated schema, and
# the inheritance form inlines a whole converted child into it.
{
    my %spec = (
        openapi => '3.1.0', info => { title => 'T', version => '1.0.0' },
        paths => { '/t' => { post => {
            operationId => 'post_t',
            requestBody => { required => 1, content => { 'application/json' => {
                schema => { '$ref' => '#/components/schemas/Pet' } } } },
            parameters => [ { name => 'filter', in => 'query', content => {
                'application/json' => { schema => { type => 'object' } } } } ],
            responses => { 200 => { description => 'ok' } },
        } } },
        components => { schemas => {
            Pet => { type => 'object', required => ['petType'],
                     properties => { petType => { type => 'string' } },
                     discriminator => { propertyName => 'petType' } },
            Dog => { allOf => [ { '$ref' => '#/components/schemas/Pet' },
                                { required => ['bark'],
                                  properties => { bark => { type => 'string' } } } ] },
            Cat => { allOf => [ { '$ref' => '#/components/schemas/Pet' },
                                { required => ['meow'],
                                  properties => { meow => { type => 'string' } } } ] },
        } },
    );
    for (1 .. 100) { Open::API->new(spec => \%spec) }   # warm up

    my $bd = rss_kb();
    for (1 .. 500) {
        my $api = Open::API->new(spec => \%spec);
        my ($ok) = $api->validate_request('post_t', {
            header => { 'content-type' => 'application/json' },
            query  => 'filter={"a":1}',
            body   => '{"petType":"Dog","bark":"woof"}' });
        die 'validate broke' unless $ok;
        $api->synthesize('post_t');
    }
    my $ad = rss_kb();
    my $gd = $ad - $bd;
    diag("discriminator RSS before=$bd kB after=$ad kB growth=$gd kB (500 cycles)");
    cmp_ok($gd, '<', 4096, 'the discriminator expansion leaks nothing measurable');
}

done_testing();
