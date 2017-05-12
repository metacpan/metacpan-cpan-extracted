package Parse::Eyapp::Cleaner;
use warnings;
use strict;
use Scalar::Util qw{reftype};

my $lexlevel = 0;  # Used by the lexical analyzer. Controls in which section we are:
my (
  $input,
             # head (0), body(1) or tail (2)
  @lineno,   # Used by the lexical analyzer. $lineno[0] is the line number for 
             # the beginning of the token, $lineno[1] the end
  $nberr,    # Number of errors up to now
);

my $filename;
my $bypass = 0;

sub trim {
  $_[0] =~ s/\s+$//;
  $_[0] =~ s/^\s+//;
}

sub controller {
  my $ouput = '';

  local $/= undef;
  $$input = <>;

  while () {

   my ($token, $attr) =  _Lexer();

   last unless $token;

   if ($token eq '.') {
     ($token, $attr) =  _Lexer();
     next;
   }
   next unless defined(reftype($attr)) && defined($attr->[0]);
   print $attr->[0] unless ($token =~ /(CODE)|\$/);
  } 
  print "\n";
}

{

  my $output = '';

  sub _generate {
    $output .= sprintf "%s"x@_, @_;
  }

  sub ppcontroller {
    $input = shift;
    my %args = @_;

    my $skipcomments = $args{skipcomments}? '|COMMENT' : '';

    my $depth = 0;

    my $delete_set = 'CODE|BLANKS|DEFAULTACTION|\n|\$'.$skipcomments;
    $delete_set = qr{$delete_set};

    my $end_cr_set = qr{\n\s*$|^\s*$};


    my $ouput = '';

    my ($ptoken, $pattr) = ('', ['', -1]);
    while () {

     my ($token, $attr) =  _Lexer();

     last unless $token;

     next if $token eq '$';
     next unless defined(reftype($attr)) && defined($attr->[0]);

     if ($token eq '.') {                 # attribute name
       ($token, $attr) =  _Lexer();
     }
     elsif ($token eq 'NAME') {
       trim($attr->[0]);
       my $g = ($depth == 0)? "\n      " : " ";
       _generate $attr->[0].$g;
     }
     elsif ($token =~ /\b(VARIABLE)\b/) {
       my $g = ($output =~ $end_cr_set)? '': "\n"; 
       $attr->[0] =~ s/\s*:\s*$/:/; # remove blanks before and after colon
       _generate $g.$attr->[0]."\n      ";
     }
     elsif ($token =~ /\b(IDENT|LITERAL|NUMBER|REGEXP)\b/) {
       _generate $attr->[0]." ";
     }
     elsif ($token =~ /(PREC|STAR\b|PLUS|OPTION|[)(])/) {
       $depth++ if $token eq '(';
       $depth-- if $token eq ')';
       _generate $attr->[0]." ";
     }
     elsif ($token =~ /\b(TOKEN|ASSOC|CONFLICT|SYNTACTIC|SEMANTIC|STRICT|START|EXPECT|NAMINGSCHEME|LEXER|UNION)\b/) {
       my $g = ($output =~ $end_cr_set)? '': "\n"; 
       _generate $g.$attr->[0]." ";
     }
     elsif ($token =~ /TREE/) {
       _generate "\n".$attr->[0]."\n";
     }
     elsif ($token eq ':') {
       _generate ":\n      ";
     }
     elsif ($token eq '|') {
       $output =~ s/[ \t]*$//;
       my $g = ($output =~ $end_cr_set)? '': "\n"; 
       _generate "$g    | ";
       #_generate "\n  ".$attr->[0]." ";
     }
     elsif ($token eq ';') {
       my $g;
       if ($output =~ m{[:|]\s*$}) {
         $g = "/* empty */\n";
       }
       elsif ($output =~ $end_cr_set) {
         $g = '';
       }
       else {
         $g =  "\n"; 
       }
       _generate "$g;\n";
     }
     elsif ($token eq '%%') {
       my $g = ($output =~ $end_cr_set)? '': "\n"; 
       _generate "$g\n%%\n\n"; 
     }
     else {
       _generate $attr->[0] unless ($token =~ $delete_set);
     }
     ($ptoken, $pattr) =  ($token, $attr);
    } 
    _generate "\n";

    $output =~ s/\s*\Z/\n/;
    return $output;
  }
} # end closure

