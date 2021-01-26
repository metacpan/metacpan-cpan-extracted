#!perl
use v5.10;

use lib qw(lib);

use Module::Release;
my $release = Module::Release->new;
$release->load_mixin( 'Module::Release::Git' );

my @contributors = $release->get_recent_contributors();
say join "\n", @contributors;
