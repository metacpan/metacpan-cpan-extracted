####################################################################
#
#    This file was generated using Parse::Yapp version 1.06.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Parse::Yapp::Parse;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 1 "YappParse.yp"

# Copyright © 1998, 1999, 2000, 2001, Francois Desarmenien.
# Copyright © 2017 William N. Braswell, Jr.
# All Rights Reserved.
# (see COPYRIGHT in Parse::Yapp.pm pod section for use and distribution rights)
#
# Parse/Yapp/Parser.yp: Parse::Yapp::Parser.pm source file
#
# Use: yapp -m 'Parse::Yapp::Parse' -o Parse/Yapp/Parse.pm YappParse.yp
#
# to generate the Parser module.
# 
#line 15 "YappParse.yp"

require 5.004;

use Carp;

my($input,$lexlevel,@lineno,$nberr,$prec,$labelno);
my($syms,$head,$tail,$token,$term,$nterm,$rules,$precterm,$start,$nullable);
my($expect);



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.06',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			"%%" => -6,
			'UNION' => 1,
			'START' => 3,
			'ASSOC' => 8,
			'EXPECT' => 9,
			"\n" => 7,
			'TOKEN' => 14,
			'error' => 13,
			'HEADCODE' => 10,
			'TYPE' => 11
		},
		GOTOS => {
			'decls' => 12,
			'decl' => 2,
			'head' => 4,
			'headsec' => 5,
			'yapp' => 6
		}
	},
	{#State 1
		ACTIONS => {
			'CODE' => 15
		}
	},
	{#State 2
		DEFAULT => -9
	},
	{#State 3
		ACTIONS => {
			'IDENT' => 16
		},
		GOTOS => {
			'ident' => 17
		}
	},
	{#State 4
		ACTIONS => {
			'error' => 22,
			'IDENT' => 23,
			"%%" => 21
		},
		GOTOS => {
			'rulesec' => 20,
			'body' => 19,
			'rules' => 18
		}
	},
	{#State 5
		ACTIONS => {
			"%%" => 24
		}
	},
	{#State 6
		ACTIONS => {
			'' => 25
		}
	},
	{#State 7
		DEFAULT => -10
	},
	{#State 8
		ACTIONS => {
			"<" => 26
		},
		DEFAULT => -19,
		GOTOS => {
			'typedecl' => 27
		}
	},
	{#State 9
		ACTIONS => {
			'NUMBER' => 28
		}
	},
	{#State 10
		ACTIONS => {
			"\n" => 29
		}
	},
	{#State 11
		ACTIONS => {
			"<" => 26
		},
		DEFAULT => -19,
		GOTOS => {
			'typedecl' => 30
		}
	},
	{#State 12
		ACTIONS => {
			'UNION' => 1,
			"%%" => -7,
			'START' => 3,
			"\n" => 7,
			'EXPECT' => 9,
			'ASSOC' => 8,
			'TYPE' => 11,
			'HEADCODE' => 10,
			'TOKEN' => 14,
			'error' => 13
		},
		GOTOS => {
			'decl' => 31
		}
	},
	{#State 13
		ACTIONS => {
			"\n" => 32
		}
	},
	{#State 14
		ACTIONS => {
			"<" => 26
		},
		DEFAULT => -19,
		GOTOS => {
			'typedecl' => 33
		}
	},
	{#State 15
		ACTIONS => {
			"\n" => 34
		}
	},
	{#State 16
		DEFAULT => -4
	},
	{#State 17
		ACTIONS => {
			"\n" => 35
		}
	},
	{#State 18
		DEFAULT => -28
	},
	{#State 19
		ACTIONS => {
			'TAILCODE' => 36
		},
		DEFAULT => -45,
		GOTOS => {
			'tail' => 37
		}
	},
	{#State 20
		ACTIONS => {
			'error' => 22,
			'IDENT' => 23,
			"%%" => 39
		},
		GOTOS => {
			'rules' => 38
		}
	},
	{#State 21
		DEFAULT => -26
	},
	{#State 22
		ACTIONS => {
			";" => 40
		}
	},
	{#State 23
		ACTIONS => {
			":" => 41
		}
	},
	{#State 24
		DEFAULT => -5
	},
	{#State 25
		DEFAULT => 0
	},
	{#State 26
		ACTIONS => {
			'IDENT' => 42
		}
	},
	{#State 27
		ACTIONS => {
			'LITERAL' => 44,
			'IDENT' => 16
		},
		GOTOS => {
			'symbol' => 43,
			'symlist' => 45,
			'ident' => 46
		}
	},
	{#State 28
		ACTIONS => {
			"\n" => 47
		}
	},
	{#State 29
		DEFAULT => -14
	},
	{#State 30
		ACTIONS => {
			'IDENT' => 16
		},
		GOTOS => {
			'identlist' => 48,
			'ident' => 49
		}
	},
	{#State 31
		DEFAULT => -8
	},
	{#State 32
		DEFAULT => -18
	},
	{#State 33
		ACTIONS => {
			'IDENT' => 16,
			'LITERAL' => 44
		},
		GOTOS => {
			'symbol' => 43,
			'ident' => 46,
			'symlist' => 50
		}
	},
	{#State 34
		DEFAULT => -15
	},
	{#State 35
		DEFAULT => -13
	},
	{#State 36
		DEFAULT => -46
	},
	{#State 37
		DEFAULT => -1
	},
	{#State 38
		DEFAULT => -27
	},
	{#State 39
		DEFAULT => -25
	},
	{#State 40
		DEFAULT => -30
	},
	{#State 41
		ACTIONS => {
			'IDENT' => 16,
			'CODE' => 52,
			'LITERAL' => 44
		},
		DEFAULT => -35,
		GOTOS => {
			'rule' => 54,
			'rhselt' => 55,
			'ident' => 46,
			'code' => 53,
			'rhselts' => 51,
			'rhss' => 57,
			'symbol' => 58,
			'rhs' => 56
		}
	},
	{#State 42
		ACTIONS => {
			">" => 59
		}
	},
	{#State 43
		DEFAULT => -22
	},
	{#State 44
		DEFAULT => -2
	},
	{#State 45
		ACTIONS => {
			"\n" => 60,
			'IDENT' => 16,
			'LITERAL' => 44
		},
		GOTOS => {
			'ident' => 46,
			'symbol' => 61
		}
	},
	{#State 46
		DEFAULT => -3
	},
	{#State 47
		DEFAULT => -17
	},
	{#State 48
		ACTIONS => {
			'IDENT' => 16,
			"\n" => 62
		},
		GOTOS => {
			'ident' => 63
		}
	},
	{#State 49
		DEFAULT => -24
	},
	{#State 50
		ACTIONS => {
			'LITERAL' => 44,
			"\n" => 64,
			'IDENT' => 16
		},
		GOTOS => {
			'ident' => 46,
			'symbol' => 61
		}
	},
	{#State 51
		ACTIONS => {
			'LITERAL' => 44,
			'IDENT' => 16,
			'CODE' => 52
		},
		DEFAULT => -36,
		GOTOS => {
			'ident' => 46,
			'code' => 53,
			'symbol' => 58,
			'rhselt' => 65
		}
	},
	{#State 52
		DEFAULT => -44
	},
	{#State 53
		DEFAULT => -40
	},
	{#State 54
		DEFAULT => -32
	},
	{#State 55
		DEFAULT => -38
	},
	{#State 56
		ACTIONS => {
			'PREC' => 67
		},
		DEFAULT => -34,
		GOTOS => {
			'prec' => 66
		}
	},
	{#State 57
		ACTIONS => {
			";" => 69,
			"|" => 68
		}
	},
	{#State 58
		DEFAULT => -39
	},
	{#State 59
		DEFAULT => -20
	},
	{#State 60
		DEFAULT => -12
	},
	{#State 61
		DEFAULT => -21
	},
	{#State 62
		DEFAULT => -16
	},
	{#State 63
		DEFAULT => -23
	},
	{#State 64
		DEFAULT => -11
	},
	{#State 65
		DEFAULT => -37
	},
	{#State 66
		ACTIONS => {
			'CODE' => 52
		},
		DEFAULT => -42,
		GOTOS => {
			'epscode' => 71,
			'code' => 70
		}
	},
	{#State 67
		ACTIONS => {
			'LITERAL' => 44,
			'IDENT' => 16
		},
		GOTOS => {
			'ident' => 46,
			'symbol' => 72
		}
	},
	{#State 68
		ACTIONS => {
			'LITERAL' => 44,
			'CODE' => 52,
			'IDENT' => 16
		},
		DEFAULT => -35,
		GOTOS => {
			'rhs' => 56,
			'rhselts' => 51,
			'code' => 53,
			'ident' => 46,
			'rhselt' => 55,
			'symbol' => 58,
			'rule' => 73
		}
	},
	{#State 69
		DEFAULT => -29
	},
	{#State 70
		DEFAULT => -43
	},
	{#State 71
		DEFAULT => -33
	},
	{#State 72
		DEFAULT => -41
	},
	{#State 73
		DEFAULT => -31
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'yapp', 3, undef
	],
	[#Rule 2
		 'symbol', 1,
sub
#line 33 "YappParse.yp"
{
                        exists($$syms{$_[1][0]})
                    or  do {
                        $$syms{$_[1][0]} = $_[1][1];
                        $$term{$_[1][0]} = undef;
                    };
                    $_[1]
                }
	],
	[#Rule 3
		 'symbol', 1, undef
	],
	[#Rule 4
		 'ident', 1,
sub
#line 44 "YappParse.yp"
{
                        exists($$syms{$_[1][0]})
                    or  do {
                        $$syms{$_[1][0]} = $_[1][1];
                        $$term{$_[1][0]} = undef;
                    };
                    $_[1]
                }
	],
	[#Rule 5
		 'head', 2, undef
	],
	[#Rule 6
		 'headsec', 0, undef
	],
	[#Rule 7
		 'headsec', 1, undef
	],
	[#Rule 8
		 'decls', 2, undef
	],
	[#Rule 9
		 'decls', 1, undef
	],
	[#Rule 10
		 'decl', 1, undef
	],
	[#Rule 11
		 'decl', 4,
sub
#line 69 "YappParse.yp"
{
                for (@{$_[3]}) {
                    my($symbol,$lineno)=@$_;

                        exists($$token{$symbol})
                    and do {
                        _SyntaxError(0,
                                "Token $symbol redefined: ".
                                "Previously defined line $$syms{$symbol}",
                                $lineno);
                        next;
                    };
                    $$token{$symbol}=$lineno;
                    $$term{$symbol} = [ ];
                }
                undef
            }
	],
	[#Rule 12
		 'decl', 4,
sub
#line 87 "YappParse.yp"
{
                for (@{$_[3]}) {
                    my($symbol,$lineno)=@$_;

                        defined($$term{$symbol}[0])
                    and do {
                        _SyntaxError(1,
                            "Precedence for symbol $symbol redefined: ".
                            "Previously defined line $$syms{$symbol}",
                            $lineno);
                        next;
                    };
                    $$token{$symbol}=$lineno;
                    $$term{$symbol} = [ $_[1][0], $prec ];
                }
                ++$prec;
                undef
            }
	],
	[#Rule 13
		 'decl', 3,
sub
#line 105 "YappParse.yp"
{ $start=$_[2][0]; undef }
	],
	[#Rule 14
		 'decl', 2,
sub
#line 106 "YappParse.yp"
{ push(@$head,$_[1]); undef }
	],
	[#Rule 15
		 'decl', 3,
sub
#line 107 "YappParse.yp"
{ undef }
	],
	[#Rule 16
		 'decl', 4,
sub
#line 109 "YappParse.yp"
{
                for ( @{$_[3]} ) {
                    my($symbol,$lineno)=@$_;

                        exists($$nterm{$symbol})
                    and do {
                        _SyntaxError(0,
                                "Non-terminal $symbol redefined: ".
                                "Previously defined line $$syms{$symbol}",
                                $lineno);
                        next;
                    };
                    delete($$term{$symbol});   #not a terminal
                    $$nterm{$symbol}=undef;    #is a non-terminal
                }
            }
	],
	[#Rule 17
		 'decl', 3,
sub
#line 125 "YappParse.yp"
{ $expect=$_[2][0]; undef }
	],
	[#Rule 18
		 'decl', 2,
sub
#line 126 "YappParse.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 19
		 'typedecl', 0, undef
	],
	[#Rule 20
		 'typedecl', 3, undef
	],
	[#Rule 21
		 'symlist', 2,
sub
#line 133 "YappParse.yp"
{ push(@{$_[1]},$_[2]); $_[1] }
	],
	[#Rule 22
		 'symlist', 1,
sub
#line 134 "YappParse.yp"
{ [ $_[1] ] }
	],
	[#Rule 23
		 'identlist', 2,
sub
#line 137 "YappParse.yp"
{ push(@{$_[1]},$_[2]); $_[1] }
	],
	[#Rule 24
		 'identlist', 1,
sub
#line 138 "YappParse.yp"
{ [ $_[1] ] }
	],
	[#Rule 25
		 'body', 2,
sub
#line 143 "YappParse.yp"
{
                    $start
                or  $start=$$rules[1][0];

                    ref($$nterm{$start})
                or  _SyntaxError(2,"Start symbol $start not found ".
                                   "in rules section",$_[2][1]);

                $$rules[0]=[ '$start', [ $start, chr(0) ], undef, undef ];
            }
	],
	[#Rule 26
		 'body', 1,
sub
#line 153 "YappParse.yp"
{ _SyntaxError(2,"No rules in input grammar",$_[1][1]); }
	],
	[#Rule 27
		 'rulesec', 2, undef
	],
	[#Rule 28
		 'rulesec', 1, undef
	],
	[#Rule 29
		 'rules', 4,
sub
#line 160 "YappParse.yp"
{ _AddRules($_[1],$_[3]); undef }
	],
	[#Rule 30
		 'rules', 2,
sub
#line 161 "YappParse.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 31
		 'rhss', 3,
sub
#line 164 "YappParse.yp"
{ push(@{$_[1]},$_[3]); $_[1] }
	],
	[#Rule 32
		 'rhss', 1,
sub
#line 165 "YappParse.yp"
{ [ $_[1] ] }
	],
	[#Rule 33
		 'rule', 3,
sub
#line 168 "YappParse.yp"
{ push(@{$_[1]}, $_[2], $_[3]); $_[1] }
	],
	[#Rule 34
		 'rule', 1,
sub
#line 169 "YappParse.yp"
{
                                my($code)=undef;

                                    defined($_[1])
                                and $_[1][-1][0] eq 'CODE'
                                and $code = ${pop(@{$_[1]})}[1];

                                push(@{$_[1]}, undef, $code);

                                $_[1]
                            }
	],
	[#Rule 35
		 'rhs', 0, undef
	],
	[#Rule 36
		 'rhs', 1, undef
	],
	[#Rule 37
		 'rhselts', 2,
sub
#line 186 "YappParse.yp"
{ push(@{$_[1]},$_[2]); $_[1] }
	],
	[#Rule 38
		 'rhselts', 1,
sub
#line 187 "YappParse.yp"
{ [ $_[1] ] }
	],
	[#Rule 39
		 'rhselt', 1,
sub
#line 190 "YappParse.yp"
{ [ 'SYMB', $_[1] ] }
	],
	[#Rule 40
		 'rhselt', 1,
sub
#line 191 "YappParse.yp"
{ [ 'CODE', $_[1] ] }
	],
	[#Rule 41
		 'prec', 2,
sub
#line 195 "YappParse.yp"
{
                       	defined($$term{$_[2][0]})
                    or  do {
                        _SyntaxError(1,"No precedence for symbol $_[2][0]",
                                         $_[2][1]);
                        return undef;
                    };

                    ++$$precterm{$_[2][0]};
                    $$term{$_[2][0]}[1];
				}
	],
	[#Rule 42
		 'epscode', 0,
sub
#line 208 "YappParse.yp"
{ undef }
	],
	[#Rule 43
		 'epscode', 1,
sub
#line 209 "YappParse.yp"
{ $_[1] }
	],
	[#Rule 44
		 'code', 1,
sub
#line 212 "YappParse.yp"
{ $_[1] }
	],
	[#Rule 45
		 'tail', 0, undef
	],
	[#Rule 46
		 'tail', 1,
sub
#line 218 "YappParse.yp"
{ $tail=$_[1] }
	]
],
                                  @_);
    bless($self,$class);
}

