use Test::More tests => 1;

BEGIN {
	use_ok( 'SQL::Template' );
}

diag( "Testing SQL::Template $SQL::Template::VERSION, Perl $], $^X" );