use Test::More;

BEGIN {
	unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
}
plan( tests => 3 );

use Padre::Perl;
use Padre::Plugin::Catalyst;

ok( my $perl = Padre::Perl->perl, "Get perl interpreter" );
ok( defined $perl, "Perl interpreter defined" );

SKIP: {
	skip( "old method. perl_interpreter was moved to Padre::Perl->perl", 1 );
	ok( my $perl = Padre->perl_interpreter, "Padre perl_interpreter" );
}

