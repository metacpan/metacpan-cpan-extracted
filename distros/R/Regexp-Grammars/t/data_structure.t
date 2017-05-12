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
        <file>

        <objrule: file>
            <[element]>*

        <objrule: element>
            <command> | <literal>

        <objrule: command>
            \\  <name=literal>  <options>?  <args>?

        <objrule: options>
            \[  <[option]> ** (,)  \]

        <objrule: args>
            \{  <[element]>*  \}

        <objrule: option>
            [^][\$&%#_{}~^\s,]+

        <objrule: literal>
            [^][\$&%#_{}~^\s]+

    }xms
};

my $target = {
      "" => "\\documentclass[a4paper,11pt]{article}\n\\usepackage{latexsym}\n\\author{D. Conway}\n\\title{Parsing \\LaTeX{}}\n\\begin{document}\n\\maketitle\n\\tableofcontents\n\\section{Description}\n...is easy \\footnote{But not \\emph{necessarily} simple}.\n\\end{document}",
      "file" => bless({
        "" => "\\documentclass[a4paper,11pt]{article}\n\\usepackage{latexsym}\n\\author{D. Conway}\n\\title{Parsing \\LaTeX{}}\n\\begin{document}\n\\maketitle\n\\tableofcontents\n\\section{Description}\n...is easy \\footnote{But not \\emph{necessarily} simple}.\n\\end{document}",
        "check" => "check",
        "element" => [
          bless({
            "" => "\\documentclass[a4paper,11pt]{article}",
            "command" => bless({
              "" => "\\documentclass[a4paper,11pt]{article}",
              "args" => bless({
                "" => "{article}",
                
                "element" => [
                  bless({
                    "" => "article",
                    
                    "literal" => bless({ "" => "article", }, "literal"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "documentclass", }, "literal"),
              "options" => bless({
                "" => "[a4paper,11pt]",
                
                "option" => [
                  bless({ "" => "a4paper", }, "option"),
                  bless({ "" => "11pt", }, "option"),
                ],
              }, "options"),
            }, "command"),
          }, "element"),
          bless({
            "" => "\n\\usepackage{latexsym}",
            
            "command" => bless({
              "" => "\\usepackage{latexsym}",
              
              "args" => bless({
                "" => "{latexsym}",
                
                "element" => [
                  bless({
                    "" => "latexsym",
                    
                    "literal" => bless({ "" => "latexsym", }, "literal"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "usepackage", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "" => "\n\\author{D. Conway}",
            
            "command" => bless({
              "" => "\\author{D. Conway}",
              
              "args" => bless({
                "" => "{D. Conway}",
                
                "element" => [
                  bless({
                    "" => "D.",
                    
                    "literal" => bless({ "" => "D.", }, "literal"),
                  }, "element"),
                  bless({
                    "" => " Conway",
                    
                    "literal" => bless({ "" => "Conway", }, "literal"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "author", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "" => "\n\\title{Parsing \\LaTeX{}}",
            
            "command" => bless({
              "" => "\\title{Parsing \\LaTeX{}}",
              
              "args" => bless({
                "" => "{Parsing \\LaTeX{}}",
                
                "element" => [
                  bless({
                    "" => "Parsing",
                    
                    "literal" => bless({ "" => "Parsing", }, "literal"),
                  }, "element"),
                  bless({
                    "" => " \\LaTeX{}",
                    
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
            "" => "\n\\begin{document}",
            
            "command" => bless({
              "" => "\\begin{document}",
              
              "args" => bless({
                "" => "{document}",
                
                "element" => [
                  bless({
                    "" => "document",
                    
                    "literal" => bless({ "" => "document", }, "literal"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "begin", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "" => "\n\\maketitle\n",
            
            "command" => bless({
              "" => "\\maketitle\n",
              
              "name" => bless({ "" => "maketitle", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "" => "\\tableofcontents\n",
            
            "command" => bless({
              "" => "\\tableofcontents\n",
              
              "name" => bless({ "" => "tableofcontents", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "" => "\\section{Description}",
            
            "command" => bless({
              "" => "\\section{Description}",
              
              "args" => bless({
                "" => "{Description}",
                
                "element" => [
                  bless({
                    "" => "Description",
                    
                    "literal" => bless({ "" => "Description", }, "literal"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "section", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "" => "\n...is",
            
            "literal" => bless({ "" => "...is", }, "literal"),
          }, "element"),
          bless({
            "" => " easy",
            
            "literal" => bless({ "" => "easy", }, "literal"),
          }, "element"),
          bless({
            "" => " \\footnote{But not \\emph{necessarily} simple}",
            
            "command" => bless({
              "" => "\\footnote{But not \\emph{necessarily} simple}",
              
              "args" => bless({
                "" => "{But not \\emph{necessarily} simple}",
                
                "element" => [
                  bless({
                    "" => "But",
                    
                    "literal" => bless({ "" => "But", }, "literal"),
                  }, "element"),
                  bless({
                    "" => " not",
                    
                    "literal" => bless({ "" => "not", }, "literal"),
                  }, "element"),
                  bless({
                    "" => " \\emph{necessarily}",
                    
                    "command" => bless({
                      "" => "\\emph{necessarily}",
                      
                      "args" => bless({
                        "" => "{necessarily}",
                        
                        "element" => [
                          bless({
                            "" => "necessarily",
                            
                            "literal" => bless({ "" => "necessarily", }, "literal"),
                          }, "element"),
                        ],
                      }, "args"),
                      "name" => bless({ "" => "emph", }, "literal"),
                    }, "command"),
                  }, "element"),
                  bless({
                    "" => " simple",
                    
                    "literal" => bless({ "" => "simple", }, "literal"),
                  }, "element"),
                ],
              }, "args"),
              "name" => bless({ "" => "footnote", }, "literal"),
            }, "command"),
          }, "element"),
          bless({
            "" => ".",
            
            "literal" => bless({ "" => ".", }, "literal"),
          }, "element"),
          bless({
            "" => "\n\\end{document}",
            
            "command" => bless({
              "" => "\\end{document}",
              
              "args" => bless({
                "" => "{document}",
                
                "element" => [
                  bless({
                    "" => "document",
                    
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

ok +($input =~ $parser)    => 'Matched';
is_deeply \%/, $target     => 'Returned correct data structure';
is $/{""}, $original_input => 'Captured entire text';


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
