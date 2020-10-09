package main;

use 5.006;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

use PPI::Document;
use PPIx::Regexp;
use Scalar::Util qw{ refaddr };

{
    note 'Test static method PPIx::Regexp->extract_regexps()';

    my $doc = PPI::Document->new( 'eg/predump' );
    my @re = PPIx::Regexp->extract_regexps( $doc );

    cmp_ok scalar @re, '==', 2, 'Found two regexps';

    is $re[0]->content(), 'qr{ \\s* , \\s* }smx',
	q<First regexp is qr{ \\s* , \\s* }smx>;

    is $re[1]->content(), 's/ \\\\\\\\ /\\\\/smxg',
	q<Second regexp is s/ \\\\\\\\ /\\\\/smxg>;

}

{
    note 'Setup for testing statement()';

    my $code = 'm/x/;';
    my $doc = PPI::Document->new( \$code );
    my @stmt = @{ $doc->find( 'PPI::Statement' ) || [] };

    cmp_ok scalar @stmt, '==', 1, "'$code' contains exactly 1 statement";
    cmp_ok $stmt[0]->content(), 'eq', $code, "That statement is '$code'";

    my @re = PPIx::Regexp->extract_regexps( $doc );

    cmp_ok scalar @re, '==', 1, "'$code' contains one regexp";
    cmp_ok $re[0]->content(), 'eq', 'm/x/', q<That regexp is 'm/x/'>;

    my @lit = @{ $re[0]->find( 'PPIx::Regexp::Token::Literal' ) || [] };

    cmp_ok scalar @lit, '==', 1, q<'m/x/' contains exactly one literal>;

    note 'Test statement()';

    my $got_stmt = $lit[0]->statement();
    ok $got_stmt, 'statement() called on literal returned something';

    # The following is what this block is all about.
    cmp_ok refaddr( $got_stmt ), '==', refaddr( $stmt[0] ),
	'statement() called on literal returned original PPI statement';

    is scalar PPIx::Regexp->new( 'm/x/' )->statement(), undef,
	'statement() returns nothing if regexp did not come from PPI::Document';
}

{
    note 'Normalizing content for ppi()';

    use PPIx::Regexp::Tokenizer;
    my %arg = (
	tokenizer	=> PPIx::Regexp::Tokenizer->new( '' ),
    );
    foreach my $short ( qw{ Code Interpolation } ) {
	my $class = "PPIx::Regexp::Token::$short";
	foreach my $data (
	    { input => '$foo' },
	    { input => '$foo[42]' },
	    { input => '$foo->{bar}' },
	    { input => '$foo->*@' },
	    { input => '$foo->*[ 2 .. 4 ]' },
	    { input => '${foo}', Interpolation => '$foo' },
	    { input => '${ foo }', Interpolation => '$foo' },
	    { input => '$${foo}', Interpolation => '$$foo' },
	    { input => '@${foo}', Interpolation => '@$foo' },
	    { input => '@{[foo]}' },
	    { input => '$#foo' },
	) {
	    my $got = $class->__new( $data->{input}, %arg )->
		__ppi_normalize_content();
	    my $want = defined $data->{$short} ? $data->{$short} :
		defined $data->{want} ? $data->{want} :
		$data->{input};
	    is $got, $want, "$short normalizes '$data->{input}' to '$want'";
	}
    }
}

done_testing;

1;

# ex: set textwidth=72 :
