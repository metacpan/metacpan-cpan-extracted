use 5.010;
use warnings;

use Test::More 'no_plan';

use Regexp::Grammars;

my $list_nonempty = qr{
    <List>

    <rule: List>
        \(  <[Value]> ** [,]  \)

    <token: Value>
        \d+
}xms;

my $list_empty = qr{
    <List>

    <rule: List>
        \(  (?: <[Value]> ** , x? )?  \)
            (?{ $MATCH{Value} //= [] })

    <token: Value>
        \d+
}xms;

no Regexp::Grammars;

while (my $input = <DATA>) {
    chomp $input;
    my $input_copy = $input;
    my ($list, $data_structure) = split /\s*:\s*/, $input;

    if ($list !~ m{ \( \s* \) }xms) {
        ok +($input =~ $list_nonempty) => 'Matched non-empty list:' . $list;
        is_deeply $/{List}{Value}, eval($data_structure)
                                       => 'Build correct structure';
    }

    ok +($input_copy =~ $list_empty) => 'Matched possibly-empty list:' . $list;
    is_deeply $/{List}{Value}, eval($data_structure)
                                => 'Build correct structure';
}


__DATA__
() : []
(1) : [1]
(1,2) : [1,2]
(1,2,3) : [1,2,3]
(  ) : []
( 1 ) : [1]
(1, 2 ) : [1,2]
(1, 2,3 ) : [1,2,3]
