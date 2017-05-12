#!perl -T

use strict;
use warnings;

use Test::More;
use Test::MockObject;
use Test::Exception;

use Template::Benchmark;

plan tests => 7;

my ( $bench );

Test::MockObject->fake_module( 'Template::Benchmark::Engines::MockEngineOne',
    feature_syntax =>
        sub
        {
            my ( $self, $feature_name ) = @_;

            return( 'literal' ) if $feature_name eq 'literal_text';
            return( 'scalar' )  if $feature_name eq 'scalar_variable';
            return( undef );
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

            return( 'literal' ) if $feature_name eq 'literal_text';
            return( 'array' )   if $feature_name eq 'array_variable_value';
            return( undef );
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

            return( 'scalar' )  if $feature_name eq 'scalar_variable';
            return( 'array' )   if $feature_name eq 'array_variable_value';
            return( undef );
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
# 1: single features_from One
$bench = Template::Benchmark->new(
    features_from => 'MockEngineOne',
    only_plugin   => 'MockEngineOne',
    );
is_deeply( $bench->{ features }, [ qw/literal_text scalar_variable/ ],
    'features_from => "One"' );

#
# 2: single features_from Two
$bench = Template::Benchmark->new(
    features_from => 'MockEngineTwo',
    only_plugin   => 'MockEngineTwo',
    );
is_deeply( $bench->{ features }, [ qw/literal_text array_variable_value/ ],
    'features_from => "Two"' );

#
# 3: single features_from Three
$bench = Template::Benchmark->new(
    features_from => 'MockEngineThree',
    only_plugin   => 'MockEngineThree',
    );
is_deeply( $bench->{ features }, [ qw/scalar_variable array_variable_value/ ],
    'features_from => "Three"' );

#
# 4: multiple features_from One+Two (literal_text)
$bench = Template::Benchmark->new(
    features_from => [ qw/MockEngineOne MockEngineTwo/ ],
    only_plugin   => [ qw/MockEngineOne MockEngineTwo/ ],
    );
is_deeply( $bench->{ features }, [ qw/literal_text/ ],
    'features_from => [ qw/One Two/ ]' );

#
# 5: multiple features_from One+Three (scalar_variable)
$bench = Template::Benchmark->new(
    features_from => [ qw/MockEngineOne MockEngineThree/ ],
    only_plugin   => [ qw/MockEngineOne MockEngineThree/ ],
    );
is_deeply( $bench->{ features }, [ qw/scalar_variable/ ],
    'features_from => [ qw/One Three/ ]' );

#
# 6: multiple features_from Two+Three (array_variable_value)
$bench = Template::Benchmark->new(
    features_from => [ qw/MockEngineTwo MockEngineThree/ ],
    only_plugin   => [ qw/MockEngineTwo MockEngineThree/ ],
    );
is_deeply( $bench->{ features }, [ qw/array_variable_value/ ],
    'features_from => [ qw/Two Three/ ]' );

#
# 7: multiple features_from One+Two+Three (FAIL)
$bench = Template::Benchmark->new(
    features_from => [ qw/MockEngineOne MockEngineTwo MockEngineThree/ ],
    only_plugin   => [ qw/MockEngineOne MockEngineTwo MockEngineThree/ ],
    );
is_deeply( $bench->{ features }, [],
    'features_from => [ qw/One Two Three/ ]' );
#  TODO: check error
