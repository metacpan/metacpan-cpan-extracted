use Test::More tests => 75;

use lib 'lib';
use Parse::EBNF::Rule;

my $rule = Parse::EBNF::Rule->new();


# failure

$rule->parse('Not a valid rule');
ok($rule->has_error());


# simple literals

$rule->parse("[1] Rule ::= 'foo'");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'literal');
ok($rule->base_token()->{content} eq 'foo');

$rule->parse('[1] Rule ::= "foo"');
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'literal');
ok($rule->base_token()->{content} eq 'foo');


# simple Subrule

$rule->parse("[1] Rule ::= SubRule");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'subrule');
ok($rule->base_token()->{content} eq 'SubRule');


# reduced regex literal alternation

$rule->parse("[1] Rule ::= 'foo' | 'bar'");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'rx');
ok($rule->base_token()->{content} eq '(foo)|(bar)');


# rule alternation

$rule->parse("[1] Rule ::= SubRuleA | SubRuleB");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'alternation');
ok($rule->base_token()->{tokens}->[0]->{type} eq 'subrule');
ok($rule->base_token()->{tokens}->[1]->{type} eq 'subrule');
ok($rule->base_token()->{tokens}->[0]->{content} eq 'SubRuleA');
ok($rule->base_token()->{tokens}->[1]->{content} eq 'SubRuleB');


# repetition modifiers

$rule->parse("[1] Rule ::= SubRule+");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'repeat plus');
ok($rule->base_token()->{tokens}->[0]->{type} eq 'subrule');
ok($rule->base_token()->{tokens}->[0]->{content} eq 'SubRule');

$rule->parse("[1] Rule ::= SubRule*");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'repeat star');
ok($rule->base_token()->{tokens}->[0]->{type} eq 'subrule');
ok($rule->base_token()->{tokens}->[0]->{content} eq 'SubRule');

$rule->parse("[1] Rule ::= SubRule?");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'repeat quest');
ok($rule->base_token()->{tokens}->[0]->{type} eq 'subrule');
ok($rule->base_token()->{tokens}->[0]->{content} eq 'SubRule');


# lists

$rule->parse("[1] Rule ::= Foo Bar Baz");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'list');
ok($rule->base_token()->{tokens}->[0]->{type} eq 'subrule');
ok($rule->base_token()->{tokens}->[1]->{type} eq 'subrule');
ok($rule->base_token()->{tokens}->[2]->{type} eq 'subrule');
ok($rule->base_token()->{tokens}->[0]->{content} eq 'Foo');
ok($rule->base_token()->{tokens}->[1]->{content} eq 'Bar');
ok($rule->base_token()->{tokens}->[2]->{content} eq 'Baz');


# hex chars

$rule->parse("[1] Rule ::= #x55");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'rx');
ok($rule->base_token()->{content} eq '\\x55');


# rx classes

$rule->parse("[1] Rule ::= [a-zA-Z]");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'rx');
ok($rule->base_token()->{content} eq '[a-zA-Z]');

$rule->parse("[1] Rule ::= [#x20-#x30]");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'rx');
ok($rule->base_token()->{content} eq '[\\x20-\\x30]');

$rule->parse("[1] Rule ::= [abc]");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'rx');
ok($rule->base_token()->{content} eq '[abc]');

$rule->parse("[1] Rule ::= [#x21#x22#x23]");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'rx');
ok($rule->base_token()->{content} eq '[\\x21\\x22\\x23]');

$rule->parse("[1] Rule ::= [^a-zA-Z]");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'rx');
ok($rule->base_token()->{content} eq '[^a-zA-Z]');

$rule->parse("[1] Rule ::= [^#x20-#x30]");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'rx');
ok($rule->base_token()->{content} eq '[^\\x20-\\x30]');

$rule->parse("[1] Rule ::= [^abc]");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'rx');
ok($rule->base_token()->{content} eq '[^abc]');

$rule->parse("[1] Rule ::= [^#x21#x22#x23]");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'rx');
ok($rule->base_token()->{content} eq '[^\\x21\\x22\\x23]');


# brackets

$rule->parse("[1] Rule ::= ( Foo Bar )");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'list');
ok($rule->base_token()->{tokens}->[0]->{type} eq 'subrule');
ok($rule->base_token()->{tokens}->[1]->{type} eq 'subrule');
ok($rule->base_token()->{tokens}->[0]->{content} eq 'Foo');
ok($rule->base_token()->{tokens}->[1]->{content} eq 'Bar');


# comments

$rule->parse("[1] Rule ::= /* foo */ Bar");
ok(!$rule->has_error());
ok($rule->base_token()->{type} eq 'subrule');
ok($rule->base_token()->{content} eq 'Bar');


# TODO: add tests for:
#
# negation:		A - B
#