#line 221 "YappParse.yp"

sub _Error {
    my($value)=$_[0]->YYCurval;

    my($what)= $token ? "input: '$$value[0]'" : "end of input";

    _SyntaxError(1,"Unexpected $what",$$value[1]);
}

sub _Lexer {
 
    #At EOF
        pos($$input) >= length($$input)
    and return('',[ undef, -1 ]);

    #In TAIL section
        $lexlevel > 1
    and do {
        my($pos)=pos($$input);

        $lineno[0]=$lineno[1];
        $lineno[1]=-1;
        pos($$input)=length($$input);
        return('TAILCODE',[ substr($$input,$pos), $lineno[0] ]);
    };

    #Skip blanks
            $lexlevel == 0
        ?   $$input=~m{\G((?:
                                [\t\ ]+    # Any white space char but \n
                            |   \#[^\n]*  # Perl like comments
                            |   /\*.*?\*/ # C like comments
                            )+)}xsgc
        :   $$input=~m{\G((?:
                                \s+       # any white space char
                            |   \#[^\n]*  # Perl like comments
                            |   /\*.*?\*/ # C like comments
                            )+)}xsgc
    and do {
        my($blanks)=$1;

        #Maybe At EOF
            pos($$input) >= length($$input)
        and return('',[ undef, -1 ]);

        $lineno[1]+= $blanks=~tr/\n//;
    };

    $lineno[0]=$lineno[1];

        $$input=~/\G([A-Za-z_][A-Za-z0-9_]*)/gc
    and return('IDENT',[ $1, $lineno[0] ]);

        $$input=~/\G('(?:[^'\\]|\\\\|\\'|\\)+?')/gc
    and do {
            $1 eq "'error'"
        and do {
            _SyntaxError(0,"Literal 'error' ".
                           "will be treated as error token",$lineno[0]);
            return('IDENT',[ 'error', $lineno[0] ]);
        };
        return('LITERAL',[ $1, $lineno[0] ]);
    };

        $$input=~/\G(%%)/gc
    and do {
        ++$lexlevel;
        return($1, [ $1, $lineno[0] ]);
    };

        $$input=~/\G\{/gc
    and do {
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
        return('CODE',[ $code, $lineno[0] ]);
    };

    if($lexlevel == 0) {# In head section
            $$input=~/\G%(left|right|nonassoc)/gc
        and return('ASSOC',[ uc($1), $lineno[0] ]);
            $$input=~/\G%(start)/gc
        and return('START',[ undef, $lineno[0] ]);
            $$input=~/\G%(expect)/gc
        and return('EXPECT',[ undef, $lineno[0] ]);
            $$input=~/\G%\{/gc
        and do {
            my($code);

                $$input=~/\G(.*?)%}/sgc
            or  _SyntaxError(2,"Unmatched %{ opened line $lineno[0]",-1);

            $code=$1;
            $lineno[1]+= $code=~tr/\n//;
            return('HEADCODE',[ $code, $lineno[0] ]);
        };
            $$input=~/\G%(token)/gc
        and return('TOKEN',[ undef, $lineno[0] ]);
            $$input=~/\G%(type)/gc
        and return('TYPE',[ undef, $lineno[0] ]);
            $$input=~/\G%(union)/gc
        and return('UNION',[ undef, $lineno[0] ]);
            $$input=~/\G([0-9]+)/gc
        and return('NUMBER',[ $1, $lineno[0] ]);

    }
    else {# In rule section
            $$input=~/\G%(prec)/gc
        and return('PREC',[ undef, $lineno[0] ]);
    }

    #Always return something
        $$input=~/\G(.)/sg
    or  die "Parse::Yapp::Grammar::Parse: Match (.) failed: report as a BUG";

        $1 eq "\n"
    and ++$lineno[1];

    ( $1 ,[ $1, $lineno[0] ]);

}

