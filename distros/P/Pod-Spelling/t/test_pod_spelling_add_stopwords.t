use strict;
use warnings;

use Test::More;

use lib 'lib';

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

eval {
	use Test::Pod::Spelling;
};

is( $@, '', 'use_ok' );

eval {
	add_stopwords(qw(
		Goddard LICENCE inline behaviour spelt TODO API
	));
};
is( $@, '', 'add_stopwords inline' );

my $rv = eval { pod_file_spelling_ok( 't/good.pod' ) };
is( $@, '', 'no errors');
is( $rv, 0, 'good.pod' );


done_testing( 5 );



