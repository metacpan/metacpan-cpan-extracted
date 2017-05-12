use v5.10;
use warnings;

use Regexp::Grammars;
use re 'eval';

my $metagrammar = q{
    <RegexGrammar>

    <token: RegexGrammar>
        \A
        <ActivePattern= RuleBody>
        <[Definitions=  Ruledef]>*
        \z

    <token: Ruledef>
        \<  <Obj=(obj|)> <Type=(rule|token)>  \s*+ : \s*+  <Rulename=IDENT>  \>
            <Body=RuleBody>

    <token: RuleBody>
        <[Std=StdRegex]>+ % <[NonStd=Translatable]>

    <token: StdRegex>
        <MATCH= ([^<]*+ .*?)>

    <token: Translatable>
        <Subrule= SeparatedList>
      | <Subrule= SubruleCall>
      | <Directive>

    <token: Directive>
        \<  debug \s*+ : \s*+ 
            <Debug=(?: off | run | jump | step | continue | match | try )>
        \s*+  \>
      |  
        \<  logfile \s*+ : \s*+ <Log=(\S+)> \s*+ \>
        
    <token: SeparatedList>
              <Subrule= SubruleCall>
                  <ws1= (\s*+)>
                        \*\*
                  <ws2= (\s*+)>
        (?: <Separator= SubruleCall>
          | <Separator= PARENS> 
        )

    <token: SubruleCall>
            <WS=(\s++)>
        |
            \<
            (?:     <Noncapturing=(\.?)>         <Subrule=IDENT> 
                |   \[                      \s*+ <Subrule=IDENT> \s*+  \]
                |      <Alias=IDENT> \s*+ = \s*+ <Subrule=IDENT> \s*+
                |   \[ <Alias=IDENT> \s*+ = \s*+ <Subrule=IDENT> \s*+ \]
                |
                    <Noncapturing= (\.?)>
                           <Alias= IDENT>
                                   \s*+ = \s*+
                      ( <Action= PARENBLOCK> | <Subpattern= PARENS> )
                                   \s*+
            )
            \>

    <token: IDENT>
        [^\W\d]\w*+

    <token: CHARSET>
        (?> \[  \^?+  \]?+  [^]]*+  \] )

    <token: PARENBLOCK>
        \(\?\{ (?: \\\\. | <.BRACES> | <.PARENS> | <.CHARSET> | [^][()\\\\]++ )* \}\)

    <token: PARENS>
        \( (?: \\\\. | <.PARENS> | <.CHARSET> | [^][()\\\\]++ )* \)

    <token: BRACES>
        \{  (?: \\\\. | <.BRACES> | [^{}\\\\]++ )*  \}
};                          

my $parser = qr{
    $metagrammar
}xms;

#use Data::Dumper 'Dumper'; warn Dumper [ $parser ];

if ($metagrammar =~ $parser) {
    my $structure = $/{RegexGrammar};
    use Data::Dumper 'Dumper';
    say Dumper $structure;
}

