use 5.010;
use warnings;

use Test::More;
plan 'no_plan';

use Regexp::Grammars;

my $list_nonempty = qr{
    <List>

    <rule: List>
        \(  <[Value]>{0,}% <sep=(,)>  \)

    <token: Value>
        \d+
}xms;

no Regexp::Grammars;

while (my $input = <DATA>) {
    chomp $input;
    my $input_copy = $input;
    my ($list, $data_structure) = split /\s*:\s*/, $input;

    if ($list !~ m{ \( \s* \) }xms) {
        ok +($input =~ $list_nonempty xor $data_structure =~ /FAIL/) => 'Correct for:' . $list;
        if ($data_structure !~ /FAIL/) {
            is_deeply $/{List}{Value}, eval($data_structure)
                                       => 'Build correct structure';
        }
    }
}


__DATA__
() : undef
(1) : [1]
(1,2) : [1,2]
(1,2,3) : [1,2,3]
(1,2,3,4) : [1,2,3,4]
(1,2,3,4,5) : [1,2,3,4,5]
(  ) : undef
( 1 ) : [1]
(1, 2 ) : [1,2]
(1, 2,3 ) : [1,2,3]
(1, 2, 3, 4) : [1,2,3,4]
(1, 2, 3, 4,5) : [1,2,3,4,5]
