use v5.10;
use warnings;

my $parser = do{
    use Regexp::Grammars;
    qr{
        <file>

        <rule: file>
            <[element]>*

        <rule: element>
            <special> | <command> | <literal>

        <token: special>
            <MATCH= mathematical>
          | <MATCH= group>
          | <MATCH= comment>
          | <MATCH= vinculum>
          | <MATCH= newline>
          | <MATCH= super>
          | <MATCH= sub>
          | <MATCH= column_separator>

        <rule: mathematical>
            \$ <[element]>* \$

        <rule: comment>
            \# <MATCH= ( [^\n]* \n [^\S\n]* )>

        <rule: vinculum>
            \~

        <rule: newline>
            \\ \\

        <rule: super>
            \^

        <rule: sub>
            \_

        <rule: column_separator>
            \$

        <rule: command>
            \\  <name>  <options>?  <[arg=group]>*

        <rule: options>
            \[  <[option]>+ % <_Sep=(,)>  \]
        
        <rule: group>
            \{  <[element]>*  \}

        <rule: option>
            [^][\$&%#_{}~^\s,]++

        <token: literal>
            <MATCH=( [^][\\\$&%#_{}~^\s]*+  (?: \\[^\w\\] [^][\\\$&%#_{}~^\s]*+ )*+ )>
                <require: (?{ length($CAPTURE) > 0 })>

        <token: name>
            <MATCH=alphas> | <MATCH=single_nonalpha>

        <token: alphas>
            <MATCH=([^\W\d_]++)>

        <token: single_nonalpha>
            <MATCH=([\W\d_])>

    }xms
};

my $input = do{ local $/; <DATA>};
if ($input =~ $parser) {
    use Data::Dumper 'Dumper';
    warn Dumper [ \%/ ];
}


__DATA__
\documentclass[a4paper,11pt]{article}
\usepackage{latexsym}
\author{D.~Conway}
\title{Parsing \LaTeX{}}
\begin{document}
\maketitle
\tableofcontents
\section{Description}
...is easy \footnote{But not\\ \emph{necessarily} simple}.
In fact it's $easy_peasy^2$ to do.
\end{document}
