use strict;
use warnings;

# blech! but Test::Requires does a stringy eval, so this works...
use Test::Requires { 'MooseX::ConfigFromFile' => '()' };
use Test::More 0.88;
use Test::Fatal;
use Test::Deep '!blessed';
use Path::Tiny 0.009;
use Scalar::Util 'blessed';
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my %constructor_args;
{
    package App;

    use Moose;
    with 'MooseX::Getopt';
    with 'MooseX::ConfigFromFile';

    has 'config_from_override' => (
        is       => 'ro',
        isa      => 'Bool',
        default  => 0,
    );

    has 'optional_from_config' => (
        is        => 'ro',
        isa       => 'Str',
        required  => 0,
    );

    has 'optional_with_init_arg' => (
        is       => 'ro',
        isa      => 'Str',
        required => 0,
        init_arg => 'foo',
    );

    has 'required_from_config' => (
        is        => 'ro',
        isa       => 'Str',
        required  => 1,
    );

    has 'required_from_argv' => (
        is        => 'ro',
        isa       => 'Str',
        required  => 1,
    );

    sub get_config_from_file
    {
        my ( $class, $file ) = @_;

        my %config = (
            required_from_config => 'from_config_1',
            optional_from_config => 'from_config_2',
        );

        if ( $file ne Path::Tiny::path('/notused/default') ) {
            $config{config_from_override} = 1;
        }

        return \%config;
    }

    around BUILDARGS => sub
    {
        my ($orig, $class) = (shift, shift);
        my $args = $class->$orig(@_);
        $constructor_args{$class} = $args;
    };
}

{
    package App::DefaultConfigFile;

    use Moose;
    extends 'App';

    has '+configfile' => (
        default => Path::Tiny::path('/notused/default')->stringify,
    );
}

{
    package App::DefaultConfigFileCodeRef;

    use Moose;
    extends 'App';

    has '+configfile' => (
        default => sub { return Path::Tiny::path('/notused/default')->stringify },
    );
}

{
    package App::ConfigFileWrapped;

    use Moose;
    extends 'App';

    sub _get_default_configfile { '/notused/default' }
}


# No config specified
{
    local @ARGV = qw( --required_from_argv 1 );

    like exception { App->new_with_options },
        ($Getopt::Long::Descriptive::VERSION >= 0.091
            ? qr/Mandatory parameter 'required_from_config' missing/
            : qr/Required option missing: required_from_config/);

    {
        my $app = App::DefaultConfigFile->new_with_options;
        isa_ok( $app, 'App::DefaultConfigFile' );
        app_ok( $app );

        ok(  !$app->config_from_override,
            '... config_from_override false as expected' );

        is( path($app->configfile), path('/notused/default'),
            '... configfile is /notused/default as expected' );

        cmp_deeply(
            $constructor_args{blessed($app)},
            superhashof({
                configfile => str(path('/notused/default')),
            }),
            'correct constructor args passed',
        );
    }

    {
        my $app = App::DefaultConfigFileCodeRef->new_with_options;
        isa_ok( $app, 'App::DefaultConfigFileCodeRef' );
        app_ok( $app );

        ok(  !$app->config_from_override,
            '... config_from_override false as expected' );

        is( path($app->configfile), path('/notused/default'),
            '... configfile is /notused/default as expected' );

        cmp_deeply(
            $constructor_args{blessed $app},
            superhashof({
                configfile => str(path('/notused/default')),
            }),
            'correct constructor args passed',
        );
    }

    SKIP: {
        eval "use MooseX::ConfigFromFile 0.08 (); 1;";
        diag("MooseX::ConfigFromFile 0.08 needed to test this use of configfile defaults"),
        skip "MooseX::ConfigFromFile 0.08 needed to test this use of configfile defaults", 7 if $@;

        my $app = App::ConfigFileWrapped->new_with_options;
        isa_ok( $app, 'App::ConfigFileWrapped' );
        app_ok( $app );

        ok(  !$app->config_from_override,
            '... config_from_override false as expected' );

        is( $app->configfile, path('/notused/default'),
            '... configfile is /notused/default as expected' );

        cmp_deeply(
            $constructor_args{blessed $app},
            superhashof({
                configfile => str(path('/notused/default')),
            }),
            'correct constructor args passed',
        );
    }
}

