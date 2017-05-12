use strict;
use 5.010;

use Test::More 'no_plan';

my $test_grammar = do {
    use Regexp::Grammars;
    qr{
        <keyword=(\w+)>
            <content=(.+?)>
        <end_keyword (:keyword)>

      | <keyword=(\w+)>
            <content=(.+?)>
        <rev_keyword(:keyword)>

        <token: end_keyword>   end_ <\:keyword>
        <token: rev_keyword>        </:keyword>
    }xms;
};

ok 'fooxend_foo' =~ $test_grammar => 'Match end';
is $/{keyword}, 'foo'             => 'Keyword as expected';
is $/{content}, 'x'               => 'Content as expected';
is $/{end_keyword}, 'end_foo'     => 'End_keyword as expected';

ok 'fooxoof' =~ $test_grammar => 'Match rev';
is $/{keyword}, 'foo'         => 'Keyword as expected';
is $/{content}, 'x'           => 'Content as expected';
is $/{rev_keyword}, 'oof'     => 'End_keyword as expected';
