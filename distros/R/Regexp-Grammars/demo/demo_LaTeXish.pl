use v5.10;
use warnings;

my $parser = do{
    use Regexp::Grammars;
    qr{
        <debug:on>
        <file>

        <objrule: Latex::file>
            <[element]>*

        <objrule: Latex::element>
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

        <objrule: Latex::mathematical>
            \$ <[element]>* \$

        <objrule: comment>
            \# <MATCH= ( [^\n]* \n [^\S\n]* )>

        <objrule: Latex::vinculum>
            \~

        <objrule: Latex::newline>
            \\ \\

        <objrule: Latex::super>
            \^

        <objrule: Latex::sub>
            \_

        <objrule: Latex::column_separator>
            \$

        <objrule: Latex::command>
            \\  <name>  <options>?  <[arg=group]>*

        <objrule: Latex::options>
            \[  <[option]>+ % <_Sep=(,)>  \]

        <objrule: Latex::group>
            \{  <[element]>*  \}

        <objrule: Latex::option>
            [^][\$&%#_{}~^\s,]++

        <objtoken: Latex::literal>
            ( [^][\\\$&%#_{}~^\s]*+  (?: \\[^\w\\] [^][\\\$&%#_{}~^\s]*+ )*+ )
                <require: (?{ length($CAPTURE) > 0 })>

        <token: name>
            <.alphas> | <.single_nonalpha>

        <token: alphas>
            [^\W\d_]++

        <token: single_nonalpha>
            [\W\d_]

    }xms
};

my $input = do{ local $/; <DATA>};
if ($input =~ $parser) {
    $/{file}->explain(0);
}

sub Latex::file::explain
{
    my ($self, $level) = @_;
    for my $element (@{$self->{element}})
    {
        $element->explain($level);
        print "\n";
    }
}

sub Latex::element::explain
{
    my ($self, $level) = @_;
    (  $self->{command}
    || $self->{literal}
    || $self->{special} )->explain($level)
}

sub Latex::command::explain
{
    my ($self, $level) = @_;
    say "\t"x$level, "Command:";
    say "\t"x($level+1), "Name: $self->{name}";
    if ($self->{options}) {
        say "\t"x$level, "\tOptions:";
        $self->{options}->explain($level+2)
    }

    for my $arg (@{$self->{arg}}) {
        say "\t"x$level, "\tArg:";
        $arg->explain($level+2)
    }
}

sub Latex::options::explain
{
    my ($self, $level) = @_;
    $_->explain($level) foreach @{$self->{option}};
}

sub Latex::group::explain
{
    my ($self, $level) = @_;
    $_->explain($level) foreach @{$self->{element}};
}


sub Latex::option::explain
{
    my ($self, $level) = @_;
    say "\t"x$level, "Option: $self->{q{}}";
}

sub Latex::literal::explain
{
    my ($self, $level, $label) = @_;
    $label //= 'Literal';
    say "\t"x$level, "$label: ", $self->{q{}};
}

sub Latex::mathematical::explain {
    my ($self, $level) = @_;

    say "\t"x$level, "Mathematical:";
    for my $element (@{$self->{element}})
    {
        $element->explain($level+1);
        print "\n";
    }
}

sub Latex::comment::explain {
    my ($self, $level) = @_;

    say "\t"x$level, "Comment: $self->{q{}}";
}

sub Latex::vinculum::explain {
    my ($self, $level) = @_;

    say "\t"x$level, "Non-breaking space";
}

sub Latex::newline::explain {
    my ($self, $level) = @_;

    say "\t"x$level, "Newline";
}

sub Latex::super::explain {
    my ($self, $level) = @_;

    say "\t"x$level, "Superscript...";
}

sub Latex::sub::explain {
    my ($self, $level) = @_;

    say "\t"x$level, "Subscript...";
}

sub Latex::column_separator::explain {
    my ($self, $level) = @_;

    say "\t"x$level, "Column Break";
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
...is easy\footnote{But not\\ \emph{necessarily} simple}.
In fact it's $easy_peasy^2$ to do.
\end{document}
