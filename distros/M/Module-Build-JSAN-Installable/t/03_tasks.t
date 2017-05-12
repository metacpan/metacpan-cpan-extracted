BEGIN {
	$| = 1;
}
use Test::More tests => 14;
use File::Spec::Functions qw(catdir catfile);
use Module::Build::JSAN::Installable;
use Cwd;
use Capture::Tiny qw(capture);
use Path::Class;


diag( "Using Module::Build::JSAN::Installable $Module::Build::JSAN::Installable::VERSION" );


my $original_dir = cwd();
my $blib_dir = catdir qw(.. .. blib lib);

chdir(catdir(qw(t MBJI-Tasks)));


#================================================================================================================================================================================================================================================
diag( "Running ./Build on test distribution" );

(undef, undef) = capture { system($^X, "-I$blib_dir", 'Build.PL'); };

ok(-e '_build', 'Build.PL appeared to execute correctly');
ok(-e 'Build', 'Building script was created');

my $build = Module::Build::JSAN::Installable->current();


#================================================================================================================================================================================================================================================
# Creating tasks

$ENV{JSANLIB} = dir('jsan');

my ($std, $err) = capture { system($^X, "-I$blib_dir", 'Build', 'task', '--task_name=all'); };

#diag("STDOUT: [$std], STDERR: [$err]");


#================================================================================================================================================================================================================================================
# Checking file presence

ok(-e catfile(qw(lib Task Digest MD5 Even.js)), '"Even" bundle was created');
ok(-e catfile(qw(lib Task Digest MD5 Odd.js)), '"Odd" bundle was created');
ok(-e catfile(qw(lib Task Digest MD5 EvenPlusOdd.js)), '"Odd" bundle was created');
ok(-e catfile(qw(lib Task Digest MD5 Part21.js)), '"Odd" bundle was created');
ok(-e catfile(qw(lib Task Digest MD5 Part22.js)), '"Odd" bundle was created');
ok(-e catfile(qw(lib Task Digest MD5 Part23.js)), '"Odd" bundle was created');


#================================================================================================================================================================================================================================================
# Checking file content

my $even_content            = file(qw(lib Task Digest MD5 Even.js))->slurp;
my $odd_content             = file(qw(lib Task Digest MD5 Odd.js))->slurp;
my $even_plus_odd_content   = file(qw(lib Task Digest MD5 EvenPlusOdd.js))->slurp;
my $part21                  = file(qw(lib Task Digest MD5 Part21.js))->slurp;
my $part22                  = file(qw(lib Task Digest MD5 Part22.js))->slurp;
my $part23                  = file(qw(lib Task Digest MD5 Part23.js))->slurp;


ok($even_content =~ /2;\s+4;/s, '`Even` bundle is correct');
ok($odd_content =~ /1;\s+3;/s, '`Odd` bundle is correct');
ok($even_plus_odd_content =~ /2;\s+4;\s+1;\s+3;/s, '`Odd` bundle is correct');
ok($part23 =~ /jsan1;\s+part23;\s+jsan2;/s, '`Part23` bundle is correct');
ok($part22 =~ /jsan1;\s+part23;\s+jsan2;\s+part22;/s, '`Part22` bundle is correct');
ok($part21 =~ /jsan1;\s+part23;\s+jsan2;\s+part22;\s+part21;\s+jsan4;/s, '`Part21` bundle is correct');



# Cleanup
(undef, undef) = capture { $build->dispatch('realclean'); };
unlink('MANIFEST') if -e 'MANIFEST';
unlink('MANIFEST.SKIP.bak') if -e 'MANIFEST.SKIP.bak';
unlink('META.json') if -e 'META.json';
unlink('Build.bat') if -e 'Build.bat';
unlink('Build.com') if -e 'Build.com';

chdir($original_dir);