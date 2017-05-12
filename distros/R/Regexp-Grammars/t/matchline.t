use strict;
use 5.010;

use Test::More 'no_plan';

my $test_grammar = do {
    use Regexp::Grammars;
    qr{
        <startmarker>
            <content>
        <endmarker>

        <token: startmarker>   <at=matchline> \{ <after=matchline>

        <token: content>       (?: <[matchline]> <[num]> <ws>? )+
                       |       <data=(.*)> <matched=(?{1})>

        <token: endmarker>     <matchline> \}
                         |     \] <superbracket=(?{1})>

        <token: num>           \d++
    }xms;
};

   #012345
ok " \n{\naa\n}" =~ $test_grammar  => 'Matched test 1';
is $/{startmarker}{at}, 2          => "Aliased <matchline>";
is $/{startmarker}{after}, 2       => "Post-aliased <matchline>";
is $/{endmarker}{matchline},  4    => "Unaliased <matchline>";
ok ! exists $/{content}{matchline} => "No <matchline>";

   #012345
ok " \n{\naa\n]" =~ $test_grammar    => 'Matched test 2';
is $/{startmarker}{at}, 2            => "Aliased <matchline>";
ok ! exists $/{endmarker}{matchline} => "No unaliased <matchline>";
ok ! exists $/{content}{matchline}   => "No <matchline>";

   #0123456
ok "{11\n22\n\n\n33\n}" =~ $test_grammar  => 'Matched test 3';
is $/{startmarker}{at}, 1                 => "Aliased <matchline>";
is $/{endmarker}{matchline}, 6            => "Unaliased <matchline>";
is_deeply $/{content}{num}, [11,22,33]    => "Repeated contents";
is_deeply $/{content}{matchline}, [1,2,5] => "Repeated <[matchline]>";

