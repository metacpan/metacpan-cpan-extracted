BEGIN {
	$| = 1;
}
use Test::More tests => 2;
use File::Spec::Functions qw(catdir catfile);
use Cwd;
use Capture::Tiny qw(capture);

my $debug = 0;

my $original_dir = cwd();
my $blib_dir = catdir qw(.. .. blib lib);
my $littered_file = catfile($original_dir, qw(t inc Module Build Functions.pm));

diag("$littered_file should not be there.") if $debug;

ok(! -e $littered_file, 'Build.PL has not littered');
(undef, undef) = capture { do './Build.PL' } unless $debug;
do './Build.PL' if $debug;
ok(! -e $littered_file, 'Build.PL does not litter');

