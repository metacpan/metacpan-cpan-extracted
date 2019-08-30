package main;

use 5.006;

use strict;
use warnings;

use lib qw{ inc };
use My::Module::Test;

use Test::More 0.88;	# Because of done_testing();

note     'PPIx::Regexp::Node::Range';

parse(   '/[a-z]/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, child => 0 );
klass(   'PPIx::Regexp::Node::Range' );
xplain(  q<Characters between 'a' and 'z' inclusive> );

note     'PPIx::Regexp::Token::Assertion';
parse(
    '/^\\A\\B\\B{gcb}\\B{g}\\B{sb}\\B{wb}\\G\\K\\Z\\b\\b{gcb}\\b{g}\\b{sb}\\b{wb}\B{lb}\b{lb}\\z$/'
);
value(   failures => [], 0 );
choose(  child => 1, child => 0 );
klass(   'PPIx::Regexp::Token::Assertion' );
value(   explain => [],
    'Assert position is at beginning of string or after newline' );
choose(  child => 1, child => 1 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is at beginning of string' );
choose(  child => 1, child => 2 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is not at word/nonword boundary' );
choose(  child => 1, child => 3 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is not at grapheme cluster boundary' );
choose(  child => 1, child => 4 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is not at grapheme cluster boundary' );
choose(  child => 1, child => 5 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is not at sentence boundary' );
choose(  child => 1, child => 6 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is not at word boundary' );
choose(  child => 1, child => 7 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is at pos()' );
choose(  child => 1, child => 8 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'In s///, keep everything before the \\K' );
choose(  child => 1, child => 9 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is at end of string, or newline before end' );
choose(  child => 1, child => 10 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is at word/nonword boundary' );
choose(  child => 1, child => 11 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is at grapheme cluster boundary' );
choose(  child => 1, child => 12 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is at grapheme cluster boundary' );
choose(  child => 1, child => 13 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is at sentence boundary' );
choose(  child => 1, child => 14 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is at word boundary' );
choose(  child => 1, child => 15 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is not at line boundary' );
choose(  child => 1, child => 16 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is at line boundary' );
choose(  child => 1, child => 17 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is at end of string' );
choose(  child => 1, child => 18 );
klass(   'PPIx::Regexp::Token::Assertion' );
xplain(  'Assert position is at end of string or newline' );

note     'PPIx::Regexp::Token::Backreference';

parse(   '/(?<foo>x)\\1\\g-1\\g{foo}/' );
value(   failures => [], 0 );
choose(  child => 1, child => 1 );
klass(   'PPIx::Regexp::Token::Backreference' );
xplain(  'Back reference to capture group 1' );
choose(  child => 1, child => 2 );
klass(   'PPIx::Regexp::Token::Backreference' );
xplain(  'Back reference to 1st previous capture group (1 in this regexp)' );
choose(  child => 1, child => 3 );
klass(   'PPIx::Regexp::Token::Backreference' );
xplain(  q<Back reference to capture group 'foo'> );

note     'PPIx::Regexp::Token::Backtrack';

parse(   '/(*ACCEPT)(*COMMIT)(*FAIL)(*MARK:foo)(*PRUNE:bar)(*SKIP:baz)(*THEN:fee)(*:fie)(*F:foe)/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0 );
klass(   'PPIx::Regexp::Token::Backtrack' );
xplain(  'Causes match to succeed at the point of the (*ACCEPT)' );
choose(  child => 1, child => 1 );
klass(   'PPIx::Regexp::Token::Backtrack' );
xplain(  'Causes match failure when backtracked into on failure' );
choose(  child => 1, child => 2 );
klass(   'PPIx::Regexp::Token::Backtrack' );
xplain(  'Always fails, forcing backtrack' );
choose(  child => 1, child => 3 );
klass(   'PPIx::Regexp::Token::Backtrack' );
xplain(  'Name branches of alternation, target for (*SKIP)' );
choose(  child => 1, child => 4 );
klass(   'PPIx::Regexp::Token::Backtrack' );
xplain(  'Prevent backtracking past here on failure' );
choose(  child => 1, child => 5 );
klass(   'PPIx::Regexp::Token::Backtrack' );
xplain(  'Like (*PRUNE) but also discards match to this point' );
choose(  child => 1, child => 6 );
klass(   'PPIx::Regexp::Token::Backtrack' );
xplain(  'Force next alternation on failure' );
choose(  child => 1, child => 7 );
klass(   'PPIx::Regexp::Token::Backtrack' );
xplain(  'Name branches of alternation, target for (*SKIP)' );
choose(  child => 1, child => 8 );
klass(   'PPIx::Regexp::Token::Backtrack' );
xplain(  'Always fails, forcing backtrack' );

note     'PPIx::Regexp::Token::CharClass::POSIX -- asserted';

parse(   '/[[:alnum:][:alpha:][:ascii:][:blank:][:cntrl:][:digit:][:graph:][:lower:][:print:][:punct:][:space:][:upper:][:word:][:xdigit:]]/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, child => 0 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Any alphanumeric character' );
choose(  child => 1, child => 0, child => 1 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Any alphabetic' );
choose(  child => 1, child => 0, child => 2 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Any character in the ASCII character set' );
choose(  child => 1, child => 0, child => 3 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'A GNU extension, equal to a space or a horizontal tab ("\\t")' );
choose(  child => 1, child => 0, child => 4 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Any control character' );
choose(  child => 1, child => 0, child => 5 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Any decimal digit' );
choose(  child => 1, child => 0, child => 6 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Any non-space printable character' );
choose(  child => 1, child => 0, child => 7 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Any lowercase character' );
choose(  child => 1, child => 0, child => 8 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Any printable character' );
choose(  child => 1, child => 0, child => 9 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Any graphical character excluding "word" characters' );
choose(  child => 1, child => 0, child => 10 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Any whitespace character' );
choose(  child => 1, child => 0, child => 11 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Any uppercase character' );
choose(  child => 1, child => 0, child => 12 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'A Perl extension, equivalent to "\\w"' );
choose(  child => 1, child => 0, child => 13 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Any hexadecimal digit' );

note     'PPIx::Regexp::Token::CharClass::POSIX -- negated';

parse(   '/[[:^alnum:][:^alpha:][:^ascii:][:^blank:][:^cntrl:][:^digit:][:^graph:][:^lower:][:^print:][:^punct:][:^space:][:^upper:][:^word:][:^xdigit:]]/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, child => 0 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Anything but an alphanumeric character' );
choose(  child => 1, child => 0, child => 1 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Anything but an alphabetic' );
choose(  child => 1, child => 0, child => 2 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Anything but a character in the ASCII character set' );
choose(  child => 1, child => 0, child => 3 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'A GNU extension, anything but a space or a horizontal tab ("\\t")' );
choose(  child => 1, child => 0, child => 4 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Anything but a control character' );
choose(  child => 1, child => 0, child => 5 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Anything but a decimal digit' );
choose(  child => 1, child => 0, child => 6 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Anything but a non-space printable character' );
choose(  child => 1, child => 0, child => 7 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Anything but a lowercase character' );
choose(  child => 1, child => 0, child => 8 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Anything but a printable character' );
choose(  child => 1, child => 0, child => 9 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Anything but a graphical character excluding "word" characters' );
choose(  child => 1, child => 0, child => 10 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Anything but a whitespace character' );
choose(  child => 1, child => 0, child => 11 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Anything but an uppercase character' );
choose(  child => 1, child => 0, child => 12 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'A Perl extension, equivalent to "\\W"' );
choose(  child => 1, child => 0, child => 13 );
klass(   'PPIx::Regexp::Token::CharClass::POSIX' );
xplain(  'Anything but a hexadecimal digit' );

note     'PPIx::Regexp::Token::CharClass::Simple';

parse(
    '/.\\C\\D\\H\\N\\R\\S\\V\\W\\X\\d\\h\\s\\v\\w\\P{Upper}\\p{Upper}\\p{Script=<\A(?:Latin|Greek)\z>}/'
);
value(   failures => [], 0 );
choose(  child => 1, child => 0 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match any character' );
choose(  child => 1, child => 1 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match a single octet (removed in 5.23.0)' );
choose(  child => 1, child => 2 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match any character but a decimal digit' );
choose(  child => 1, child => 3 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match a non-horizontal-white-space character' );
choose(  child => 1, child => 4 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match any character but a new-line character' );
choose(  child => 1, child => 5 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match a generic new-line character' );
choose(  child => 1, child => 6 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match non-white-space character' );
choose(  child => 1, child => 7 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match a non-vertical-white-space character' );
choose(  child => 1, child => 8 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match non-word character' );
choose(  child => 1, child => 9 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match a Unicode extended grapheme cluster' );
choose(  child => 1, child => 10 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match decimal digit' );
choose(  child => 1, child => 11 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match a horizontal-white-space character' );
choose(  child => 1, child => 12 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match white-space character' );
choose(  child => 1, child => 13 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match a vertical-white-space character' );
choose(  child => 1, child => 14 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match word character' );
choose(  child => 1, child => 15 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match character without Unicode or custom property \'Upper\'' );
choose(  child => 1, child => 16 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match character with Unicode or custom property \'Upper\'' );
choose(  child => 1, child => 17 );
klass(   'PPIx::Regexp::Token::CharClass::Simple' );
xplain(  'Match character with Unicode wildcard property \'Script=<\A(?:Latin|Greek)\z>\'' );

note     'PPIx::Regexp::Token::Code';

parse(   '/(?{foo()})/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, child => 0 );
klass(   'PPIx::Regexp::Token::Code' );
xplain(  'Perl expression' );

note     'PPIx::Regexp::Token::Comment';

parse(   '/(?#foo)/' );
value(   failures => [], 0 );
choose(  child => 1, start => 1 );
klass(   'PPIx::Regexp::Token::Comment' );
xplain(  'Comment' );

note     'PPIx::Regexp::Token::Condition';

parse(   '/(?(DEFINE))(?(R))(?(1))(?(<foo>))(?(R1))(?(R&foo))/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, child => 0 );
klass(   'PPIx::Regexp::Token::Condition' );
xplain(  'Define a group to be recursed into' );
choose(  child => 1, child => 1, child => 0 );
klass(   'PPIx::Regexp::Token::Condition' );
xplain(  'True if recursing' );
choose(  child => 1, child => 2, child => 0 );
klass(   'PPIx::Regexp::Token::Condition' );
xplain(  'True if capture group 1 matched' );
choose(  child => 1, child => 3, child => 0 );
klass(   'PPIx::Regexp::Token::Condition' );
xplain(  'True if capture group \'foo\' matched' );
choose(  child => 1, child => 4, child => 0 );
klass(   'PPIx::Regexp::Token::Condition' );
xplain(  'True if recursing directly inside capture group 1' );
choose(  child => 1, child => 5, child => 0 );
klass(   'PPIx::Regexp::Token::Condition' );
xplain(  'True if recursing directly inside capture group \'foo\'' );

note     'PPIx::Regexp::Token::Control';

parse(   '/\\E\\F\\L\\Q\\U\\l\\u/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0 );
klass(   'PPIx::Regexp::Token::Control' );
xplain(  'End of interpolation control' );
choose(  child => 1, child => 1 );
klass(   'PPIx::Regexp::Token::Control' );
xplain(  'Fold case until \\E' );
choose(  child => 1, child => 2 );
klass(   'PPIx::Regexp::Token::Control' );
xplain(  'Lowercase until \\E' );
choose(  child => 1, child => 3 );
klass(   'PPIx::Regexp::Token::Control' );
xplain(  'Quote metacharacters until \\E' );
choose(  child => 1, child => 4 );
klass(   'PPIx::Regexp::Token::Control' );
xplain(  'Uppercase until \\E' );
choose(  child => 1, child => 5 );
klass(   'PPIx::Regexp::Token::Control' );
xplain(  'Lowercase next character' );
choose(  child => 1, child => 6 );
klass(   'PPIx::Regexp::Token::Control' );
xplain(  'Uppercase next character' );

note     'PPIx::Regexp::Token::Delimiter';

parse(   '//' );
value(   failures => [], 0 );
choose(  child => 1, start => 0 );
klass(   'PPIx::Regexp::Token::Delimiter' );
xplain(  'Regular expression or replacement string delimiter' );
choose(  child => 1, finish => 0 );
klass(   'PPIx::Regexp::Token::Delimiter' );
xplain(  'Regular expression or replacement string delimiter' );

note     'PPIx::Regexp::Token::Greediness';

parse(   '/x*?y*+/' );
value(   failures => [], 0 );
choose(  child => 1, child => 2 );
klass(   'PPIx::Regexp::Token::Greediness' );
xplain(  'match shortest string first' );
choose(  child => 1, child => 5 );
klass(   'PPIx::Regexp::Token::Greediness' );
xplain(  'match longest string and give nothing back' );

note     'PPIx::Regexp::Token::GroupType::Assertion';

parse(   '/(?!x)(?<!y)(?<=z)(?=w)/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, type => 0 );
klass(   'PPIx::Regexp::Token::GroupType::Assertion' );
xplain(  'Negative look-ahead assertion' );
choose(  child => 1, child => 1, type => 0 );
klass(   'PPIx::Regexp::Token::GroupType::Assertion' );
xplain(  'Negative look-behind assertion' );
choose(  child => 1, child => 2, type => 0 );
klass(   'PPIx::Regexp::Token::GroupType::Assertion' );
xplain(  'Positive look-behind assertion' );
choose(  child => 1, child => 3, type => 0 );
klass(   'PPIx::Regexp::Token::GroupType::Assertion' );
xplain(  'Positive look-ahead assertion' );

note     'PPIx::Regexp::Token::GroupType::BranchReset';

parse(   '/(?|(foo)|(bar))/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, type => 0 );
klass(   'PPIx::Regexp::Token::GroupType::BranchReset' );
xplain(  'Re-use capture group numbers' );

note     'PPIx::Regexp::Token::GroupType::Code';

parse(   '/(?{foo()})(?p{bar()})(??{baz()})/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, type => 0 );
klass(   'PPIx::Regexp::Token::GroupType::Code' );
xplain(  'Evaluate code. Always matches.' );
choose(  child => 1, child => 1, type => 0 );
klass(   'PPIx::Regexp::Token::GroupType::Code' );
xplain(  'Evaluate code, use as regexp at this point (removed in 5.9.5)' );
choose(  child => 1, child => 2, type => 0 );
klass(   'PPIx::Regexp::Token::GroupType::Code' );
xplain(  'Evaluate code, use as regexp at this point' );

note     'PPIx::Regexp::Token::GroupType::NamedCapture';

parse(   '/(?<foo>\\d)/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, type => 0 );
klass(   'PPIx::Regexp::Token::GroupType::NamedCapture' );
xplain(  'Capture match into \'foo\'' );

note     'PPIx::Regexp::Token::GroupType::Subexpression';

parse(   '/(?>x)/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, type => 0 );
klass(   'PPIx::Regexp::Token::GroupType::Subexpression' );
xplain(  'Match subexpression without backtracking' );

note     'PPIx::Regexp::Token::GroupType::Switch';

parse(   '/(?(1)x|y)/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, type => 0 );
klass(   'PPIx::Regexp::Token::GroupType::Switch' );
xplain(  'Match one of the following \'|\'-delimited alternatives' );

note     'PPIx::Regexp::Token::Literal';

parse(   '/x/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0 );
klass(   'PPIx::Regexp::Token::Literal' );
xplain(  'Literal character' );

note     'PPIx::Regexp::Token::Modifier';

parse(   '/(foo(?u-n:(bar)))/smxna' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, child => 3, type => 0 );
klass(   'PPIx::Regexp::Token::Modifier' );
xplain(  'u: match using Unicode semantics; -n: parentheses capture' );
choose(  child => 2 );
klass(   'PPIx::Regexp::Token::Modifier' );
xplain(  'a: restrict non-Unicode classes to ASCII; m: ^ and $ match within string; n: parentheses do not capture; s: . can match newline; x: ignore whitespace and comments' );

note	 'PPIx::Regexp::Token::Unknown since 5.28; previously ::NoOp';

parse   ( '/\\N{}/' );
value   ( failures => [], 1 );
choose  ( child => 1, child => 0 );
klass   ( 'PPIx::Regexp::Token::Unknown' );
xplain  ( 'Empty Unicode character name' );

note     'PPIx::Regexp::Token::Operator';

parse(   '/(?[(\\w-[[:lower:]])|\\p{Greek}])|[^a-z]/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, child => 0, child => 1 );
klass(   'PPIx::Regexp::Token::Operator' );
xplain(  'Subtraction operator' );
choose(  child => 1, child => 0, child => 1 );
klass(   'PPIx::Regexp::Token::Operator' );
xplain(  'Union operator' );
choose(  child => 1, child => 1 );
klass(   'PPIx::Regexp::Token::Operator' );
xplain(  'Alternation operator' );
choose(  child => 1, child => 2, type => 0 );
klass(   'PPIx::Regexp::Token::Operator' );
xplain(  'Inversion operator' );
choose(  child => 1, child => 2, child => 0, child => 1 );
klass(   'PPIx::Regexp::Token::Operator' );
xplain(  'Range operator' );

note     'PPIx::Regexp::Token::Quantifier';

parse(   '/a*b+c?/' );
value(   failures => [], 0 );
choose(  child => 1, child => 1 );
klass(   'PPIx::Regexp::Token::Quantifier' );
xplain(  'match zero or more times' );
choose(  child => 1, child => 3 );
klass(   'PPIx::Regexp::Token::Quantifier' );
xplain(  'match one or more times' );
choose(  child => 1, child => 5 );
klass(   'PPIx::Regexp::Token::Quantifier' );
xplain(  'match zero or one time' );

note     'PPIx::Regexp::Token::Structure';

parse(   '/(?[(\\w-[0-9])]){1,3}/' );
value(   failures => [], 0 );
choose(  child => 0 );
klass(   'PPIx::Regexp::Token::Structure' );
xplain(  'Match regexp' );
choose(  child => 1, start => 0 );
klass(   'PPIx::Regexp::Token::Structure' );
xplain(  'Regular expression or replacement string delimiter' );
choose(  child => 1, child => 0, start => 0 );
klass(   'PPIx::Regexp::Token::Structure' );
xplain(  'Extended character class' );
choose(  child => 1, child => 0, child => 0, start => 0 );
klass(   'PPIx::Regexp::Token::Structure' );
xplain(  'Capture or grouping' );
choose(  child => 1, child => 0, child => 0, child => 2, start => 0 );
klass(   'PPIx::Regexp::Token::Structure' );
xplain(  'Character class' );
choose(  child => 1, child => 0, child => 0, child => 2, finish => 0 );
klass(   'PPIx::Regexp::Token::Structure' );
xplain(  'End character class' );
choose(  child => 1, child => 0, child => 0, finish => 0 );
klass(   'PPIx::Regexp::Token::Structure' );
xplain(  'End capture or grouping' );
choose(  child => 1, child => 0, finish => 0 );
klass(   'PPIx::Regexp::Token::Structure' );
xplain(  'End extended character class' );
choose(  child => 1, finish => 0 );
klass(   'PPIx::Regexp::Token::Structure' );
xplain(  'Regular expression or replacement string delimiter' );

note     'PPIx::Regexp::Token::Recursion';

parse(   '/(?<z>x(?1))(?R)(?0)(?&z)/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0, child => 1 );
klass(   'PPIx::Regexp::Token::Recursion' );
xplain(  'Recurse into capture group 1' );
choose(  child => 1, child => 1 );
klass(   'PPIx::Regexp::Token::Recursion' );
xplain(  'Recurse to beginning of regular expression' );
choose(  child => 1, child => 2 );
klass(   'PPIx::Regexp::Token::Recursion' );
xplain(  'Recurse to beginning of regular expression' );
choose(  child => 1, child => 3 );
klass(   'PPIx::Regexp::Token::Recursion' );
xplain(  'Recurse into capture group \'z\'' );

note     'PPIx::Regexp::Token::Unmatched';

parse(   '/)/' );
value(   failures => [], 1 );
choose(  child => 1, child => 0 );
klass(   'PPIx::Regexp::Token::Unmatched' );
xplain(  'Unmatched token' );

note     'PPIx::Regexp::Token::Whitespace';

parse(   's{ (?[ \\d])} {x}x' );
value(   failures => [], 0 );
choose(  child => 1, start => 1 );
klass(   'PPIx::Regexp::Token::Whitespace' );
xplain(  'Not significant under /x' );
choose(  child => 1, child => 0, start => 1 );
klass(   'PPIx::Regexp::Token::Whitespace' );
xplain(  'Not significant in extended character class' );
choose(  child => 2 );
klass(   'PPIx::Regexp::Token::Whitespace' );
xplain(  'Not significant' );

note     'PPIx::Regexp::Structure::Capture';

parse(   '/(\\d+)(?<foo>\\w+)/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0 );
klass(   'PPIx::Regexp::Structure::Capture' );
xplain(  'Capture group number 1' );
choose(  child => 1, child => 1 );
klass(   'PPIx::Regexp::Structure::Capture' );
xplain(  'Named capture group \'foo\' (number 2)' );

note     'PPIx::Regexp::Structure::Quantifier';

parse(   '/x{1,4}y{2,}z{3}w{$foo}/' );
value(   failures => [], 0 );
choose(  child => 1, child => 1 );
klass(   'PPIx::Regexp::Structure::Quantifier' );
xplain(  'match 1 to 4 times' );
choose(  child => 1, child => 3 );
klass(   'PPIx::Regexp::Structure::Quantifier' );
xplain(  'match 2 or more times' );
choose(  child => 1, child => 5 );
klass(   'PPIx::Regexp::Structure::Quantifier' );
xplain(  'match exactly 3 times' );
choose(  child => 1, child => 7 );
klass(   'PPIx::Regexp::Structure::Quantifier' );
xplain(  'match $foo times' );

note     'PPIx::Regexp::Structure::Regexp';

parse(   '/x/' );
value(   failures => [], 0 );
choose(  child => 1 );
klass(   'PPIx::Regexp::Structure::Regexp' );
xplain(  'Regular expression' );

note     'PPIx::Regexp::Structure::Replacement';

parse(   's/x/y/' );
value(   failures => [], 0 );
choose(  child => 2 );
klass(   'PPIx::Regexp::Structure::Replacement' );
xplain(  'Replacement string or expression' );

note     'PPIx::Regexp';

parse(   '/x/' );
value(   failures => [], 0 );
choose();
klass(   'PPIx::Regexp' );
xplain(  undef );

note	'Caret';

parse(   '/(?^)(x)/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0 );
klass(   'PPIx::Regexp::Token::Modifier' );
xplain(  'd: match using default semantics; -i: do case-sensitive matching; -m: ^ and $ match only at ends of string; -s: . can not match newline; -x: regard whitespace as literal' );

parse(   '/(?^)(x)/n' );
value(   failures => [], 0 );
choose(  child => 1, child => 0 );
klass(   'PPIx::Regexp::Token::Modifier' );
xplain(  'd: match using default semantics; -i: do case-sensitive matching; -m: ^ and $ match only at ends of string; -n: parentheses capture; -s: . can not match newline; -x: regard whitespace as literal' );

note	'Capture vs grouping';

parse(	'/(x)/' );
value(   failures => [], 0 );
choose(  child => 1, child => 0 );
klass(   'PPIx::Regexp::Structure::Capture' );
xplain(  'Capture group number 1' );

parse(	'/(x)/n' );
value(   failures => [], 0 );
choose(  child => 1, child => 0 );
klass(   'PPIx::Regexp::Structure' );
xplain(  'Grouping' );

note	'Retraction of \\K inside look-around';

parse(	'/(?=\\K)\K/' );
value(	failures => [], 0 );
choose(	child => 1, child => 0, child => 0 );
klass(	'PPIx::Regexp::Token::Assertion' );
xplain(	'In s///, keep everything before the \K; retracted inside look-around assertion' );
value(	perl_version_removed => [], '5.031003' );
choose(	child => 1, child => 1 );
klass(	'PPIx::Regexp::Token::Assertion' );
xplain(	'In s///, keep everything before the \K' );
value(	perl_version_removed => [], undef );

done_testing;

sub xplain {
    splice @_, 0, 0, explain => [];
    goto &value;
}

1;

# ex: set textwidth=72 :
