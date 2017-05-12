#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Benchmark;

my ( $bench, $plugin, $version, $plugin_module, $template_dir, $cache_dir,
     $engine_errors );

my @plugin_requirements = (
    [ TemplateSandbox =>
        [ qw/Template::Sandbox Cache::CacheFactory CHI Cache::FastMmap
             Cache::FileCache Cache::FastMemoryCache Cache::Ref::FIFO/ ],
        '$Template::Sandbox::VERSION',
    ],
    [ TemplateToolkit =>
        [ qw/Template::Toolkit Template::Stash::XS Template::Parser::CET/ ],
        '$Template::VERSION',
    ],
    [ HTMLTemplate =>
        [ qw/HTML::Template/ ],
        '$HTML::Template::VERSION',
    ],
    );

PLUGIN: foreach my $plugin_requirement ( @plugin_requirements )
{
    my ( $plugin_name, $requirements, $get_version ) = @{$plugin_requirement};

    next if defined $ENV{ TB_TEST_PLUGIN_20 } and
            $ENV{ TB_TEST_PLUGIN_20 } ne $plugin_name;

    foreach my $requirement ( @{$requirements} )
    {
        eval "use $requirement";
        next PLUGIN if $@;
    }
    $plugin  = $plugin_name;
    $version = eval $get_version;
    last PLUGIN;
}

unless( $plugin )
{
    plan skip_all =>
        ( 'Instance testing requires one of the following sets of modules ' .
          'to be installed: (' .
          join( ') (',
              map { join( ' ', @{$_->[ 1 ]} ) } @plugin_requirements ) . ')' );
}

diag( "Using plugin $plugin ($version) for instance tests" );

$plugin_module = "Template::Benchmark::Engines::$plugin";

plan tests => 10 + 2;

#
#  1:  ensure Template::Benchmark detects that the engine is available.
is_deeply(
    [ grep { $_ eq $plugin_module } Template::Benchmark->engine_plugins() ],
    [ $plugin_module ],
    "is $plugin detected?" );

#
#  2-3: construct
$bench = Template::Benchmark->new(
    only_plugin      => $plugin,
    duration         => 1,
    template_repeats => 1,
    );
isnt( $bench, undef,
    'constructor produced something' );
is( ref( $bench ), 'Template::Benchmark',
    'constructor produced a Template::Benchmark' );

#
#  4: no engine_errors
$engine_errors = $bench->engine_errors();
is_deeply( $engine_errors, {},
    'no engine errors produced' );
foreach my $engine ( keys( %{$engine_errors} ) )
{
    diag( "Engine error: $engine\n" .
        join( "\n", @{$engine_errors->{ $engine }} ) );
}

#
#  5: engines()
is_deeply( [ $bench->engines() ],
    [ $plugin_module ],
    '$bench->engines()' );

#
#  6: features()
{
    my %o = Template::Benchmark->default_options();
    is_deeply( [ $bench->features() ],
        [ grep { $o{ $_ } } Template::Benchmark->valid_features() ],
        '$bench->features()' );
}

#
#  7-8: template dir exists
$template_dir = $bench->{ template_dir };
isnt( $template_dir, undef, 'template_dir set' );
ok( -d $template_dir, 'template_dir exists' );

#
#  9-10: cache dir exists
$cache_dir = $bench->{ cache_dir };
isnt( $cache_dir, undef, 'cache_dir set' );
ok( -d $cache_dir, 'cache_dir exists' );




#
#  +2: Cleanup, dirs removed.
undef $bench;
ok( !( -d $template_dir ), 'template_dir removed' );
ok( !( -d $cache_dir ),    'cache_dir removed' );
