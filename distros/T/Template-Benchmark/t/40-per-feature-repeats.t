#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Template::Benchmark;

my ( $bench, $plugin, $version, $plugin_module, $result, $expected, $test_name,
     $expected_literal, $expected_scalar, %features );

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
    #  Requires 0.2007 for a bugfix when running under taint mode.
    [ TextXslate =>
        [ 'Text::Xslate 0.2007' ],
        '$Text::Xslate::VERSION',
    ],
    );

PLUGIN: foreach my $plugin_requirement ( @plugin_requirements )
{
    my ( $plugin_name, $requirements, $get_version ) = @{$plugin_requirement};

    next if defined $ENV{ TB_TEST_PLUGIN_40 } and
            $ENV{ TB_TEST_PLUGIN_40 } ne $plugin_name;

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
        ( 'Feature repeats testing requires one of the following sets of ' .
          'modules to be installed: (' .
          join( ') (',
              map { join( ' ', @{$_->[ 1 ]} ) } @plugin_requirements ) . ')' );
}

diag( "Using plugin $plugin ($version) for feature repeats tests" );

$plugin_module = "Template::Benchmark::Engines::$plugin";

plan tests => 7 * 2;

$expected_literal = <<'END_OF_EXPECTED';
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
END_OF_EXPECTED

$expected_scalar =  <<'END_OF_EXPECTED';
I is a scalar, yarr!
END_OF_EXPECTED

foreach my $template_repeats ( 1..2 )
{
    #
    #  1:  1 feature x1, template xN
    $test_name = "1 feature x1, template x$template_repeats";
    $expected  = $expected_literal x $template_repeats;

    %features = map { $_ => 0 } Template::Benchmark->valid_features();
    $features{ literal_text } = 1;
    $bench = Template::Benchmark->new(
        only_plugin      => $plugin,
        duration         => 0,
        template_repeats => $template_repeats,
        %features,
        );
    $result = $bench->benchmark();
    is( $result->{ reference }->{ output }, $expected, $test_name );

    #
    #  2:  1 feature x2, template xN
    $test_name = "1 feature x2, template x$template_repeats";
    $expected  = ( $expected_literal x 2 ) x $template_repeats;

    %features = map { $_ => 0 } Template::Benchmark->valid_features();
    $features{ literal_text } = 2;
    $bench = Template::Benchmark->new(
        only_plugin      => $plugin,
        duration         => 0,
        template_repeats => $template_repeats,
        %features,
        );
    $result = $bench->benchmark();
    is( $result->{ reference }->{ output }, $expected, $test_name );

    #
    #  3:  2 features (x2, x1), template xN
    $test_name = "2 features (x2, x1), template x$template_repeats";
    $expected  = ( ( $expected_literal x 2 ) . $expected_scalar ) x
        $template_repeats;

    %features = map { $_ => 0 } Template::Benchmark->valid_features();
    $features{ literal_text }    = 2;
    $features{ scalar_variable } = 1;
    $bench = Template::Benchmark->new(
        only_plugin      => $plugin,
        duration         => 0,
        template_repeats => $template_repeats,
        %features,
        );
    $result = $bench->benchmark();
    is( $result->{ reference }->{ output }, $expected, $test_name );

    #
    #  4:  2 features (x1, x2), template xN
    $test_name = "2 features (x1, x2), template x$template_repeats";
    $expected  = ( $expected_literal . ( $expected_scalar x 2 ) ) x
        $template_repeats;

    %features = map { $_ => 0 } Template::Benchmark->valid_features();
    $features{ literal_text }    = 1;
    $features{ scalar_variable } = 2;
    $bench = Template::Benchmark->new(
        only_plugin      => $plugin,
        duration         => 0,
        template_repeats => $template_repeats,
        %features,
        );
    $result = $bench->benchmark();
    is( $result->{ reference }->{ output }, $expected, $test_name );

    #
    #  5:  1 feature x'a string', template xN
    $test_name = "1 feature x'a string', template x$template_repeats";
    $expected  = $expected_literal x $template_repeats;

    %features = map { $_ => 0 } Template::Benchmark->valid_features();
    $features{ literal_text } = 'a string';
    $bench = Template::Benchmark->new(
        only_plugin      => $plugin,
        duration         => 0,
        template_repeats => $template_repeats,
        %features,
        );
    $result = $bench->benchmark();
    is( $result->{ reference }->{ output }, $expected, $test_name );

    #
    #  6:  1 feature x<float>, template xN
    $test_name = "1 feature x<float>, template x$template_repeats";
    $expected  = $expected_literal x $template_repeats;

    %features = map { $_ => 0 } Template::Benchmark->valid_features();
    $features{ literal_text } = 3.25;
    $bench = Template::Benchmark->new(
        only_plugin      => $plugin,
        duration         => 0,
        template_repeats => $template_repeats,
        %features,
        );
    $result = $bench->benchmark();
    is( $result->{ reference }->{ output }, $expected, $test_name );

    #
    #  7:  1 feature x-5, template xN
    $test_name = "1 feature x-5, template x$template_repeats";
    $expected  = $expected_literal x $template_repeats;

    %features = map { $_ => 0 } Template::Benchmark->valid_features();
    $features{ literal_text } = -5;
    $bench = Template::Benchmark->new(
        only_plugin      => $plugin,
        duration         => 0,
        template_repeats => $template_repeats,
        %features,
        );
    $result = $bench->benchmark();
    is( $result->{ reference }->{ output }, $expected, $test_name );
}
