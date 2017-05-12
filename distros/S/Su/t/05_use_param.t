use Test::More tests => 11;
use lib qw(lib ../lib);
use File::Path;
use Fatal qw(rmtree);
use Su::Process base => './somedir';
use Su::Model;

is( $Su::Process::PROCESS_BASE_DIR, "./somedir" );

is( $Su::Process::PROCESS_DIR, "Procs" );

my $mdl = Su::Model->new;
is( $mdl->{base}, undef );
is( $mdl->{dir},  undef );

## If setting variable is passed to the Model constructor, then reference these vars.

$mdl = Su::Model->new( base => "./foodir" );
is( $mdl->{base}, "./foodir" );
is( $mdl->{dir},  undef );

$mdl = Su::Model->new( base => "./foodir", dir => 'bardir' );
is( $mdl->{base}, "./foodir" );
is( $mdl->{dir},  "bardir" );

rmtree "./t/test05" if ( -d "./t/test05" );

$Su::Process::PROCESS_BASE_DIR = "./t/test05_dmy";

$Su::Process::PROCESS_DIR = "Templates_dmy";

$mdl = Su::Model->new( base => "./t/test05", dir => "paramTemplates" );

$mdl->generate_model('MdlClass');

ok( -f "./t/test05" . "/" . "paramTemplates" . "/" . "MdlClass.pm" );

ok( !-d "./t/test05_dmy" );

ok( !-d "./t/test05" . "/" . "Templates_dmy" );

