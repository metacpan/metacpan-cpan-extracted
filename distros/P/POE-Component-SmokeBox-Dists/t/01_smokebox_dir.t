use strict;
use warnings;
use Test::More tests => 1;
use File::Temp qw[tempdir];
use POE::Component::SmokeBox::Dists;
use Cwd;

my $tmpdir = tempdir( DIR => 't', CLEANUP => 1 );
my $cwd = getcwd; END { chdir $cwd }
chdir $tmpdir;

$ENV{PERL5_SMOKEBOX_DIR} = cwd();

my $smokebox_dir = POE::Component::SmokeBox::Dists::_smokebox_dir();

diag("SmokeBox directory is in '$smokebox_dir'\n");

ok( $smokebox_dir eq cwd(), 'PERL5_SMOKEBOX_DIR' );
