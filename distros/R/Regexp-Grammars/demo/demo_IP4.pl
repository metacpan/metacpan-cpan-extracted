use v5.10;
use warnings;

use Regexp::Grammars;

my $grammar = qr{
    \A <IP4_addr> \Z

    <token: quad>
        <MATCH=( \d{1,3} )>
        <require: (?{ $MATCH < 256 })>

    <token: IP4_addr>
        <[MATCH=quad]>+ % (\.)
        <require: (?{ @$MATCH == 4 })>
}xms;

while (my $line = <>) {
    if ($line =~ $grammar) {
        use Data::Dumper 'Dumper';
        say Dumper \%/;
    }
}
