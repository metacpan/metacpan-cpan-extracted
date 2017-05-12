use Test::More tests => 3;
use File::Spec::Functions qw(catdir catfile);
use File::Path;
use Cwd;

BEGIN {
    my $original_dir = cwd();
    my $littered_file = catfile($original_dir, qw(t inc Module Build Functions.pm));
    
    ok(! -e $littered_file, 'Build.PL has not littered');
    
	use_ok( 'inc::Module::Build::Functions' );
	
	ok(! -e $littered_file, 'Build.PL does not litter');
}