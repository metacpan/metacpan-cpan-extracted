use strict;
use warnings;
use lib 't/lib';
use File::Spec;
use Cwd 'abs_path';
use Test::More;
use ConfigCascade::Test::Data;
use ConfigCascade::Test::RW_Widget;
use ConfigCascade::Test::RO_Widget;
BEGIN { use_ok('MooseX::ConfigCascade::Util') };

my $test_data = ConfigCascade::Test::Data->new;
my $expected = $test_data->expected;
# with path not set

my $widget = ConfigCascade::Test::RW_Widget->new;

isa_ok( $widget->cascade_util, 'MooseX::ConfigCascade::Util', "->cascade_util");
is( $widget->cascade_util->path, undef, '->cascade_util->path not set by default');
isa_ok( $widget->cascade_util->conf, 'HASH', '->conf with ->path not set');
is( scalar( keys %{$widget->cascade_util->conf}), 0, '->conf is an empty HashRef with ->path not set');


foreach my $type ( $test_data->types ){
    
    my $accessor = $type.'_no_default';
    ok( ! defined $widget->$accessor, "->$accessor initialised correctly" );

    foreach my $create_mode ( $test_data->modes ){
        next if $create_mode=~/no_default/;

        $accessor = $type."_".$create_mode;
        my $expected_value = $expected->{$type}->( $accessor, 'package' );

        is_deeply( $widget->$accessor, $expected_value, "->$accessor initialised correctly" );

    }

}


# with path set
my $util = MooseX::ConfigCascade::Util->new;

isa_ok( $util, 'MooseX::ConfigCascade::Util', 'MooseX::ConfigCascade::Util->new' );

my @path_info = File::Spec->splitpath( abs_path(__FILE__) );
my $data_dir = File::Spec->catdir( $path_info[1], 'data' );

die "Could not find test data directory $data_dir" unless -d $data_dir;

my %files = (
    json => 'widget.json',
    yaml => 'widget.yml'
);

foreach my $filetype (keys %files){

    my $filename = $files{$filetype};
    my $path = File::Spec->catdir( $data_dir, $filename );
    die "Could not find test file '$filename' in $data_dir" unless -f $path;

    MooseX::ConfigCascade::Util->path( $path );

    is( MooseX::ConfigCascade::Util->path, $path, '->path gives correct return value' );


    foreach my $rwo ( $test_data->rwo ){

        my $package = "ConfigCascade::Test::".uc($rwo)."_Widget";
        $widget = $package->new;

        isa_ok( $widget->cascade_util, 'MooseX::ConfigCascade::Util', "($rwo) ->cascade_util");
        is( $widget->cascade_util->path, $path, "($rwo) ->cascade_util->path behaves as class attribute");

        my $conf = $widget->cascade_util->conf;

        isa_ok( $conf, 'HASH', "($rwo) ->conf" );

        my $expected_conf = $expected->{conf}->( $filetype );

        is_deeply( $conf, $expected_conf, "($rwo) conf loaded correctly" );

        foreach my $type ( $test_data->types ){
            
            my $accessor = $type.'_no_default';
            ok( defined $widget->$accessor, "($rwo) ->$accessor initialised correctly" );

            foreach my $create_mode ( $test_data->modes ){

                $accessor = $type."_".$create_mode;
                my $expected_value = $expected->{$type}->( $accessor, $filetype );
                is_deeply( $widget->$accessor, $expected_value, "($rwo) ->$accessor initialised correctly" );

            }
        }
    }
}




my %base_conf = %{$expected->{conf}->('program')};

ok( MooseX::ConfigCascade::Util->conf( \%base_conf ), 'setting conf directly seems ok' );
is_deeply( MooseX::ConfigCascade::Util->conf, \%base_conf, '->conf returns correct value after setting directly' );


            




done_testing();