sub slurp_perl_code {
  my($level,$from,$code);

  $from=pos($$input);

  $level=1;
  while($$input=~/([{}])/gc) {
          substr($$input,pos($$input)-1,1) eq '\\' #Quoted
      and next;
          $level += ($1 eq '{' ? 1 : -1)
      or last;
  }
      $level
  and  _SyntaxError(2,"Unmatched { opened line $lineno[0]",-1);
  $code = substr($$input,$from,pos($$input)-$from-1);
  $lineno[1]+= $code=~tr/\n//;
  return [ $code, $lineno[0] ];
}


sub _Lexer {
 
    #At EOF
        pos($$input) && (pos($$input) >= length($$input))
    and return('',[ '', -1 ]);

    #In TAIL section
        $lexlevel > 1
    and do {
        my($pos)=pos($$input);

        $lineno[0]=$lineno[1];
        $lineno[1]=-1;
        pos($$input)=length($$input);
    };

    #Skip blanks
            $lexlevel == 0
        ?   $$input=~m{\G((?:             # Head section: \n separates declarations
                                [\t\ ]+   # Any white space char but \n
                            )+)}xsgc
        :   $$input=~m{\G((?:
                                \s+       # any white space char, including \n
                            )+)}xsgc
    and do {
        my($blanks)=$1;

        #Maybe At EOF
            pos($$input) >= length($$input)
        and return('',[ $blanks, -1 ]);

        $lineno[1]+= $blanks=~tr/\n//;
        return ('BLANKS', [ $blanks, $lineno[0]]);
    };

    $$input=~m{\G((?:
                      \#[^\n]*\s*  # Perl like comments
                    | /\*.*?\*/\s* # C like comments
                   )+)}xsgc
    and do {
        my($blanks)=$1;

        #Maybe At EOF
            pos($$input) >= length($$input)
        and return('',[ $blanks, -1 ]);

        $lineno[1]+= $blanks=~tr/\n//;
        trim($blanks);
        return ('COMMENT', [ $blanks, $lineno[0]]);
    };

    $lineno[0]=$lineno[1];

        $$input=~/\G([A-Za-z_][A-Za-z0-9_]*\s*:)/gc
    and return('VARIABLE',[ $1, $lineno[0] ]);

        $$input=~/\G([A-Za-z_][A-Za-z0-9_]*)/gc
    and return('IDENT',[ $1, $lineno[0] ]);

        $$input =~ m{\G(
           /             # opening slash
             (?:[^/\\]|    # an ordinary character
                  \\\\|    # escaped \ i.e. \\
                   \\/|    # escaped slash i.e. \/
                    \\     # escape i.e. \
             )*?           # non greedy repetitions
           /               # closing slash
          )
        }xgc and return('REGEXP',[ $1, $lineno[0] ]);


        $$input=~/\G( '                # opening apostrophe
                         (?:[^'\\]|    # an ordinary character
                              \\\\|    # escaped \ i.e. \\
                               \\'|    # escaped apostrophe i.e. \'
                                \\     # escape i.e. \
                        )*?            # non greedy repetitions
                      '                # closing apostrophe
                    )/gxc
    and do {
        my $string = $1;

        # The string 'error' is reserved for the special token 'error'
            $string eq "'error'"
        and do {
            _SyntaxError(0,"Literal 'error' ".
                           "will be treated as error token",$lineno[0]);
            return('IDENT',[ 'error', $lineno[0] ]);
        };

        my $lines = $string =~ tr/\n//;
        _SyntaxError(2, "Constant string $string contains newlines",$lineno[0]) if $lines;
        $lineno[1] += $lines;
        return('LITERAL',[ $string, $lineno[0] ]);
    };

    # New section: body or tail
        $$input=~/\G(%%)/gc
    and do {
        ++$lexlevel;
        return($1, [ $1, $lineno[0] ]);
    };


        $$input=~/\G%begin\s*{/gc
    and do {
        return ('BEGINCODE', &slurp_perl_code());
    };

        $$input=~/\G{/gc
    and do {
        &slurp_perl_code();
    };

    if($lexlevel == 0) {# In head section
            $$input=~/\G(%(left|right|nonassoc))/gc
        and return('ASSOC',[ $1, $lineno[0] ]);

            $$input=~/\G(%start)/gc
        and return('START',[ $1, $lineno[0] ]);

            $$input=~/\G(%expect)/gc
        and return('EXPECT',[ $1, $lineno[0] ]);

            $$input=~/\G(%namingscheme)/gc
        and return('NAMINGSCHEME',[ $1, $lineno[0] ]);

            $$input=~/\G%{/gc
        and do {
            my($code);

                $$input=~/\G(.*?)%}/sgc
            or  _SyntaxError(2,"Unmatched %{ opened line $lineno[0]",-1);

            $code=$1;
            $lineno[1]+= $code=~tr/\n//;
            return('HEADCODE',[ $code, $lineno[0] ]);
        };
            $$input=~/\G(%token)/gc
        and return('TOKEN',[ $1, $lineno[0] ]);

            $$input=~/\G(%conflict)/gc
        and return('CONFLICT',[ $1, $lineno[0] ]);


            $$input=~/\G(%strict)/gc
        and return('STRICT',[ $1, $lineno[0] ]);

            $$input=~/\G(%semantic\s+token)/gc
        and return('SEMANTIC',[ $1, $lineno[0] ]);

            $$input=~/\G(%syntactic\s+token)/gc
        and return('SYNTACTIC',[ $1, $lineno[0] ]);

            $$input=~/\G(%type)/gc
        and return('TYPE',[ $1, $lineno[0] ]);

            $$input=~/\G%prefix\s+([A-Za-z_][A-Za-z0-9_:]*::)/gc
        and return('PREFIX',[ $1, $lineno[0] ]);

            $$input=~/\G(%union)/gc
        and return('UNION',[ $1, $lineno[0] ]);

            $$input=~/\G(%lexer)/gc
        and return('LEXER',[ $1, $lineno[0] ]);

            $$input=~/\G(%defaultaction)/gc
        and return('DEFAULTACTION',[ $1, $lineno[0] ]);

            $$input=~/\G(%tree((?:\s+(?:bypass|alias)){0,2}))/gc
        and do {
          my $treeoptions =  defined($2)? $2 : '';
          return('TREE',[ $1, $lineno[0] ])
        };

            $$input=~/\G(%metatree)/gc
        and return('METATREE',[ $1, $lineno[0] ]);

            $$input=~/\G([0-9]+)/gc
        and return('NUMBER',[ $1, $lineno[0] ]);

    }
    else {# In rule section
            $$input=~/\G(%prec)/gc
        and return('PREC',[ $1, $lineno[0] ]);

            $$input=~/\G((<\s*%name\s*([A-Za-z_][A-Za-z0-9_]*)\s*)?\*\s*>)/gc
        and return('STAR',[ $1, $lineno[0] ]);

            $$input=~/\G((%name\s*([A-Za-z_][A-Za-z0-9_]*)\s*)?\*)/gc
        and return('STAR',[ $1, $lineno[0] ]);

            $$input=~/\G((<\s*%name\s*([A-Za-z_][A-Za-z0-9_]*)\s*)?\+\s*>)/gc
        and return('PLUS',[ $1, $lineno[0] ]);

            $$input=~/\G((%name\s*([A-Za-z_][A-Za-z0-9_]*)\s*)?\+)/gc
        and return('PLUS',[ $1, $lineno[0] ]);

            $$input=~/\G((<\s*%name\s*([A-Za-z_][A-Za-z0-9_]*)\s*)?\?\s*)>/gc
        and return('OPTION',[ $1, $lineno[0] ]);

            $$input=~/\G((%name\s*([A-Za-z_][A-Za-z0-9_]*)\s*)?\?)/gc
        and return('OPTION',[ $1, $lineno[0] ]);

            $$input=~/\G(%no\s+bypass\s+[A-Za-z_][A-Za-z0-9_]*\s*)/gc
        and do {
          return('NAME',[ $1, $lineno[0] ]);
        };

            $$input=~/\G(%name\s+[\w:]*\n?)/gc
        and do {
          return('NAME',[ $1, $lineno[0] ]);
        };
    }

    #Always return something
        $$input=~/\G(.)/sg
    or  return ('', ['', -1]);

        $1 eq "\n"
    and ++$lineno[1];

    ( $1 ,[ $1, $lineno[0] ]);

}

sub _SyntaxError {
    my($level,$message,$lineno)=@_;

    $message= "*".
              [ 'Warning', 'Error', 'Fatal' ]->[$level].
              "* $message, at ".
              ($lineno < 0 ? "eof" : "line $lineno")." at file $filename\n";

        $level > 1
    and die $message;

    warn $message;

        $level > 0
    and ++$nberr;

        $nberr == 20 
    and die "*Fatal* Too many errors detected.\n"
}

1;

