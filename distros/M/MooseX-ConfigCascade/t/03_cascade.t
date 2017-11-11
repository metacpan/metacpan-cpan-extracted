use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Spec;
use Cwd 'abs_path';
use ConfigCascade::Test::BottleBox;
use ConfigCascade::Test::Bottle;
use ConfigCascade::Test::Label;
use ConfigCascade::Test::Logo;

BEGIN { use_ok('MooseX::ConfigCascade::Util') };
use Data::Dumper;

my $filename = 'bottle.json';
my @path_info = File::Spec->splitpath( abs_path(__FILE__) );
my $data_dir = File::Spec->catdir( $path_info[1], 'data' );

die "Could not find test data directory $data_dir" unless -d $data_dir;
my $path = File::Spec->catdir( $data_dir, $filename );
die "Could not find test file '$filename' in $data_dir" unless -f $path;

MooseX::ConfigCascade::Util->path( $path );

my $test_item;


##########################################################
$test_item = 'Logo';
##########################################################

my $logo = ConfigCascade::Test::Logo->new;

Logo_unaffected_attribute_tests( $test_item, $logo );
Logo_always_affected_attribute_tests( $test_item, $logo );
is_deeply( $logo->colors, { 'colors from Logo key' => 'colors from Logo value'}, $test_item.' attribute "colors" correctly takes value from Logo' );


##########################################################
$test_item = 'Label';
##########################################################
my $label = ConfigCascade::Test::Label->new;


Label_unaffected_attribute_tests( $test_item, $label );
is( $label->manufacturer, 'manufacturer from Label', $test_item.': attribute "manufacturer" correctly takes value from Label');


Logo_unaffected_attribute_tests( $test_item, $label->logo );
Logo_always_affected_attribute_tests( $test_item, $label->logo );
is_deeply( $label->logo->colors, { 'colors from Logo key' => 'colors from Logo value'}, $test_item.' attribute "colors" correctly takes value from Logo' );


##########################################################
$test_item = 'Bottle';
##########################################################
my $bottle = ConfigCascade::Test::Bottle->new;

Bottle_unaffected_attribute_tests( $test_item, $bottle );
Label_unaffected_attribute_tests( $test_item, $bottle->label );
Logo_unaffected_attribute_tests( $test_item, $bottle->label->logo );
Logo_always_affected_attribute_tests( $test_item, $bottle->label->logo );

is( $bottle->glass_type, 5, $test_item.' test: attribute "glass_type" correctly unaffected' );
is( $bottle->label->manufacturer, 'manufacturer from Label', $test_item.' test: attribute "label" correctly takes value from Label' );
is_deeply( $bottle->label->logo->colors, { 'colors from Logo key' => 'colors from Logo value' }, $test_item.' test: attribute "colors" correctly takes value from Logo' );

                

##########################################################
$test_item = 'BottleBox';
##########################################################
my $box = ConfigCascade::Test::BottleBox->new;

BottleBox_unaffected_attribute_tests( $test_item, $box );
Bottle_unaffected_attribute_tests( $test_item, $box->bottle );
Label_unaffected_attribute_tests( $test_item, $box->bottle->label );
Logo_unaffected_attribute_tests( $test_item, $box->bottle->label->logo );
Logo_always_affected_attribute_tests( $test_item, $box->bottle->label->logo );

is( $box->material, 'Material from BottleBox', $test_item.' test: attribute "material" correctly takes value from BottleBox' );
is( $box->bottle->glass_type, 2, $test_item.' test: attribute "glass_type" correctly takes value from BottleBox' );
is( $box->bottle->label->manufacturer, 'manufacturer from BottleBox', $test_item.' test: attribute "manufacturer" correctly takes value from BottleBox' );
is_deeply( $box->bottle->label->logo->colors, { 'colors from Logo key' => 'colors from Logo value' }, $test_item.' test: attribute "colors" correctly takes value from Logo' );



done_testing();




sub BottleBox_unaffected_attribute_tests{
    my ($test_item, $box ) = @_;

    is( $box->width, 22.5, $test_item.' test: attribute "width" correctly unaffected' );
    is( $box->packing, 'packing from package', $test_item.' test: attribute "packing" correctly unaffected' );
}
 



sub Bottle_unaffected_attribute_tests{
    my ($test_item, $bottle) = @_;

    isa_ok( $bottle->top, 'ConfigCascade::Test::BottleTop', $test_item.' test: attribute "top" (correctly unaffected)' );
    is_deeply( $bottle->style, { "design from package key" => "design from package value" }, $test_item.' test: attribute "style" correctly unaffected' );
} 



sub Label_unaffected_attribute_tests{

    my ($test_item, $label) = @_;

    is( $label->glue_type, 3, $test_item.' test: attribute "glue_type" correctly unaffected' );
    is_deeply( $label->suppliers, [ 'suppliers from package' ], $test_item.': attribute "suppliers" correctly unaffected' );

}


sub Logo_unaffected_attribute_tests{
    my ($test_item,$logo) = @_;

    is( $logo->width, 20.2, $test_item.' test: attribute "width" correctly unaffected' );
    is( $logo->height, 10, $test_item.' test: attribute "height" correctly unaffected' );
    is_deeply( $logo->designers, [ 'designers from package value' ], $test_item.' test: attribute "manufacturer" correctly unaffected' );

}


sub Logo_always_affected_attribute_tests{
    my ($test_item,$logo) = @_;

    is( $logo->slogan, 'slogan from '.$test_item, $test_item.' test: attribute "slogan" correctly takes value from '.$test_item);
    is( $logo->company_name, 'company_name from '.$test_item, $test_item.' test: attribute company_name correctly takes value from '.$test_item);

}



