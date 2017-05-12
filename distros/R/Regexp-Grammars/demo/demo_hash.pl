use v5.10;
use warnings;

my %hash = (
    do => 'a deer',
    re => 'a drop of golden sun',
    mi => 'a name I call myself',
    fa => 'a long long way to run',
);

my $grammar = do {
    use Regexp::Grammars;
    qr{
        <[_WORD=%hash]>+

        <defns=(?{  [@hash{ @{$MATCH{_WORD}} }]  })>
    }xms;
};

while (my $line = <>) {
    if ($line =~ $grammar) {
        use Data::Dumper 'Dumper';
        say Dumper \%/;
    }
}

say {*STDERR} 'done!';
