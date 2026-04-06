use v5.26;
use strict;
use warnings;
use Test::More;
use File::Spec;
use Modern::OpenAPI::Generator::Spec;

my $yaml = File::Spec->catfile( 't', 'data', 'minimal.yaml' );
my $json = File::Spec->catfile( 't', 'data', 'minimal.json' );

{
    my $s = Modern::OpenAPI::Generator::Spec->load($yaml);
    is( $s->openapi_version, '3.0.0', 'openapi_version from yaml' );
    is( $s->title,           'Minimal', 'title' );
    my $ops = $s->operations;
    is( @$ops, 1, 'one operation' );
    is( $ops->[0]{operation_id}, 'get_ping', 'operationId' );
}

{
    my $s = Modern::OpenAPI::Generator::Spec->load($json);
    is( $s->title, 'Minimal', 'load json' );
    is( $s->raw->{openapi}, '3.0.0', 'raw openapi key' );
}

{
    my $s = Modern::OpenAPI::Generator::Spec->load($yaml);
    my $h = $s->clone_with_mojo_to('Controller');
    my $to =
      $h->{paths}{'/ping'}{get}{'x-mojo-to'};
    is( $to, 'Controller#get_ping', 'x-mojo-to' );
}

{
    my $err = '';
    eval { Modern::OpenAPI::Generator::Spec->load('/nonexistent/openapi.yaml'); 1 }
    or $err = $@ || '';
    like( $err, qr/Spec not found/, 'missing file croaks' );
}

done_testing;
