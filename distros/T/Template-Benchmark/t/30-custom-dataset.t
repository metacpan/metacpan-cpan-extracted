#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Template::Benchmark;

my ( $bench, $plugin, $version, $plugin_module, $dataset, $result, $expected );

#  IMPORTANT:  ------------------------------------------------
#  IMPORTANT:  These must be engines that support all features.
#  IMPORTANT:  ------------------------------------------------
my @plugin_requirements = (
    [ TemplateSandbox =>
        [ qw/Template::Sandbox Cache::CacheFactory CHI Cache::FastMmap
             Cache::FileCache Cache::FastMemoryCache Cache::Ref::FIFO/ ],
        '$Template::Sandbox::VERSION',
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

    next if defined $ENV{ TB_TEST_PLUGIN_30 } and
            $ENV{ TB_TEST_PLUGIN_30 } ne $plugin_name;

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
        ( 'Dataset testing requires one of the following sets of modules ' .
          'to be installed: (' .
          join( ') (',
              map { join( ' ', @{$_->[ 1 ]} ) } @plugin_requirements ) . ')' );
}

diag( "Using plugin $plugin ($version) for dataset tests" );

$plugin_module = "Template::Benchmark::Engines::$plugin";

plan tests => 6;

$dataset = {
    hash1 => {
        scalar_variable => 'twinkle twinkle little scalar',
        hash_variable   => {
            'hash_value_key' =>
                'ha-ha-ha-hash',
            },
        array_variable   => [ qw/this is an array/ ],
        this => { is => { a => { very => { deep => { hash => {
            structure => "scraping the bottom of the hashref",
            } } } } } },
        template_if_true  => 'yay',
        template_if_false => 'nope',
        },
    hash2 => {
        array_loop =>
            [ qw/do ray me so fah/ ],
        hash_loop  => {
            animal    => 'camel',
            mineral   => 'lignite',
            vegetable => 'ew',
            },
        records_loop => [
            { name => 'Larry Nomates', age => 43,  },
            ],
        variable_if      => 0,
        variable_if_else => 1,
        variable_expression_a => 200,
        variable_expression_b => 100,
        variable_function_arg => 'BzzZZzzZZzzZZzzZZ',
        },
    };

$expected = <<'END_OF_EXPECTED';
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
twinkle twinkle little scalar
ha-ha-ha-hash
an
scraping the bottom of the hashref
doraymesofah
animal: camelmineral: lignitevegetable: ew
Larry Nomates: 43
doraymesofah
animal: camelmineral: lignitevegetable: ew
Larry Nomates: 43
true

true
true
yay

yay
yay
22
20000
201
substring
Zz
END_OF_EXPECTED

#
#  1:  construct with custom dataset
$bench = Template::Benchmark->new(
    only_plugin      => $plugin,
    features_from    => $plugin,
    duration         => 0,
    template_repeats => 1,
    dataset          => $dataset,
    );
is( ref( $bench ), 'Template::Benchmark', 'custom dataset constructor' );

$result = $bench->benchmark() or
    die "Template::Benchmark->benchmark() failed to return a result.";

#
#  2: Did we get the expected data used?
is( $result->{ reference }->{ output }, $expected, 'custom dataset was used' );

#
#  3: not a hashref
throws_ok
    {
        $bench = Template::Benchmark->new(
            only_plugin      => $plugin,
            features_from    => $plugin,
            duration         => 0,
            template_repeats => 1,
            dataset          => [ qw/some random stuff/ ],
            );
    }
    qr{Option 'dataset' must be a dataset name or a hashref, got: ARRAY at .*Template.*Benchmark\.pm line},
    'error on construct with non-hash custom dataset';


#
#  4: missing hash1
throws_ok
    {
        $bench = Template::Benchmark->new(
            only_plugin      => $plugin,
            features_from    => $plugin,
            duration         => 0,
            template_repeats => 1,
            dataset          => { hash2 => {} },
            );
    }
    qr{Option 'dataset' hashref is missing required 'hash1' key at .*Template.*Benchmark\.pm line},
    'error on construct with custom dataset without hash1 key';


#
#  5: missing hash2
throws_ok
    {
        $bench = Template::Benchmark->new(
            only_plugin      => $plugin,
            features_from    => $plugin,
            duration         => 0,
            template_repeats => 1,
            dataset          => { hash1 => {} },
            );
    }
    qr{Option 'dataset' hashref is missing required 'hash2' key at .*Template.*Benchmark\.pm line},
    'error on construct with custom dataset without hash1 key';


#
#  6: no such dataset
throws_ok
    {
        $bench = Template::Benchmark->new(
            only_plugin      => $plugin,
            features_from    => $plugin,
            duration         => 0,
            template_repeats => 1,
            dataset          => 'nosuchdataset',
            );
    }
    qr{Unknown dataset name 'nosuchdataset' at .*Template.*Benchmark\.pm line},
    'error on construct with non-existing dataset name';
