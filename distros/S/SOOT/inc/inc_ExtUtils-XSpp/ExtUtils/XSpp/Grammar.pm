####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package ExtUtils::XSpp::Grammar;
use vars qw ( @ISA );
use strict;

@ISA= qw ( ExtUtils::XSpp::Grammar::YappDriver );
#Included Parse/Yapp/Driver.pm file----------------------------------------
{
#
# Module ExtUtils::XSpp::Grammar::YappDriver
#
# This module is part of the Parse::Yapp package available on your
# nearest CPAN
#
# Any use of this module in a standalone parser make the included
# text under the same copyright as the Parse::Yapp module itself.
#
# This notice should remain unchanged.
#
# (c) Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package ExtUtils::XSpp::Grammar::YappDriver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

$VERSION = '1.05';
$COMPATIBLE = '0.07';
$FILENAME=__FILE__;

use Carp;

#Known parameters, all starting with YY (leading YY will be discarded)
my(%params)=(YYLEX => 'CODE', 'YYERROR' => 'CODE', YYVERSION => '',
			 YYRULES => 'ARRAY', YYSTATES => 'ARRAY', YYDEBUG => '');
#Mandatory parameters
my(@params)=('LEX','RULES','STATES');

sub new {
    my($class)=shift;
	my($errst,$nberr,$token,$value,$check,$dotpos);
    my($self)={ ERROR => \&_Error,
				ERRST => \$errst,
                NBERR => \$nberr,
				TOKEN => \$token,
				VALUE => \$value,
				DOTPOS => \$dotpos,
				STACK => [],
				DEBUG => 0,
				CHECK => \$check };

	_CheckParams( [], \%params, \@_, $self );

		exists($$self{VERSION})
	and	$$self{VERSION} < $COMPATIBLE
	and	croak "Yapp driver version $VERSION ".
			  "incompatible with version $$self{VERSION}:\n".
			  "Please recompile parser module.";

        ref($class)
    and $class=ref($class);

    bless($self,$class);
}

sub YYParse {
    my($self)=shift;
    my($retval);

	_CheckParams( \@params, \%params, \@_, $self );

	if($$self{DEBUG}) {
		_DBLoad();
		$retval = eval '$self->_DBParse()';#Do not create stab entry on compile
        $@ and die $@;
	}
	else {
		$retval = $self->_Parse();
	}
    $retval
}

sub YYData {
	my($self)=shift;

		exists($$self{USER})
	or	$$self{USER}={};

	$$self{USER};
	
}

sub YYErrok {
	my($self)=shift;

	${$$self{ERRST}}=0;
    undef;
}

sub YYNberr {
	my($self)=shift;

	${$$self{NBERR}};
}

sub YYRecovering {
	my($self)=shift;

	${$$self{ERRST}} != 0;
}

sub YYAbort {
	my($self)=shift;

	${$$self{CHECK}}='ABORT';
    undef;
}

sub YYAccept {
	my($self)=shift;

	${$$self{CHECK}}='ACCEPT';
    undef;
}

sub YYError {
	my($self)=shift;

	${$$self{CHECK}}='ERROR';
    undef;
}

sub YYSemval {
	my($self)=shift;
	my($index)= $_[0] - ${$$self{DOTPOS}} - 1;

		$index < 0
	and	-$index <= @{$$self{STACK}}
	and	return $$self{STACK}[$index][1];

	undef;	#Invalid index
}

sub YYCurtok {
	my($self)=shift;

        @_
    and ${$$self{TOKEN}}=$_[0];
    ${$$self{TOKEN}};
}

sub YYCurval {
	my($self)=shift;

        @_
    and ${$$self{VALUE}}=$_[0];
    ${$$self{VALUE}};
}

sub YYExpect {
    my($self)=shift;

    keys %{$self->{STATES}[$self->{STACK}[-1][0]]{ACTIONS}}
}

sub YYLexer {
    my($self)=shift;

	$$self{LEX};
}


#################
# Private stuff #
#################


sub _CheckParams {
	my($mandatory,$checklist,$inarray,$outhash)=@_;
	my($prm,$value);
	my($prmlst)={};

	while(($prm,$value)=splice(@$inarray,0,2)) {
        $prm=uc($prm);
			exists($$checklist{$prm})
		or	croak("Unknow parameter '$prm'");
			ref($value) eq $$checklist{$prm}
		or	croak("Invalid value for parameter '$prm'");
        $prm=unpack('@2A*',$prm);
		$$outhash{$prm}=$value;
	}
	for (@$mandatory) {
			exists($$outhash{$_})
		or	croak("Missing mandatory parameter '".lc($_)."'");
	}
}

sub _Error {
	print "Parse error.\n";
}

sub _DBLoad {
	{
		no strict 'refs';

			exists(${__PACKAGE__.'::'}{_DBParse})#Already loaded ?
		and	return;
	}
	my($fname)=__FILE__;
	my(@drv);
	open(DRV,"<$fname") or die "Report this as a BUG: Cannot open $fname";
	while(<DRV>) {
                	/^\s*sub\s+_Parse\s*{\s*$/ .. /^\s*}\s*#\s*_Parse\s*$/
        	and     do {
                	s/^#DBG>//;
                	push(@drv,$_);
        	}
	}
	close(DRV);

	$drv[0]=~s/_P/_DBP/;
	eval join('',@drv);
}

#Note that for loading debugging version of the driver,
#this file will be parsed from 'sub _Parse' up to '}#_Parse' inclusive.
#So, DO NOT remove comment at end of sub !!!
sub _Parse {
    my($self)=shift;

	my($rules,$states,$lex,$error)
     = @$self{ 'RULES', 'STATES', 'LEX', 'ERROR' };
	my($errstatus,$nberror,$token,$value,$stack,$check,$dotpos)
     = @$self{ 'ERRST', 'NBERR', 'TOKEN', 'VALUE', 'STACK', 'CHECK', 'DOTPOS' };

#DBG>	my($debug)=$$self{DEBUG};
#DBG>	my($dbgerror)=0;

#DBG>	my($ShowCurToken) = sub {
#DBG>		my($tok)='>';
#DBG>		for (split('',$$token)) {
#DBG>			$tok.=		(ord($_) < 32 or ord($_) > 126)
#DBG>					?	sprintf('<%02X>',ord($_))
#DBG>					:	$_;
#DBG>		}
#DBG>		$tok.='<';
#DBG>	};

	$$errstatus=0;
	$$nberror=0;
	($$token,$$value)=(undef,undef);
	@$stack=( [ 0, undef ] );
	$$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

#DBG>	print STDERR ('-' x 40),"\n";
#DBG>		$debug & 0x2
#DBG>	and	print STDERR "In state $stateno:\n";
#DBG>		$debug & 0x08
#DBG>	and	print STDERR "Stack:[".
#DBG>					 join(',',map { $$_[0] } @$stack).
#DBG>					 "]\n";


        if  (exists($$actions{ACTIONS})) {

				defined($$token)
            or	do {
				($$token,$$value)=&$lex($self);
#DBG>				$debug & 0x01
#DBG>			and	print STDERR "Need token. Got ".&$ShowCurToken."\n";
			};

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
#DBG>			$debug & 0x01
#DBG>		and	print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

#DBG>				$debug & 0x04
#DBG>			and	print STDERR "Shift and go to state $act.\n";

					$$errstatus
				and	do {
					--$$errstatus;

#DBG>					$debug & 0x10
#DBG>				and	$dbgerror
#DBG>				and	$$errstatus == 0
#DBG>				and	do {
#DBG>					print STDERR "**End of Error recovery.\n";
#DBG>					$dbgerror=0;
#DBG>				};
				};


                push(@$stack,[ $act, $$value ]);

					$$token ne ''	#Don't eat the eof
				and	$$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

#DBG>			$debug & 0x04
#DBG>		and	$act
#DBG>		and	print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

                $act
            or  $self->YYAccept();

            $$dotpos=$len;

                unpack('A1',$lhs) eq '@'    #In line rule
            and do {
                    $lhs =~ /^\@[0-9]+\-([0-9]+)$/
                or  die "In line rule name '$lhs' ill formed: ".
                        "report it as a BUG.\n";
                $$dotpos = $1;
            };

            @sempar =       $$dotpos
                        ?   map { $$_[1] } @$stack[ -$$dotpos .. -1 ]
                        :   ();

            $semval = $code ? &$code( $self, @sempar )
                            : @sempar ? $sempar[0] : undef;

            splice(@$stack,-$len,$len);

                $$check eq 'ACCEPT'
            and do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Accept.\n";

				return($semval);
			};

                $$check eq 'ABORT'
            and	do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Abort.\n";

				return(undef);

			};

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
#DBG>				$debug & 0x04
#DBG>			and	print STDERR 
#DBG>				    "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

#DBG>				$debug & 0x10
#DBG>			and	$dbgerror
#DBG>			and	$$errstatus == 0
#DBG>			and	do {
#DBG>				print STDERR "**End of Error recovery.\n";
#DBG>				$dbgerror=0;
#DBG>			};

			    push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

#DBG>			$debug & 0x10
#DBG>		and	do {
#DBG>			print STDERR "**Entering Error recovery.\n";
#DBG>			++$dbgerror;
#DBG>		};

            ++$$nberror;

        };

			$$errstatus == 3	#The next token is not valid: discard it
		and	do {
				$$token eq ''	# End of input: no hope
			and	do {
#DBG>				$debug & 0x10
#DBG>			and	print STDERR "**At eof: aborting.\n";
				return(undef);
			};

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

			$$token=$$value=undef;
		};

        $$errstatus=3;

		while(	  @$stack
			  and (		not exists($$states[$$stack[-1][0]]{ACTIONS})
			        or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
					or	$$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Pop state $$stack[-1][0].\n";

			pop(@$stack);
		}

			@$stack
		or	do {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**No state left on stack: aborting.\n";

			return(undef);
		};

		#shift the error token

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Shift \$error token and go to state ".
#DBG>						 $$states[$$stack[-1][0]]{ACTIONS}{error}.
#DBG>						 ".\n";

		push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
	croak("Error in driver logic. Please, report it as a BUG");

}#_Parse
#DO NOT remove comment

