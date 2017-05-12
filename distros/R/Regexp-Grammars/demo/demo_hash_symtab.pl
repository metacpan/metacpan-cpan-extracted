use v5.10;
use warnings;

my $grammar = do {
    my %type_symbol_table = (
        'num'  => 'num',
        'str'  => 'str',
        'bool' => 'bool',
    );

    use Regexp::Grammars;
    qr{
        <[statement]>+

        <rule: statement>
              <typedef>
            | <vardef>

        <rule: typedef>
            type <ident> : <typename>
                (?{ $type_symbol_table{$MATCH{ident}} = $MATCH{typename} })

        <rule: vardef>
            var <ident> : <typename>

        <rule: typename>
            <name=%type_symbol_table>
                <MATCH=(?{ $type_symbol_table{$MATCH{name}} })>

        |   <pointer=(?: \^ )> <typename>

        <token: ident>
            [^\W\d] \w*

    }xms;
};

while (my $line = <>) {
    if ($line =~ $grammar) {
        use Data::Dumper 'Dumper';
        say Dumper \%/;
    }
}

say {*STDERR} 'done!';
