use v5.10;
use warnings;

use Regexp::Grammars;

my $parser = qr{
    <debug:match>
    <Try>

    <rule: Try>
        <Word= (\w+)>
        <Middle=(\w+?)>
        <Suffix= (-fu)>
        <require: (?{ $MATCH{Word} eq 'your' })>
}xms;

while (<>) {
    say 'matched' if /$parser/;
}