sub _SyntaxError {
    my($level,$message,$lineno)=@_;

    $message= "*".
              [ 'Warning', 'Error', 'Fatal' ]->[$level].
              "* $message, at ".
              ($lineno < 0 ? "eof" : "line $lineno").
              ".\n";

        $level > 1
    and die $message;

    warn $message;

        $level > 0
    and ++$nberr;

        $nberr == 20 
    and die "*Fatal* Too many errors detected.\n"
}

sub _AddRules {
    my($lhs,$lineno)=@{$_[0]};
    my($rhss)=$_[1];

        ref($$nterm{$lhs})
    and do {
        _SyntaxError(1,"Non-terminal $lhs redefined: ".
                       "Previously declared line $$syms{$lhs}",$lineno);
        return;
    };

        ref($$term{$lhs})
    and do {
        my($where) = exists($$token{$lhs}) ? $$token{$lhs} : $$syms{$lhs};
        _SyntaxError(1,"Non-terminal $lhs previously ".
                       "declared as token line $where",$lineno);
        return;
    };

        ref($$nterm{$lhs})      #declared through %type
    or  do {
            $$syms{$lhs}=$lineno;   #Say it's declared here
            delete($$term{$lhs});   #No more a terminal
    };
    $$nterm{$lhs}=[];       #It's a non-terminal now

    my($epsrules)=0;        #To issue a warning if more than one epsilon rule

    for my $rhs (@$rhss) {
        my($tmprule)=[ $lhs, [ ], splice(@$rhs,-2) ]; #Init rule

            @$rhs
        or  do {
            ++$$nullable{$lhs};
            ++$epsrules;
        };

        for (0..$#$rhs) {
            my($what,$value)=@{$$rhs[$_]};

                $what eq 'CODE'
            and do {
                my($name)='@'.++$labelno."-$_";
                push(@$rules,[ $name, [], undef, $value ]);
                push(@{$$tmprule[1]},$name);
                next;
            };
            push(@{$$tmprule[1]},$$value[0]);
        }
        push(@$rules,$tmprule);
        push(@{$$nterm{$lhs}},$#$rules);
    }

        $epsrules > 1
    and _SyntaxError(0,"More than one empty rule for symbol $lhs",$lineno);
}

sub Parse {
    my($self)=shift;

        @_ > 0
    or  croak("No input grammar\n");

    my($parsed)={};

    $input=\$_[0];

    $lexlevel=0;
    @lineno=(1,1);
    $nberr=0;
    $prec=0;
    $labelno=0;

    $head=();
    $tail="";

    $syms={};
    $token={};
    $term={};
    $nterm={};
    $rules=[ undef ];   #reserve slot 0 for start rule
    $precterm={};

    $start="";
    $nullable={};
    $expect=0;

    pos($$input)=0;


    $self->YYParse(yylex => \&_Lexer, yyerror => \&_Error);

        $nberr
    and _SyntaxError(2,"Errors detected: No output",-1);

    @$parsed{ 'HEAD', 'TAIL', 'RULES', 'NTERM', 'TERM',
              'NULL', 'PREC', 'SYMS',  'START', 'EXPECT' }
    =       (  $head,  $tail,  $rules,  $nterm,  $term,
               $nullable, $precterm, $syms, $start, $expect);

    undef($input);
    undef($lexlevel);
    undef(@lineno);
    undef($nberr);
    undef($prec);
    undef($labelno);

    undef($head);
    undef($tail);

    undef($syms);
    undef($token);
    undef($term);
    undef($nterm);
    undef($rules);
    undef($precterm);

    undef($start);
    undef($nullable);
    undef($expect);

    $parsed
}


1;
