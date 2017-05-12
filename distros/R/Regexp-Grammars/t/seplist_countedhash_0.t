use 5.010;
use warnings;

use Test::More;
plan 'no_plan';

use Regexp::Grammars;

my $list_parser = qr{
    <List>

    <rule: List>
        \(  <[Value]>{0} % [,]  \)

    <token: Value>
        \d+
}xms;

no Regexp::Grammars;

while (my $input = <DATA>) {
    chomp $input;
    my $input_copy = $input;
    my ($list, $data_structure) = split /\s*:\s*/, $input;

    ok +($input =~ $list_parser xor $data_structure =~ /FAIL/) => 'Correct for:' . $list;
    if ($data_structure !~ /FAIL/) {
        is_deeply $/{List}{Value}, eval($data_structure)
                                    => 'Build correct structure';
    }
}


__DATA__
() : undef
(1) : FAIL
(1,2) : FAIL
(1,2,3) : FAIL
(1,2,3,4) : FAIL
(1,2,3,4,5) : FAIL
(  ) : undef
( 1 ) : FAIL
(1, 2 ) : FAIL
(1, 2,3 ) : FAIL
(1, 2, 3, 4) : FAIL
(1, 2, 3, 4,5) : FAIL
