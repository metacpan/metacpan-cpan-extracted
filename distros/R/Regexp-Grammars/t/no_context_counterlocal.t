use 5.010;
use warnings;

use Test::More;
plan 'no_plan';


# Use this class declaration to check that classes with ctors
# actually call the ctor when objrules use them...
{ package file;

  sub new {
    my ($class, $data_ref) = @_;
    my $new_obj = bless {'check'=>'check',%{$data_ref}}, $class;
    return $new_obj;
  }
}

my $parser = do{
    use Regexp::Grammars;
    qr{
        <nocontext:>
        <file>

        <objrule: file>
            <context:>
            <[element]>*

        <objrule: element>
            <command> | <literal>

        <objrule: command>
            <context:>
            \\  <name=literal>  <options>?  <args>?

        <objrule: options>
            \[  <[option]> ** (,)  \]

        <objrule: args>
            <context:>
            \{  <[element]>*  \}

        <objrule: option>
            <context:>
            [^][\$&%#_{}~^\s,]+

        <objrule: literal>
            [^][\$&%#_{}~^\s]+

    }xms
};

my $target = {
      "file" => bless({
        "" => "\\documentclass[a4paper,11pt]{article}\n\\usepackage{latexsym}\n\\author{D. Conway}\n\\title{Parsing \\LaTeX{}}\n\\begin{document}\n\\maketitle\n\\tableofcontents\n\\section{Description}\n...is easy \\footnote{But not \\emph{necessarily} simple}.\n\\end{document}",
        "check" => "check",
        "element" => [
          bless({
            "command" => bless({
              "" => "\\documentclass[a4paper,11pt]{article}",
              "args" => bless({
                "" => "{article}",

                "element" => [
                  bless({

                    "literal" => bless({ "" => "article", }, "literal"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "documentclass", }, "literal"),
              "options" => bless({
                "option" => [
                  bless({ "" => "a4paper", }, "option"),
                  bless({ "" => "11pt", }, "option"),
                ],
              }, "options"),
            }, "command"),
          }, "element"),
          bless({
            "command" => bless({
              "" => "\\usepackage{latexsym}",

              "args" => bless({
                "" => "{latexsym}",

                "element" => [
                  bless({
                    "literal" => bless({ "" => "latexsym", }, "literal"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "usepackage", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "command" => bless({
              "" => "\\author{D. Conway}",

              "args" => bless({
                "" => "{D. Conway}",

                "element" => [
                  bless({
                    "literal" => bless({ "" => "D.", }, "literal"),
                  }, "element"),
                  bless({
                    "literal" => bless({ "" => "Conway", }, "literal"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "author", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "command" => bless({
              "" => "\\title{Parsing \\LaTeX{}}",

              "args" => bless({
                "" => "{Parsing \\LaTeX{}}",

                "element" => [
                  bless({
                    "literal" => bless({ "" => "Parsing", }, "literal"),
                  }, "element"),
                  bless({
                    "command" => bless({
                      "" => "\\LaTeX{}",

                      "args" => bless({ "" => "{}", }, "args"),
                      "name" => bless({ "" => "LaTeX", }, "literal"),
                    }, "command"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "title", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "command" => bless({
              "" => "\\begin{document}",

              "args" => bless({
                "" => "{document}",

                "element" => [
                  bless({
                    "literal" => bless({ "" => "document", }, "literal"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "begin", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "command" => bless({
              "" => "\\maketitle\n",

              "name" => bless({ "" => "maketitle", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "command" => bless({
              "" => "\\tableofcontents\n",

              "name" => bless({ "" => "tableofcontents", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "command" => bless({
              "" => "\\section{Description}",

              "args" => bless({
                "" => "{Description}",

                "element" => [
                  bless({
                    "literal" => bless({ "" => "Description", }, "literal"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "section", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "literal" => bless({ "" => "...is", }, "literal"),
          }, "element"),
          bless({
            "literal" => bless({ "" => "easy", }, "literal"),
          }, "element"),
          bless({
            "command" => bless({
              "" => "\\footnote{But not \\emph{necessarily} simple}",

              "args" => bless({
                "" => "{But not \\emph{necessarily} simple}",

                "element" => [
                  bless({
                    "literal" => bless({ "" => "But", }, "literal"),
                  }, "element"),
                  bless({
                    "literal" => bless({ "" => "not", }, "literal"),
                  }, "element"),
                  bless({
                    "command" => bless({
                      "" => "\\emph{necessarily}",

                      "args" => bless({
                        "" => "{necessarily}",

                        "element" => [
                          bless({
                            "literal" => bless({ "" => "necessarily", }, "literal"),
                          }, "element"),
                        ],
                      }, "args"),
                      "name" => bless({ "" => "emph", }, "literal"),
                    }, "command"),
                  }, "element"),
                  bless({
                    "literal" => bless({ "" => "simple", }, "literal"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "footnote", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "literal" => bless({ "" => ".", }, "literal"),
          }, "element"),
          bless({
            "command" => bless({
              "" => "\\end{document}",

              "args" => bless({
                "" => "{document}",

                "element" => [
                  bless({
                    "literal" => bless({ "" => "document", }, "literal"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "end", }, "literal"),
            }, "command"),
          }, "element"),
        ],
      }, "file"),
};

my $input = do{ local $/; <DATA>};
chomp $input;
my $original_input = $input;

ok +($input =~ $parser) => 'Matched';
is_deeply \%/, $target  => 'Returned correct data structure';
ok ! exists $/{""}      => "Didn't capture entire text";


__DATA__
\documentclass[a4paper,11pt]{article}
\usepackage{latexsym}
\author{D. Conway}
\title{Parsing \LaTeX{}}
\begin{document}
\maketitle
\tableofcontents
\section{Description}
...is easy \footnote{But not \emph{necessarily} simple}.
\end{document}
