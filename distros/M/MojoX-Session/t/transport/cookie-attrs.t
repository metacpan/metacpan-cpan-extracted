use Test::More;

use lib 't/lib';

use Mojo::Transaction::HTTP;
use Mojo::Cookie::Response;
use MojoX::Session::Store::Dummy;

my @attrs = qw/name path domain httponly secure/;

plan tests => 2 + 2*@attrs;

use_ok('MojoX::Session');
use_ok('MojoX::Session::Transport::Cookie');

foreach my $attr (@attrs) {
	my $tx = Mojo::Transaction::HTTP->new;

	my $session = MojoX::Session->new(
		tx        => $tx,
		store     => MojoX::Session::Store::Dummy->new,
		transport => MojoX::Session::Transport::Cookie->new( $attr => 1 ),
	);

	my $sid = $session->create;
	$session->flush;
	ok($sid, "session with $attr");
	my $cookie = $tx->res->cookies->[0];
	is($cookie->$attr, 1, "$attr == 1");
}
