use strict; use warnings;

use Test::More;

BEGIN {
	eval { require Pod::Spelling };
	if ($@){
		plan skip_all => 'requires Pod::Spelling' ;
	}
}

# First, we test without allow_words
ok((-e 't/test.pod'), 'Got file');
my $o = Pod::Spelling->new( 'import_speller' => 'Pod::Spelling::CommonMistakes' );
my @r = $o->check_file( 't/test.pod' );

is(  @r, 1, 'Expected errors' );
is( $r[0], 'abandonning', 'Known erroneous word');

# Now, we test again setting it!
$o = Pod::Spelling->new(
	'import_speller' => 'Pod::Spelling::CommonMistakes',
	'allow_words' => 'abandonning'
);

@r = $o->check_file( 't/test.pod' );
is(  @r, 0, 'No errors for allow_words/STRING');

done_testing();