# Config specified
{
    local @ARGV = qw( --configfile /notused/override --required_from_argv 1 --foo bar);

    {
        my $app = App->new_with_options;
        isa_ok( $app, 'App' );
        app_ok( $app );
        is( $app->optional_with_init_arg, 'bar', 'attribute set via init_arg' );
    }

    {
        my $app = App::DefaultConfigFile->new_with_options;
        isa_ok( $app, 'App::DefaultConfigFile' );
        app_ok( $app );

        ok( $app->config_from_override,
             '... config_from_override true as expected' );

        is( path($app->configfile), path('/notused/override'),
            '... configfile is /notused/override as expected' );

        cmp_deeply(
            $constructor_args{blessed $app},
            superhashof({
                configfile => str(path('/notused/override')),
            }),
            'correct constructor args passed',
        );
    }
    {
        my $app = App::DefaultConfigFileCodeRef->new_with_options;
        isa_ok( $app, 'App::DefaultConfigFileCodeRef' );
        app_ok( $app );

        ok( $app->config_from_override,
             '... config_from_override true as expected' );

        is( path($app->configfile), path('/notused/override'),
            '... configfile is /notused/override as expected' );

        cmp_deeply(
            $constructor_args{blessed $app},
            superhashof({
                configfile => str(path('/notused/override')),
            }),
            'correct constructor args passed',
        );
    }
    {
        my $app = App::ConfigFileWrapped->new_with_options;
        isa_ok( $app, 'App::ConfigFileWrapped' );
        app_ok( $app );

        ok( $app->config_from_override,
             '... config_from_override true as expected' );

        is( path($app->configfile), path('/notused/override'),
            '... configfile is /notused as expected' );

        cmp_deeply(
            $constructor_args{blessed $app},
            superhashof({
                configfile => str(path('/notused/override')),
            }),
            'correct constructor args passed',
        );
    }
}

# Required arg not supplied from cmdline
{
    local @ARGV = qw( --configfile /notused/override );
    like exception { App->new_with_options },
        ($Getopt::Long::Descriptive::VERSION >= 0.091
            ? qr/Mandatory parameter 'required_from_argv' missing/
            : qr/Required option missing: required_from_argv/);
}

# Config file value overriden from cmdline
{
    local @ARGV = qw( --configfile /notused/override --required_from_argv 1 --required_from_config override );

    my $app = App->new_with_options;
    isa_ok( $app, 'App' );

    is( $app->required_from_config, 'override',
        '... required_from_config is override as expected' );

    is( $app->optional_from_config, 'from_config_2',
        '... optional_from_config is from_config_2 as expected' );
}

# No config file
{
    local @ARGV = qw( --required_from_argv 1 --required_from_config noconfig );

    my $app = App->new_with_options;
    isa_ok( $app, 'App' );

    is( $app->required_from_config, 'noconfig',
        '... required_from_config is noconfig as expected' );

    ok( !defined $app->optional_from_config,
        '... optional_from_config is undef as expected' );
}

{
    package BaseApp::WithConfig;
    use Moose;
    with 'MooseX::ConfigFromFile';

    sub get_config_from_file { return {}; }
}

{
    package DerivedApp::Getopt;
    use Moose;
    extends 'BaseApp::WithConfig';
    with 'MooseX::Getopt';
}

# With DerivedApp, the Getopt role was applied at a different level
# than the ConfigFromFile role
{
    ok ! exception { DerivedApp::Getopt->new_with_options }, 'Can create DerivedApp';
}

sub app_ok {
    my $app = shift;

    is( $app->required_from_config, 'from_config_1',
        '... required_from_config is from_config_1 as expected' );

    is( $app->optional_from_config, 'from_config_2',
        '... optional_from_config is from_config_2 as expected' );

    is( $app->required_from_argv, '1',
        '... required_from_argv is 1 as expected' );
}

done_testing;
