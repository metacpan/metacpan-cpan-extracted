use Test::More tests => 2;
use File::Spec::Functions qw(catdir catfile);
use Module::Build;
use Cwd;
use Capture::Tiny qw(capture);

my $debug = 0;

my $original_dir = cwd();
my $blib_dir = catdir qw(.. .. blib lib);

chdir(catdir(qw(t MBF-Test3)));

(undef, undef) = capture { system($^X, "-I$blib_dir", 'Build.PL'); } unless $debug;
system($^X, "-I$blib_dir", 'Build.PL') if $debug;

my $build = Module::Build->current();

my $test1 = {
	'meta-test1' => 'meta-test1',
};

is_deeply($build->meta_add(), $test1, 'meta_add is correct');

my $test2 = {
	'resources' => {
		'repository'  => 'http://svn.ali.as/cpan/trunk/Module-Build-Functions/',
		'bugtracker'  => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Build-Functions',
		'MailingList' => 'mailto:module-build@perl.org',
	}
};

is_deeply($build->meta_merge(), $test2, 'meta_merge is correct');

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