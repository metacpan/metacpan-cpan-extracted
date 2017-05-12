BEGIN {
	$| = 1;
}
use Test::More tests => 9;
use File::Spec::Functions qw(catdir catfile);
use Module::Build;
use Cwd;
use Capture::Tiny qw(capture);
diag( "Using Module::Build $Module::Build::VERSION" );

use t::lib::Module::Build::SubClass;


my $debug = 0;

my $original_dir = cwd();
my $lib_dir  = catdir qw(.. lib);
my $blib_dir = catdir qw(.. .. blib lib);

chdir(catdir(qw(t MBF-Test7)));


(undef, undef) = capture { system($^X, "-I$blib_dir", "-I$lib_dir", 'Build.PL'); } unless $debug;
system($^X, "-I$blib_dir", 'Build.PL') if $debug;
ok(-e '_build', 'Build.PL appeared to execute correctly');
ok(-e 'Build', 'Building script was created');
ok(-e catfile(qw(inc Module Build Functions.pm)), 'Build.PL appeared to bundle itself into ./inc');
ok(-e catfile(qw(inc Module Build Functions DSL.pm)), 'Build.PL appeared to bundle DSL class into ./inc');
ok(-e catfile(qw(inc Module Build SubClass.pm)), 'Build.PL appeared to bundle a custom subclass into ./inc');

my $build = Module::Build->current();

ok(ref $build eq 'Module::Build::SubClass', 'Build was resumed with correct class');


is_deeply($build->custom_flag(), 'flag_set', 'Custom flag property was processed correctly');

is_deeply($build->custom_array(), [ 1, 1, 2, 3] , 'Custom array property was processed correctly');

is_deeply($build->custom_hash(), {
    key1 => 'value1',
    key2 => 'value2'
} , 'Custom hash property was processed correctly');


# Cleanup
if (not $debug) {
	(undef, undef) = capture { $build->dispatch('realclean'); };
	unlink('Build.bat') if -e 'Build.bat';
	unlink('Build.com') if -e 'Build.com';
}
unlink(catfile(qw(inc Module Build Functions DSL.pm)));
unlink(catfile(qw(inc Module Build Functions.pm)));
unlink(catfile(qw(inc Module Build SubClass.pm)));
rmdir(catdir(qw(inc Module Build Functions)));
rmdir(catdir(qw(inc Module Build)));
rmdir(catdir(qw(inc Module)));
rmdir(catdir(qw(inc .author)));
rmdir('inc');

chdir($original_dir);