#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PGTest;

# declare-then-register: the normal shape
{
    package KwApp;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/gql' => PGTest::sdl(), { resolvers => PGTest::resolvers() };
    plugin 'GraphQL';
}
{
    my $app = KwApp->to_app;
    my $r = hit($app, path => '/gql',
        body => '{"query":"{ users(first: 1) { id } }"}');
    is $r->[0], 200, 'declare-then-register serves';
    my $st = Punk::Plugin::GraphQL::state_for('KwApp');
    ok $st->{registered}, 'state says registered';
    is scalar @{ $st->{endpoints} }, 1, 'one endpoint recorded';
}

# register-then-declare is not a thing - the keyword records, the plugin
# mounts - but plugin-first with the terse inline endpoint is
{
    package TerseApp;
    use Punk;
    use Punk::Plugin::GraphQL;
    plugin 'GraphQL' => {
        path      => '/api/graphql',
        schema    => PGTest::sdl(),
        resolvers => PGTest::resolvers(),
    };
}
{
    my $app = TerseApp->to_app;
    my $r = hit($app, path => '/api/graphql',
        body => '{"query":"{ users(first: 1) { name } }"}');
    is $r->[0], 200, 'terse plugin form serves';
    is jdec($r)->{data}{users}[0]{name}, 'user1', 'and executes';
}

# the keyword's hash form: graphql PATH => { schema => ..., ... }
{
    package HashApp;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/g' => {
        schema    => PGTest::sdl(),
        resolvers => PGTest::resolvers(),
    };
    plugin 'GraphQL';
}
{
    my $r = hit(HashApp->to_app, path => '/g',
        body => '{"query":"{ users(first: 1) { id } }"}');
    is $r->[0], 200, 'keyword hash form serves';
}

# tripwire: keyword used, plugin never registered -> to_app croaks
{
    package Forgot;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/gql' => PGTest::sdl();
}
{
    my $app = eval { Forgot->to_app };
    like $@, qr/never registered/, 'unregistered keyword croaks at to_app';
}

# path normalisation + duplicate endpoint croaks
{
    package Dup;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql 'gql/'  => PGTest::sdl();
    graphql '/gql'  => PGTest::sdl();
    my $err = do { local $@; eval { plugin 'GraphQL' }; $@ };
    ::like($err, qr/duplicate endpoint '\/gql'/,
        'normalised duplicate path croaks at register');
}

# schema is required
{
    package NoSchema;
    use Punk;
    use Punk::Plugin::GraphQL;
    my $err = do { local $@; eval { graphql '/gql' }; $@ };
    ::like($err, qr/schema is required/, 'keyword without schema croaks');
}

# plugin-first ordering: the keyword after registration mounts at the
# declaration itself
{
    package PluginFirst;
    use Punk;
    use Punk::Plugin::GraphQL;
    plugin 'GraphQL';
    graphql '/gql' => PGTest::sdl(), { resolvers => PGTest::resolvers() };
}
{
    my $r = hit(PluginFirst->to_app, path => '/gql',
        body => '{"query":"{ users(first: 1) { id } }"}');
    is $r->[0], 200, 'plugin-first, keyword-after serves';
}

# plugin registered but nothing ever declared croaks at to_app
{
    package Empty;
    use Punk;
    use Punk::Plugin::GraphQL;
    plugin 'GraphQL';
}
{
    my $app = eval { Empty->to_app };
    like $@, qr/no graphql endpoints were declared/,
        'register without endpoints croaks at to_app';
}

# a prebuilt schema object is accepted; resolvers alongside it are not
{
    package Prebuilt;
    use Punk;
    use Punk::Plugin::GraphQL;
    my $schema = GraphQL::Houtou::build_schema(
        PGTest::sdl(), resolvers => PGTest::resolvers());
    graphql '/gql' => $schema;
    plugin 'GraphQL';
}
{
    my $r = hit(Prebuilt->to_app, path => '/gql',
        body => '{"query":"{ users(first: 1) { id } }"}');
    is $r->[0], 200, 'prebuilt schema object serves';
}
{
    package PrebuiltBad;
    use Punk;
    use Punk::Plugin::GraphQL;
    my $schema = GraphQL::Houtou::build_schema(PGTest::sdl());
    graphql '/gql' => $schema, { resolvers => PGTest::resolvers() };
    my $err = do { local $@; eval { plugin 'GraphQL' }; $@ };
    ::like($err, qr/resolvers belong in the schema object/,
        'schema object plus resolvers croaks');
}

# schema from a file
{
    require File::Temp;
    my ($fh, $file) = File::Temp::tempfile(SUFFIX => '.graphql');
    print $fh PGTest::sdl();
    close $fh;
    package FileApp;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/gql' => $file, { resolvers => PGTest::resolvers() };
    plugin 'GraphQL';
}
{
    my $r = hit(FileApp->to_app, path => '/gql',
        body => '{"query":"{ users(first: 1) { email } }"}');
    is $r->[0], 200, 'SDL file schema serves';
}

# a missing schema file croaks at register, naming the file
{
    package BadFile;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/gql' => '/nonexistent/schema.graphql';
    my $err = do { local $@; eval { plugin 'GraphQL' }; $@ };
    ::like($err, qr/cannot read schema file '\/nonexistent/,
        'missing schema file croaks with the path');
}

done_testing();
