package main;

use strict;
use warnings;

use lib qw{ inc };

use PPI::Document;
use My::Module::Test;
use PPIx::Regexp::Constant qw{ MINIMUM_PERL };
use Scalar::Util qw{ refaddr };

local @PPIx::Regexp::Constant::CARP_NOT = (
    @PPIx::Regexp::Constant::CARP_NOT, 'My::Module::Test' );

my $is_ascii = ord( "\t" ) == 9;	# per perlebcdic

my $have_charnames;

BEGIN {
    eval {
	require charnames;
	charnames->import( qw{ :full } );
	$have_charnames = charnames->can( 'vianame' );
    };
}

tokenize( {}, '-notest' ); # We don't know how to tokenize a hash reference.
equals  ( undef, 'We did not get an object' );
value   ( errstr => [], 'HASH not supported' );

parse   ( {}, '-notest' ); # If we can't tokenize it, we surely can't parse it.
equals  ( undef, 'We did not get an object' );
value   ( errstr => [], 'HASH not supported' );

parse   ( 'fubar' );	# We can't make anything of this.
value   ( failures => [], 1 );
klass   ( 'PPIx::Regexp' );
value   ( capture_names => [], undef );
value   ( max_capture_number => [], undef );
value   ( source => [], 'fubar' );

tokenize( '/$x{$y{z}}/' );
count   ( 5 );
choose  ( 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
choose  ( 1 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Interpolation' );
content ( '$x{$y{z}}' );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( 4 );
klass   ( 'PPIx::Regexp::Token::Modifier' );
content ( '' );

{

    # The navigation tests get done in their own local scope so that all
    # the object references we have held go away when we are done.

    parse   ( '/ ( 1 2(?#comment)) /x' );
    value   ( failures => [], 0 );
    value   ( errstr => [], undef );
    klass   ( 'PPIx::Regexp' );
    value   ( elements => [], 3 );

    choose  ( first_element => [] );
    klass   ( 'PPIx::Regexp::Token::Structure' );
    content ( '' );

    choose  ( last_element => [] );
    klass   ( 'PPIx::Regexp::Token::Modifier' );
    content ( 'x' );

    choose  ( tokens => [] );
    count   ( 13 );
    navigate( 7 );
    klass   ( 'PPIx::Regexp::Token::Literal' );
    content ( '2' );

    my $lit1 = choose( find_first => 'Token::Literal' );
    klass   ( 'PPIx::Regexp::Token::Literal' );
    content ( '1' );
    true    ( significant => [] );
    false   ( whitespace => [] );
    false   ( comment => [] );

    navigate( next_sibling => [] );
    klass   ( 'PPIx::Regexp::Token::Whitespace' );
    content ( ' ' );
    false   ( significant => [] );
    true    ( whitespace => [] );
    false   ( comment => [] );

    my $lit2 = navigate( next_sibling => [] );
    klass   ( 'PPIx::Regexp::Token::Literal' );
    content ( '2' );

    navigate( previous_sibling => [] );

    navigate( previous_sibling => [] );
    equals  ( $lit1, 'Two previouses undo two nexts' );

    navigate( snext_sibling => [] );
    equals  ( $lit2, 'A snext gets us the next significant token' );

    navigate( sprevious_sibling => [] );
    equals  ( $lit1, 'An sprevious gets us back' );

    navigate( previous_sibling => [] );
    equals  ( undef, 'Nobody before the first literal' );

    navigate( $lit2, next_sibling => [] );
    klass   ( 'PPIx::Regexp::Token::Comment' );
    content ( '(?#comment)' );
    false   ( significant => [] );
    false   ( whitespace => [] );
    true    ( comment => [] );

    navigate( next_sibling => [] );
    equals  ( undef, 'Nobody after second whitespace' );

    navigate( $lit2, snext_sibling => [] );
    equals  ( undef, 'Nobody significant after second literal' );

    navigate( $lit1, sprevious_sibling => [] );
    equals  ( undef, 'Nobody significant before first literal' );

    navigate( $lit1, parent => [] );
    klass   ( 'PPIx::Regexp::Structure::Capture' );

    my $top = navigate( top => [] );
    klass   ( 'PPIx::Regexp' );
    true    ( ancestor_of => $lit1 );
    true    ( contains    => $lit1 );
    false   ( ancestor_of => undef );

    navigate( $lit1 );
    true    ( descendant_of => $top );
    false   ( descendant_of => $lit2 );
    false   ( ancestor_of   => $lit2 );
    false   ( descendant_of => undef );

    choose  ( find => 'Token::Literal' );
    count   ( 2 );
    navigate( -1 );
    equals  ( $lit2, 'The last literal is the second one' );

    choose  ( find_parents => 'Token::Literal' );
    count   ( 1 );

    my $capt = navigate( 0 );
    klass   ( 'PPIx::Regexp::Structure::Capture' );
    value   ( elements => [], 7 );
    value   ( name => [], undef );

    navigate( $capt, first_element => [] );
    klass   ( 'PPIx::Regexp::Token::Structure' );
    content ( '(' );

    navigate( $capt, last_element => [] );
    klass   ( 'PPIx::Regexp::Token::Structure' );
    content ( ')' );

    navigate( $capt, schildren => [] );
    count   ( 2 );
    navigate( 1 );
    klass   ( 'PPIx::Regexp::Token::Literal' );
    content ( '2' );

    choose  ( find => sub {
	    ref $_[1] eq 'PPIx::Regexp::Token::Literal'
		or return 0;
	    $_[1]->content() eq '2'
		or return 0;
	    return 1;
	} );
    count   ( 1 );
    navigate( 0 );
    equals  ( $lit2, 'We found the second literal again' );

    navigate( parent => [], schild => 1 );
    equals  ( $lit2, 'The second significant child is the second literal' );

    navigate( parent => [], schild => -2 );
    equals  ( $lit1, 'The -2nd significant child is the first literal' );

    choose  ( previous_sibling => [] );
    equals  ( undef, 'The top-level object has no previous sibling' );

    choose  ( sprevious_sibling => [] );
    equals  ( undef, 'The top-level object has no significant previous sib' );

    choose  ( next_sibling => [] );
    equals  ( undef, 'The top-level object has no next sibling' );

    choose  ( snext_sibling => [] );
    equals  ( undef, 'The top-level object has no significant next sibling' );

    choose  ( find => [ {} ] );
    equals  ( undef, 'Can not find a hash reference' );

    navigate( $lit2 );
    value   ( nav => [], [ child => [1], child => [0], child => [2] ] );

}

SKIP: {

    # The cache tests get done in their own scope to ensure the objects
    # are destroyed.

    my $num_tests = 8;
    my $doc = PPI::Document->new( \'m/foo/smx' )
	or skip( 'Failed to create PPI::Document', $num_tests );
    my $m = $doc->find_first( 'PPI::Token::Regexp::Match' )
	or skip( 'Failed to find PPI::Token::Regexp::Match', $num_tests );

    my $o1 = PPIx::Regexp->new_from_cache( $m );
    my $o2 = PPIx::Regexp->new_from_cache( $m );

    equals( $o1, $o2, 'new_from_cache() same object' );

    cache_count( 1 );

    PPIx::Regexp->flush_cache( 42 );	# Anything not a PPIx::Regexp

    cache_count( 1 );			# Nothing happens

    my $o9 = PPIx::Regexp->new_from_cache( '/foo/' );

    cache_count( 1 );			# Not cached.

    $o9->flush_cache();

    cache_count( 1 );			# Not flushed, either.

    PPIx::Regexp->flush_cache();

    cache_count();

    $o1 = PPIx::Regexp->new_from_cache( $m );

    cache_count( 1 );

    $o1->flush_cache();

    cache_count();

}

SKIP: {

    # More cache tests, in their own scope not only to ensure object
    # destruction, but so $DISABLE_CACHE can be localized.

    local $PPIx::Regexp::DISABLE_CACHE = 1;

    my $num_tests = 2;
    my $doc = PPI::Document->new( \'m/foo/smx' )
	or skip( 'Failed to create PPI::Document', $num_tests );
    my $m = $doc->find_first( 'PPI::Token::Regexp::Match' )
	or skip( 'Failed to find PPI::Token::Regexp::Match', $num_tests );

    my $o1 = PPIx::Regexp->new_from_cache( $m );
    my $o2 = PPIx::Regexp->new_from_cache( $m );

    different( $o1, $o2, 'new_from_cache() same object, cache disabled' );

    cache_count();	# Should still be nothing in cache.

}

tokenize( '/\\n\\04\\xff\\x{0c}\\N{LATIN SMALL LETTER E}\\N{U+61}/' );
count   ( 10 );
choose  ( 2 );
value   ( ordinal => [], ord "\n" );
choose  ( 3 );
value   ( ordinal => [], ord "\04" );
choose  ( 4 );
value   ( ordinal => [], ord "\xff" );
choose  ( 5 );
value   ( ordinal => [], ord "\x{0c}" );
SKIP: {
    $have_charnames
	or skip( "unable to load charnames::vianame", 1 );
    choose  ( 6 );
    value   ( ordinal => [], ord 'e' );
}
choose  ( 7 );
value   ( ordinal => [], ord 'a' );

tokenize( 's/\\b/\\b/' );
count   ( 7 );
choose  ( 4 );
value   ( ordinal => [], ord "\b" );

tokenize( '//smx' );
count   ( 4 );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::Modifier' );
content ( 'smx' );
true    ( asserts => 's' );
true    ( asserts => 'm' );
true    ( asserts => 'x' );
false   ( negates => 'i' );

tokenize( '//r' );
count   ( 4 );
choose  ( 3 );
content ( 'r' );
true    ( asserts => 'r' );
value   ( match_semantics => [], undef );
value   ( perl_version_introduced => [], 5.013002 );

tokenize( '/(?^:foo)/' );
count   ( 10 );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::GroupType::Modifier' );
content ( '?^:' );
true    ( asserts => 'd' );
false   ( asserts => 'l' );
false   ( asserts => 'u' );
true    ( negates => 'i' );
true    ( negates => 's' );
true    ( negates => 'm' );
true    ( negates => 'x' );
value	( match_semantics => [], 'd' );
value   ( perl_version_introduced => [], 5.013006 );

tokenize( '/(?^l:foo)/' );
count   ( 10 );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::GroupType::Modifier' );
content ( '?^l:' );
false   ( asserts => 'd' );
true    ( asserts => 'l' );
false   ( asserts => 'u' );
value   ( match_semantics => [], 'l' );
value   ( perl_version_introduced => [], 5.013006 );

tokenize( 'qr/foo{3}/' );
count   ( 10 );
choose  ( 7 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '}' );
false   ( can_be_quantified => [] );
true    ( is_quantifier => [] );

tokenize( 'qr/foo{3,}/' );
count   ( 11 );
choose  ( 8 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '}' );
false   ( can_be_quantified => [] );
true    ( is_quantifier => [] );

tokenize( 'qr/foo{3,5}/' );
count   ( 12 );
choose  ( 9 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '}' );
false   ( can_be_quantified => [] );
true    ( is_quantifier => [] );

tokenize( 'qr/foo{,3}/' );
count   ( 11 );
choose  ( 8 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '}' );
false   ( can_be_quantified => [] );
true    ( is_quantifier => [] );	# As of 5.33.6; previously false

tokenize( '/{}/' );
count   ( 6 );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '}' );
false   ( can_be_quantified => [] );
false   ( is_quantifier => [] );

tokenize( '/x{}/' );
count   ( 7 );
choose  ( 4 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '}' );
false   ( can_be_quantified => [] );
false   ( is_quantifier => [] );

tokenize( '/{2}/' );
count   ( 7 );
choose  ( 4 );
content ( '}' );
false   ( can_be_quantified => [] );
false   ( is_quantifier => [] );

tokenize( '/\\1?\\g{-1}*\\k<foo>{1,3}+/' );
count   ( 15 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\1' );
true    ( can_be_quantified => [] );
false   ( is_quantifier => [] );
value   ( perl_version_introduced => [], MINIMUM_PERL );
choose  ( 4 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\g{-1}' );
true    ( can_be_quantified => [] );
false   ( is_quantifier => [] );
value   ( perl_version_introduced => [], '5.009005' );
choose  ( 6 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\k<foo>' );
true    ( can_be_quantified => [] );
false   ( is_quantifier => [] );
value   ( perl_version_introduced => [], '5.009005' );

tokenize( '/\\\\d{3,5}+.*?/' );
count   ( 15 );
choose  ( 9 );
klass   ( 'PPIx::Regexp::Token::Greediness' );
content ( '+' );
value   ( perl_version_introduced => [], '5.009005' );
choose  ( 12 );
klass   ( 'PPIx::Regexp::Token::Greediness' );
content ( '?' );
value   ( perl_version_introduced => [], MINIMUM_PERL );

tokenize( '/(?<foo>bar)/' );
count   ( 10 );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::GroupType::NamedCapture' );
content ( '?<foo>' );
value   ( name => [], 'foo' );
value   ( perl_version_introduced => [], '5.009005' );

tokenize( '/(?\'for\'bar)/' );
count   ( 10 );
choose  ( 3 );
value   ( name => [], 'for' );
value   ( perl_version_introduced => [], '5.009005' );

tokenize( '/(?P<fur>bar)/' );
count   ( 10 );
choose  ( 3 );
value   ( name => [], 'fur' );
value   ( perl_version_introduced => [], '5.009005' );

tokenize( '/(*PRUNE:foo)x/' );
count   ( 6 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Backtrack' );
content ( '(*PRUNE:foo)' );
value   ( perl_version_introduced => [], '5.009005' );

tokenize( 's/\\bfoo\\Kbar/baz/' );
count   ( 16 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Assertion' );
content ( '\\b' );
value   ( perl_version_introduced => [], MINIMUM_PERL );
choose  ( 6 );
klass   ( 'PPIx::Regexp::Token::Assertion' );
content ( '\\K' );
value   ( perl_version_introduced => [], '5.009005' );

tokenize( '/(*PRUNE:foo)x/' );
count   ( 6 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Backtrack' );
content ( '(*PRUNE:foo)' );
value   ( perl_version_introduced => [], '5.009005' );

tokenize( '/(?|(foo))/' );
count   ( 12 );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::GroupType::BranchReset' );
content ( '?|' );
value   ( perl_version_introduced => [], '5.009005' );

parse   ( '/[a-z]/' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( regular_expression => [] );
true    ( interpolates => [] );
choose  ( find_first => 'PPIx::Regexp::Structure::CharClass' );
klass   ( 'PPIx::Regexp::Structure::CharClass' );
false   ( negated => [] );

parse   ( 'm\'[^a-z]\'' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( regular_expression => [] );
false   ( interpolates => [] );
choose  ( find_first => 'PPIx::Regexp::Structure::CharClass' );
klass   ( 'PPIx::Regexp::Structure::CharClass' );
true    ( negated => [] );

parse   ( '/(?|(?<baz>foo(wah))|(bar))(hoo)/' );
value   ( failures => [], 0 );
value   ( max_capture_number => [], 3 );
value   ( capture_names => [], [ 'baz' ] );
value   ( perl_version_introduced => [], '5.009005' );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::BranchReset' );
count   ( 3 );
choose  ( child => 1, child => 0, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(' );
choose  ( child => 1, child => 0, type => 0 );
klass   ( 'PPIx::Regexp::Token::GroupType::BranchReset' );
content ( '?|' );
choose  ( child => 1, child => 0, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ')' );
choose  ( child => 1, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Structure::NamedCapture' );
count   ( 4 );
value   ( number => [], 1 );
value   ( name => [], 'baz' );
choose  ( child => 1, child => 0, child => 0, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(' );
choose  ( child => 1, child => 0, child => 0, type => 0 );
klass   ( 'PPIx::Regexp::Token::GroupType::NamedCapture' );
content ( '?<baz>' );
choose  ( child => 1, child => 0, child => 0, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ')' );
choose  ( child => 1, child => 0, child => 0, child => 3 );
klass   ( 'PPIx::Regexp::Structure::Capture' );
count   ( 3 );
value   ( number => [], 2 );
choose  ( child => 1, child => 0, child => 0, child => 3, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(' );
choose  ( child => 1, child => 0, child => 0, child => 3, type => 0 );
klass   ( undef );
content ( undef );
choose  ( child => 1, child => 0, child => 0, child => 3, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ')' );
choose  ( child => 1, child => 0, child => 1 );
klass   ( 'PPIx::Regexp::Token::Operator' );
content ( '|' );
true    ( significant => [] );
true    ( can_be_quantified => [] );
false   ( is_quantifier => [] );
choose  ( child => 1, child => 0, child => 2 );
klass   ( 'PPIx::Regexp::Structure::Capture' );
count   ( 3 );
value   ( number => [], 1 );
choose  ( child => 1, child => 0, child => 2, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(' );
choose  ( child => 1, child => 0, child => 2, type => 0 );
klass   ( undef );
content ( undef );
choose  ( child => 1, child => 0, child => 2, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ')' );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Structure::Capture' );
count   ( 3 );
value   ( number => [], 3 );
choose  ( child => 1, child => 1, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(' );
choose  ( child => 1, child => 1, type => 0 );
klass   ( undef );
content ( undef );
choose  ( child => 1, child => 1, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ')' );

parse   ( 's/(foo)/${1}bar/g' );
klass   ( 'PPIx::Regexp' );
value   ( failures => [], 0 );
value   ( max_capture_number => [], 1 );
value   ( capture_names => [], [] );
value   ( perl_version_introduced => [], MINIMUM_PERL );
count   ( 4 );
choose  ( type => 0 );
content ( 's' );
choose  ( regular_expression => [] );
content ( '/(foo)/' );
choose  ( replacement => [] );
content ( '${1}bar/' );
choose  ( modifier => [] );
content ( 'g' );

tokenize( '/((((((((((x))))))))))\\10/' );
count   ( 26 );
choose  ( 23 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\10' );

parse   ( '/((((((((((x))))))))))\\10/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 2 );
choose  ( child => 1, start => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 1, type => 0 );
klass   ( undef );
content ( undef );
choose  ( child => 1, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\10' );

tokenize( '/(((((((((x)))))))))\\10/' );
count   ( 24 );
choose  ( 21 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\10' );

parse   ( '/(((((((((x)))))))))\\10/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 2 );
choose  ( child => 1, start => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 1, type => 0 );
klass   ( undef );
content ( undef );
choose  ( child => 1, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( '\\10' );

parse   ( '/(x)\\1/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 2 );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\1' );
value   ( absolute => [], 1 );
false   ( is_named => [] );
value   ( name => [], undef );
value   ( number => [], 1 );

parse   ( '/(x)\\g1/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 2 );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\g1' );
value   ( absolute => [], 1 );
false   ( is_named => [] );
value   ( name => [], undef );
value   ( number => [], 1 );

parse   ( '/(x)\\g-1/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 2 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::Capture' );
count   ( 1 );
choose  ( child => 1, child => 0, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(' );
choose  ( child => 1, child => 0, type => 0 );
klass   ( undef );
content ( undef );
choose  ( child => 1, child => 0, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ')' );
choose  ( child => 1, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'x' );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\g-1' );
value   ( absolute => [], 1 );
false   ( is_named => [] );
value   ( name => [], undef );
value   ( number => [], -1 );

parse   ( '/(x)\\g{1}/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 2 );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\g{1}' );
value   ( absolute => [], 1 );
false   ( is_named => [] );
value   ( name => [], undef );
value   ( number => [], 1 );

parse   ( '/(x)\\g{-1}/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 2 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::Capture' );
count   ( 1 );
choose  ( child => 1, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'x' );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\g{-1}' );
value   ( absolute => [], 1 );
false   ( is_named => [] );
value   ( name => [], undef );
value   ( number => [], -1 );

parse   ( '/(?<foo>\d+)\\g{foo}/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 2 );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\g{foo}' );
value   ( absolute => [], undef );
true    ( is_named => [] );
value   ( name => [], 'foo' );
value   ( number => [], undef );

parse   ( '/(?<foo>)\\k<foo>/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 2 );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\k<foo>' );
value   ( absolute => [], undef );
true    ( is_named => [] );
value   ( name => [], 'foo' );
value   ( number => [], undef );

parse   ( '/(?<foo>\d+)\\k\'foo\'/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 2 );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '\\k\'foo\'' );
value   ( absolute => [], undef );
true    ( is_named => [] );
value   ( name => [], 'foo' );
value   ( number => [], undef );

parse   ( '/(?<foo>\d+)(?P=foo)/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 2 );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Backreference' );
content ( '(?P=foo)' );
value   ( absolute => [], undef );
true    ( is_named => [] );
value   ( name => [], 'foo' );
value   ( number => [], undef );

parse   ( '/(?1)/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 1 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Token::Recursion' );
content ( '(?1)' );
value   ( absolute => [], 1 );
false   ( is_named => [] );
value   ( name => [], undef );
value   ( number => [], 1 );

parse   ( '/(x)(?-1)/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 2 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::Capture' );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Recursion' );
content ( '(?-1)' );
value   ( absolute => [], 1 );
false   ( is_named => [] );
value   ( name => [], undef );
value   ( number => [], -1 );

parse   ( '/(x)(?+1)(y)/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 3 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::Capture' );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Recursion' );
content ( '(?+1)' );
value   ( absolute => [], 2 );
false   ( is_named => [] );
value   ( name => [], undef );
value   ( number => [], '+1' );
choose  ( child => 1, child => 2 );
klass   ( 'PPIx::Regexp::Structure::Capture' );

parse   ( '/(?R)/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 1 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Token::Recursion' );
content ( '(?R)' );
value   ( absolute => [], 0 );
false   ( is_named => [] );
value   ( name => [], undef );
value   ( number => [], 0 );

parse   ( '/(?&foo)/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 1 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Token::Recursion' );
content ( '(?&foo)' );
value   ( absolute => [], undef );
true    ( is_named => [] );
value   ( name => [], 'foo' );
value   ( number => [], undef );

parse   ( '/(?P>foo)/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 1 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Token::Recursion' );
content ( '(?P>foo)' );
value   ( absolute => [], undef );
true    ( is_named => [] );
value   ( name => [], 'foo' );
value   ( number => [], undef );

parse   ( '/(?(1)foo)/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 1 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::Switch' );
count   ( 4 );
value   ( perl_version_introduced => [], '5.005' );
choose  ( child => 1, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Token::Condition' );
content ( '(1)' );
value   ( absolute => [], 1 );
false   ( is_named => [] );
value   ( name => [], undef );
value   ( number => [], 1 );

parse   ( '/(?(R1)foo)/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 1 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::Switch' );
count   ( 4 );
value   ( perl_version_introduced => [], '5.009005' );
choose  ( child => 1, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Token::Condition' );
content ( '(R1)' );
value   ( absolute => [], 1 );
false   ( is_named => [] );
value   ( name => [], undef );
value   ( number => [], 1 );

parse   ( '/(?(<bar>)foo)/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 1 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::Switch' );
count   ( 4 );
value   ( perl_version_introduced => [], '5.009005' );
choose  ( child => 1, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Token::Condition' );
content ( '(<bar>)' );
value   ( absolute => [], undef );
true    ( is_named => [] );
value   ( name => [], 'bar' );
value   ( number => [], undef );

parse   ( '/(?(\'bar\')foo)/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 1 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::Switch' );
count   ( 4 );
value   ( perl_version_introduced => [], '5.009005' );
choose  ( child => 1, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Token::Condition' );
content ( '(\'bar\')' );
value   ( absolute => [], undef );
true    ( is_named => [] );
value   ( name => [], 'bar' );
value   ( number => [], undef );

parse   ( '/(?(R&bar)foo)/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 1 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::Switch' );
count   ( 4 );
value   ( perl_version_introduced => [], '5.009005' );
choose  ( child => 1, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Token::Condition' );
content ( '(R&bar)' );
value   ( absolute => [], undef );
true    ( is_named => [] );
value   ( name => [], 'bar' );
value   ( number => [], undef );

parse   ( '/(?(DEFINE)foo)/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 1 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::Switch' );
count   ( 4 );
value   ( perl_version_introduced => [], '5.009005' );
choose  ( child => 1, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Token::Condition' );
content ( '(DEFINE)' );
value   ( absolute => [], 0 );
false   ( is_named => [] );
value   ( name => [], undef );
value   ( number => [], 0 );

tokenize( '/(?p{ code })/' );
count   ( 8 );
choose  ( 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
value   ( perl_version_removed => [], undef );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::GroupType::Code' );
content ( '?p' );
value   ( perl_version_removed => [], '5.009005' );

parse   ( '/(?p{ code })/' );
value   ( failures => [], 0);
klass   ( 'PPIx::Regexp' );
value   ( perl_version_removed => [], '5.009005' );
count   ( 3 );
choose  ( child => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
value   ( perl_version_removed => [], undef );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 1 );
value   ( perl_version_removed => [], '5.009005' );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::Code' );
count   ( 1 );
value   ( perl_version_removed => [], '5.009005' );
choose  ( child => 1, child => 0, start => [] );
count   ( 1 );
choose  ( child => 1, child => 0, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(' );
value   ( perl_version_removed => [], undef );
choose  ( child => 1, child => 0, type => [] );
count   ( 1 );
choose  ( child => 1, child => 0, type => 0 );
klass   ( 'PPIx::Regexp::Token::GroupType::Code' );
content ( '?p' );
value   ( perl_version_removed => [], '5.009005' );

parse   ( 'qr{foo}smx' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
choose  ( regular_expression => [] );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
value   ( delimiters => [], '{}' );
choose  ( top => [] );
klass   ( 'PPIx::Regexp' );
value   ( delimiters => [], '{}' );
value   ( delimiters => 1, undef );

parse   ( 's<foo>[bar]smx' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
choose  ( regular_expression => [] );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
value   ( delimiters => [], '<>' );
choose  ( top => [], replacement => [] );
klass   ( 'PPIx::Regexp::Structure::Replacement' );
value   ( delimiters => [], '[]' );
choose  ( top => [] );
klass   ( 'PPIx::Regexp' );
value   ( delimiters => 0, '<>' );
value   ( delimiters => 1, '[]' );

parse   ( 's/foo/bar/smx' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
value   ( delimiters => 0, '//' );
value   ( delimiters => 1, '//' );

tokenize( '/foo/', encoding => 'utf8' );
value   ( failures => [], 0 );
count   ( 7 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'f' );

tokenize( 'm/\\N\\n/' );
count   ( 6 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::CharClass::Simple' );
content ( '\\N' );
value   ( perl_version_introduced => [], '5.011' );
value   ( perl_version_removed => [], undef );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( '\\n' );
value   ( perl_version_introduced => [], MINIMUM_PERL );
value   ( perl_version_removed => [], undef );

tokenize( '/\\p{ Match = lo-ose }/' );
count   ( 5 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::CharClass::Simple' );
content ( '\\p{ Match = lo-ose }' );
value   ( perl_version_introduced => [], '5.006001' );
value   ( perl_version_removed => [], undef );

tokenize( '/\\pL/' );
count   ( 5 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::CharClass::Simple' );
content ( '\\pL' );
value   ( perl_version_introduced => [], '5.006001' );
value   ( perl_version_removed => [], undef );

parse   ( 'm{)}smx' );
value   ( failures => [], 1 );
klass   ( 'PPIx::Regexp' );
value   ( delimiters => 0, '{}' );

parse   ( 's/(\\d+)/roman($1)/ge' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
count   ( 4 );
value   ( perl_version_introduced => [], '5.000' );
value   ( perl_version_removed => [], undef );
choose  ( child => 2, child => 0 );
klass   ( 'PPIx::Regexp::Token::Code' );
content ( 'roman($1)' );
value   ( perl_version_introduced => [], '5.000' );
value   ( perl_version_removed => [], undef );

tokenize( '/${foo}bar/' );
count   ( 8 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Interpolation' );
content ( '${foo}' );
ppi     ( '$foo' );

{
    parse   ( 's/x/$1/e' );
    choose  ( child => 2, child => 0 );
    klass   ( 'PPIx::Regexp::Token::Code' );
    content ( '$1' );
    value   ( ppi => [], PPI::Document->new( \'$1' ) );
    my $doc1 = result();
    value   ( ppi => [], PPI::Document->new( \'$1' ) );
    my $doc2 = result();
    cmp_ok( refaddr( $doc1 ), '==', refaddr( $doc2 ),
	'Ensure we get back the same object from both calls to ppi()' );
}

##tokenize( '/[[:lower:]]/' );
##count   ( 7 );
##choose  ( 3 );
##klass   ( 'PPIx::Regexp::Token::CharClass::POSIX' );
##content ( '[:lower:]' );
##true    ( significant => [] );
##true    ( can_be_quantified => [] );
##false   ( is_quantifier => [] );
##true    ( is_case_sensitive => [] );
##
##parse   ( '/[[:lower:]]/' );
##value   ( failures => [], 0 );
##klass   ( 'PPIx::Regexp' );
##count   ( 3 );
##choose  ( child => 1 );
##klass   ( 'PPIx::Regexp::Structure::Regexp' );
##count   ( 1 );
##choose  ( child => 1, child => 0 );
##klass   ( 'PPIx::Regexp::Structure::CharClass' );
##count   ( 1 );
##choose  ( child => 1, child => 0, child => 0 );
##klass   ( 'PPIx::Regexp::Token::CharClass::POSIX' );
##content ( '[:lower:]' );
##true    ( significant => [] );
##true    ( can_be_quantified => [] );
##false   ( is_quantifier => [] );
##true    ( is_case_sensitive => [] );
##
##tokenize( '/[[:alpha:]]/' );
##count   ( 7 );
##choose  ( 3 );
##klass   ( 'PPIx::Regexp::Token::CharClass::POSIX' );
##content ( '[:alpha:]' );
##true    ( significant => [] );
##true    ( can_be_quantified => [] );
##false   ( is_quantifier => [] );
##false   ( is_case_sensitive => [] );
##
##parse   ( '/[[:alpha:]]/' );
##value   ( failures => [], 0 );
##klass   ( 'PPIx::Regexp' );
##count   ( 3 );
##choose  ( child => 1 );
##klass   ( 'PPIx::Regexp::Structure::Regexp' );
##count   ( 1 );
##choose  ( child => 1, child => 0 );
##klass   ( 'PPIx::Regexp::Structure::CharClass' );
##count   ( 1 );
##choose  ( child => 1, child => 0, child => 0 );
##klass   ( 'PPIx::Regexp::Token::CharClass::POSIX' );
##content ( '[:alpha:]' );
##true    ( significant => [] );
##true    ( can_be_quantified => [] );
##false   ( is_quantifier => [] );
##false   ( is_case_sensitive => [] );
##
##tokenize( '/\\p{Lower}/' );
##count   ( 5 );
##choose  ( 2 );
##klass   ( 'PPIx::Regexp::Token::CharClass::Simple' );
##content ( '\\p{Lower}' );
##true    ( significant => [] );
##true    ( can_be_quantified => [] );
##false   ( is_quantifier => [] );
##true    ( is_case_sensitive => [] );
##
##parse   ( '/\\p{Lower}/' );
##value   ( failures => [], 0 );
##klass   ( 'PPIx::Regexp' );
##count   ( 3 );
##choose  ( child => 1 );
##klass   ( 'PPIx::Regexp::Structure::Regexp' );
##count   ( 1 );
##choose  ( child => 1, child => 0 );
##klass   ( 'PPIx::Regexp::Token::CharClass::Simple' );
##content ( '\\p{Lower}' );
##true    ( significant => [] );
##true    ( can_be_quantified => [] );
##false   ( is_quantifier => [] );
##true    ( is_case_sensitive => [] );
##
##tokenize( '/\\p{Alpha}/' );
##count   ( 5 );
##choose  ( 2 );
##klass   ( 'PPIx::Regexp::Token::CharClass::Simple' );
##content ( '\\p{Alpha}' );
##true    ( significant => [] );
##true    ( can_be_quantified => [] );
##false   ( is_quantifier => [] );
##false   ( is_case_sensitive => [] );
##
##parse   ( '/\\p{Alpha}/' );
##value   ( failures => [], 0 );
##klass   ( 'PPIx::Regexp' );
##count   ( 3 );
##choose  ( child => 1 );
##klass   ( 'PPIx::Regexp::Structure::Regexp' );
##count   ( 1 );
##choose  ( child => 1, start => [] );
##count   ( 1 );
##choose  ( child => 1, child => 0 );
##klass   ( 'PPIx::Regexp::Token::CharClass::Simple' );
##content ( '\\p{Alpha}' );
##true    ( significant => [] );
##true    ( can_be_quantified => [] );
##false   ( is_quantifier => [] );
##false   ( is_case_sensitive => [] );

parse   ( '/ . /' );
false   ( modifier_asserted => 'u' );
false   ( modifier_asserted => 'x' );

parse   ( '/ . /', default_modifiers => [ 'smxu' ] );
true    ( modifier_asserted => 'u' );
false   ( modifier_asserted => 'l' );
true    ( modifier_asserted => 'x' );

parse   ( '/ . /', default_modifiers => [ 'smxu', '-u' ] );
false   ( modifier_asserted => 'u' );
false   ( modifier_asserted => 'l' );
true    ( modifier_asserted => 'x' );

# This to be sure we recognize 'aa' when consecutive.

parse   ( '/ . /aasmx' );
value   ( failures => [], 0 );
true    ( modifier_asserted => 'aa' );
false   ( modifier_asserted => 'a' );

# Bug reported by Anonymous Monk. /aia is equivalent to /aai

parse   ( '/ . /asmxa' );
value   ( failures => [], 0 );
true    ( modifier_asserted => 'aa' );
false   ( modifier_asserted => 'a' );

# Wishlist by Anonymous Monk to know what modifiers were asserted where.

parse	( '/foo/i' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose	( child => 1 );
klass	( 'PPIx::Regexp::Structure::Regexp' );
count	( 3 );
choose	( child => 1, child => 0 );
klass	( 'PPIx::Regexp::Token::Literal' );
content	( 'f' );
true	( modifier_asserted => 'i' );

parse	( '/(?i)foo/' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose	( child => 1 );
klass	( 'PPIx::Regexp::Structure::Regexp' );
count	( 4 );
choose	( child => 1, child => 1 );
klass	( 'PPIx::Regexp::Token::Literal' );
content	( 'f' );
true	( modifier_asserted => 'i' );

parse	( '/(?i:foo)/' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose	( child => 1 );
klass	( 'PPIx::Regexp::Structure::Regexp' );
count	( 1 );
choose	( child => 1, child => 0 );
klass	( 'PPIx::Regexp::Structure::Modifier' );
count	( 3 );
choose	( child => 1, child => 0, child => 0 );
klass	( 'PPIx::Regexp::Token::Literal' );
content	( 'f' );
true	( modifier_asserted => 'i' );

parse	( '/foo/', default_modifiers => [ 'i' ] );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose	( child => 1 );
klass	( 'PPIx::Regexp::Structure::Regexp' );
count	( 3 );
choose	( child => 1, child => 0 );
klass	( 'PPIx::Regexp::Token::Literal' );
content	( 'f' );
true	( modifier_asserted => 'i' );

parse	( '/(?-i:foo)/i' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose	( child => 1 );
klass	( 'PPIx::Regexp::Structure::Regexp' );
count	( 1 );
choose	( child => 1, child => 0 );
klass	( 'PPIx::Regexp::Structure::Modifier' );
count	( 3 );
choose	( child => 1, child => 0, child => 0 );
klass	( 'PPIx::Regexp::Token::Literal' );
content	( 'f' );
false	( modifier_asserted => 'i' );


# End of wishlist by Anonymous Monk to know what modifiers were asserted where.

# Handle leading and trailing white space

parse   ( ' /foo/ ' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
count   ( 5 );
value   ( delimiters => [], '//' );		# The purpose of these
choose  ( modifier => [] );			# tests is to ensure
klass   ( 'PPIx::Regexp::Token::Modifier' );	# that the significant
value   ( content => [], '' );			# parts of the regexp
choose  ( regular_expression => [] );		# can still be found if
klass   ( 'PPIx::Regexp::Structure::Regexp' );	# we introduce leading
choose  ( type => 0 );				# and trailing white
klass   ( 'PPIx::Regexp::Token::Structure' );	# space
value   ( content => [], '' );			# ...
choose  ( child => 0 );
klass   ( 'PPIx::Regexp::Token::Whitespace' );
content ( ' ' );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
choose  ( child => 2 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 3 );
choose  ( child => 2, start => [] );
count   ( 1 );
choose  ( child => 2, start => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 2, type => [] );
count   ( 0 );
choose  ( child => 2, finish => [] );
count   ( 1 );
choose  ( child => 2, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 2, child => 0 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'f' );
choose  ( child => 2, child => 1 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'o' );
choose  ( child => 2, child => 2 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'o' );
choose  ( child => 3 );
klass   ( 'PPIx::Regexp::Token::Modifier' );
content ( '' );
choose  ( child => 4 );
klass   ( 'PPIx::Regexp::Token::Whitespace' );
content ( ' ' );

# RT #82140: incorrect parsing of (\?|...) - Alexandr Ciornii

tokenize( '/(\\?|I)/' );
value   ( failures => [], 0 );
count   ( 9 );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( '\\?' );

tokenize( '?(\\?|I)?' );
value   ( failures => [], 0 );
count   ( 8 );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::GroupType::BranchReset' );
content ( '\\?|' );

# RT #82140: incorrect parsing of (\?>...) - Alexandr Ciornii

tokenize( '/(\\?>I)/' );
value   ( failures => [], 0 );
count   ( 9 );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( '\\?' );

tokenize( '?(\\?>I)?' );
value   ( failures => [], 0 );
count   ( 8 );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::GroupType::Subexpression' );
content ( '\\?>' );

# RT #82140: incorrect parsing of (\?:...) - Alexandr Ciornii

tokenize( '/(\\?:I)/' );
value   ( failures => [], 0 );
count   ( 9 );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( '\\?' );

tokenize( '?(\\?:I)?' );
value   ( failures => [], 0 );
count   ( 8 );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::GroupType::Modifier' );
content ( '\\?:' );

# RT 91798: non-breaking space should not be whitespace - Nobuo Kumagai

tokenize( "/\240/x" );
value   ( failures => [], 0 );
count   ( 5 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( "\240" );

note '/ee should parse like /e';
tokenize( 's/foo/bar(42)/ee' );
count   ( 9 );
choose  ( 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( 's' );
choose  ( 1 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'f' );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'o' );
choose  ( 4 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'o' );
choose  ( 5 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( 6 );
klass   ( 'PPIx::Regexp::Token::Code' );
content ( 'bar(42)' );
choose  ( 7 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( 8 );
klass   ( 'PPIx::Regexp::Token::Modifier' );
content ( 'ee' );

# RT 107331 - Bogus trailing characters should cause error - Klaus Rindfrey

parse   ( '/foo/|' );
value   ( failures => [], 1 );
klass   ( 'PPIx::Regexp' );
count   ( 4 );
choose  ( child => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 3 );
choose  ( child => 1, start => [] );
count   ( 1 );
choose  ( child => 1, start => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 1, type => [] );
count   ( 0 );
choose  ( child => 1, finish => [] );
count   ( 1 );
choose  ( child => 1, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'f' );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'o' );
choose  ( child => 1, child => 2 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'o' );
choose  ( child => 2 );
klass   ( 'PPIx::Regexp::Token::Modifier' );
content ( '' );
choose  ( child => 3 );
klass   ( 'PPIx::Regexp::Token::Unknown' );
content ( '|' );
error   ( 'Trailing characters after expression' );
choose  ( 'modifier' => [] );
klass   ( 'PPIx::Regexp::Token::Modifier' );
content ( '' );

# As of Perl 5.23.4, only space and horizontal tab can be parsed as
# whitespace inside a bracketed character klass inside an extended
# bracketed character klass.
tokenize( "/(?[ [\f] ])/" );
count   ( 11 );
choose  ( 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
choose  ( 1 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(?[' );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::Whitespace' );
content ( ' ' );
choose  ( 4 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '[' );
choose  ( 5 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( "\f" );
choose  ( 6 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ']' );
choose  ( 7 );
klass   ( 'PPIx::Regexp::Token::Whitespace' );
content ( ' ' );
choose  ( 8 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '])' );
choose  ( 9 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( 10 );
klass   ( 'PPIx::Regexp::Token::Modifier' );
content ( '' );

# Ensure that the error gets cleared when a PPIx::Regexp::Token::Unknown
# gets reblessed into something useful.

parse   ( '/{?+}/' );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Quantifier' );
content ( '?' );
error   ( undef );
choose  ( child => 1, child => 2 );
klass   ( 'PPIx::Regexp::Token::Greediness' );
content ( '+' );
error   ( undef );

# \U and friends are still metacharacters inside \Q

tokenize( '/\\Q\\Ux\\Ey/' );
count   ( 9 );
choose  ( 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
choose  ( 1 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Control' );
content ( '\\Q' );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::Control' );
content ( '\\U' );
choose  ( 4 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'x' );
choose  ( 5 );
klass   ( 'PPIx::Regexp::Token::Control' );
content ( '\\E' );
choose  ( 6 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'y' );
choose  ( 7 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( 8 );
klass   ( 'PPIx::Regexp::Token::Modifier' );
content ( '' );

# Need to report an error if the switch condition can not be deciphered.

parse   ( '/(?([w]))/' );
value   ( failures => [], 1 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 1 );
choose  ( child => 1, start => [] );
count   ( 1 );
choose  ( child => 1, start => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 1, type => [] );
count   ( 0 );
choose  ( child => 1, finish => [] );
count   ( 1 );
choose  ( child => 1, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::Unknown' );
count   ( 1 );
choose  ( child => 1, child => 0, start => [] );
count   ( 1 );
choose  ( child => 1, child => 0, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(' );
choose  ( child => 1, child => 0, type => [] );
count   ( 1 );
choose  ( child => 1, child => 0, type => 0 );
klass   ( 'PPIx::Regexp::Token::GroupType::Switch' );
content ( '?' );
choose  ( child => 1, child => 0, finish => [] );
count   ( 1 );
choose  ( child => 1, child => 0, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ')' );
choose  ( child => 1, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Structure::Capture' );
count   ( 1 );
choose  ( child => 1, child => 0, child => 0, start => [] );
count   ( 1 );
choose  ( child => 1, child => 0, child => 0, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(' );
choose  ( child => 1, child => 0, child => 0, type => [] );
count   ( 0 );
choose  ( child => 1, child => 0, child => 0, finish => [] );
count   ( 1 );
choose  ( child => 1, child => 0, child => 0, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ')' );
choose  ( child => 1, child => 0, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Structure::CharClass' );
count   ( 1 );
choose  ( child => 1, child => 0, child => 0, child => 0, start => [] );
count   ( 1 );
choose  ( child => 1, child => 0, child => 0, child => 0, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '[' );
choose  ( child => 1, child => 0, child => 0, child => 0, type => [] );
count   ( 0 );
choose  ( child => 1, child => 0, child => 0, child => 0, finish => [] );
count   ( 1 );
choose  ( child => 1, child => 0, child => 0, child => 0, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ']' );
choose  ( child => 1, child => 0, child => 0, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'w' );
choose  ( child => 2 );
klass   ( 'PPIx::Regexp::Token::Modifier' );
content ( '' );

# Make sure we do not prematurely end an extended bracketed character
# class if we encounter a bracketed character class followed immediately
# by the end of a parenthesized group (e.g. in '(?[([x])])' the extended
# class should end at the end of the string).

parse   ( '/(?[(\\w-[[:lower:]])|\\p{Greek}])|[^a-z]/' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 3 );
choose  ( child => 1, start => [] );
count   ( 1 );
choose  ( child => 1, start => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 1, type => [] );
count   ( 0 );
choose  ( child => 1, finish => [] );
count   ( 1 );
choose  ( child => 1, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::RegexSet' );
count   ( 3 );
choose  ( child => 1, child => 0, start => [] );
count   ( 1 );
choose  ( child => 1, child => 0, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(?[' );
choose  ( child => 1, child => 0, type => [] );
count   ( 0 );
choose  ( child => 1, child => 0, finish => [] );
count   ( 1 );
choose  ( child => 1, child => 0, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '])' );
choose  ( child => 1, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Structure' );
count   ( 3 );
choose  ( child => 1, child => 0, child => 0, start => [] );
count   ( 1 );
choose  ( child => 1, child => 0, child => 0, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(' );
choose  ( child => 1, child => 0, child => 0, type => [] );
count   ( 0 );
choose  ( child => 1, child => 0, child => 0, finish => [] );
count   ( 1 );
choose  ( child => 1, child => 0, child => 0, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ')' );
choose  ( child => 1, child => 0, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Token::CharClass::Simple' );
content ( '\\w' );
choose  ( child => 1, child => 0, child => 0, child => 1 );
klass   ( 'PPIx::Regexp::Token::Operator' );
content ( '-' );
choose  ( child => 1, child => 0, child => 0, child => 2 );
klass   ( 'PPIx::Regexp::Structure::CharClass' );
count   ( 1 );
choose  ( child => 1, child => 0, child => 0, child => 2, start => [] );
count   ( 1 );
choose  ( child => 1, child => 0, child => 0, child => 2, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '[' );
choose  ( child => 1, child => 0, child => 0, child => 2, type => [] );
count   ( 0 );
choose  ( child => 1, child => 0, child => 0, child => 2, finish => [] );
count   ( 1 );
choose  ( child => 1, child => 0, child => 0, child => 2, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ']' );
choose  ( child => 1, child => 0, child => 0, child => 2, child => 0 );
klass   ( 'PPIx::Regexp::Token::CharClass::POSIX' );
content ( '[:lower:]' );
choose  ( child => 1, child => 0, child => 1 );
klass   ( 'PPIx::Regexp::Token::Operator' );
content ( '|' );
choose  ( child => 1, child => 0, child => 2 );
klass   ( 'PPIx::Regexp::Token::CharClass::Simple' );
content ( '\\p{Greek}' );
choose  ( child => 1, child => 1 );
klass   ( 'PPIx::Regexp::Token::Operator' );
content ( '|' );
choose  ( child => 1, child => 2 );
klass   ( 'PPIx::Regexp::Structure::CharClass' );
count   ( 1 );
choose  ( child => 1, child => 2, start => [] );
count   ( 1 );
choose  ( child => 1, child => 2, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '[' );
choose  ( child => 1, child => 2, type => [] );
count   ( 1 );
choose  ( child => 1, child => 2, type => 0 );
klass   ( 'PPIx::Regexp::Token::Operator' );
content ( '^' );
choose  ( child => 1, child => 2, finish => [] );
count   ( 1 );
choose  ( child => 1, child => 2, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ']' );
choose  ( child => 1, child => 2, child => 0 );
klass   ( 'PPIx::Regexp::Node::Range' );
count   ( 3 );
choose  ( child => 1, child => 2, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'a' );
choose  ( child => 1, child => 2, child => 0, child => 1 );
klass   ( 'PPIx::Regexp::Token::Operator' );
content ( '-' );
choose  ( child => 1, child => 2, child => 0, child => 2 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'z' );
choose  ( child => 2 );
klass   ( 'PPIx::Regexp::Token::Modifier' );
content ( '' );

# Make sure we record the correct number of captures in the presence of
# the /n qualifier.
note	'Correct number of captures in presence of /n qualifier';
parse   ( '/(foo)/n' );
value   ( max_capture_number => [], 0 );
parse   ( '/(?<foo>foo)/n' );
value   ( max_capture_number => [], 1 );

# ?foo? without a specific type has been removed as of 5.21.1. These
# would be in t/version.t except that the limit is not on a single
# token but on the combination of empty type and question mark
# delimiters.
note    '?foo? without explicit type is removed in 5.21.1';
parse   ( '?foo?' );
value   ( perl_version_removed => [], 5.021001 );
parse   ( 'm?foo?' );
value   ( perl_version_removed => [], undef );

# postderef
note	'postderef was added experimentally in 5.19.5';
tokenize( '/$x->$*foo/' );
count   ( 8 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Interpolation' );
content ( '$x->$*' );
tokenize( '/$x->$#*foo/' );
count   ( 8 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Interpolation' );
content ( '$x->$#*' );
tokenize( '/$x->@*foo/' );
count   ( 8 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Interpolation' );
content ( '$x->@*' );
tokenize( '/$x->@[1,2]/' );
count   ( 5 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Interpolation' );
content ( '$x->@[1,2]' );
tokenize( 's/x/$x->%{foo,bar}/e' );
count   ( 7 );
choose  ( 4 );
klass   ( 'PPIx::Regexp::Token::Code' );
content ( '$x->%{foo,bar}' );

# \x{}
note	'/\\x{}/ generates a NUL by default';
parse   ( '/\\x{}/' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( '\\x{}' );
value   ( ordinal => [], 0 );

note	q</\x{}/ is an error if "use re 'strict'" is in effect>;
parse   ( '/\\x{}/', strict => 1 );
value   ( failures => [], 1 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Token::Unknown' );
content ( '\\x{}' );
error   ( 'Empty \\x{} is an error under "use re \'strict\'"' );


# \o{}
note	'/\\o{}/ is an error';
parse   ( '/\\o{}/' );
value   ( failures => [], 1 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Token::Unknown' );
content ( '\\o{}' );
error   ( 'Empty \\o{} is an error' );

note	'/\\o{ }/ is not normally an error';
parse   ( '/\\o{ }/' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( '\\o{ }' );
value   ( ordinal => [], 0 );

note	q</\\o{ }/ is an error if "use re 'strict'" is in effect>;
parse   ( '/\\o{ }/', strict => 1 );
value   ( failures => [], 1 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Token::Unknown' );
content ( '\\o{ }' );
error   ( 'Non-octal character in \\o{...}' );



# \p{}

note	q</\\p{ }/ is an error>;
parse   ( '/\\p{ }/' );
value   ( failures => [], 1 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Token::Unknown' );
content ( '\\p{ }' );
error   ( 'Empty \\p{} is an error' );



note	'Make sure \Q stacks with \U, \L and \F';
tokenize( '/\\Qx\\Uy\\E\\w\\E/' );
count   ( 11 );
choose  ( 7 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( '\\w' );

note	'use re qw{ strict }';

tokenize( '/\\N{}/', strict => 1 );
count   ( 5 );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Unknown' );
content ( '\\N{}' );
error   ( 'Empty Unicode character name' );
value   ( perl_version_introduced => [], '5.023008' );
value   ( perl_version_removed => [], '5.027001' );

parse   ( '/[A-z]/', strict => 1 );
value   ( failures => [], 1 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
value   ( perl_version_introduced => [], '5.023008' );
value   ( perl_version_removed => [], undef );
choose  ( child => 1, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Node::Unknown' );
count   ( 3 );
error   ( 'Non-portable range ends prohibited by "use re \'strict\'"' );
value   ( perl_version_introduced => [], '5.023008' );
value   ( perl_version_removed => [], undef );


note	'next_element(), previous_element()';

parse	( '/(x)/' );
choose  ( child => 1, child => 0, child => 0 );	# 'x'
navigate( previous_element => [] );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(' );
navigate( next_element	=> [] );
klass	( 'PPIx::Regexp::Token::Literal' );
content	( 'x' );


note	'snext_element(), sprevious_element()';

parse	( '/ ( x ) /x' );
choose  ( child => 1, child => 0, child => 0 );	# 'x'
navigate( sprevious_element => [] );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '(' );
navigate( snext_element	=> [] );
klass	( 'PPIx::Regexp::Token::Literal' );
content	( 'x' );


note	'accepts_perl(), requirements_for_perl()';

parse	( '/x/' );
value	( accepts_perl => [ '5.000' ], 1 );
value	( accepts_perl => [ '5.010001' ], 1 );
value	( requirements_for_perl => [], '5.000 <= $]' );

parse	( '/x/a' );
value	( accepts_perl => [ '5.000' ], 0 );
value	( accepts_perl => [ '5.010001' ], 0 );
value	( accepts_perl => [ '5.013010' ], 1 );
value	( accepts_perl => [ '5.014' ], 1 );
value	( requirements_for_perl => [], '5.013010 <= $]' );

parse	( '/x{/' );
value	( accepts_perl => [ '5.000' ], 1 );
value	( accepts_perl => [ '5.010001' ], 1 );
value	( accepts_perl => [ '5.025000' ], 1 );
value	( accepts_perl => [ '5.025001' ], 0 );
value	( accepts_perl => [ '5.027000' ], 0 );
value	( accepts_perl => [ '5.027001' ], 1 );
value	( requirements_for_perl => [],
    '5.000 <= $] < 5.025001 || 5.027001 <= $]' );

{
    my $re = '/ [f g] o o b a (?#comment) r /';
    parse	( $re );
    value	( scontent => [], '/ [f g] o o b a  r /' );

    parse	( $re, default_modifiers => [ qw{ x } ] );
    value	( scontent => [], '/[f g]oobar/' );

    parse	( $re, default_modifiers => [ qw{ xx } ] );
    value	( scontent => [], '/[fg]oobar/' );
}

{
    parse	( '/^(?i:foo)$/' );
    navigate	( 'first_token' );
    klass	( 'PPIx::Regexp::Token::Structure' );
    content	( '' );
    navigate	( 'next_token' );
    klass	( 'PPIx::Regexp::Token::Delimiter' );
    content	( '/' );
    navigate	( 'next_token' );
    klass	( 'PPIx::Regexp::Token::Assertion' );
    content	( '^' );
    navigate	( 'next_token' );
    klass	( 'PPIx::Regexp::Token::Structure' );
    content	( '(' );
    navigate	( 'next_token' );
    klass	( 'PPIx::Regexp::Token::GroupType::Modifier' );
    content	( '?i:' );
    navigate	( 'next_token' );
    klass	( 'PPIx::Regexp::Token::Literal' );
    content	( 'f' );
    navigate	( 'next_token' );
    klass	( 'PPIx::Regexp::Token::Literal' );
    content	( 'o' );
    navigate	( 'next_token' );
    klass	( 'PPIx::Regexp::Token::Literal' );
    content	( 'o' );
    navigate	( 'next_token' );
    klass	( 'PPIx::Regexp::Token::Structure' );
    content	( ')' );
    navigate	( 'next_token' );
    klass	( 'PPIx::Regexp::Token::Assertion' );
    content	( '$' );
    navigate	( 'next_token' );
    klass	( 'PPIx::Regexp::Token::Delimiter' );
    content	( '/' );
    navigate	( 'next_token' );
    klass	( 'PPIx::Regexp::Token::Modifier' );
    content	( '' );
    ok ! navigate( 'next_token' ), 'There is no next token';
}

{
    parse	( '/^(?i:foo)$/' );
    navigate	( 'last_token' );
    klass	( 'PPIx::Regexp::Token::Modifier' );
    content	( '' );
    navigate	( 'previous_token' );
    klass	( 'PPIx::Regexp::Token::Delimiter' );
    content	( '/' );
    navigate	( 'previous_token' );
    klass	( 'PPIx::Regexp::Token::Assertion' );
    content	( '$' );
    navigate	( 'previous_token' );
    klass	( 'PPIx::Regexp::Token::Structure' );
    content	( ')' );
    navigate	( 'previous_token' );
    klass	( 'PPIx::Regexp::Token::Literal' );
    content	( 'o' );
    navigate	( 'previous_token' );
    klass	( 'PPIx::Regexp::Token::Literal' );
    content	( 'o' );
    navigate	( 'previous_token' );
    klass	( 'PPIx::Regexp::Token::Literal' );
    content	( 'f' );
    navigate	( 'previous_token' );
    klass	( 'PPIx::Regexp::Token::GroupType::Modifier' );
    content	( '?i:' );
    navigate	( 'previous_token' );
    klass	( 'PPIx::Regexp::Token::Structure' );
    content	( '(' );
    navigate	( 'previous_token' );
    klass	( 'PPIx::Regexp::Token::Assertion' );
    content	( '^' );
    navigate	( 'previous_token' );
    klass	( 'PPIx::Regexp::Token::Delimiter' );
    content	( '/' );
    navigate	( 'previous_token' );
    klass	( 'PPIx::Regexp::Token::Structure' );
    content	( '' );
    ok ! navigate( 'previous_token' ), 'There is no next token';
}

SKIP: {
    $is_ascii
	or skip(
	'Non-ASCII machines will have different ordinal values',
	10,
    );

    note 'Ordinals';

    tokenize( '/foo/', '--notokens' );
    dump_result( ordinal => 1, tokens => 1,
	<<'EOD', q<Tokenization of '/foo/'> );
PPIx::Regexp::Token::Structure	''
PPIx::Regexp::Token::Delimiter	'/'
PPIx::Regexp::Token::Literal	'f'	0x66
PPIx::Regexp::Token::Literal	'o'	0x6f
PPIx::Regexp::Token::Literal	'o'	0x6f
PPIx::Regexp::Token::Delimiter	'/'
PPIx::Regexp::Token::Modifier	''
EOD

    parse   ( '/(foo[a-z\\d])/x' );
    dump_result( verbose => 1,
	<<'EOD', q<Verbose parse of '/(foo[a-z\\d])/x'> );
PPIx::Regexp	failures=0	max_capture_number=1
  PPIx::Regexp::Token::Structure	''	significant	is_matcher=false
  PPIx::Regexp::Structure::Regexp	/ ... /	max_capture_number=1	is_matcher=true
    PPIx::Regexp::Structure::Capture	( ... )	number=1	name=undef	can_be_quantified	is_matcher=true
      PPIx::Regexp::Token::Literal	'f'	0x66	significant	can_be_quantified	is_matcher=true
      PPIx::Regexp::Token::Literal	'o'	0x6f	significant	can_be_quantified	is_matcher=true
      PPIx::Regexp::Token::Literal	'o'	0x6f	significant	can_be_quantified	is_matcher=true
      PPIx::Regexp::Structure::CharClass	[ ... ]	can_be_quantified	is_matcher=true
        PPIx::Regexp::Node::Range
          PPIx::Regexp::Token::Literal	'a'	0x61	significant	can_be_quantified	is_matcher=true
          PPIx::Regexp::Token::Operator	'-'	significant	can_be_quantified	is_matcher=false
          PPIx::Regexp::Token::Literal	'z'	0x7a	significant	can_be_quantified	is_matcher=true
        PPIx::Regexp::Token::CharClass::Simple	'\\d'	significant	can_be_quantified	is_matcher=true
  PPIx::Regexp::Token::Modifier	'x'	significant	x	is_matcher=false
EOD

    parse   ( '/(?<foo>\\d+)/' );
    dump_result( perl_version => 1,
	<<'EOD', q<Perl versions in '/(?<foo>\\d+)/'> );
PPIx::Regexp	failures=0	5.009005 <= $]
  PPIx::Regexp::Token::Structure	''	5.000 <= $]
  PPIx::Regexp::Structure::Regexp	/ ... /	5.009005 <= $]
    PPIx::Regexp::Structure::NamedCapture	(?<foo> ... )	5.009005 <= $]
      PPIx::Regexp::Token::CharClass::Simple	'\\d'	5.000 <= $]
      PPIx::Regexp::Token::Quantifier	'+'	5.000 <= $]
  PPIx::Regexp::Token::Modifier	''	5.000 <= $]
EOD

    tokenize( '/[a-z]/', '--notokens' );
    dump_result( test => 1, verbose => 1, tokens => 1,
	<<'EOD', q<Test tokenization of '/[a-z]/'> );
tokenize( '/[a-z]/' );
count   ( 9 );
choose  ( 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
true    ( significant => [] );
false   ( can_be_quantified => [] );
false   ( is_quantifier => [] );
choose  ( 1 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
true    ( significant => [] );
false   ( can_be_quantified => [] );
false   ( is_quantifier => [] );
choose  ( 2 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '[' );
true    ( significant => [] );
false   ( can_be_quantified => [] );
false   ( is_quantifier => [] );
choose  ( 3 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'a' );
true    ( significant => [] );
true    ( can_be_quantified => [] );
false   ( is_quantifier => [] );
choose  ( 4 );
klass   ( 'PPIx::Regexp::Token::Operator' );
content ( '-' );
true    ( significant => [] );
true    ( can_be_quantified => [] );
false   ( is_quantifier => [] );
choose  ( 5 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'z' );
true    ( significant => [] );
true    ( can_be_quantified => [] );
false   ( is_quantifier => [] );
choose  ( 6 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ']' );
true    ( significant => [] );
true    ( can_be_quantified => [] );
false   ( is_quantifier => [] );
choose  ( 7 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
true    ( significant => [] );
false   ( can_be_quantified => [] );
false   ( is_quantifier => [] );
choose  ( 8 );
klass   ( 'PPIx::Regexp::Token::Modifier' );
content ( '' );
true    ( significant => [] );
false   ( can_be_quantified => [] );
false   ( is_quantifier => [] );
EOD

    parse   ( '/[a-z]/' );
    dump_result( test => 1, verbose => 1,
	<<'EOD', q<Test of '/[a-z]/'> );
parse   ( '/[a-z]/' );
value   ( failures => [], 0 );
klass   ( 'PPIx::Regexp' );
count   ( 3 );
choose  ( child => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '' );
true    ( significant => [] );
false   ( can_be_quantified => [] );
false   ( is_quantifier => [] );
choose  ( child => 1 );
klass   ( 'PPIx::Regexp::Structure::Regexp' );
count   ( 1 );
choose  ( child => 1, start => [] );
count   ( 1 );
choose  ( child => 1, start => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 1, type => [] );
count   ( 0 );
choose  ( child => 1, finish => [] );
count   ( 1 );
choose  ( child => 1, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Delimiter' );
content ( '/' );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Structure::CharClass' );
count   ( 1 );
choose  ( child => 1, child => 0, start => [] );
count   ( 1 );
choose  ( child => 1, child => 0, start => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( '[' );
choose  ( child => 1, child => 0, type => [] );
count   ( 0 );
choose  ( child => 1, child => 0, finish => [] );
count   ( 1 );
choose  ( child => 1, child => 0, finish => 0 );
klass   ( 'PPIx::Regexp::Token::Structure' );
content ( ']' );
choose  ( child => 1, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Node::Range' );
count   ( 3 );
choose  ( child => 1, child => 0, child => 0, child => 0 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'a' );
true    ( significant => [] );
true    ( can_be_quantified => [] );
false   ( is_quantifier => [] );
choose  ( child => 1, child => 0, child => 0, child => 1 );
klass   ( 'PPIx::Regexp::Token::Operator' );
content ( '-' );
true    ( significant => [] );
true    ( can_be_quantified => [] );
false   ( is_quantifier => [] );
choose  ( child => 1, child => 0, child => 0, child => 2 );
klass   ( 'PPIx::Regexp::Token::Literal' );
content ( 'z' );
true    ( significant => [] );
true    ( can_be_quantified => [] );
false   ( is_quantifier => [] );
choose  ( child => 2 );
klass   ( 'PPIx::Regexp::Token::Modifier' );
content ( '' );
true    ( significant => [] );
false   ( can_be_quantified => [] );
false   ( is_quantifier => [] );
EOD

}

finis   ();

done_testing;

1;

# ex: set textwidth=72 :
