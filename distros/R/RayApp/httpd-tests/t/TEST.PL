
use blib;
use lib qw( lib );

use warnings FATAL => 'all';

use Apache::TestRun ();

eval {
	use RayApp;
	use RayApp::mod_perl;
};
if ($@) {
	die "RayApp or RayApp::mod_perl is not alright:\n$@\n";
}

Apache::TestRun->new->run(
	'-maxclients' => 5,
	@ARGV
);

