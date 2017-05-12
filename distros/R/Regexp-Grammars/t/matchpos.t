use strict;
use 5.010;

use Test::More 'no_plan';

my $test_grammar = do {
    use Regexp::Grammars;
    qr{
        <startmarker>
            <content>
        <endmarker>

        <token: startmarker>   <at=matchpos> \{ <after=matchpos>

        <token: content>       (?: <[matchpos]> <[num]> <ws>? )+
                       |       <data=(.*)> <matched=(?{1})>

        <token: endmarker>     <matchpos> \}
                         |     \] <superbracket=(?{1})>

        <token: num>           \d++
    }xms;
};

   #012345
ok "  {aa}" =~ $test_grammar      => 'Matched test 1';
is $/{startmarker}{at}, 2         => "Aliased <matchpos>";
is $/{startmarker}{after}, 3      => "Post-aliased <matchpos>";
is $/{endmarker}{matchpos},  5    => "Unaliased <matchpos>";
ok ! exists $/{content}{matchpos} => "No <matchpos>";

   #012345
ok "  {aa]" =~ $test_grammar        => 'Matched test 2';
is $/{startmarker}{at}, 2           => "Aliased <matchpos>";
ok ! exists $/{endmarker}{matchpos} => "No unaliased <matchpos>";
ok ! exists $/{content}{matchpos}   => "No <matchpos>";

   #0123456
ok "{1 2 3}" =~ $test_grammar            => 'Matched test 3';
is $/{startmarker}{at}, 0                => "Aliased <matchpos>";
is $/{endmarker}{matchpos}, 6            => "Unaliased <matchpos>";
is_deeply $/{content}{num}, [1,2,3]      => "Repeated contents";
is_deeply $/{content}{matchpos}, [1,3,5] => "Repeated <[matchpos]>";