1;

}
#End of include--------------------------------------------------




sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'ID' => 25,
			'p_typemap' => 4,
			'p_any' => 3,
			'OPSPECIAL' => 30,
			'COMMENT' => 6,
			'p_exceptionmap' => 33,
			"class" => 8,
			'RAW_CODE' => 34,
			"const" => 10,
			"int" => 37,
			'p_module' => 15,
			'p_package' => 44,
			"enum" => 43,
			'p_loadplugin' => 42,
			'PREPROCESSOR' => 16,
			"short" => 17,
			'p_file' => 46,
			"unsigned" => 47,
			'p_name' => 19,
			'p_include' => 20,
			"long" => 21,
			"char" => 24
		},
		GOTOS => {
			'perc_loadplugin' => 26,
			'class_name' => 1,
			'top_list' => 2,
			'perc_package' => 29,
			'function' => 28,
			'nconsttype' => 27,
			'looks_like_function' => 5,
			'exceptionmap' => 31,
			'special_block_start' => 32,
			'perc_name' => 7,
			'class_decl' => 35,
			'typemap' => 9,
			'enum' => 36,
			'decorate_class' => 11,
			'special_block' => 12,
			'perc_module' => 38,
			'type_name' => 13,
			'perc_file' => 41,
			'perc_any' => 40,
			'basic_type' => 39,
			'template' => 14,
			'looks_like_renamed_function' => 45,
			'top' => 18,
			'function_decl' => 48,
			'perc_include' => 49,
			'directive' => 50,
			'type' => 22,
			'class' => 23,
			'raw' => 51
		}
	},
	{#State 1
		ACTIONS => {
			'OPANG' => 52
		},
		DEFAULT => -119
	},
	{#State 2
		ACTIONS => {
			'ID' => 25,
			'' => 53,
			'p_typemap' => 4,
			'p_any' => 3,
			'OPSPECIAL' => 30,
			'COMMENT' => 6,
			'p_exceptionmap' => 33,
			"class" => 8,
			'RAW_CODE' => 34,
			"const" => 10,
			"int" => 37,
			'p_module' => 15,
			"enum" => 43,
			'p_package' => 44,
			'p_loadplugin' => 42,
			'PREPROCESSOR' => 16,
			"short" => 17,
			'p_file' => 46,
			"unsigned" => 47,
			'p_name' => 19,
			'p_include' => 20,
			"long" => 21,
			"char" => 24
		},
		GOTOS => {
			'perc_loadplugin' => 26,
			'class_name' => 1,
			'function' => 28,
			'perc_package' => 29,
			'nconsttype' => 27,
			'looks_like_function' => 5,
			'exceptionmap' => 31,
			'special_block_start' => 32,
			'perc_name' => 7,
			'class_decl' => 35,
			'typemap' => 9,
			'enum' => 36,
			'decorate_class' => 11,
			'special_block' => 12,
			'perc_module' => 38,
			'type_name' => 13,
			'perc_file' => 41,
			'perc_any' => 40,
			'basic_type' => 39,
			'template' => 14,
			'looks_like_renamed_function' => 45,
			'top' => 54,
			'function_decl' => 48,
			'perc_include' => 49,
			'directive' => 50,
			'type' => 22,
			'class' => 23,
			'raw' => 51
		}
	},
	{#State 3
		ACTIONS => {
			'OPSPECIAL' => 30,
			'OPCURLY' => 55
		},
		DEFAULT => -109,
		GOTOS => {
			'special_block' => 56,
			'special_block_start' => 32
		}
	},
	{#State 4
		ACTIONS => {
			'OPCURLY' => 57
		}
	},
	{#State 5
		DEFAULT => -75
	},
	{#State 6
		DEFAULT => -25
	},
	{#State 7
		ACTIONS => {
			'ID' => 25,
			"class" => 8,
			"short" => 17,
			"const" => 10,
			"unsigned" => 47,
			"long" => 21,
			"int" => 37,
			"char" => 24
		},
		GOTOS => {
			'type_name' => 13,
			'class_name' => 1,
			'basic_type' => 39,
			'nconsttype' => 27,
			'template' => 14,
			'looks_like_function' => 58,
			'class_decl' => 59,
			'type' => 22
		}
	},
	{#State 8
		ACTIONS => {
			'ID' => 60
		}
	},
	{#State 9
		DEFAULT => -14
	},
	{#State 10
		ACTIONS => {
			'ID' => 25,
			"short" => 17,
			"unsigned" => 47,
			"long" => 21,
			"int" => 37,
			"char" => 24
		},
		GOTOS => {
			'type_name' => 13,
			'class_name' => 1,
			'basic_type' => 39,
			'nconsttype' => 61,
			'template' => 14
		}
	},
	{#State 11
		ACTIONS => {
			'SEMICOLON' => 62
		}
	},
	{#State 12
		DEFAULT => -27
	},
	{#State 13
		DEFAULT => -117
	},
	{#State 14
		DEFAULT => -118
	},
	{#State 15
		ACTIONS => {
			'OPCURLY' => 63
		}
	},
	{#State 16
		DEFAULT => -26
	},
	{#State 17
		ACTIONS => {
			"int" => 64
		},
		DEFAULT => -126
	},
	{#State 18
		DEFAULT => -1
	},
	{#State 19
		ACTIONS => {
			'OPCURLY' => 65
		}
	},
	{#State 20
		ACTIONS => {
			'OPCURLY' => 66
		}
	},
	{#State 21
		ACTIONS => {
			"int" => 67
		},
		DEFAULT => -125
	},
	{#State 22
		ACTIONS => {
			'ID' => 68
		}
	},
	{#State 23
		DEFAULT => -4
	},
	{#State 24
		DEFAULT => -123
	},
	{#State 25
		ACTIONS => {
			'DCOLON' => 70
		},
		DEFAULT => -132,
		GOTOS => {
			'class_suffix' => 69
		}
	},
	{#State 26
		ACTIONS => {
			'SEMICOLON' => 71
		}
	},
	{#State 27
		ACTIONS => {
			'STAR' => 73,
			'AMP' => 72
		},
		DEFAULT => -114
	},
	{#State 28
		DEFAULT => -7
	},
	{#State 29
		ACTIONS => {
			'SEMICOLON' => 74
		}
	},
	{#State 30
		DEFAULT => -164
	},
	{#State 31
		DEFAULT => -15
	},
	{#State 32
		ACTIONS => {
			'CLSPECIAL' => 75,
			'line' => 76
		},
		GOTOS => {
			'special_block_end' => 77,
			'lines' => 78
		}
	},
	{#State 33
		ACTIONS => {
			'OPCURLY' => 79
		}
	},
	{#State 34
		DEFAULT => -24
	},
	{#State 35
		ACTIONS => {
			'SEMICOLON' => 80
		}
	},
	{#State 36
		DEFAULT => -6
	},
	{#State 37
		DEFAULT => -124
	},
	{#State 38
		ACTIONS => {
			'SEMICOLON' => 81
		}
	},
	{#State 39
		DEFAULT => -120
	},
	{#State 40
		ACTIONS => {
			'SEMICOLON' => 82
		}
	},
	{#State 41
		ACTIONS => {
			'SEMICOLON' => 83
		}
	},
	{#State 42
		ACTIONS => {
			'OPCURLY' => 84
		}
	},
	{#State 43
		ACTIONS => {
			'ID' => 86,
			'OPCURLY' => 85
		}
	},
	{#State 44
		ACTIONS => {
			'OPCURLY' => 87
		}
	},
	{#State 45
		DEFAULT => -84,
		GOTOS => {
			'function_metadata' => 88
		}
	},
	{#State 46
		ACTIONS => {
			'OPCURLY' => 89
		}
	},
	{#State 47
		ACTIONS => {
			"short" => 17,
			"long" => 21,
			"int" => 37,
			"char" => 24
		},
		DEFAULT => -121,
		GOTOS => {
			'basic_type' => 90
		}
	},
	{#State 48
		ACTIONS => {
			'SEMICOLON' => 91
		}
	},
	{#State 49
		ACTIONS => {
			'SEMICOLON' => 92
		}
	},
	{#State 50
		DEFAULT => -5
	},
	{#State 51
		DEFAULT => -3
	},
	{#State 52
		ACTIONS => {
			'ID' => 25,
			"short" => 17,
			"unsigned" => 47,
			"const" => 10,
			"long" => 21,
			"int" => 37,
			"char" => 24
		},
		GOTOS => {
			'type_list' => 94,
			'type_name' => 13,
			'class_name' => 1,
			'basic_type' => 39,
			'nconsttype' => 27,
			'template' => 14,
			'type' => 93
		}
	},
	{#State 53
		DEFAULT => 0
	},
	{#State 54
		DEFAULT => -2
	},
	{#State 55
		ACTIONS => {
			'ID' => 97,
			'p_any' => 95
		},
		GOTOS => {
			'perc_any_arg' => 96,
			'perc_any_args' => 98
		}
	},
	{#State 56
		DEFAULT => -22,
		GOTOS => {
			'mixed_blocks' => 99
		}
	},
	{#State 57
		ACTIONS => {
			'ID' => 25,
			"short" => 17,
			"unsigned" => 47,
			"const" => 10,
			"long" => 21,
			"int" => 37,
			"char" => 24
		},
		GOTOS => {
			'type_name' => 13,
			'class_name' => 1,
			'basic_type' => 39,
			'nconsttype' => 27,
			'template' => 14,
			'type' => 100
		}
	},
	{#State 58
		DEFAULT => -76
	},
	{#State 59
		DEFAULT => -40
	},
	{#State 60
		ACTIONS => {
			'COLON' => 102
		},
		DEFAULT => -44,
		GOTOS => {
			'base_classes' => 101
		}
	},
	{#State 61
		ACTIONS => {
			'STAR' => 73,
			'AMP' => 72
		},
		DEFAULT => -113
	},
	{#State 62
		DEFAULT => -37
	},
	{#State 63
		ACTIONS => {
			'ID' => 25
		},
		GOTOS => {
			'class_name' => 103
		}
	},
	{#State 64
		DEFAULT => -128
	},
	{#State 65
		ACTIONS => {
			'ID' => 25
		},
		GOTOS => {
			'class_name' => 104
		}
	},
	{#State 66
		ACTIONS => {
			'ID' => 106,
			'DASH' => 107
		},
		GOTOS => {
			'file_name' => 105
		}
	},
	{#State 67
		DEFAULT => -127
	},
	{#State 68
		ACTIONS => {
			'OPPAR' => 108
		}
	},
	{#State 69
		ACTIONS => {
			'DCOLON' => 109
		},
		DEFAULT => -133
	},
	{#State 70
		ACTIONS => {
			'ID' => 110
		}
	},
	{#State 71
		DEFAULT => -11
	},
	{#State 72
		DEFAULT => -116
	},
	{#State 73
		DEFAULT => -115
	},
	{#State 74
		DEFAULT => -9
	},
	{#State 75
		DEFAULT => -165
	},
	{#State 76
		DEFAULT => -166
	},
	{#State 77
		DEFAULT => -163
	},
	{#State 78
		ACTIONS => {
			'CLSPECIAL' => 75,
			'line' => 111
		},
		GOTOS => {
			'special_block_end' => 112
		}
	},
	{#State 79
		ACTIONS => {
			'ID' => 113
		}
	},
	{#State 80
		DEFAULT => -36
	},
	{#State 81
		DEFAULT => -8
	},
	{#State 82
		DEFAULT => -13
	},
	{#State 83
		DEFAULT => -10
	},
	{#State 84
		ACTIONS => {
			'ID' => 25
		},
		GOTOS => {
			'class_name' => 114
		}
	},
	{#State 85
		DEFAULT => -30,
		GOTOS => {
			'enum_element_list' => 115
		}
	},
	{#State 86
		ACTIONS => {
			'OPCURLY' => 116
		}
	},
	{#State 87
		ACTIONS => {
			'ID' => 25
		},
		GOTOS => {
			'class_name' => 117
		}
	},
	{#State 88
		ACTIONS => {
			'p_code' => 123,
			'p_cleanup' => 119,
			'p_any' => 3,
			'p_catch' => 127,
			'p_postcall' => 121
		},
		DEFAULT => -77,
		GOTOS => {
			'perc_postcall' => 122,
			'perc_code' => 118,
			'perc_any' => 124,
			'perc_cleanup' => 125,
			'perc_catch' => 120,
			'_function_metadata' => 126
		}
	},
	{#State 89
		ACTIONS => {
			'ID' => 106,
			'DASH' => 107
		},
		GOTOS => {
			'file_name' => 128
		}
	},
	{#State 90
		DEFAULT => -122
	},
	{#State 91
		DEFAULT => -38
	},
	{#State 92
		DEFAULT => -12
	},
	{#State 93
		DEFAULT => -130
	},
	{#State 94
		ACTIONS => {
			'CLANG' => 129,
			'COMMA' => 130
		}
	},
	{#State 95
		DEFAULT => -22,
		GOTOS => {
			'mixed_blocks' => 131
		}
	},
	{#State 96
		DEFAULT => -110
	},
	{#State 97
		ACTIONS => {
			'CLCURLY' => 132
		}
	},
	{#State 98
		ACTIONS => {
			'p_any' => 95,
			'CLCURLY' => 134
		},
		GOTOS => {
			'perc_any_arg' => 133
		}
	},
	{#State 99
		ACTIONS => {
			'OPSPECIAL' => 30,
			'OPCURLY' => 135
		},
		DEFAULT => -108,
		GOTOS => {
			'simple_block' => 137,
			'special_block' => 136,
			'special_block_start' => 32
		}
	},
	{#State 100
		ACTIONS => {
			'CLCURLY' => 138
		}
	},
	{#State 101
		ACTIONS => {
			'COMMA' => 140
		},
		DEFAULT => -52,
		GOTOS => {
			'class_metadata' => 139
		}
	},
	{#State 102
		ACTIONS => {
			"protected" => 144,
			"private" => 143,
			"public" => 141
		},
		GOTOS => {
			'base_class' => 142
		}
	},
	{#State 103
		ACTIONS => {
			'CLCURLY' => 145
		}
	},
	{#State 104
		ACTIONS => {
			'CLCURLY' => 146
		}
	},
	{#State 105
		ACTIONS => {
			'CLCURLY' => 147
		}
	},
	{#State 106
		ACTIONS => {
			'DOT' => 149,
			'SLASH' => 148
		}
	},
	{#State 107
		DEFAULT => -138
	},
	{#State 108
		ACTIONS => {
			'ID' => 25,
			"short" => 17,
			"const" => 10,
			"unsigned" => 47,
			"long" => 21,
			"int" => 37,
			"char" => 24
		},
		DEFAULT => -143,
		GOTOS => {
			'type_name' => 13,
			'class_name' => 1,
			'basic_type' => 39,
			'nconsttype' => 27,
			'template' => 14,
			'arg_list' => 151,
			'argument' => 152,
			'type' => 150
		}
	},
	{#State 109
		ACTIONS => {
			'ID' => 153
		}
	},
	{#State 110
		DEFAULT => -136
	},
	{#State 111
		DEFAULT => -167
	},
	{#State 112
		DEFAULT => -162
	},
	{#State 113
		ACTIONS => {
			'CLCURLY' => 154
		}
	},
	{#State 114
		ACTIONS => {
			'CLCURLY' => 155
		}
	},
	{#State 115
		ACTIONS => {
			'ID' => 156,
			'PREPROCESSOR' => 16,
			'RAW_CODE' => 34,
			'OPSPECIAL' => 30,
			'COMMENT' => 6,
			'CLCURLY' => 158
		},
		GOTOS => {
			'enum_element' => 157,
			'special_block' => 12,
			'raw' => 159,
			'special_block_start' => 32
		}
	},
	{#State 116
		DEFAULT => -30,
		GOTOS => {
			'enum_element_list' => 160
		}
	},
	{#State 117
		ACTIONS => {
			'CLCURLY' => 161
		}
	},
	{#State 118
		DEFAULT => -91
	},
	{#State 119
		ACTIONS => {
			'OPSPECIAL' => 30
		},
		GOTOS => {
			'special_block' => 162,
			'special_block_start' => 32
		}
	},
	{#State 120
		DEFAULT => -94
	},
	{#State 121
		ACTIONS => {
			'OPSPECIAL' => 30
		},
		GOTOS => {
			'special_block' => 163,
			'special_block_start' => 32
		}
	},
	{#State 122
		DEFAULT => -93
	},
	{#State 123
		ACTIONS => {
			'OPSPECIAL' => 30
		},
		GOTOS => {
			'special_block' => 164,
			'special_block_start' => 32
		}
	},
	{#State 124
		DEFAULT => -95
	},
	{#State 125
		DEFAULT => -92
	},
	{#State 126
		DEFAULT => -83
	},
	{#State 127
		ACTIONS => {
			'OPCURLY' => 165
		}
	},
	{#State 128
		ACTIONS => {
			'CLCURLY' => 166
		}
	},
	{#State 129
		DEFAULT => -129
	},
	{#State 130
		ACTIONS => {
			'ID' => 25,
			"short" => 17,
			"unsigned" => 47,
			"const" => 10,
			"long" => 21,
			"int" => 37,
			"char" => 24
		},
		GOTOS => {
			'type_name' => 13,
			'class_name' => 1,
			'basic_type' => 39,
			'nconsttype' => 27,
			'template' => 14,
			'type' => 167
		}
	},
	{#State 131
		ACTIONS => {
			'OPCURLY' => 135,
			'OPSPECIAL' => 30,
			'SEMICOLON' => 168
		},
		GOTOS => {
			'simple_block' => 137,
			'special_block' => 136,
			'special_block_start' => 32
		}
	},
	{#State 132
		DEFAULT => -22,
		GOTOS => {
			'mixed_blocks' => 169
		}
	},
	{#State 133
		DEFAULT => -111
	},
	{#State 134
		DEFAULT => -106
	},
	{#State 135
		ACTIONS => {
			'ID' => 170
		}
	},
	{#State 136
		DEFAULT => -20
	},
	{#State 137
		DEFAULT => -21
	},
	{#State 138
		ACTIONS => {
			'OPCURLY' => 171,
			'SEMICOLON' => 172
		}
	},
	{#State 139
		ACTIONS => {
			'OPCURLY' => 173,
			'p_any' => 3,
			'p_catch' => 127
		},
		GOTOS => {
			'perc_any' => 175,
			'perc_catch' => 174
		}
	},
	{#State 140
		ACTIONS => {
			"protected" => 144,
			"private" => 143,
			"public" => 141
		},
		GOTOS => {
			'base_class' => 176
		}
	},
	{#State 141
		ACTIONS => {
			'ID' => 25,
			'p_name' => 19
		},
		GOTOS => {
			'perc_name' => 178,
			'class_name' => 177,
			'class_name_rename' => 179
		}
	},
	{#State 142
		DEFAULT => -42
	},
	{#State 143
		ACTIONS => {
			'ID' => 25,
			'p_name' => 19
		},
		GOTOS => {
			'perc_name' => 178,
			'class_name' => 177,
			'class_name_rename' => 180
		}
	},
	{#State 144
		ACTIONS => {
			'ID' => 25,
			'p_name' => 19
		},
		GOTOS => {
			'perc_name' => 178,
			'class_name' => 177,
			'class_name_rename' => 181
		}
	},
	{#State 145
		DEFAULT => -98
	},
	{#State 146
		DEFAULT => -96
	},
	{#State 147
		DEFAULT => -101
	},
	{#State 148
		ACTIONS => {
			'ID' => 106,
			'DASH' => 107
		},
		GOTOS => {
			'file_name' => 182
		}
	},
	{#State 149
		ACTIONS => {
			'ID' => 183
		}
	},
	{#State 150
		ACTIONS => {
			'ID' => 185,
			'p_length' => 184
		}
	},
	{#State 151
		ACTIONS => {
			'CLPAR' => 186,
			'COMMA' => 187
		}
	},
	{#State 152
		DEFAULT => -141
	},
	{#State 153
		DEFAULT => -137
	},
	{#State 154
		ACTIONS => {
			'OPCURLY' => 188
		}
	},
	{#State 155
		DEFAULT => -100
	},
	{#State 156
		ACTIONS => {
			'EQUAL' => 189
		},
		DEFAULT => -33
	},
	{#State 157
		ACTIONS => {
			'COMMA' => 190
		},
		DEFAULT => -31
	},
	{#State 158
		ACTIONS => {
			'SEMICOLON' => 191
		}
	},
	{#State 159
		DEFAULT => -35
	},
	{#State 160
		ACTIONS => {
			'ID' => 156,
			'PREPROCESSOR' => 16,
			'RAW_CODE' => 34,
			'OPSPECIAL' => 30,
			'COMMENT' => 6,
			'CLCURLY' => 192
		},
		GOTOS => {
			'enum_element' => 157,
			'special_block' => 12,
			'raw' => 159,
			'special_block_start' => 32
		}
	},
	{#State 161
		DEFAULT => -97
	},
	{#State 162
		DEFAULT => -103
	},
	{#State 163
		DEFAULT => -104
	},
	{#State 164
		DEFAULT => -102
	},
	{#State 165
		ACTIONS => {
			'ID' => 25
		},
		GOTOS => {
			'class_name' => 193,
			'class_name_list' => 194
		}
	},
	{#State 166
		DEFAULT => -99
	},
	{#State 167
		DEFAULT => -131
	},
	{#State 168
		DEFAULT => -112
	},
	{#State 169
		ACTIONS => {
			'OPSPECIAL' => 30,
			'OPCURLY' => 135
		},
		DEFAULT => -107,
		GOTOS => {
			'simple_block' => 137,
			'special_block' => 136,
			'special_block_start' => 32
		}
	},
	{#State 170
		ACTIONS => {
			'CLCURLY' => 195
		}
	},
	{#State 171
		ACTIONS => {
			'ID' => 196
		}
	},
	{#State 172
		DEFAULT => -18
	},
	{#State 173
		DEFAULT => -53,
		GOTOS => {
			'class_body_list' => 197
		}
	},
	{#State 174
		DEFAULT => -50
	},
	{#State 175
		DEFAULT => -51
	},
	{#State 176
		DEFAULT => -43
	},
	{#State 177
		DEFAULT => -48
	},
	{#State 178
		ACTIONS => {
			'ID' => 25
		},
		GOTOS => {
			'class_name' => 198
		}
	},
	{#State 179
		DEFAULT => -45
	},
	{#State 180
		DEFAULT => -47
	},
	{#State 181
		DEFAULT => -46
	},
	{#State 182
		DEFAULT => -140
	},
	{#State 183
		DEFAULT => -139
	},
	{#State 184
		ACTIONS => {
			'OPCURLY' => 199
		}
	},
	{#State 185
		ACTIONS => {
			'EQUAL' => 200
		},
		DEFAULT => -146
	},
	{#State 186
		ACTIONS => {
			"const" => 201
		},
		DEFAULT => -69,
		GOTOS => {
			'const' => 202
		}
	},
	{#State 187
		ACTIONS => {
			'ID' => 25,
			"short" => 17,
			"unsigned" => 47,
			"const" => 10,
			"long" => 21,
			"int" => 37,
			"char" => 24
		},
		GOTOS => {
			'argument' => 203,
			'type_name' => 13,
			'class_name' => 1,
			'basic_type' => 39,
			'nconsttype' => 27,
			'template' => 14,
			'type' => 150
		}
	},
	{#State 188
		ACTIONS => {
			'ID' => 25,
			"short" => 17,
			"unsigned" => 47,
			"long" => 21,
			"int" => 37,
			"char" => 24
		},
		GOTOS => {
			'type_name' => 205,
			'class_name' => 204,
			'basic_type' => 39
		}
	},
	{#State 189
		ACTIONS => {
			'ID' => 25,
			'INTEGER' => 208,
			'QUOTED_STRING' => 210,
			'DASH' => 212,
			'FLOAT' => 211
		},
		GOTOS => {
			'class_name' => 206,
			'value' => 209,
			'expression' => 207
		}
	},
	{#State 190
		DEFAULT => -32
	},
	{#State 191
		DEFAULT => -28
	},
	{#State 192
		ACTIONS => {
			'SEMICOLON' => 213
		}
	},
	{#State 193
		DEFAULT => -134
	},
	{#State 194
		ACTIONS => {
			'COMMA' => 214,
			'CLCURLY' => 215
		}
	},
	{#State 195
		DEFAULT => -23
	},
	{#State 196
		ACTIONS => {
			'CLCURLY' => 216
		}
	},
	{#State 197
		ACTIONS => {
			'ID' => 231,
			'p_typemap' => 4,
			'p_any' => 3,
			'OPSPECIAL' => 30,
			"virtual" => 232,
			'COMMENT' => 6,
			"class_static" => 218,
			"package_static" => 233,
			"public" => 219,
			'p_exceptionmap' => 33,
			'RAW_CODE' => 34,
			"const" => 10,
			"static" => 237,
			"int" => 37,
			"private" => 224,
			'CLCURLY' => 240,
			'PREPROCESSOR' => 16,
			"short" => 17,
			"unsigned" => 47,
			'p_name' => 19,
			'TILDE' => 227,
			"protected" => 228,
			"long" => 21,
			"char" => 24
		},
		GOTOS => {
			'class_name' => 1,
			'nconsttype' => 27,
			'looks_like_function' => 5,
			'static' => 217,
			'exceptionmap' => 234,
			'special_block_start' => 32,
			'perc_name' => 220,
			'typemap' => 221,
			'class_body_element' => 235,
			'method' => 236,
			'vmethod' => 222,
			'nmethod' => 223,
			'special_block' => 12,
			'access_specifier' => 225,
			'type_name' => 13,
			'ctor' => 226,
			'perc_any' => 238,
			'basic_type' => 39,
			'template' => 14,
			'virtual' => 239,
			'looks_like_renamed_function' => 241,
			'_vmethod' => 242,
			'type' => 22,
			'dtor' => 229,
			'raw' => 243,
			'method_decl' => 230
		}
	},
	{#State 198
		DEFAULT => -49
	},
	{#State 199
		ACTIONS => {
			'ID' => 244
		}
	},
	{#State 200
		ACTIONS => {
			'ID' => 25,
			'INTEGER' => 208,
			'QUOTED_STRING' => 210,
			'DASH' => 212,
			'FLOAT' => 211
		},
		GOTOS => {
			'class_name' => 206,
			'value' => 209,
			'expression' => 245
		}
	},
	{#State 201
		DEFAULT => -68
	},
	{#State 202
		DEFAULT => -74
	},
	{#State 203
		DEFAULT => -142
	},
	{#State 204
		DEFAULT => -119
	},
	{#State 205
		ACTIONS => {
			'CLCURLY' => 246
		}
	},
	{#State 206
		ACTIONS => {
			'OPPAR' => 247
		},
		DEFAULT => -151
	},
	{#State 207
		DEFAULT => -34
	},
	{#State 208
		DEFAULT => -147
	},
	{#State 209
		ACTIONS => {
			'AMP' => 248,
			'PIPE' => 249
		},
		DEFAULT => -156
	},
	{#State 210
		DEFAULT => -150
	},
	{#State 211
		DEFAULT => -149
	},
	{#State 212
		ACTIONS => {
			'INTEGER' => 250
		}
	},
	{#State 213
		DEFAULT => -29
	},
	{#State 214
		ACTIONS => {
			'ID' => 25
		},
		GOTOS => {
			'class_name' => 251
		}
	},
	{#State 215
		DEFAULT => -105
	},
	{#State 216
		ACTIONS => {
			'OPCURLY' => 252,
			'OPSPECIAL' => 30
		},
		DEFAULT => -161,
		GOTOS => {
			'special_blocks' => 254,
			'special_block' => 253,
			'special_block_start' => 32
		}
	},
	{#State 217
		ACTIONS => {
			'ID' => 25,
			"class_static" => 218,
			"package_static" => 233,
			"short" => 17,
			"unsigned" => 47,
			"const" => 10,
			'p_name' => 19,
			"long" => 21,
			"static" => 237,
			"int" => 37,
			"char" => 24
		},
		GOTOS => {
			'type_name' => 13,
			'class_name' => 1,
			'basic_type' => 39,
			'nconsttype' => 27,
			'template' => 14,
			'looks_like_function' => 5,
			'static' => 217,
			'perc_name' => 255,
			'looks_like_renamed_function' => 241,
			'nmethod' => 256,
			'type' => 22
		}
	},
	{#State 218
		DEFAULT => -72
	},
	{#State 219
		ACTIONS => {
			'COLON' => 257
		}
	},
	{#State 220
		ACTIONS => {
			'ID' => 231,
			"virtual" => 232,
			"short" => 17,
			"unsigned" => 47,
			"const" => 10,
			'p_name' => 19,
			'TILDE' => 227,
			"long" => 21,
			"int" => 37,
			"char" => 24
		},
		GOTOS => {
			'type_name' => 13,
			'class_name' => 1,
			'ctor' => 260,
			'basic_type' => 39,
			'nconsttype' => 27,
			'template' => 14,
			'looks_like_function' => 58,
			'virtual' => 239,
			'perc_name' => 258,
			'_vmethod' => 242,
			'dtor' => 261,
			'vmethod' => 259,
			'type' => 22
		}
	},
	{#State 221
		DEFAULT => -57
	},
	{#State 222
		DEFAULT => -65
	},
	{#State 223
		DEFAULT => -64
	},
	{#State 224
		ACTIONS => {
			'COLON' => 262
		}
	},
	{#State 225
		DEFAULT => -59
	},
	{#State 226
		DEFAULT => -66
	},
	{#State 227
		ACTIONS => {
			'ID' => 263
		}
	},
	{#State 228
		ACTIONS => {
			'COLON' => 264
		}
	},
	{#State 229
		DEFAULT => -67
	},
	{#State 230
		ACTIONS => {
			'SEMICOLON' => 265
		}
	},
	{#State 231
		ACTIONS => {
			'DCOLON' => 70,
			'OPPAR' => 266
		},
		DEFAULT => -132,
		GOTOS => {
			'class_suffix' => 69
		}
	},
	{#State 232
		DEFAULT => -70
	},
	{#State 233
		DEFAULT => -71
	},
	{#State 234
		DEFAULT => -58
	},
	{#State 235
		DEFAULT => -54
	},
	{#State 236
		DEFAULT => -55
	},
	{#State 237
		DEFAULT => -73
	},
	{#State 238
		ACTIONS => {
			'SEMICOLON' => 267
		}
	},
	{#State 239
		ACTIONS => {
			'ID' => 25,
			"virtual" => 232,
			"short" => 17,
			"unsigned" => 47,
			"const" => 10,
			'p_name' => 19,
			'TILDE' => 227,
			"long" => 21,
			"int" => 37,
			"char" => 24
		},
		GOTOS => {
			'type_name' => 13,
			'class_name' => 1,
			'basic_type' => 39,
			'nconsttype' => 27,
			'template' => 14,
			'looks_like_function' => 268,
			'virtual' => 271,
			'perc_name' => 269,
			'type' => 22,
			'dtor' => 270
		}
	},
	{#State 240
		DEFAULT => -41
	},
	{#State 241
		DEFAULT => -84,
		GOTOS => {
			'function_metadata' => 272
		}
	},
	{#State 242
		DEFAULT => -87
	},
	{#State 243
		DEFAULT => -56
	},
	{#State 244
		ACTIONS => {
			'CLCURLY' => 273
		}
	},
	{#State 245
		DEFAULT => -145
	},
	{#State 246
		ACTIONS => {
			'OPCURLY' => 274
		}
	},
	{#State 247
		ACTIONS => {
			'ID' => 25,
			'INTEGER' => 208,
			'QUOTED_STRING' => 210,
			'DASH' => 212,
			'FLOAT' => 211
		},
		DEFAULT => -155,
		GOTOS => {
			'class_name' => 206,
			'value_list' => 275,
			'value' => 276
		}
	},
	{#State 248
		ACTIONS => {
			'ID' => 25,
			'INTEGER' => 208,
			'QUOTED_STRING' => 210,
			'DASH' => 212,
			'FLOAT' => 211
		},
		GOTOS => {
			'class_name' => 206,
			'value' => 277
		}
	},
	{#State 249
		ACTIONS => {
			'ID' => 25,
			'INTEGER' => 208,
			'QUOTED_STRING' => 210,
			'DASH' => 212,
			'FLOAT' => 211
		},
		GOTOS => {
			'class_name' => 206,
			'value' => 278
		}
	},
	{#State 250
		DEFAULT => -148
	},
	{#State 251
		DEFAULT => -135
	},
	{#State 252
		ACTIONS => {
			'p_any' => 95
		},
		GOTOS => {
			'perc_any_arg' => 96,
			'perc_any_args' => 279
		}
	},
	{#State 253
		DEFAULT => -159
	},
	{#State 254
		ACTIONS => {
			'OPSPECIAL' => 30,
			'SEMICOLON' => 281
		},
		GOTOS => {
			'special_block' => 280,
			'special_block_start' => 32
		}
	},
	{#State 255
		ACTIONS => {
			'ID' => 25,
			"short" => 17,
			"unsigned" => 47,
			"const" => 10,
			"long" => 21,
			"int" => 37,
			"char" => 24
		},
		GOTOS => {
			'type_name' => 13,
			'class_name' => 1,
			'basic_type' => 39,
			'nconsttype' => 27,
			'template' => 14,
			'looks_like_function' => 58,
			'type' => 22
		}
	},
	{#State 256
		DEFAULT => -86
	},
	{#State 257
		DEFAULT => -61
	},
	{#State 258
		ACTIONS => {
			'ID' => 282,
			'TILDE' => 227,
			'p_name' => 19,
			"virtual" => 232
		},
		GOTOS => {
			'perc_name' => 258,
			'ctor' => 260,
			'_vmethod' => 242,
			'dtor' => 261,
			'vmethod' => 259,
			'virtual' => 239
		}
	},
	{#State 259
		DEFAULT => -88
	},
	{#State 260
		DEFAULT => -79
	},
	{#State 261
		DEFAULT => -81
	},
	{#State 262
		DEFAULT => -63
	},
	{#State 263
		ACTIONS => {
			'OPPAR' => 283
		}
	},
	{#State 264
		DEFAULT => -62
	},
	{#State 265
		DEFAULT => -39
	},
	{#State 266
		ACTIONS => {
			'ID' => 25,
			"short" => 17,
			"const" => 10,
			"unsigned" => 47,
			"long" => 21,
			"int" => 37,
			"char" => 24
		},
		DEFAULT => -143,
		GOTOS => {
			'type_name' => 13,
			'class_name' => 1,
			'basic_type' => 39,
			'nconsttype' => 27,
			'template' => 14,
			'arg_list' => 284,
			'argument' => 152,
			'type' => 150
		}
	},
	{#State 267
		DEFAULT => -60
	},
	{#State 268
		ACTIONS => {
			'EQUAL' => 285
		},
		DEFAULT => -84,
		GOTOS => {
			'function_metadata' => 286
		}
	},
	{#State 269
		ACTIONS => {
			'TILDE' => 227,
			'p_name' => 19,
			"virtual" => 232
		},
		GOTOS => {
			'perc_name' => 269,
			'dtor' => 261,
			'virtual' => 271
		}
	},
	{#State 270
		DEFAULT => -82
	},
	{#State 271
		ACTIONS => {
			'TILDE' => 227,
			'p_name' => 19,
			"virtual" => 232
		},
		GOTOS => {
			'perc_name' => 269,
			'dtor' => 270,
			'virtual' => 271
		}
	},
	{#State 272
		ACTIONS => {
			'p_code' => 123,
			'p_cleanup' => 119,
			'p_any' => 3,
			'p_catch' => 127,
			'p_postcall' => 121
		},
		DEFAULT => -85,
		GOTOS => {
			'perc_postcall' => 122,
			'perc_code' => 118,
			'perc_any' => 124,
			'perc_cleanup' => 125,
			'perc_catch' => 120,
			'_function_metadata' => 126
		}
	},
	{#State 273
		DEFAULT => -144
	},
	{#State 274
		ACTIONS => {
			'ID' => 287
		}
	},
	{#State 275
		ACTIONS => {
			'CLPAR' => 288,
			'COMMA' => 289
		}
	},
	{#State 276
		DEFAULT => -153
	},
	{#State 277
		DEFAULT => -157
	},
	{#State 278
		DEFAULT => -158
	},
	{#State 279
		ACTIONS => {
			'p_any' => 95,
			'CLCURLY' => 290
		},
		GOTOS => {
			'perc_any_arg' => 133
		}
	},
	{#State 280
		DEFAULT => -160
	},
	{#State 281
		DEFAULT => -16
	},
	{#State 282
		ACTIONS => {
			'OPPAR' => 266
		}
	},
	{#State 283
		ACTIONS => {
			'CLPAR' => 291
		}
	},
	{#State 284
		ACTIONS => {
			'CLPAR' => 292,
			'COMMA' => 187
		}
	},
	{#State 285
		ACTIONS => {
			'INTEGER' => 293
		}
	},
	{#State 286
		ACTIONS => {
			'p_code' => 123,
			'p_cleanup' => 119,
			'p_any' => 3,
			'p_catch' => 127,
			'p_postcall' => 121
		},
		DEFAULT => -89,
		GOTOS => {
			'perc_postcall' => 122,
			'perc_code' => 118,
			'perc_any' => 124,
			'perc_cleanup' => 125,
			'perc_catch' => 120,
			'_function_metadata' => 126
		}
	},
	{#State 287
		ACTIONS => {
			'CLCURLY' => 294
		}
	},
	{#State 288
		DEFAULT => -152
	},
	{#State 289
		ACTIONS => {
			'ID' => 25,
			'INTEGER' => 208,
			'QUOTED_STRING' => 210,
			'DASH' => 212,
			'FLOAT' => 211
		},
		GOTOS => {
			'class_name' => 206,
			'value' => 295
		}
	},
	{#State 290
		ACTIONS => {
			'SEMICOLON' => 296
		}
	},
	{#State 291
		DEFAULT => -84,
		GOTOS => {
			'function_metadata' => 297
		}
	},
	{#State 292
		DEFAULT => -84,
		GOTOS => {
			'function_metadata' => 298
		}
	},
	{#State 293
		DEFAULT => -84,
		GOTOS => {
			'function_metadata' => 299
		}
	},
	{#State 294
		DEFAULT => -22,
		GOTOS => {
			'mixed_blocks' => 300
		}
	},
	{#State 295
		DEFAULT => -154
	},
	{#State 296
		DEFAULT => -17
	},
	{#State 297
		ACTIONS => {
			'p_code' => 123,
			'p_cleanup' => 119,
			'p_any' => 3,
			'p_catch' => 127,
			'p_postcall' => 121
		},
		DEFAULT => -80,
		GOTOS => {
			'perc_postcall' => 122,
			'perc_code' => 118,
			'perc_any' => 124,
			'perc_cleanup' => 125,
			'perc_catch' => 120,
			'_function_metadata' => 126
		}
	},
	{#State 298
		ACTIONS => {
			'p_code' => 123,
			'p_cleanup' => 119,
			'p_any' => 3,
			'p_catch' => 127,
			'p_postcall' => 121
		},
		DEFAULT => -78,
		GOTOS => {
			'perc_postcall' => 122,
			'perc_code' => 118,
			'perc_any' => 124,
			'perc_cleanup' => 125,
			'perc_catch' => 120,
			'_function_metadata' => 126
		}
	},
	{#State 299
		ACTIONS => {
			'p_code' => 123,
			'p_cleanup' => 119,
			'p_any' => 3,
			'p_catch' => 127,
			'p_postcall' => 121
		},
		DEFAULT => -90,
		GOTOS => {
			'perc_postcall' => 122,
			'perc_code' => 118,
			'perc_any' => 124,
			'perc_cleanup' => 125,
			'perc_catch' => 120,
			'_function_metadata' => 126
		}
	},
	{#State 300
		ACTIONS => {
			'OPCURLY' => 135,
			'OPSPECIAL' => 30,
			'SEMICOLON' => 301
		},
		GOTOS => {
			'simple_block' => 137,
			'special_block' => 136,
			'special_block_start' => 32
		}
	},
	{#State 301
		DEFAULT => -19
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'top_list', 1,
sub
#line 21 "XSP.yp"
{ $_[1] ? [ $_[1] ] : [] }
	],
	[#Rule 2
		 'top_list', 2,
sub
#line 22 "XSP.yp"
{ push @{$_[1]}, $_[2] if $_[2]; $_[1] }
	],
	[#Rule 3
		 'top', 1, undef
	],
	[#Rule 4
		 'top', 1, undef
	],
	[#Rule 5
		 'top', 1, undef
	],
	[#Rule 6
		 'top', 1, undef
	],
	[#Rule 7
		 'top', 1,
sub
#line 26 "XSP.yp"
{ $_[1]->resolve_typemaps; $_[1]->resolve_exceptions; $_[1] }
	],
	[#Rule 8
		 'directive', 2,
sub
#line 29 "XSP.yp"
{ ExtUtils::XSpp::Node::Module->new( module => $_[1] ) }
	],
	[#Rule 9
		 'directive', 2,
sub
#line 31 "XSP.yp"
{ ExtUtils::XSpp::Node::Package->new( perl_name => $_[1] ) }
	],
	[#Rule 10
		 'directive', 2,
sub
#line 33 "XSP.yp"
{ ExtUtils::XSpp::Node::File->new( file => $_[1] ) }
	],
	[#Rule 11
		 'directive', 2,
sub
#line 35 "XSP.yp"
{ $_[0]->YYData->{PARSER}->load_plugin( $_[1] ); undef }
	],
	[#Rule 12
		 'directive', 2,
sub
#line 37 "XSP.yp"
{ $_[0]->YYData->{PARSER}->include_file( $_[1] ); undef }
	],
	[#Rule 13
		 'directive', 2,
sub
#line 39 "XSP.yp"
{ add_top_level_directive( $_[0], @{$_[1]} ); undef }
	],
	[#Rule 14
		 'directive', 1,
sub
#line 40 "XSP.yp"
{ }
	],
	[#Rule 15
		 'directive', 1,
sub
#line 41 "XSP.yp"
{ }
	],
	[#Rule 16
		 'typemap', 9,
sub
#line 46 "XSP.yp"
{ my $package = "ExtUtils::XSpp::Typemap::" . $_[6];
                      my $type = $_[3]; my $c = 0;
                      my %args = map { "arg" . ++$c => $_ }
                                 map { join( '', @$_ ) }
                                     @{$_[8] || []};
                      my $tm = $package->new( type => $type, %args );
                      ExtUtils::XSpp::Typemap::add_typemap_for_type( $type, $tm );
                      undef }
	],
	[#Rule 17
		 'typemap', 11,
sub
#line 56 "XSP.yp"
{ my $package = "ExtUtils::XSpp::Typemap::" . $_[6];
                      my $type = $_[3];
                      # this assumes that there will be at most one named
                      # block for each directive inside the typemap
                      for( my $i = 1; $i <= $#{$_[9]}; $i += 2 ) {
                          $_[9][$i] = join "\n", @{$_[9][$i][0]}
                              if    ref( $_[9][$i] ) eq 'ARRAY'
                                 && ref( $_[9][$i][0] ) eq 'ARRAY';
                      }
                      my $tm = $package->new( type => $type, @{$_[9]} );
                      ExtUtils::XSpp::Typemap::add_typemap_for_type( $type, $tm );
                      undef }
	],
	[#Rule 18
		 'typemap', 5,
sub
#line 69 "XSP.yp"
{ my $type = $_[3]; # add simple and reference typemaps for this type
                      my $tm = ExtUtils::XSpp::Typemap::simple->new( type => $type );
                      ExtUtils::XSpp::Typemap::add_typemap_for_type( $type, $tm );
                      my $reftype = make_ref($type->clone);
                      $tm = ExtUtils::XSpp::Typemap::reference->new( type => $reftype );
                      ExtUtils::XSpp::Typemap::add_typemap_for_type( $reftype, $tm );
                      undef }
	],
	[#Rule 19
		 'exceptionmap', 12,
sub
#line 81 "XSP.yp"
{ my $package = "ExtUtils::XSpp::Exception::" . $_[9];
                      my $type = make_type($_[6]); my $c = 0;
                      my %args = map { "arg" . ++$c => $_ }
                                 map { join( "\n", @$_ ) }
                                     @{$_[11] || []};
                      my $e = $package->new( name => $_[3], type => $type, %args );
                      ExtUtils::XSpp::Exception->add_exception( $e );
                      undef }
	],
	[#Rule 20
		 'mixed_blocks', 2,
sub
#line 91 "XSP.yp"
{ [ @{$_[1]}, $_[2] ] }
	],
	[#Rule 21
		 'mixed_blocks', 2,
sub
#line 93 "XSP.yp"
{ [ @{$_[1]}, [ $_[2] ] ] }
	],
	[#Rule 22
		 'mixed_blocks', 0,
sub
#line 94 "XSP.yp"
{ [] }
	],
	[#Rule 23
		 'simple_block', 3,
sub
#line 97 "XSP.yp"
{ $_[2] }
	],
	[#Rule 24
		 'raw', 1,
sub
#line 99 "XSP.yp"
{ add_data_raw( $_[0], [ $_[1] ] ) }
	],
	[#Rule 25
		 'raw', 1,
sub
#line 100 "XSP.yp"
{ add_data_comment( $_[0], $_[1] ) }
	],
	[#Rule 26
		 'raw', 1,
sub
#line 101 "XSP.yp"
{ ExtUtils::XSpp::Node::Preprocessor->new
                              ( rows   => [ $_[1][0] ],
                                symbol => $_[1][1],
                                ) }
	],
	[#Rule 27
		 'raw', 1,
sub
#line 105 "XSP.yp"
{ add_data_raw( $_[0], [ @{$_[1]} ] ) }
	],
	[#Rule 28
		 'enum', 5,
sub
#line 109 "XSP.yp"
{ ExtUtils::XSpp::Node::Enum->new
                ( elements  => $_[3],
                  condition => $_[0]->get_conditional,
                  ) }
	],
	[#Rule 29
		 'enum', 6,
sub
#line 114 "XSP.yp"
{ ExtUtils::XSpp::Node::Enum->new
                ( name      => $_[2],
                  elements  => $_[4],
                  condition => $_[0]->get_conditional,
                  ) }
	],
	[#Rule 30
		 'enum_element_list', 0,
sub
#line 122 "XSP.yp"
{ [] }
	],
	[#Rule 31
		 'enum_element_list', 2,
sub
#line 124 "XSP.yp"
{ push @{$_[1]}, $_[2] if $_[2]; $_[1] }
	],
	[#Rule 32
		 'enum_element_list', 3,
sub
#line 126 "XSP.yp"
{ push @{$_[1]}, $_[2] if $_[2]; $_[1] }
	],
	[#Rule 33
		 'enum_element', 1,
sub
#line 131 "XSP.yp"
{ ExtUtils::XSpp::Node::EnumValue->new
                ( name => $_[1],
                  condition => $_[0]->get_conditional,
                  ) }
	],
	[#Rule 34
		 'enum_element', 3,
sub
#line 136 "XSP.yp"
{ ExtUtils::XSpp::Node::EnumValue->new
                ( name      => $_[1],
                  value     => $_[3],
                  condition => $_[0]->get_conditional,
                  ) }
	],
	[#Rule 35
		 'enum_element', 1, undef
	],
	[#Rule 36
		 'class', 2, undef
	],
	[#Rule 37
		 'class', 2, undef
	],
	[#Rule 38
		 'function', 2, undef
	],
	[#Rule 39
		 'method', 2, undef
	],
	[#Rule 40
		 'decorate_class', 2,
sub
#line 149 "XSP.yp"
{ $_[2]->set_perl_name( $_[1] ); $_[2] }
	],
	[#Rule 41
		 'class_decl', 7,
sub
#line 152 "XSP.yp"
{ create_class( $_[0], $_[2], $_[3], $_[4], $_[6],
                                $_[0]->get_conditional ) }
	],
	[#Rule 42
		 'base_classes', 2,
sub
#line 156 "XSP.yp"
{ [ $_[2] ] }
	],
	[#Rule 43
		 'base_classes', 3,
sub
#line 157 "XSP.yp"
{ push @{$_[1]}, $_[3] if $_[3]; $_[1] }
	],
	[#Rule 44
		 'base_classes', 0, undef
	],
	[#Rule 45
		 'base_class', 2,
sub
#line 161 "XSP.yp"
{ $_[2] }
	],
	[#Rule 46
		 'base_class', 2,
sub
#line 162 "XSP.yp"
{ $_[2] }
	],
	[#Rule 47
		 'base_class', 2,
sub
#line 163 "XSP.yp"
{ $_[2] }
	],
	[#Rule 48
		 'class_name_rename', 1,
sub
#line 167 "XSP.yp"
{ create_class( $_[0], $_[1], [], [] ) }
	],
	[#Rule 49
		 'class_name_rename', 2,
sub
#line 168 "XSP.yp"
{ my $klass = create_class( $_[0], $_[2], [], [] );
                             $klass->set_perl_name( $_[1] );
                             $klass
                             }
	],
	[#Rule 50
		 'class_metadata', 2,
sub
#line 174 "XSP.yp"
{ [ @{$_[1]}, @{$_[2]} ] }
	],
	[#Rule 51
		 'class_metadata', 2,
sub
#line 175 "XSP.yp"
{ [ @{$_[1]}, @{$_[2]} ] }
	],
	[#Rule 52
		 'class_metadata', 0,
sub
#line 176 "XSP.yp"
{ [] }
	],
	[#Rule 53
		 'class_body_list', 0,
sub
#line 180 "XSP.yp"
{ [] }
	],
	[#Rule 54
		 'class_body_list', 2,
sub
#line 182 "XSP.yp"
{ push @{$_[1]}, $_[2] if $_[2]; $_[1] }
	],
	[#Rule 55
		 'class_body_element', 1, undef
	],
	[#Rule 56
		 'class_body_element', 1, undef
	],
	[#Rule 57
		 'class_body_element', 1, undef
	],
	[#Rule 58
		 'class_body_element', 1, undef
	],
	[#Rule 59
		 'class_body_element', 1, undef
	],
	[#Rule 60
		 'class_body_element', 2,
sub
#line 188 "XSP.yp"
{ ExtUtils::XSpp::Node::PercAny->new( @{$_[1]} ) }
	],
	[#Rule 61
		 'access_specifier', 2,
sub
#line 192 "XSP.yp"
{ ExtUtils::XSpp::Node::Access->new( access => $_[1] ) }
	],
	[#Rule 62
		 'access_specifier', 2,
sub
#line 193 "XSP.yp"
{ ExtUtils::XSpp::Node::Access->new( access => $_[1] ) }
	],
	[#Rule 63
		 'access_specifier', 2,
sub
#line 194 "XSP.yp"
{ ExtUtils::XSpp::Node::Access->new( access => $_[1] ) }
	],
	[#Rule 64
		 'method_decl', 1, undef
	],
	[#Rule 65
		 'method_decl', 1, undef
	],
	[#Rule 66
		 'method_decl', 1, undef
	],
	[#Rule 67
		 'method_decl', 1, undef
	],
	[#Rule 68
		 'const', 1,
sub
#line 199 "XSP.yp"
{ 1 }
	],
	[#Rule 69
		 'const', 0,
sub
#line 200 "XSP.yp"
{ 0 }
	],
	[#Rule 70
		 'virtual', 1, undef
	],
	[#Rule 71
		 'static', 1, undef
	],
	[#Rule 72
		 'static', 1, undef
	],
	[#Rule 73
		 'static', 1,
sub
#line 206 "XSP.yp"
{ 'package_static' }
	],
	[#Rule 74
		 'looks_like_function', 6,
sub
#line 211 "XSP.yp"
{
              return { ret_type  => $_[1],
                       name      => $_[2],
                       arguments => $_[4],
                       const     => $_[6],
                       };
          }
	],
	[#Rule 75
		 'looks_like_renamed_function', 1, undef
	],
	[#Rule 76
		 'looks_like_renamed_function', 2,
sub
#line 222 "XSP.yp"
{ $_[2]->{perl_name} = $_[1]; $_[2] }
	],
	[#Rule 77
		 'function_decl', 2,
sub
#line 225 "XSP.yp"
{ add_data_function( $_[0],
                                         name      => $_[1]->{name},
                                         perl_name => $_[1]->{perl_name},
                                         ret_type  => $_[1]->{ret_type},
                                         arguments => $_[1]->{arguments},
                                         condition => $_[0]->get_conditional,
                                         @{$_[2]} ) }
	],
	[#Rule 78
		 'ctor', 5,
sub
#line 234 "XSP.yp"
{ add_data_ctor( $_[0], name      => $_[1],
                                            arguments => $_[3],
                                            condition => $_[0]->get_conditional,
                                            @{ $_[5] } ) }
	],
	[#Rule 79
		 'ctor', 2,
sub
#line 238 "XSP.yp"
{ $_[2]->set_perl_name( $_[1] ); $_[2] }
	],
	[#Rule 80
		 'dtor', 5,
sub
#line 241 "XSP.yp"
{ add_data_dtor( $_[0], name  => $_[2],
                                            condition => $_[0]->get_conditional,
                                            @{ $_[5] },
                                      ) }
	],
	[#Rule 81
		 'dtor', 2,
sub
#line 245 "XSP.yp"
{ $_[2]->set_perl_name( $_[1] ); $_[2] }
	],
	[#Rule 82
		 'dtor', 2,
sub
#line 246 "XSP.yp"
{ $_[2]->set_virtual( 1 ); $_[2] }
	],
	[#Rule 83
		 'function_metadata', 2,
sub
#line 248 "XSP.yp"
{ [ @{$_[1]}, @{$_[2]} ] }
	],
	[#Rule 84
		 'function_metadata', 0,
sub
#line 249 "XSP.yp"
{ [] }
	],
	[#Rule 85
		 'nmethod', 2,
sub
#line 254 "XSP.yp"
{ my $m = add_data_method
                        ( $_[0],
                          name      => $_[1]->{name},
                          perl_name => $_[1]->{perl_name},
                          ret_type  => $_[1]->{ret_type},
                          arguments => $_[1]->{arguments},
                          const     => $_[1]->{const},
                          condition => $_[0]->get_conditional,
                          @{$_[2]},
                          );
            $m
          }
	],
	[#Rule 86
		 'nmethod', 2,
sub
#line 267 "XSP.yp"
{ $_[2]->set_static( $_[1] ); $_[2] }
	],
	[#Rule 87
		 'vmethod', 1, undef
	],
	[#Rule 88
		 'vmethod', 2,
sub
#line 272 "XSP.yp"
{ $_[2]->set_perl_name( $_[1] ); $_[2] }
	],
	[#Rule 89
		 '_vmethod', 3,
sub
#line 277 "XSP.yp"
{ my $m = add_data_method
                        ( $_[0],
                          name      => $_[2]->{name},
                          perl_name => $_[2]->{perl_name},
                          ret_type  => $_[2]->{ret_type},
                          arguments => $_[2]->{arguments},
                          const     => $_[2]->{const},
                          condition => $_[0]->get_conditional,
                          @{$_[3]},
                          );
            $m->set_virtual( 1 );
            $m
          }
	],
	[#Rule 90
		 '_vmethod', 5,
sub
#line 291 "XSP.yp"
{ my $m = add_data_method
                        ( $_[0],
                          name      => $_[2]->{name},
                          perl_name => $_[2]->{perl_name},
                          ret_type  => $_[2]->{ret_type},
                          arguments => $_[2]->{arguments},
                          const     => $_[2]->{const},
                          condition => $_[0]->get_conditional,
                          @{$_[5]},
                          );
            die "Invalid pure virtual method" unless $_[4] eq '0';
            $m->set_virtual( 2 );
            $m
          }
	],
	[#Rule 91
		 '_function_metadata', 1, undef
	],
	[#Rule 92
		 '_function_metadata', 1, undef
	],
	[#Rule 93
		 '_function_metadata', 1, undef
	],
	[#Rule 94
		 '_function_metadata', 1, undef
	],
	[#Rule 95
		 '_function_metadata', 1, undef
	],
	[#Rule 96
		 'perc_name', 4,
sub
#line 314 "XSP.yp"
{ $_[3] }
	],
	[#Rule 97
		 'perc_package', 4,
sub
#line 315 "XSP.yp"
{ $_[3] }
	],
	[#Rule 98
		 'perc_module', 4,
sub
#line 316 "XSP.yp"
{ $_[3] }
	],
	[#Rule 99
		 'perc_file', 4,
sub
#line 317 "XSP.yp"
{ $_[3] }
	],
	[#Rule 100
		 'perc_loadplugin', 4,
sub
#line 318 "XSP.yp"
{ $_[3] }
	],
	[#Rule 101
		 'perc_include', 4,
sub
#line 319 "XSP.yp"
{ $_[3] }
	],
	[#Rule 102
		 'perc_code', 2,
sub
#line 320 "XSP.yp"
{ [ code => $_[2] ] }
	],
	[#Rule 103
		 'perc_cleanup', 2,
sub
#line 321 "XSP.yp"
{ [ cleanup => $_[2] ] }
	],
	[#Rule 104
		 'perc_postcall', 2,
sub
#line 322 "XSP.yp"
{ [ postcall => $_[2] ] }
	],
	[#Rule 105
		 'perc_catch', 4,
sub
#line 323 "XSP.yp"
{ [ map {(catch => $_)} @{$_[3]} ] }
	],
	[#Rule 106
		 'perc_any', 4,
sub
#line 328 "XSP.yp"
{ [ any => $_[1], any_named_arguments => $_[3] ] }
	],
	[#Rule 107
		 'perc_any', 5,
sub
#line 330 "XSP.yp"
{ [ any => $_[1], any_positional_arguments  => [ $_[3], @{$_[5]} ] ] }
	],
	[#Rule 108
		 'perc_any', 3,
sub
#line 332 "XSP.yp"
{ [ any => $_[1], any_positional_arguments  => [ $_[2], @{$_[3]} ] ] }
	],
	[#Rule 109
		 'perc_any', 1,
sub
#line 334 "XSP.yp"
{ [ any => $_[1] ] }
	],
	[#Rule 110
		 'perc_any_args', 1,
sub
#line 338 "XSP.yp"
{ $_[1] }
	],
	[#Rule 111
		 'perc_any_args', 2,
sub
#line 339 "XSP.yp"
{ [ @{$_[1]}, @{$_[2]} ] }
	],
	[#Rule 112
		 'perc_any_arg', 3,
sub
#line 343 "XSP.yp"
{ [ $_[1] => $_[2] ] }
	],
	[#Rule 113
		 'type', 2,
sub
#line 347 "XSP.yp"
{ make_const( $_[2] ) }
	],
	[#Rule 114
		 'type', 1, undef
	],
	[#Rule 115
		 'nconsttype', 2,
sub
#line 352 "XSP.yp"
{ make_ptr( $_[1] ) }
	],
	[#Rule 116
		 'nconsttype', 2,
sub
#line 353 "XSP.yp"
{ make_ref( $_[1] ) }
	],
	[#Rule 117
		 'nconsttype', 1,
sub
#line 354 "XSP.yp"
{ make_type( $_[1] ) }
	],
	[#Rule 118
		 'nconsttype', 1, undef
	],
	[#Rule 119
		 'type_name', 1, undef
	],
	[#Rule 120
		 'type_name', 1, undef
	],
	[#Rule 121
		 'type_name', 1,
sub
#line 361 "XSP.yp"
{ 'unsigned int' }
	],
	[#Rule 122
		 'type_name', 2,
sub
#line 362 "XSP.yp"
{ 'unsigned' . ' ' . $_[2] }
	],
	[#Rule 123
		 'basic_type', 1, undef
	],
	[#Rule 124
		 'basic_type', 1, undef
	],
	[#Rule 125
		 'basic_type', 1, undef
	],
	[#Rule 126
		 'basic_type', 1, undef
	],
	[#Rule 127
		 'basic_type', 2, undef
	],
	[#Rule 128
		 'basic_type', 2, undef
	],
	[#Rule 129
		 'template', 4,
sub
#line 368 "XSP.yp"
{ make_template( $_[1], $_[3] ) }
	],
	[#Rule 130
		 'type_list', 1,
sub
#line 372 "XSP.yp"
{ [ $_[1] ] }
	],
	[#Rule 131
		 'type_list', 3,
sub
#line 373 "XSP.yp"
{ push @{$_[1]}, $_[3]; $_[1] }
	],
	[#Rule 132
		 'class_name', 1, undef
	],
	[#Rule 133
		 'class_name', 2,
sub
#line 377 "XSP.yp"
{ $_[1] . '::' . $_[2] }
	],
	[#Rule 134
		 'class_name_list', 1,
sub
#line 380 "XSP.yp"
{ [ $_[1] ] }
	],
	[#Rule 135
		 'class_name_list', 3,
sub
#line 381 "XSP.yp"
{ push @{$_[1]}, $_[3]; $_[1] }
	],
	[#Rule 136
		 'class_suffix', 2,
sub
#line 384 "XSP.yp"
{ $_[2] }
	],
	[#Rule 137
		 'class_suffix', 3,
sub
#line 385 "XSP.yp"
{ $_[1] . '::' . $_[3] }
	],
	[#Rule 138
		 'file_name', 1,
sub
#line 387 "XSP.yp"
{ '-' }
	],
	[#Rule 139
		 'file_name', 3,
sub
#line 388 "XSP.yp"
{ $_[1] . '.' . $_[3] }
	],
	[#Rule 140
		 'file_name', 3,
sub
#line 389 "XSP.yp"
{ $_[1] . '/' . $_[3] }
	],
	[#Rule 141
		 'arg_list', 1,
sub
#line 391 "XSP.yp"
{ [ $_[1] ] }
	],
	[#Rule 142
		 'arg_list', 3,
sub
#line 392 "XSP.yp"
{ push @{$_[1]}, $_[3]; $_[1] }
	],
	[#Rule 143
		 'arg_list', 0, undef
	],
	[#Rule 144
		 'argument', 5,
sub
#line 396 "XSP.yp"
{ make_argument( @_[0, 1], "length($_[4])" ) }
	],
	[#Rule 145
		 'argument', 4,
sub
#line 398 "XSP.yp"
{ make_argument( @_[0, 1, 2, 4] ) }
	],
	[#Rule 146
		 'argument', 2,
sub
#line 399 "XSP.yp"
{ make_argument( @_ ) }
	],
	[#Rule 147
		 'value', 1, undef
	],
	[#Rule 148
		 'value', 2,
sub
#line 402 "XSP.yp"
{ '-' . $_[2] }
	],
	[#Rule 149
		 'value', 1, undef
	],
	[#Rule 150
		 'value', 1, undef
	],
	[#Rule 151
		 'value', 1, undef
	],
	[#Rule 152
		 'value', 4,
sub
#line 406 "XSP.yp"
{ "$_[1]($_[3])" }
	],
	[#Rule 153
		 'value_list', 1, undef
	],
	[#Rule 154
		 'value_list', 3,
sub
#line 411 "XSP.yp"
{ "$_[1], $_[2]" }
	],
	[#Rule 155
		 'value_list', 0,
sub
#line 412 "XSP.yp"
{ "" }
	],
	[#Rule 156
		 'expression', 1, undef
	],
	[#Rule 157
		 'expression', 3,
sub
#line 418 "XSP.yp"
{ "$_[1] & $_[3]" }
	],
	[#Rule 158
		 'expression', 3,
sub
#line 420 "XSP.yp"
{ "$_[1] | $_[3]" }
	],
	[#Rule 159
		 'special_blocks', 1,
sub
#line 424 "XSP.yp"
{ [ $_[1] ] }
	],
	[#Rule 160
		 'special_blocks', 2,
sub
#line 426 "XSP.yp"
{ [ @{$_[1]}, $_[2] ] }
	],
	[#Rule 161
		 'special_blocks', 0, undef
	],
	[#Rule 162
		 'special_block', 3,
sub
#line 430 "XSP.yp"
{ $_[2] }
	],
	[#Rule 163
		 'special_block', 2,
sub
#line 432 "XSP.yp"
{ [] }
	],
	[#Rule 164
		 'special_block_start', 1,
sub
#line 435 "XSP.yp"
{ push_lex_mode( $_[0], 'special' ) }
	],
	[#Rule 165
		 'special_block_end', 1,
sub
#line 437 "XSP.yp"
{ pop_lex_mode( $_[0], 'special' ) }
	],
	[#Rule 166
		 'lines', 1,
sub
#line 439 "XSP.yp"
{ [ $_[1] ] }
	],
	[#Rule 167
		 'lines', 2,
sub
#line 440 "XSP.yp"
{ push @{$_[1]}, $_[2]; $_[1] }
	]
],
                                  @_);
    bless($self,$class);
}

#line 442 "XSP.yp"


use ExtUtils::XSpp::Lexer;

1;
