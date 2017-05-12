use strict;
use warnings; 

use Test::More tests => 9;
use File::Spec::Functions qw(catdir catfile);
use Module::Build::JSAN::Installable;
use Cwd;
use Capture::Tiny qw(capture);
use File::Path;


my $original_dir = cwd();
my $blib_dir = catdir qw(.. .. blib lib);

chdir(catdir(qw(t MJ-Test2)));


#================================================================================================================================================================================================================================================
diag( "\nRunning ./Build on test distribution #1\n" );

(undef, undef) = capture { system($^X, "-I$blib_dir", 'Build.PL'); };

ok(-e '_build', 'Build.PL appeared to execute correctly');
ok(-e 'Build', 'Building script was created');

my $build = Module::Build::JSAN::Installable->current();


#================================================================================================================================================================================================================================================
diag( "\nChecking 'author'" );

my $test2 = [ 
    'SamuraiJack <root@symbie.org>'
];

is_deeply($build->dist_author(), $test2, 'dist_author is correct (single)');



#================================================================================================================================================================================================================================================
diag( "Checking build elements" );

my $test3 = $Module::Build::VERSION ge '0.35_01' ? [qw(PL support pm xs share_dir pod script js static)] : [qw(PL support pm xs pod script js static)];

is_deeply($build->build_elements(), $test3, 'build_elements list is correct');


#================================================================================================================================================================================================================================================
diag( "Checking 'requires'" );

my $test4 = {
    'Cool.JS.Lib' => '1.1',
    'Another.Cool.JS.Lib' => '1.2'
};

is_deeply($build->requires(), $test4, 'requires list is correct');


#================================================================================================================================================================================================================================================
diag( "Checking 'build_requires'" );

my $test5 = {
    'Building.JS.Lib' => '1.1',
    'Another.Building.JS.Lib' => '1.2'
};

is_deeply($build->build_requires(), $test5, 'build_requires list is correct');


#================================================================================================================================================================================================================================================
diag( "Checking 'configure_requires'" );

is_deeply($build->configure_requires(), {}, 'configure_requires list is correct');



#================================================================================================================================================================================================================================================
diag( "Various options" );

is($build->license(), 'perl', 'license is correct');

is($build->create_makefile_pl(), 'passthrough', 'create_makefile_pl is correct');


# Cleanup

(undef, undef) = capture { $build->dispatch('realclean'); };
unlink('META.json') if -e 'META.json';
unlink('Build.bat') if -e 'Build.bat';
unlink('Build.com') if -e 'Build.com';
File::Path::rmtree('inc');

chdir($original_dir);