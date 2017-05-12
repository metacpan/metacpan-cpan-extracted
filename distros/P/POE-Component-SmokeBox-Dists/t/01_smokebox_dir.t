use strict;
use warnings;
use Test::More tests => 1;
use POE::Component::SmokeBox::Dists;
use Cwd;

$ENV{PERL5_SMOKEBOX_DIR} = cwd();

my $smokebox_dir = POE::Component::SmokeBox::Dists::_smokebox_dir();

diag("SmokeBox directory is in '$smokebox_dir'\n");

ok( $smokebox_dir eq cwd(), 'PERL5_SMOKEBOX_DIR' );
