#!perl

use Test::More;

if ( defined( $ENV{DISPLAY} ) or $^O eq 'MSWin32' ) {
	plan tests => 3;
} else {
	plan skip_all => "this test needs DISPLAY";
}

use Padre;
use Padre::PluginManager;

my $p = Padre->new();
my $m = Padre::PluginManager->new();
$m->load_plugin("REPL");
isnt( $m->{plugins}->{REPL}->{status}, 'error' );

SKIP: {
	if ( $m->{plugins}->{REPL}->{status} eq 'error' ) {
		warn( "failed to load: " . $m->{plugins}->{REPL}->{errstr} );
		skip "failed to load: " . $m->{plugins}->{REPL}->{errstr}, 2;
	}

	ok( $m->{plugins}->{REPL}->enable() );
	is( $m->{plugins}->{REPL}->{status}, 'enabled' );
}
