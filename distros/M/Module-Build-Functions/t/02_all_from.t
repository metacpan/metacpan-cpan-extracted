use Test::More tests => 8;
use File::Spec::Functions qw(catdir catfile);
use Module::Build;
use Cwd;
use Capture::Tiny qw(capture);

my $debug = 0;

my $original_dir = cwd();
my $blib_dir = catdir qw(.. .. blib lib);

chdir(catdir(qw(t MBF-Test2)));

(undef, undef) = capture { system($^X, "-I$blib_dir", 'Build.PL'); } unless $debug;
system($^X, "-I$blib_dir", 'Build.PL') if $debug;

my $build = Module::Build->current();


# documentation states, that this behavior started from 0.34, but practice shows the other (?)
if ($Module::Build::VERSION ge '0.35') {
    ok(exists $build->configure_requires()->{'Module::Build'}, "Module::Build was added to 'configure_requires'"); 
} else {
    is_deeply($build->configure_requires(), {}, 'configure_requires is empty');
}

my $test2 = [
	'Curtis Jewell <perl@csjewell.fastmail.us>',
	'Curtis Jewell <csjewell@cpan.org>',
	'Curtis Jewell <csjewell@cpan.org>'
];

is_deeply($build->dist_author(), $test2, 'dist_author_from is correct');

my $test3 = {
	'perl' => '5.007',
};

is_deeply($build->requires(), $test3, 'perl_version_from is correct');

my $test4 = {
	'Module::Build' => '0.20',
};

is_deeply($build->build_requires(), $test4, 'build_requires list is correct');

my $test6 = bless( {
	'original' => '0.000_001',
	'alpha' => 1,
	'version' => [ 0, 0, 1 ],
  }, 'Module::Build::Version' );

is_deeply($build->dist_version(), $test6, 'dist_version_from works');

my @test7 = $build->cleanup();
my $got7 = ['MBF-Test2-*'];

is_deeply(\@test7, $got7, 'add_to_cleanup is correct');

is($build->license(), 'restrictive', 'license is correct (meaning no license)');

is($build->dist_abstract(), 'Second test module for Module::Build::Functions', 'abstract_from is correct');


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