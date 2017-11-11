use strict;
use warnings;
use lib 't/lib';
use File::Spec;
use Cwd 'abs_path';
use Carp;
use Data::Dumper;
use Test::More;
use ConfigCascade::Test::BottleTop;
BEGIN { use_ok('MooseX::ConfigCascade::Util') };

my @path_info = File::Spec->splitpath( abs_path(__FILE__) );
my $data_dir = File::Spec->catdir( $path_info[1], 'data' );

die "Could not find test data directory $data_dir" unless -d $data_dir;

my $filename = 'arbitrary.conf';


my $path = File::Spec->catdir( $data_dir, $filename );
die "Could not find test file '$filename' in $data_dir" unless -f $path;

ok( MooseX::ConfigCascade::Util->parser( sub{
    return {} unless $_[0];

    open my $fh,'<',$_[0] or confess "Could not open file ".$_[0].": $!";

    my $package = <$fh>;
    chomp $package;
    my $conf = {
        $package => {}
    };

    for(0..1){
        my $line = <$fh>;
        chomp $line;
        my ($k,$v) = split(/\s+/,$line);
        $conf->{$package}{$k} = $v;
    }

    return $conf;
}), "passed sub to parser ok" );

ok( MooseX::ConfigCascade::Util->path( $path ), "passed file path to ->path ok after setting parser");

my $bottle_top;
ok( $bottle_top = ConfigCascade::Test::BottleTop->new, "created object ok after setting parser" );
is( $bottle_top->radius, 10, 'attribute "radius" takes value from conf file as expected' );
is( $bottle_top->material, 'bottletop_material_from_arbitrary_conf_file', 'attribute "material" takes value from conf file as expected' );

done_testing();
