package main;

use 5.006;

use strict;
use warnings;

use PPI::Document;
use PPIx::QuoteLike::Constant qw{ HAVE_PPIX_REGEXP };
use PPIx::QuoteLike::Utils qw{ __variables };
use Test::More 0.88;	# Because of done_testing();

check( q<"foo$bar">, qw< $bar > );

check( q<'foo$bar'> );

check_token( q<"foo$bar">, qw< $bar > );

check_token( q<'foo$bar'> );

check_class( q<"foo$bar">, qw< PPIx::QuoteLike $bar > );

# Note -- the following was done using the trinary operator rather than
# if/else because I hoped that with the former implementation, when I
# added tests I would do so correctly.

note( HAVE_PPIX_REGEXP ?
    'PPIx::Regexp is installed; we can find variables in Regexps' :
    'PPIx::Regexp is not installed; we can not find variables in Regexps' );

check( q<my ( $foo ) = $bar =~ m/(baz|$burfle)/smx;>,
    HAVE_PPIX_REGEXP ?  qw< $bar $burfle $foo > :
	qw< $bar $foo > );

check( q<qr/ foo (?{ "$bar" }) />,
    HAVE_PPIX_REGEXP ? qw< $bar > : () );

check_token( q<s/ foo ( $bar[0] ) / xyz( $1 ) /smxe;>,
    HAVE_PPIX_REGEXP ? qw{ $1 @bar } : () );

if ( HAVE_PPIX_REGEXP ) {

    check_class( q<qr/ foo (?{ "$bar" }) />, qw< PPIx::Regexp $bar > );

}

done_testing;

sub check {
    my ( $expr, @want ) = @_;
    my $doc = PPI::Document->new( \$expr );
    my @got = sort( __variables( $doc ) );
    @_ = ( \@got, [ sort @want ], "Variables in q<$expr>" );
    goto &is_deeply;
}

sub check_class {
    my ( $expr, $class, @want ) = @_;
    ( my $fn = "$class.pm" ) =~ s| :: |/|smxg;
    require $fn;
    my $obj = $class->new( $expr );
    my @got = sort( __variables( $obj ) );
    @_ = ( \@got, [ sort @want ], "Variables in $class q<$expr>" );
    goto &is_deeply;
}

sub check_token {
    my ( $expr, @want ) = @_;
    my $doc = PPI::Document->new( \$expr );
    my ( $elem ) = @{ $doc->find( sub {
	$_[1]->significant() && ! $_[1]->isa( 'PPI::Node' )
    } ) || [] };
    if ( $elem ) {
	my @got = sort( __variables( $elem ) );
	@_ = ( \@got, [ sort @want ], "Variables in first token of q<$expr>" );
	goto &is_deeply;
    } else {
	@_ = ( "No tokens found in q<$expr>" );
	goto &fail;
    }
}

1;

# ex: set textwidth=72 :
