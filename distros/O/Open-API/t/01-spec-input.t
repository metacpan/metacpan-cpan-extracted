#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;

# The four spec input forms - hashref, JSON text, YAML text, filename - and
# the rejection cases (3.0 documents, garbage, missing version, bad refs).

my $HAVE_YAML = eval { require YAML::XS; 1 };

my %doc = (
    openapi => '3.1.0',
    info    => { title => 'Mini', version => '1.0.0' },
    paths   => {
        '/ping' => {
            get => {
                operationId => 'ping',
                responses   => {
                    200 => {
                        description => 'pong',
                        content     => {
                            'application/json' => { schema => { type => 'object' } },
                        },
                    },
                },
            },
        },
    },
);

# ---- hashref ---------------------------------------------------------------
{
    my $api = Open::API->new(spec => \%doc);
    isa_ok($api, 'Open::API', 'hashref spec');
    is($api->spec->{openapi}, '3.1.0', 'document readable back');
}

# ---- JSON text -------------------------------------------------------------
{
    my $json = qq({"openapi":"3.1.0","info":{"title":"Mini","version":"1.0.0"},"paths":{}});
    my $api  = Open::API->new(spec => $json);
    isa_ok($api, 'Open::API', 'JSON text spec');
    is($api->spec->{info}{title}, 'Mini', 'JSON text decoded');
}

# ---- JSON filename ---------------------------------------------------------
{
    my $api = Open::API->new(spec => "$FindBin::Bin/spec/mini.json");
    isa_ok($api, 'Open::API', 'JSON filename spec');
    is($api->spec->{paths}{'/ping'}{get}{operationId}, 'ping', 'file decoded');
}

# ---- YAML text + filename --------------------------------------------------
SKIP: {
    skip 'YAML::XS not installed', 4 unless $HAVE_YAML;

    my $yaml = "openapi: 3.1.0\ninfo:\n  title: Mini\n  version: 1.0.0\npaths: {}\n";
    my $api  = Open::API->new(spec => $yaml);
    isa_ok($api, 'Open::API', 'YAML text spec');
    is($api->spec->{info}{title}, 'Mini', 'YAML text decoded');

    my $fapi = Open::API->new(spec => "$FindBin::Bin/spec/mini.yaml");
    isa_ok($fapi, 'Open::API', 'YAML filename spec');
    is($fapi->spec->{paths}{'/ping'}{get}{operationId}, 'ping', 'YAML file decoded');
}

# ---- rejections ------------------------------------------------------------
{
    my $err;

    eval { Open::API->new(spec => { %doc, openapi => '3.0.3' }) } or $err = $@;
    like($err, qr/3\.1 only.*3\.0\.3/s, 'a 3.0 document croaks');

    undef $err;
    eval { Open::API->new(spec => { info => {} }) } or $err = $@;
    like($err, qr/no 'openapi' version/, 'missing openapi field croaks');

    undef $err;
    eval { Open::API->new(spec => '{"definitely":"broken"') } or $err = $@;
    like($err, qr/File::Raw::JSON|JSON/, 'broken JSON text croaks');

    undef $err;
    eval { Open::API->new(spec => [1, 2, 3]) } or $err = $@;
    like($err, qr/must be a hashref/, 'arrayref spec croaks');

    undef $err;
    eval { Open::API->new() } or $err = $@;
    like($err, qr/'spec' is required/, 'missing spec croaks');
}

done_testing();
