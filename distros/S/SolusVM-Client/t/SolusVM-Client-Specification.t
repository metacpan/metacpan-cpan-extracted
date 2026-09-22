use v5.36;
use warnings FATAL => 'all';
use re '/aa';

=head1 NAME

t/SolusVM-Client-Specification.t - SolusVM::Client::Specification: what the client believes about the API

=cut

use Test2::V1 -i;
use Test2::Plugin::NoWarnings;

use Cpanel::JSON::XS ();
use File::Spec       ();
use File::Temp       ();

use FindBin::libs;
use Test::SolusVM::Client qw{:all};

use SolusVM::Client::Specification ();

# A three operation OpenAPI document with everything worth distilling in it: a
# path parameter the operation does not declare, a query parameter it does, a
# body, and one of SolusVM's unnamed operations.
sub document {
    return {
        openapi    => '3.0.0',
        components => {
            schemas => {
                ServerCreateRequest => {
                    type       => 'object',
                    required   => [ 'name', 'plan_id' ],
                    properties => { name => { type => 'string' }, plan_id => { type => 'integer' }, user_data => { type => 'string' } },
                },
            },
        },
        paths => {
            '/servers' => {
                get => {
                    operationId => 'get-list-of-servers',
                    tags        => ['Servers'],
                    summary     => 'List All Servers',
                    parameters  => [ { name => 'page', in => 'query' }, { name => 'authorization', in => 'header' } ],
                },
                post => {
                    operationId => 'create-a-new-server',
                    tags        => ['Servers'],
                    summary     => 'Create a Server',

                    # Through a reference, because that is how SolusVM shares a
                    # body between operations and a distiller that does not
                    # follow one learns nothing from it.
                    requestBody => { required => 1, content => { 'application/json' => { schema => { '$ref' => '#/components/schemas/ServerCreateRequest' } } } },
                },
            },
            '/servers/{id}' => {
                get        => { operationId => 'get-an-existing-server', tags => ['Servers'] },
                parameters => [],
            },
            '/servers/start' => {
                post => { operationId => '86ea1c4590839d7621a96d1ae680ca44', tags => ['Server Batch Actions'], summary => 'Start Multiple Servers' },
            },
        },
    };
}

subtest 'operation_name' => sub {
    is( SolusVM::Client::Specification::operation_name('get-list-of-servers'), 'get_list_of_servers', 'a hyphenated id becomes an identifier' );
    is( SolusVM::Client::Specification::operation_name('Create A New Server'), 'create_a_new_server', 'so does a spaced one' );
    is( SolusVM::Client::Specification::operation_name('list-of--sshkeys--'),  'list_of_sshkeys',     'runs collapse and edges are trimmed' );

    my @unnamed = (
        { id => '86ea1c4590839d7621a96d1ae680ca44', method => 'POST', uri => '/servers/start',    expected => 'post_servers_start',   why => 'an unnamed operation is named after its verb and path' },
        { id => '80e066a98a3d07905ad9e525ad349126', method => 'POST', uri => '/servers/restart',  expected => 'post_servers_restart', why => 'including the digest perl would refuse as a method name' },
        { id => 'be3ee504724c1a3b05c4327bf90f0180', method => 'GET',  uri => '/usage/cpu/{uuid}', expected => 'get_usage_cpu',        why => 'and a placeholder is left out of a name it would only make unpredictable' },
    );

    foreach my $case (@unnamed) {
        is( SolusVM::Client::Specification::operation_name( $case->{id}, $case->{method}, $case->{uri} ), $case->{expected}, $case->{why} );
    }

    like(
        dies { SolusVM::Client::Specification::operation_name('86ea1c4590839d7621a96d1ae680ca44') },
        qr/no kind of name/,
        'a digest with no verb and path to fall back on is fatal',
    );
};

