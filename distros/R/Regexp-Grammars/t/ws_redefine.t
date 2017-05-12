use Test::More;

plan tests => 4;


use Regexp::Grammars;

my $grammar_implicit_ws = qr{
    <foo (arg => 42)>
    <rule:  foo>  foo bar  <param=(?{ $ARG{arg} })>
};

my $grammar_explicit_ws = qr{
    <foo (arg => 42)>
    <rule:  foo>  foo bar  <param=(?{ $ARG{arg} })>
    <token: ws>   \s*
};

ok 'foo bar' =~ $grammar_implicit_ws => 'Implicit grammar matched';
is $/{foo}{param}, 42                => 'Implicit grammar remembered param';

ok 'foo bar' =~ $grammar_explicit_ws => 'Explicit grammar matched';
is $/{foo}{param}, 42                => 'Explicit grammar remembered param';

