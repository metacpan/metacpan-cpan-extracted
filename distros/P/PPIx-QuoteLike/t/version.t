package main;

use 5.006;

use strict;
use warnings;

use PPIx::QuoteLike;
use PPIx::QuoteLike::Constant qw{
    SUFFICIENT_UTF8_SUPPORT_FOR_WEIRD_DELIMITERS
};
use PPIx::QuoteLike::Token::Control;
use PPIx::QuoteLike::Token::Delimiter;
use PPIx::QuoteLike::Token::Interpolation;
use PPIx::QuoteLike::Token::String;

use Test::More 0.88;	# Because of done_testing();

# NOTE we use this circumlocution to hide the :encoding() from
# xt/author/minimum_perl.t and Perl::MinimumVersion. The two-argument
# binmode itself is OK under Perl 5.6 but the :encoding() is not. But if
# we're 5.6 then SUFFICIENT_UTF8_SUPPORT_FOR_WEIRD_DELIMITERS is false,
# so the binmode() never gets executed.
use constant OUTPUT_ENCODING	=> ':encoding(utf-8)';

if ( SUFFICIENT_UTF8_SUPPORT_FOR_WEIRD_DELIMITERS ) {
    my $builder = Test::More->builder();
    foreach my $method ( qw{ output failure_output todo_output } ) {
	my $handle = $builder->$method();
	binmode $handle, OUTPUT_ENCODING;
    }
}

use charnames qw{ :full };

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

$tok = PPIx::QuoteLike::Token::Delimiter->__new( content => q<'> );
is $tok->perl_version_introduced(), '5.000',
    q{Delimiter q<'> was introduced in 5.0};
is $tok->perl_version_removed(), undef, q{Delimiter q<'> is still here};

SKIP: {
    SUFFICIENT_UTF8_SUPPORT_FOR_WEIRD_DELIMITERS
	or skip 'Weird delimiters test requires Perl 5.8.3 or above', 2;

    $tok = PPIx::QuoteLike::Token::Delimiter->__new( content =>
	qq<\N{COMBINING CIRCUMFLEX ACCENT}> );
    is $tok->perl_version_introduced(), '5.008003',
	q[Delimiter qq<\N{COMBINING CIRCUMFLEX ACCENT}> was introduced in 5.8.3 (kinda)];
    is $tok->perl_version_removed(), '5.029',
	q[Delimiter qq<\N{COMBINING CIRCUMFLEX ACCENT}> removed in 5.029];
}

SKIP: {
    SUFFICIENT_UTF8_SUPPORT_FOR_WEIRD_DELIMITERS
	or skip 'Truly weird delimiters test requires Perl 5.8.3 or above', 2;

    $ENV{AUTHOR_TESTING}
	or skip 'Truly weird delimiters are noisy, therefore author tests', 2;

    no warnings qw{ utf8 };	# Because of truly weird characters

    $tok = PPIx::QuoteLike::Token::Delimiter->__new( content =>
	qq<\N{U+FFFE}> );	# permanent noncharacter
    is $tok->perl_version_introduced(), '5.008003',
	q[Delimiter qq<\N{U+FFFE}> was introduced in 5.8.3 (kinda)];
    is $tok->perl_version_removed(), undef,
	q[Delimiter qq<\N{U+FFFE}> is still here];

    $tok = PPIx::QuoteLike::Token::Delimiter->__new( content =>
	qq<\N{U+11FFFF}> );	# illegal character
    is $tok->perl_version_introduced(), '5.008003',
	q[Delimiter qq<\N{U+11FFFF}> was introduced in 5.8.3 (kinda)];
    is $tok->perl_version_removed(), undef,
	q[Delimiter qq<\N{U+11FFFF}> is still here];
}

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

$obj = PPIx::QuoteLike->new( <<HERE_DOC );
<<~'EOD'
    How doth the little crocodile
    Improve its shining tail
    EOD
HERE_DOC
is $obj->perl_version_introduced(), '5.025007',
    'Indented here-doc was introduced in 5.25.7';
is $obj->perl_version_removed(), undef, 'Indented here-doc is still here';

done_testing;

1;

# ex: set textwidth=72 :
