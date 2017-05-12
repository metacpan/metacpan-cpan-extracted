package main;

use 5.006;

use strict;
use warnings;

use PPIx::QuoteLike;
use PPIx::QuoteLike::Token::Control;
use PPIx::QuoteLike::Token::Interpolation;
use PPIx::QuoteLike::Token::String;
use Test::More 0.88;	# Because of done_testing();

my $tok;

$tok = PPIx::QuoteLike::Token::String->__new( content => 'foo' );
is $tok->perl_version_introduced(), '5.000',
    'String was introduced in 5.0';
is $tok->perl_version_removed(), undef, 'String is still here';

$tok = PPIx::QuoteLike::Token::Control->__new( content => '\U' );
is $tok->perl_version_introduced(), '5.000',
    '\\U was introduced in 5.0';
is $tok->perl_version_removed(), undef, '\\U is still here';

$tok = PPIx::QuoteLike::Token::Control->__new( content => '\F' );
is $tok->perl_version_introduced(), '5.015008',
    '\\F was introduced in 5.15.8';
is $tok->perl_version_removed(), undef, '\\F is still here';

$tok = PPIx::QuoteLike::Token::Interpolation->__new( content => '$x' );
is $tok->perl_version_introduced(), '5.000',
    'Interpolation was introduced in 5.0';
is $tok->perl_version_removed(), undef, 'Interpolation is still here';

$tok = PPIx::QuoteLike::Token::Interpolation->__new( content => '$x->@*' );
is $tok->perl_version_introduced(), '5.019005',
    'Postfix dereference was introduced in 5.19.5';
is $tok->perl_version_removed(), undef, 'Postfix dereference is still here';

my $obj;

$obj = PPIx::QuoteLike->new( '"foo$bar"' );
is $obj->perl_version_introduced(), '5.000',
    'Double-quoted string was introduced in 5.0';
is $obj->perl_version_removed(), undef, 'Double-quoted string is still here';

$obj = PPIx::QuoteLike->new( '"foo\\F$bar"' );
is $obj->perl_version_introduced(), '5.015008',
    'Case-folded string was introduced in 5.15.8';
is $obj->perl_version_removed(), undef, 'Case-folded string is still here';

done_testing;

1;

# ex: set textwidth=72 :
