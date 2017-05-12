#!perl -T

use strict;
use warnings;

use Test::More;
use Test::MockObject;

use Template::Benchmark;

plan tests => 2;

my ( $bench );

Test::MockObject->fake_module( 'Template::Benchmark::Engines::MockEngineOne',
    feature_syntax =>
        sub
        {
            my ( $self, $feature_name ) = @_;

            return( 'a snippet' );
        },
    benchmark_descriptions =>
        sub
        {
            return( { ME1 => "Mock::Engine::One (1.00)", } );
        },
    benchmark_functions_for_uncached_string =>
        sub
        {
            return( { ME1 => sub { 'template output' }, } );
        },
    );
Test::MockObject->fake_module( 'Template::Benchmark::Engines::MockEngineTwo',
    feature_syntax =>
        sub
        {
            my ( $self, $feature_name ) = @_;

            return( 'a snippet' );
        },
    benchmark_descriptions =>
        sub
        {
            return( { ME2 => "Mock::Engine::Two (1.00)", } );
        },
    benchmark_functions_for_uncached_string =>
        sub
        {
            return( { ME2 => sub { 'template output' }, } );
        },
    );
Test::MockObject->fake_module( 'Template::Benchmark::Engines::MockEngineThree',
    feature_syntax =>
        sub
        {
            my ( $self, $feature_name ) = @_;

            return( 'a snippet' );
        },
    benchmark_descriptions =>
        sub
        {
            return( { ME3 => "Mock::Engine::Three (1.00)", } );
        },
    benchmark_functions_for_uncached_string =>
        sub
        {
            return( { ME3 => sub { 'template output' }, } );
        },
    );

#
# 1: Singular only_plugin
$bench = Template::Benchmark->new(
    only_plugin   => 'MockEngineOne',
    );
is_deeply(
    [ $bench->engines() ],
    [ 'Template::Benchmark::Engines::MockEngineOne', ],
    'singular only_plugin' );

#
# 2: Multiple only_plugin
$bench = Template::Benchmark->new(
    only_plugin   => [ qw/MockEngineOne MockEngineTwo/ ],
    );
is_deeply(
    [ sort( $bench->engines() ) ],
    [ 'Template::Benchmark::Engines::MockEngineOne',
      'Template::Benchmark::Engines::MockEngineTwo', ],
    'multiple only_plugin' );
