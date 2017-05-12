#!perl -T

use strict;
use warnings;

use Test::More;
use Test::MockObject;

use Template::Benchmark;

plan tests => 7;

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
    benchmark_functions_for_uncached_disk =>
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
    benchmark_functions_for_uncached_disk =>
        sub
        {
            return( { ME2 => sub { 'template output' }, } );
        },
    benchmark_functions_for_disk_cache =>
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
    benchmark_functions_for_disk_cache =>
        sub
        {
            return( { ME3 => sub { 'template output' }, } );
        },
    );

#
# 1: single cache_types_from One
$bench = Template::Benchmark->new(
    cache_types_from => 'MockEngineOne',
    only_plugin      => 'MockEngineOne',
    );
is_deeply( $bench->{ cache_types }, [ qw/uncached_string uncached_disk/ ],
    'cache_types_from => "One"' );

#
# 2: single cache_types_from Two
$bench = Template::Benchmark->new(
    cache_types_from => 'MockEngineTwo',
    only_plugin      => 'MockEngineTwo',
    );
is_deeply( $bench->{ cache_types }, [ qw/uncached_disk disk_cache/ ],
    'cache_types_from => "Two"' );

#
# 3: single cache_types_from Three
$bench = Template::Benchmark->new(
    cache_types_from => 'MockEngineThree',
    only_plugin      => 'MockEngineThree',
    );
is_deeply( $bench->{ cache_types }, [ qw/uncached_string disk_cache/ ],
    'cache_types_from => "Three"' );

#
# 4: multiple cache_types_from One+Two
$bench = Template::Benchmark->new(
    cache_types_from => [ qw/MockEngineOne MockEngineTwo/ ],
    only_plugin      => [ qw/MockEngineOne MockEngineTwo/ ],
    );
is_deeply( $bench->{ cache_types },
    [ qw/uncached_string uncached_disk disk_cache/ ],
    'cache_types_from => [ qw/One Two/ ]' );

#
# 5: multiple cache_types_from One+Three
$bench = Template::Benchmark->new(
    cache_types_from => [ qw/MockEngineOne MockEngineThree/ ],
    only_plugin      => [ qw/MockEngineOne MockEngineThree/ ],
    );
is_deeply( $bench->{ cache_types },
    [ qw/uncached_string uncached_disk disk_cache/ ],
    'cache_types_from => [ qw/One Three/ ]' );

#
# 6: multiple cache_types_from Two+Three
$bench = Template::Benchmark->new(
    cache_types_from => [ qw/MockEngineTwo MockEngineThree/ ],
    only_plugin      => [ qw/MockEngineTwo MockEngineThree/ ],
    );
is_deeply( $bench->{ cache_types },
    [ qw/uncached_string uncached_disk disk_cache/ ],
    'cache_types_from => [ qw/Two Three/ ]' );

#
# 7: multiple cache_types_from One+Two+Three (FAIL)
$bench = Template::Benchmark->new(
    cache_types_from => [ qw/MockEngineOne MockEngineTwo MockEngineThree/ ],
    only_plugin      => [ qw/MockEngineOne MockEngineTwo MockEngineThree/ ],
    );
is_deeply( $bench->{ cache_types },
    [ qw/uncached_string uncached_disk disk_cache/ ],
    'cache_types_from => [ qw/One Two Three/ ]' );