subtest 'distil' => sub {
    my $entries = SolusVM::Client::Specification::distil( document() );
    is( scalar @{$entries}, 4, 'four operations, and the path-level parameters are not one of them' );

    my %by_name = map { $_->{name} => $_ } @{$entries};

    is(
        $by_name{get_an_existing_server},
        hash {
            field name         => 'get_an_existing_server';
            field operation_id => 'get-an-existing-server';
            field method       => 'GET';
            field uri          => '/servers/{id}';
            field path_params  => ['id'];
            field query_params => [];
            field body_params  => [];
            field required     => [];
            field has_body     => 0;
            field tag          => 'Servers';
            field summary      => q{};
            end();
        },
        'a path parameter is found even though the document never declares it',
    );

    is( $by_name{get_list_of_servers}{query_params}, ['page'],                 'a query parameter is kept' );
    is( $by_name{get_list_of_servers}{has_body},     0,                        'and a listing has no body' );
    is( $by_name{create_a_new_server}{has_body},     1,                        'while a create does' );
    is( $by_name{post_servers_start}{summary},       'Start Multiple Servers', 'an unnamed operation keeps its summary' );

    like( dies { SolusVM::Client::Specification::distil( {} ) }, qr/not an OpenAPI document/, 'a document with no paths is refused' );

    my $nameless = { paths => { '/servers' => { get => {} } } };
    like( dies { SolusVM::Client::Specification::distil($nameless) }, qr/no operationId/, 'an operation with no operationId is refused' );

    my $twice = {
        paths => {
            '/servers'  => { get => { operationId => 'list-servers' } },
            '/machines' => { get => { operationId => 'list_servers' } },
        },
    };
    like( dies { SolusVM::Client::Specification::distil($twice) }, qr/would both be called list_servers/, 'two operations wanting one name is refused' );
};

subtest 'load' => sub {
    my $spec = SolusVM::Client::Specification::load();

    is( scalar keys %{$spec}, 309, 'the whole of the SolusVM 2 API is baked in -- if a refetch moved this, read the diff before moving the number' );
    is(
        $spec->{get_an_existing_server},
        hash {
            field method      => 'GET';
            field uri         => '/servers/{id}';
            field path_params => ['id'];
            etc();
        },
        'and a known operation says what it should',
    );

    ok( $spec == SolusVM::Client::Specification::load(), 'the same spec comes back rather than being parsed again' );

    my $directory = File::Temp->newdir();
    my $file      = File::Spec->catfile( "$directory", 'other.json' );
    open my $fh, '>', $file or die "could not write $file: $!\n";
    print {$fh} Cpanel::JSON::XS->new->utf8->encode( SolusVM::Client::Specification::distil( document() ) );
    close $fh;

    my $other = SolusVM::Client::Specification::load( file => $file );
    is( scalar keys %{$other}, 4, 'a spec from a file is loaded instead' );
    ok( $other != $spec, 'and is memoised apart from the baked in one' );
};

subtest 'fetch' => sub {
    my $mock      = mock_http_tiny();
    my $directory = File::Temp->newdir();

    mock_request( 'GET /admin-docs.json', json_response( document() ) );

    my $file = SolusVM::Client::Specification::fetch( dir => "$directory", url => 'https://solus.test/admin-docs.json' );
    is( $file, File::Spec->catfile( "$directory", 'solusvm2.json' ), 'it says where it wrote' );

    my $written = SolusVM::Client::Specification::load( file => $file );
    is( scalar keys %{$written}, 4, 'and what it wrote loads as a spec' );

    mock_request( 'GET /admin-docs.json', { status => 304, reason => 'Not Modified', success => 0, headers => {}, content => q{} } );
    is( SolusVM::Client::Specification::fetch( dir => "$directory", url => 'https://solus.test/admin-docs.json', once => 1 ), undef, 'nothing newer means nothing to do' );

    mock_request( 'GET /admin-docs.json', { status => 500, reason => 'Internal Server Error', success => 0, headers => {}, content => q{} } );
    like(
        dies { SolusVM::Client::Specification::fetch( dir => "$directory", url => 'https://solus.test/admin-docs.json' ) },
        qr/Could not fetch the SolusVM API spec.*500/s,
        'and a management node having a bad day is fatal',
    );

    like( dies { SolusVM::Client::Specification::fetch() }, qr/needs a directory/, 'fetch with nowhere to write is refused' );

    undef $mock;
};

done_testing();
