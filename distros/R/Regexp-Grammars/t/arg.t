use 5.010;
use strict;

use Test::More;
plan 'no_plan';

my $test_grammar = do {
    use Regexp::Grammars;
    qr{
        <keyword=(\w+)>
            <content=(.+?)>
        <dekeyword( delim => 'fo+/')>
      |
        <keyword=(\w+)>
            <content=(.+?)>
        <unkeyword(:keyword, prefix=>'end')>

      |
        <keyword=(\w+)>
            <content=(.+?)>
        <revkeyword=unkeyword(?{ keyword => scalar(reverse($::MATCH{keyword})) })>


        <rule: unkeyword>
            (??{ quotemeta( ($::ARG{prefix}//q{}) . $::ARG{keyword} ) })

        <token: dekeyword>
            (<:delim>) <terminator=(?{$::CAPTURE})>
    }xms;
};

ok 'fooxoof' =~ $test_grammar => 'Match reverse';
is $/{keyword}, 'foo'         => 'Keyword as expected';
is $/{content}, 'x'           => 'Content as expected';
is $/{revkeyword}, 'oof'      => 'Revkeyword as expected';

ok 'fooxendfoo' =~ $test_grammar => 'Match end';
is $/{keyword}, 'foo'            => 'Keyword as expected';
is $/{content}, 'x'              => 'Content as expected';
is $/{unkeyword}, 'endfoo'       => 'Unkeyword as expected';

ok 'fooxfoo/' =~ $test_grammar => 'Match /';
is $/{keyword}, 'foo'          => 'Keyword as expected';
is $/{content}, 'x'            => 'Content as expected';
is_deeply $/{dekeyword}, { "" =>'foo/', 'terminator'=>'foo/' }
                               => 'Dekeyword as expected';
