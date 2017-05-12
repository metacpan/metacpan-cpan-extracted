BEGIN {
	$| = 1;
}
use Test::More tests => 14;
use File::Spec::Functions qw(catdir catfile);
use Module::Build;
use Cwd;
use Capture::Tiny qw(capture);
diag( "Using Module::Build $Module::Build::VERSION" );

my $debug = 0;

my $original_dir = cwd();
my $blib_dir = catdir qw(.. .. blib lib);

chdir(catdir(qw(t MBF-Test)));


(undef, undef) = capture { system($^X, "-I$blib_dir", 'Build.PL'); } unless $debug;
system($^X, "-I$blib_dir", 'Build.PL') if $debug;
ok(-e '_build', 'Build.PL appeared to execute correctly');
ok(-e 'Build', 'Building script was created');
ok(-e catfile(qw(inc Module Build Functions.pm)), 'Build.PL appeared to bundle itself into ./inc');

my $build = Module::Build->current();

my $test1 = {
    'Module::Build' => '0.31'
};

is_deeply($build->configure_requires(), $test1, 'Version of Module::Build is found correctly');

my $test2 = [ 
	'Curtis Jewell <csjewell@cpan.org>',
    'Curtis Jewell <perl@csjewell.fastmail.us>'
];

is_deeply($build->dist_author(), $test2, 'dist_author is correct (multiple)');

my $test3 = $Module::Build::VERSION ge '0.35_01' ? 
    [qw(PL support pm xs share_dir pod script share share_d1 share_d2)] 
    : 
    [qw(PL support pm xs pod script share share_d1 share_d2)];

is_deeply($build->build_elements(), $test3, 'build_elements list is correct');

my $test4 = {
	'perl' => '5.005',
	'File::Slurp' => 0,
};

is_deeply($build->requires(), $test4, 'requires list is correct');

my $test5 = {
	'Test::More' => 0,
	'Test::Compile' => 0,
	'Module::Build' => '0.31'
};

is_deeply($build->build_requires(), $test5, 'build_requires list is correct');

my $test6 = bless( {
	'original' => '0.001_006',
	'alpha' => 1,
	'version' => [ 0, 1, 6 ],
  }, 'Module::Build::Version' );

is_deeply($build->dist_version(), $test6, 'dist_version_from works');

my @test7 = $build->cleanup();
my $got7 = ['MBF-Test-*'];

is_deeply(\@test7, $got7, 'add_to_cleanup is correct');

is($build->license(), 'perl', 'license is correct');

is($build->create_makefile_pl(), 'passthrough', 'create_makefile_pl is correct');

# Grabbing our file lists out...
Module::Build->add_property('share_files', default => sub { return {} });
Module::Build->add_property('share_d2_files', default => sub { return {} });

# Note that part of these two tests is that cover_db is NOT picked up.

my $test7 = {
	catfile(qw(share Test.pod)) => catfile(qw(share Test.pod)),
	catfile(qw(share T Test.pod)) => catfile(qw(share T Test.pod))
};

is_deeply($build->share_files(), $test7, 'Correct files are shared (dist)');

my $test8 = {
	catfile(qw(share_mod2 Test.pod)) => catfile(qw(share_d2 Test.pod)),
	catfile(qw(share_mod2 T Test.pod)) => catfile(qw(share_d2 T Test.pod))
};

is_deeply($build->share_d2_files(), $test8, 'Correct files are shared (module)');

# Cleanup
if (not $debug) {
	(undef, undef) = capture { $build->dispatch('realclean'); };
	unlink('Build.bat') if -e 'Build.bat';
	unlink('Build.com') if -e 'Build.com';
}
unlink(catfile(qw(inc Module Build Functions.pm)));
rmdir(catdir(qw(inc Module Build)));
rmdir(catdir(qw(inc Module)));
rmdir(catdir(qw(inc .author)));
rmdir('inc');

chdir($original_dir);