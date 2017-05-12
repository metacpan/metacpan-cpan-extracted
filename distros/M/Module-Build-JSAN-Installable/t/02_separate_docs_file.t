BEGIN {
	$| = 1;
}
use Test::More tests => 6;
use File::Spec::Functions qw(catdir catfile);
use Module::Build::JSAN::Installable;
use Cwd;
use Capture::Tiny qw(capture);
use Path::Class;


diag( "Using Module::Build::JSAN::Installable $Module::Build::JSAN::Installable::VERSION" );


my $original_dir = cwd();
my $blib_dir = catdir qw(.. .. blib lib);

chdir(catdir(qw(t MBJI-SeparateDocFile)));


#================================================================================================================================================================================================================================================
diag( "Running ./Build on test distribution #1" );

(undef, undef) = capture { system($^X, "-I$blib_dir", 'Build.PL'); };

ok(-e '_build', 'Build.PL appeared to execute correctly');
ok(-e 'Build', 'Building script was created');

my $build = Module::Build::JSAN::Installable->current();


#================================================================================================================================================================================================================================================
# Creating docs

$build->dispatch('manifest');

(undef, undef) = capture { $build->dispatch('docs'); };


#================================================================================================================================================================================================================================================
# Checking file presence

ok(-e catfile(qw(doc mmd Digest MD5.txt)), 'MMD Documentation for main module was created');
ok(-e catfile(qw(doc html Digest MD5.html)), 'HTML Documentation for main module was created');


#================================================================================================================================================================================================================================================
# Checking file content

my $md_content = file(qw(doc mmd Digest MD5.txt))->slurp;

ok($md_content =~ m/NAME/s && $md_content =~ m/====/s &&  $md_content =~ m/Digest\.MD5/s, 'Content of md file seems ok');


my $html_content = file(qw(doc html Digest MD5.html))->slurp;

ok($html_content =~ m!\Q<h1 id="name">NAME</h1>\E!s && $html_content =~ m!\Q<p>Digest.MD5</p>\E!s, 'Content of html file seems ok');


# Cleanup
(undef, undef) = capture { $build->dispatch('realclean'); };
unlink('MANIFEST') if -e 'MANIFEST';
unlink('MANIFEST.SKIP.bak') if -e 'MANIFEST.SKIP.bak';
unlink('META.json') if -e 'META.json';
unlink('Build.bat') if -e 'Build.bat';
unlink('Build.com') if -e 'Build.com';

chdir($original_dir);