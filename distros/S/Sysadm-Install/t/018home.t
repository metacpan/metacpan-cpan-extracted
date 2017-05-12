use Test::More;
use Sysadm::Install qw(:all);

plan tests => 1;

my $home = home_dir();

ok length( $home ), "home dir";
