package main;

use 5.006;

use strict;
use warnings;

use PPI::Document;
use PPIx::QuoteLike;
use Scalar::Util qw{ refaddr };
use Test::More 0.88;	# Because of done_testing();

{
    my $code = '"foo"';

    my $doc = PPI::Document->new( \$code );
    my @qs = @{ $doc->find( 'PPI::Token::Quote' ) || [] };

    my $pql = PPIx::QuoteLike->new( $qs[0] );

    cmp_ok refaddr( $qs[0]->statement() ), '==',
	refaddr( $pql->statement() ),
	q<PPIx::QuoteLike statement() method>;

    my @lit = @{ $pql->find( 'PPIx::QuoteLike::Token::String' ) || [] };

    cmp_ok refaddr( $lit[0]->statement() ), '==',
	refaddr( $pql->statement() ),
	q<PPIx::QuoteLike::Token::String statement() method>;

}

done_testing;

1;

# ex: set textwidth=72 :
