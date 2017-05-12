use v5.10;
use warnings;

my $grammar_unflattened = do {
    use Regexp::Grammars;
    qr{
        mv  \s* <from> \s*   <to>

        <rule: from>       <file>
        <rule: to>         <file>

        <rule: file>       <dirpath>? <filename>

        <token: dirpath>   /? (?: [\w.-]+ / )+
        <token: filename>  [\w.-]+
    }xms;
};

my $grammar_flattened = do {
    use Regexp::Grammars;
    qr{
        mv  \s* <from> \s*   <to>

        <rule: from>       <MATCH=file>
        <rule: to>         <MATCH=file>

        <rule: file>       <dirpath>? <filename>
                           (?{ $MATCH = ($MATCH{dirpath}//q{})
                                      .  $MATCH{filename}
                           })

        <token: dirpath>   /? (?: [\w.-]+ / )+
        <token: filename>  [\w.-]+
    }xms;
};

while (my $line = <>) {
    my $line_copy = $line;
    if ($line =~ $grammar_unflattened) {
        use Data::Dumper 'Dumper';
        say Dumper \%/;
    }

    if ($line_copy =~ $grammar_flattened) {
        use Data::Dumper 'Dumper';
        say Dumper \%/;
    }
}
