use 5.010;
use warnings;

use Test::More;
plan 'no_plan';

use Regexp::Grammars;

my $list_parser = qr{
    <List>

    <rule: List>
        \(  <[Value]> *% [,]  \)

    <token: Value>
        \d+
}xms;

no Regexp::Grammars;

while (my $input = <DATA>) {
    chomp $input;
    my $input_copy = $input;
    my ($list, $data_structure) = split /\s*:\s*/, $input;

    ok +($input_copy =~ $list_parser) => 'Matched $input: ' . $list;
    is_deeply $/{List}{Value}, eval($data_structure)
                                => 'Build correct structure';
}


__DATA__
()        : undef
(1)       : [1]
(1,2)     : [1,2]
(1,2,3)   : [1,2,3]
(  )      : undef
( 1 )     : [1]
(1, 2 )   : [1,2]
(1, 2,3 ) : [1,2,3]
