use v5.10;
use warnings;
use strict;

use Regexp::Grammars;

my $list_nonempty = qr{
    <List>

    <rule: List>
        \(  <[Value]>+ % (,)  \)

    <token: Value>
        \d+
}xms;

my $list_empty = qr{
    <List>

    <rule: List>
        \(  <[Value]>* % <_Sep=(,)>  \)

    <token: Value>
        \d+
}xms;

use Smart::Comments;


while (my $input = <>) {
    my $input2 = $input;
    if ($input =~ $list_nonempty) {
        ### nonempty: $/{List}
    }
    if ($input2 =~ $list_empty) {
        ### empty: $/{List}
    }
}
