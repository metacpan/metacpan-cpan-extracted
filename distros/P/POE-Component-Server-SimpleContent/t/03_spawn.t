# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('POE::Component::Server::SimpleContent') };

#########################

use POE;

my ($content) = POE::Component::Server::SimpleContent->spawn( root_dir => 'static/' );

isa_ok( $content, 'POE::Component::Server::SimpleContent' );

POE::Session->create(
	package_states => [
		'main' => [ qw(_start) ],
	],
);

$poe_kernel->run();
exit 0;

sub _start {
  $content->shutdown();
}
