use strict;
use warnings;

use Test::More;

BEGIN {
	eval { require Lingua::Ispell };
	if ($@){
		eval { 
			require Text::Aspell;
			my $o = Text::Aspell->new;
			$o->check('house');
			die $o->errstr if $o->errstr;
		};
	}
	if ($@){
		plan skip_all => 'requires Lingua::Ispell or Text::Aspell' ; 
	}
}

BEGIN {
	use lib 'lib';
	use_ok('Pod::Spelling');
}

my $o = Pod::Spelling->new(
	spell_check_callback => sub { return 'foo' },
);

isa_ok( $o, 'Pod::Spelling');

like( 
	join('',$o->check_file( 't/good.pod' )),
	qr/^(foo)+$/,
	'override callback'
);

done_testing();

