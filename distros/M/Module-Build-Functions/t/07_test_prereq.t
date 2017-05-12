BEGIN {
	$| = 1;
}
use Test::More;
use File::Spec::Functions qw(catdir catfile);
use Cwd;
use Capture::Tiny qw(capture);


eval "use Test::Prereq::Build;";
if ($@) {
    plan skip_all => "Test::Prereq::Build required to test dependencies";
    
    exit(0);
}


eval "use Path::Class;";
if ($@) {
    plan skip_all => "Path::Class required to test dependencies";
    
    exit(0);
}

plan tests => 6;


my $original_dir = cwd();
my $blib_dir = catdir qw(.. .. blib lib);


chdir(catdir(qw(t MBF-Test4)));

(undef, undef) = capture { system($^X, "-I$blib_dir", 'Build.PL'); };

ok(-e '_build', 'Build.PL appeared to execute correctly');
ok(-e 'Build', 'Building script was created');
ok(-e catfile(qw(inc Module Build Functions.pm)), 'Build.PL appeared to bundle itself into ./inc');


my ($std, $err) = capture { system($^X, "-I$blib_dir", 'Build', 'test'); };

ok($err =~ /Found some modules that didn't show up in PREREQ_PM/s && $err =~ /Path::Class/s, 'Missed prerequisite was detected');


($std, $err) = capture { system($^X, "-I$blib_dir", 'Build', 'realclean'); };

ok(! -e '_build', "'realclean' action cleaned '_build'");
ok(! -e 'Build', "'realclean' action cleaned 'Build'");

chdir($original_dir);