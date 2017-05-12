use Test::Base tests => 2;
use IO::All;

my $output_dir = "t/output";
my $module_dir = "$output_dir/Foo-Bar";

io->dir($output_dir)->rmtree;
my $lib = io('lib')->absolute->pathname;

$ENV{MODULE_MAKE_TEST} = 1;

system("$^X -I$lib -MModule::Make=new - $output_dir/Foo-Bar") == 0 or die;

ok io->file("$module_dir/src/config.yaml")->exists,
    "config.yaml created";

ok io->file("$module_dir/src/Makefile")->exists,
    "Initial Makefile created";
