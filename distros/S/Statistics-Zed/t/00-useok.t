use Test::More tests => 3;

BEGIN {
	use_ok( 'Statistics::Zed' );
}

diag( "Testing Statistics::Zed $Statistics::Zed::VERSION, Perl $], $^X" );
1;

my $zed = Statistics::Zed->new();
isa_ok($zed, 'Statistics::Zed');
isa_ok($zed, 'Statistics::Data');

1;

