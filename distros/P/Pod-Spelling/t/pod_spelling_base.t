use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Cwd;

use lib 'lib';

BEGIN {
	my $no_pm;
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
		$no_pm ++;
	}
	if (!$no_pm) {
		plan tests => 8;
	}
}

BEGIN {
	use_ok('Pod::Spelling');
}


no warnings 'Pod::Spelling';

my $rv;

my $o = eval { Pod::Spelling->new };

isa_ok( $o, 'Pod::Spelling') or BAIL_OUT "";

diag getcwd();

my @rv = $o->check_file( 't/good.pod' );
ok( not(@rv), 'default dummy callback')
	or diag join', ', @rv;

$o = Pod::Spelling->new( use_pod_wordlist => 1, );

isa_ok( $o, 'Pod::Spelling');

$rv = 	$o->check_file( 't/pod_wordlist.pod' );
is( $rv, 0, 'even default dummy callback passes pod-wordlist' );

$o = Pod::Spelling->new( allow_words => 'Goddard', );
isa_ok( $o, 'Pod::Spelling');

unlike( 
	join('', $o->check_file( 't/good.pod' )), 
	qr/Goddard/,
	'even default dummy callback passes allow_word'
);

is( $o->check_file('t/rt_75228.txt'), 0, 'apostrophes');

done_testing();




