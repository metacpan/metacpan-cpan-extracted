use 5.010;
use warnings;
use Test::More 'no_plan';

my $parser = do{
    use Regexp::Grammars;
    qr{
        <num> | <str> | <bool> | <list(arg=>1)>

        <token: num>
            \d++

        <token: str>
            ' <content=( .*? )> '

        <token: bool>
            <MATCH=(t)> <etc=(rue)>
          | <etc=(f)> <MATCH=(alse)>

        <token: list>
            <[Dash=(-)]> ** <[Dot=(\.)]>
            <minimize:>
    }xms
};

ok +("'abc'" =~ $parser)    => 'Matched str';
is_deeply $/{str}, { q{} => "'abc'", content => 'abc' }  => 'Unflattened correctly';

ok +(42 =~ $parser) => 'Matched num';
is $/{num}, 42      => 'Flattened correctly';

ok +('true' =~ $parser) => 'Matched true';
is $/{bool}, 't'        => 'Flattened correctly';

ok +('false' =~ $parser) => 'Matched false';
is $/{bool}, 'alse'      => 'Flattened correctly';

ok +('-.-.-' =~ $parser)    => 'Matched list';
is_deeply $/{list}, { q{}=>'-.-.-', Dash=>['-','-','-'], Dot=>['.','.'] }     => 'Flattened correctly';

ok +('-' =~ $parser) => 'Matched minimized list';
is $/{list}, '-'     => 'Flattened correctly';
