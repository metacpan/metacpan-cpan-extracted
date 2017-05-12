use 5.010;
use warnings;

use Test::More;
plan 'no_plan';

use Regexp::Grammars;

my $list_nonempty = qr{
    <List>

    <rule: List>
        \(  <[Value]> {1,4}% [,]  \)

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
() : FAIL
(1) : [1]
(1,2) : [1,2]
(1,2,3) : [1,2,3]
(1,2,3,4) : [1,2,3,4]
(1,2,3,4,5) : FAIL
(  ) : FAIL
( 1 ) : [1]
(1, 2 ) : [1,2]
(1, 2,3 ) : [1,2,3]
(1, 2, 3, 4) : [1,2,3,4]
(1, 2, 3, 4,5) : FAIL
