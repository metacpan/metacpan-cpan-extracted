#! /usr/bin/perl

use strict;
use warnings;
use 5.010;

my $query
    = q{ body:("et tu" (Brute OR Caesar)) AND published:[1900 TO 2010] NOT author:Shakespeare };

my $grammar = do{
    use Regexp::Grammars;
    qr{
        \A \s* <Query> \s* \Z

        <rule: Query>
            <[And_Clause]>+ % (OR)

        <rule: And_Clause>
            <[Term]>+ % <[And_Operator]>

        <rule: And_Operator>
            AND
          | NOT
          | \s++  <MATCH=(?{'AND'})>

        <token: Term>
            (?: <Field> : )?
            (?:
                \( <Subquery=Query> \)
              | <Range>
              | <Value=Quoted_Value>
              | <Value=Raw_Value>
            )

        <token: Field>
            <.Non_Keyword>  \w++

        <rule: Range>
            \[  <From=(.*?)>  TO  <To=(.*?)>  \]

        <rule: Quoted_Value>
            '  <MATCH=( [^'\\]*+  (?: \\. [^'\\]*+ )*+ )>  '
          | "  <MATCH=( [^"\\]*+  (?: \\. [^"\\]*+ )*+ )>  "

        <rule: Raw_Value>
            <.Non_Keyword> [^'"()][^\s()]*+

        <token: Non_Keyword>
            (?! NOT | AND | OR | \( | \) )
    }xms;
};

if ($query =~ $grammar) {
    use Data::Dumper 'Dumper';
    say Dumper \%/;
}
else {
    say 'Failed';
}

