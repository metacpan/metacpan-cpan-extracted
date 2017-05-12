####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package TM::AsTMa::Fact2;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 1 "yapp/astma2-fact.yp"

use Data::Dumper;
use TM;
use TM::Literal;

use constant {
    XSD        => 'http://www.w3.org/2001/XMLSchema',
    XSD_STRING => 'http://www.w3.org/2001/XMLSchema#string',
    ASTMA      => 'http://psi.tm.bond.edu.au/astma/2.0/',
    ONTOLOGY   => 'http://psi.tm.bond.edu.au/astma/2.0/#ontology',
    TEMPLATE   => 'http://psi.tm.bond.edu.au/astma/2.0/#template'
    };

sub _expand_template {
    my $store  = shift;
    my $ted    = shift;
    my $params = shift; # they are all strings at this level

#warn "params".Dumper $params;

    my @returns = $store->match (TM->FORALL, type => 'return', irole => 'thing', iplayer => $store->tids ($ted) )
                  or die "template '$ted' does not have a 'return' characteristic";
#warn Dumper \@returns;
    my $return = $returns[0]->[TM->PLAYERS]->[1] and (scalar @returns == 1
                  or die "ambiguous 'return' characteristics for '$ted'");

    my $value  = $return->[0] and ($return->[1] eq 'http://www.w3.org/2001/XMLSchema#string' 
		  or die "'return' characteristic of '$ted' is no string");
#warn "template id '$ted' >>>$value<<<";
    foreach my $p (keys %$params) {
	$value =~ s/{\s*\$$p\s*}/$params->{$p}/sg;
    }
#warn "after template id '$ted' >>>$value<<<";
    die "variable '$1' in template '$ted' has no value at expansion" if $value =~ /{\s*(\$\w+)\s*}/;
    return $value;
}



sub new {
    my $class   = shift;
    my %options = @_;
    my $store   = delete $options{store} || new TM;       # the Yapp parser is picky and interprets this :-/

    ref($class) and $class=ref($class);

    my $self = $class->SUPER::new( 
##				   yydebug   => 0x01,
				   yyversion => '1.05',
				   yystates  =>
[
	{#State 0
		DEFAULT => -1,
		GOTOS => {
			'instance' => 1
		}
	},
	{#State 1
		ACTIONS => {
			'' => 2,
			'LOG' => 10,
			'EOL' => 13,
			'CANCEL' => 4,
			'INCLUDE' => 6,
			'TED' => 5,
			'ENCODING' => 7,
			'VERSION' => 11
		},
		DEFAULT => -4,
		GOTOS => {
			'@1-0' => 8,
			'clause' => 9,
			'template_expansion' => 3,
			'directive' => 12
		}
	},
	{#State 2
		DEFAULT => 0
	},
	{#State 3
		DEFAULT => -6
	},
	{#State 4
		DEFAULT => -8
	},
	{#State 5
		ACTIONS => {
			'LPAREN' => 14
		},
		DEFAULT => -14,
		GOTOS => {
			'parameters' => 15
		}
	},
	{#State 6
		DEFAULT => -11
	},
	{#State 7
		DEFAULT => -12
	},
	{#State 8
		ACTIONS => {
			'BRA' => 17
		},
		DEFAULT => -22,
		GOTOS => {
			'@3-0' => 18,
			'topic' => 16,
			'theme' => 19
		}
	},
	{#State 9
		DEFAULT => -3
	},
	{#State 10
		DEFAULT => -9
	},
	{#State 11
		DEFAULT => -10
	},
	{#State 12
		DEFAULT => -7
	},
	{#State 13
		DEFAULT => -2
	},
	{#State 14
		ACTIONS => {
			'ID' => 20
		},
		GOTOS => {
			'bindings' => 21,
			'binding' => 22
		}
	},
	{#State 15
		DEFAULT => -13
	},
	{#State 16
		DEFAULT => -21
	},
	{#State 17
		DEFAULT => -22,
		GOTOS => {
			'@3-0' => 18,
			'topic' => 23
		}
	},
	{#State 18
		DEFAULT => -44,
		GOTOS => {
			'attachments' => 24
		}
	},
	{#State 19
		ACTIONS => {
			'DOT' => 25
		}
	},
	{#State 20
		ACTIONS => {
			'COLON' => 26
		}
	},
	{#State 21
		ACTIONS => {
			'RPAREN' => 27,
			'COMMA' => 28
		}
	},
	{#State 22
		DEFAULT => -16
	},
	{#State 23
		ACTIONS => {
			'KET' => 29
		}
	},
	{#State 24
		ACTIONS => {
			'ID' => 30,
			'HAS' => 31,
			'DATE' => 32,
			'WILDCARD' => 33,
			'WHICH' => 35,
			'EQUAL' => 36,
			'EOL' => 38,
			'SUBCL' => 39,
			'REIFIES' => 40,
			'URI' => 41,
			'TED' => 45,
			'ISA' => 46,
			'TILDE' => 47
		},
		DEFAULT => -24,
		GOTOS => {
			'expansion' => 42,
			'predefined_inlines' => 43,
			'association' => 37,
			'identification' => 44,
			'tid' => 34
		}
	},
	{#State 25
		DEFAULT => -5
	},
	{#State 26
		DEFAULT => -18,
		GOTOS => {
			'@2-2' => 48
		}
	},
	{#State 27
		DEFAULT => -15
	},
	{#State 28
		ACTIONS => {
			'ID' => 20
		},
		GOTOS => {
			'binding' => 49
		}
	},
	{#State 29
		DEFAULT => -20
	},
	{#State 30
		DEFAULT => -68
	},
	{#State 31
		ACTIONS => {
			'ID' => 30,
			'URI' => 41,
			'EQUAL' => 36,
			'TILDE' => 47,
			'DATE' => 32,
			'WILDCARD' => 33
		},
		GOTOS => {
			'characteristic' => 51,
			'tid' => 50
		}
	},
	{#State 32
		DEFAULT => -70
	},
	{#State 33
		DEFAULT => -69
	},
	{#State 34
		DEFAULT => -61
	},
	{#State 35
		ACTIONS => {
			'TED' => 45,
			'HAS' => 52,
			'ISA' => 46,
			'SUBCL' => 39
		},
		GOTOS => {
			'expansion' => 53,
			'predefined_inlines' => 43
		}
	},
	{#State 36
		ACTIONS => {
			'URI' => 54
		}
	},
	{#State 37
		DEFAULT => -23
	},
	{#State 38
		ACTIONS => {
			'ID' => 30,
			'URI' => 41,
			'EQUAL' => 36,
			'TILDE' => 47,
			'DATE' => 32,
			'WILDCARD' => 33
		},
		GOTOS => {
			'identification' => 55,
			'tid' => 34
		}
	},
	{#State 39
		DEFAULT => -56
	},
	{#State 40
		DEFAULT => -25,
		GOTOS => {
			'@4-1' => 56
		}
	},
	{#State 41
		DEFAULT => -73
	},
	{#State 42
		DEFAULT => -47
	},
	{#State 43
		ACTIONS => {
			'LPAREN' => 14
		},
		DEFAULT => -14,
		GOTOS => {
			'parameters' => 57
		}
	},
	{#State 44
		DEFAULT => -49
	},
	{#State 45
		DEFAULT => -57
	},
	{#State 46
		DEFAULT => -55
	},
	{#State 47
		ACTIONS => {
			'URI' => 58
		}
	},
	{#State 48
		ACTIONS => {
			'VALUE' => 59
		}
	},
	{#State 49
		DEFAULT => -17
	},
	{#State 50
		ACTIONS => {
			'AT' => 60
		},
		DEFAULT => -64,
		GOTOS => {
			'scope' => 61
		}
	},
	{#State 51
		DEFAULT => -45
	},
	{#State 52
		ACTIONS => {
			'ID' => 30,
			'URI' => 41,
			'EQUAL' => 36,
			'TILDE' => 47,
			'DATE' => 32,
			'WILDCARD' => 33
		},
		GOTOS => {
			'characteristic' => 62,
			'tid' => 50
		}
	},
	{#State 53
		DEFAULT => -48
	},
	{#State 54
		DEFAULT => -71
	},
	{#State 55
		DEFAULT => -50
	},
	{#State 56
		ACTIONS => {
			'ID' => 30,
			'URI' => 41,
			'EQUAL' => 36,
			'TILDE' => 47,
			'DATE' => 32,
			'WILDCARD' => 33
		},
		GOTOS => {
			'identification' => 63,
			'tid' => 34
		}
	},
	{#State 57
		DEFAULT => -58,
		GOTOS => {
			'@10-2' => 64
		}
	},
	{#State 58
		DEFAULT => -72
	},
	{#State 59
		DEFAULT => -19
	},
	{#State 60
		ACTIONS => {
			'ID' => 30,
			'URI' => 41,
			'EQUAL' => 36,
			'TILDE' => 47,
			'DATE' => 32,
			'WILDCARD' => 33
		},
		GOTOS => {
			'tid' => 65
		}
	},
	{#State 61
		ACTIONS => {
			'SUBCL' => 66
		},
		DEFAULT => -66,
		GOTOS => {
			'type' => 67
		}
	},
	{#State 62
		DEFAULT => -46
	},
	{#State 63
		DEFAULT => -26,
		GOTOS => {
			'@5-3' => 68
		}
	},
	{#State 64
		ACTIONS => {
			'ID' => 30,
			'URI' => 41,
			'EQUAL' => 36,
			'TILDE' => 47,
			'DATE' => 32,
			'WILDCARD' => 33
		},
		GOTOS => {
			'identification' => 69,
			'tid' => 34
		}
	},
	{#State 65
		DEFAULT => -65
	},
	{#State 66
		ACTIONS => {
			'ID' => 30,
			'URI' => 41,
			'EQUAL' => 36,
			'TILDE' => 47,
			'DATE' => 32,
			'WILDCARD' => 33
		},
		GOTOS => {
			'tid' => 70
		}
	},
	{#State 67
		ACTIONS => {
			'COLON' => 71
		}
	},
	{#State 68
		ACTIONS => {
			'AT' => 60
		},
		DEFAULT => -64,
		GOTOS => {
			'scope' => 72
		}
	},
	{#State 69
		DEFAULT => -59,
		GOTOS => {
			'@11-4' => 73
		}
	},
	{#State 70
		DEFAULT => -67
	},
	{#State 71
		DEFAULT => -62,
		GOTOS => {
			'@12-4' => 74
		}
	},
	{#State 72
		ACTIONS => {
			'LPAREN' => 75,
			'EOL' => 76
		},
		GOTOS => {
			'rolesin' => 77
		}
	},
	{#State 73
		ACTIONS => {
			'DOWNCOMMA' => 79
		},
		DEFAULT => -51,
		GOTOS => {
			'relative' => 78
		}
	},
	{#State 74
		ACTIONS => {
			'VALUE' => 80
		}
	},
	{#State 75
		DEFAULT => -28
	},
	{#State 76
		DEFAULT => -29
	},
	{#State 77
		DEFAULT => -22,
		GOTOS => {
			'@3-0' => 18,
			'roles' => 82,
			'topic' => 81,
			'role' => 83
		}
	},
	{#State 78
		DEFAULT => -60
	},
	{#State 79
		DEFAULT => -44,
		GOTOS => {
			'attachments' => 84
		}
	},
	{#State 80
		DEFAULT => -63
	},
	{#State 81
		DEFAULT => -37,
		GOTOS => {
			'@6-1' => 85
		}
	},
	{#State 82
		ACTIONS => {
			'RPAREN' => 86,
			'COMMA' => 88,
			'EOL' => 87
		},
		DEFAULT => -30,
		GOTOS => {
			'rolesout' => 89,
			'rolesep' => 90
		}
	},
	{#State 83
		DEFAULT => -35
	},
	{#State 84
		ACTIONS => {
			'ID' => 30,
			'HAS' => 31,
			'DATE' => 32,
			'WILDCARD' => 33,
			'WHICH' => 35,
			'EQUAL' => 36,
			'EOL' => 38,
			'SUBCL' => 39,
			'URI' => 41,
			'COMMA' => 92,
			'TED' => 45,
			'TILDE' => 47,
			'ISA' => 46
		},
		DEFAULT => -53,
		GOTOS => {
			'expansion' => 42,
			'upcomma' => 91,
			'predefined_inlines' => 43,
			'identification' => 44,
			'tid' => 34
		}
	},
	{#State 85
		ACTIONS => {
			'COLON' => 93
		}
	},
	{#State 86
		DEFAULT => -31
	},
	{#State 87
		ACTIONS => {
			'COLON' => -32,
			'DOT' => -32,
			'KET' => -32
		},
		DEFAULT => -34
	},
	{#State 88
		DEFAULT => -33
	},
	{#State 89
		DEFAULT => -27
	},
	{#State 90
		DEFAULT => -22,
		GOTOS => {
			'@3-0' => 18,
			'topic' => 81,
			'role' => 94
		}
	},
	{#State 91
		DEFAULT => -52
	},
	{#State 92
		DEFAULT => -54
	},
	{#State 93
		DEFAULT => -38,
		GOTOS => {
			'@7-3' => 95
		}
	},
	{#State 94
		DEFAULT => -36
	},
	{#State 95
		ACTIONS => {
			'ID' => 30,
			'URI' => 41,
			'EQUAL' => 36,
			'TILDE' => 47,
			'DATE' => 32,
			'WILDCARD' => 33
		},
		GOTOS => {
			'identification' => 97,
			'identifications' => 96,
			'tid' => 34
		}
	},
	{#State 96
		ACTIONS => {
			'ID' => 30,
			'URI' => 41,
			'DATE' => 32,
			'WILDCARD' => 33,
			'EQUAL' => 36,
			'TILDE' => 47
		},
		DEFAULT => -39,
		GOTOS => {
			'identification' => 98,
			'tid' => 34
		}
	},
	{#State 97
		DEFAULT => -40,
		GOTOS => {
			'@8-1' => 99
		}
	},
	{#State 98
		DEFAULT => -42,
		GOTOS => {
			'@9-2' => 100
		}
	},
	{#State 99
		DEFAULT => -41
	},
	{#State 100
		DEFAULT => -43
	}
],
				   yyrules   =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'instance', 0, undef
	],
	[#Rule 2
		 'instance', 2, undef
	],
	[#Rule 3
		 'instance', 2, undef
	],
	[#Rule 4
		 '@1-0', 0,
sub
#line 96 "yapp/astma2-fact.yp"
{ $_[0]->{USER}->{ctx} = undef; }
	],
	[#Rule 5
		 'clause', 3, undef
	],
	[#Rule 6
		 'clause', 1, undef
	],
	[#Rule 7
		 'clause', 1, undef
	],
	[#Rule 8
		 'directive', 1,
sub
#line 102 "yapp/astma2-fact.yp"
{ die "Cancelled"; }
	],
	[#Rule 9
		 'directive', 1,
sub
#line 103 "yapp/astma2-fact.yp"
{ warn $_[1]; 1; }
	],
	[#Rule 10
		 'directive', 1,
sub
#line 104 "yapp/astma2-fact.yp"
{ die "unsupported version $_[1]" unless $_[1] =~ /^2\./; 1; }
	],
	[#Rule 11
		 'directive', 1,
sub
#line 105 "yapp/astma2-fact.yp"
{
                                                            my $content;

                                                            if ($_[1] =~ /\|\s*$/) { # a pipe | at the end, this is a UNIX pipe
								my $fh = IO::File->new ($_[1]) || die "unable to open pipe '$_[1]'";
								local $/ = undef;
								$content = <$fh>;
								$fh->close;
							    } else {
								use LWP::Simple;
								$content = get($_[1]) || die "unable to load '$_[1] with LWP'\n";
							    }
#warn "new content >>>$content<<<";
                                                            $_[0]->YYData->{INPUT} = $content . $_[0]->YYData->{INPUT}; # prepend it
                                                            }
	],
	[#Rule 12
		 'directive', 1,
sub
#line 120 "yapp/astma2-fact.yp"
{
                                                            use Encode;
                                                            Encode::from_to ($_[0]->YYData->{INPUT}, "iso-8859-1", $_[1]);
                                                            }
	],
	[#Rule 13
		 'template_expansion', 2,
sub
#line 126 "yapp/astma2-fact.yp"
{ $_[0]->YYData->{INPUT} .= "\n" . 
                                                                                      _expand_template ($_[0]->{USER}->{store},
													$_[1],
													$_[2])      # compute the expanded version
                                                                                    . "\n";                         # extend the text at the end;
                                                           }
	],
	[#Rule 14
		 'parameters', 0,
sub
#line 135 "yapp/astma2-fact.yp"
{ { } }
	],
	[#Rule 15
		 'parameters', 3,
sub
#line 136 "yapp/astma2-fact.yp"
{ $_[2] }
	],
	[#Rule 16
		 'bindings', 1, undef
	],
	[#Rule 17
		 'bindings', 3,
sub
#line 140 "yapp/astma2-fact.yp"
{ $_[1] = { %{$_[1]}, %{$_[3]} }; $_[1]; }
	],
	[#Rule 18
		 '@2-2', 0,
sub
#line 143 "yapp/astma2-fact.yp"
{ $_[0]->{USER}->{value} = 1 }
	],
	[#Rule 19
		 'binding', 4,
sub
#line 143 "yapp/astma2-fact.yp"
{ { "$_[1]" => $_[4]->[0] } }
	],
	[#Rule 20
		 'theme', 3, undef
	],
	[#Rule 21
		 'theme', 1, undef
	],
	[#Rule 22
		 '@3-0', 0,
sub
#line 150 "yapp/astma2-fact.yp"
{ unshift @{$_[0]->{USER}->{ctx}}, undef; }
	],
	[#Rule 23
		 'topic', 3, undef
	],
	[#Rule 24
		 'association', 0, undef
	],
	[#Rule 25
		 '@4-1', 0,
sub
#line 156 "yapp/astma2-fact.yp"
{ $_[0]->{USER}->{reifier} = $_[0]->{USER}->{ctx}->[0]; 
					                            $_[0]->{USER}->{ctx}->[0] = undef;
				       }
	],
	[#Rule 26
		 '@5-3', 0,
sub
#line 159 "yapp/astma2-fact.yp"
{ $_[0]->{USER}->{atype}   = $_[0]->{USER}->{ctx}->[0];
					 $_[0]->{USER}->{assoc}   = 1;                                 # indicate to lexer that we are in assoc context
				       }
	],
	[#Rule 27
		 'association', 8,
sub
#line 164 "yapp/astma2-fact.yp"
{
#  warn "roles :". Dumper $_[7];
			  $_[0]->{USER}->{store}->assert ([ $_[0]->{USER}->{reifier},       # LID
							    $_[5],                          # SCOPE
							    $_[0]->{USER}->{atype},         # TYPE
							    TM->ASSOC,                      # KIND
							    @{$_[7]},  # ROLES, PLAYERS
							    undef ] );
                          $_[0]->{USER}->{implicits}->{'isa-scope'}->{$_[5]}++ if $_[5];
	                  $_[0]->{USER}->{assoc} = undef;                                 # indicate to lexer that we left assoc context
		      }
	],
	[#Rule 28
		 'rolesin', 1, undef
	],
	[#Rule 29
		 'rolesin', 1, undef
	],
	[#Rule 30
		 'rolesout', 0, undef
	],
	[#Rule 31
		 'rolesout', 1, undef
	],
	[#Rule 32
		 'rolesout', 1, undef
	],
	[#Rule 33
		 'rolesep', 1, undef
	],
	[#Rule 34
		 'rolesep', 1, undef
	],
	[#Rule 35
		 'roles', 1, undef
	],
	[#Rule 36
		 'roles', 3,
sub
#line 187 "yapp/astma2-fact.yp"
{ 
                                                  push @{$_[1]->[0]}, @{$_[3]->[0]};
						  push @{$_[1]->[1]}, @{$_[3]->[1]};
						  $_[1];
					          }
	],
	[#Rule 37
		 '@6-1', 0,
sub
#line 194 "yapp/astma2-fact.yp"
{ $_[0]->{USER}->{role} = $_[0]->{USER}->{ctx}->[0] }
	],
	[#Rule 38
		 '@7-3', 0,
sub
#line 195 "yapp/astma2-fact.yp"
{                         $_[0]->{USER}->{ctx}->[0] = undef }
	],
	[#Rule 39
		 'role', 5,
sub
#line 196 "yapp/astma2-fact.yp"
{
			                        [ [ ($_[0]->{USER}->{role}) x scalar @{$_[5]} ], $_[5] ]
						}
	],
	[#Rule 40
		 '@8-1', 0,
sub
#line 201 "yapp/astma2-fact.yp"
{ $_[0]->{USER}->{ctx}->[0] = undef }
	],
	[#Rule 41
		 'identifications', 2,
sub
#line 202 "yapp/astma2-fact.yp"
{ [ $_[1] ] }
	],
	[#Rule 42
		 '@9-2', 0,
sub
#line 203 "yapp/astma2-fact.yp"
{ $_[0]->{USER}->{ctx}->[0] = undef }
	],
	[#Rule 43
		 'identifications', 3,
sub
#line 204 "yapp/astma2-fact.yp"
{ push @{$_[1]}, $_[2]; $_[1]; }
	],
	[#Rule 44
		 'attachments', 0, undef
	],
	[#Rule 45
		 'attachments', 3, undef
	],
	[#Rule 46
		 'attachments', 4, undef
	],
	[#Rule 47
		 'attachments', 2, undef
	],
	[#Rule 48
		 'attachments', 3, undef
	],
	[#Rule 49
		 'attachments', 2, undef
	],
	[#Rule 50
		 'attachments', 3, undef
	],
	[#Rule 51
		 'relative', 0, undef
	],
	[#Rule 52
		 'relative', 3, undef
	],
	[#Rule 53
		 'upcomma', 0, undef
	],
	[#Rule 54
		 'upcomma', 1, undef
	],
	[#Rule 55
		 'predefined_inlines', 1,
sub
#line 224 "yapp/astma2-fact.yp"
{ 'isa' }
	],
	[#Rule 56
		 'predefined_inlines', 1,
sub
#line 225 "yapp/astma2-fact.yp"
{ 'subclasses' }
	],
	[#Rule 57
		 'predefined_inlines', 1, undef
	],
	[#Rule 58
		 '@10-2', 0,
sub
#line 229 "yapp/astma2-fact.yp"
{ unshift @{$_[0]->{USER}->{ctx}}, undef; }
	],
	[#Rule 59
		 '@11-4', 0,
sub
#line 230 "yapp/astma2-fact.yp"
{
#  warn " expand ctx ".Dumper $_[0]->{USER}->{ctx};
				my $left      = $_[0]->{USER}->{ctx}->[1];
				my $ted       = $_[1];
				my $right     = $_[0]->{USER}->{ctx}->[0];
				my $store     = $_[0]->{USER}->{store};
                                my $params    = $_[2];

#warn "left $left ted $ted right $right";

				if ($ted eq 'subclasses') {
				    $store->assert ([ undef,                          # LID
						      undef,                          # SCOPE
						      'is-subclass-of',               # TYPE
						      TM->ASSOC,                      # KIND
						      [ 'subclass',  'superclass' ],  # ROLES
						      [ $left,       $right ],        # PLAYERS
						      undef ] );
				} elsif ($ted eq 'isa') {
				    $store->assert ([ undef,                   	      # LID
						      undef,                   	      # SCOPE
						      'isa',                  	      # TYPE
						      TM->ASSOC,        	      # KIND
						      [ 'instance', 'class' ], 	      # ROLES
						      [ $left,       $right ],	      # PLAYERS
						      undef ] );
				} elsif ($ted eq 'hasa') {                            # same, but other way round
				    $store->assert ([ undef,                   	      # LID
						      undef,                   	      # SCOPE
						      'isa',               	      # TYPE
						      TM->ASSOC,        	      # KIND
						      [ 'instance', 'class' ], 	      # ROLES
						      [ $right,     $left ],	      # PLAYERS
						      undef ] );
				} else {
				    $_[0]->YYData->{INPUT} .= "\n" .
    					                      _expand_template ($store,
										$ted,
										{ %$params,
										  '_left' => $left,
										  '_right' => $right})      # compute the expanded version
                                                            . "\n";                                         # extend the text at the end;
				}
			    }
	],
	[#Rule 60
		 'expansion', 6,
sub
#line 275 "yapp/astma2-fact.yp"
{ shift @{$_[0]->{USER}->{ctx}}; }
	],
	[#Rule 61
		 'identification', 1,
sub
#line 278 "yapp/astma2-fact.yp"
{
#    warn "tid: >>".$_[1]."<<";
                                 if (! defined $_[1]) {                                                     # wildcard
				     $_[0]->{USER}->{ctx}->[0] ||= $_[0]->{USER}->{store}->internalize (sprintf "uuid-%010d", $TM::toplet_ctr++);
				 } elsif (ref ($_[1])) {                                                    # reference means indicator
                                     $_[0]->{USER}->{ctx}->[0] = $_[0]->{USER}->{store}->internalize ($_[0]->{USER}->{ctx}->[0] => $_[1]);
				 } elsif ($_[1] =~ /^\w+:.+/) {                                             # URI means subject address
                                     $_[0]->{USER}->{ctx}->[0] = $_[0]->{USER}->{store}->internalize ($_[0]->{USER}->{ctx}->[0] => $_[1]);
				 } else {                                                                   # some lousy identifier
#   warn "checking for context ".Dumper $_[0]->{USER}->{ctx}->[0] ;
				     die "duplicate ID: $_[1] and $_[0]->{USER}->{ctx}->[0]"
					 if ($_[0]->{USER}->{ctx}->[0]);                                    # we already have an identifier!
				     $_[0]->{USER}->{ctx}->[0] = $_[0]->{USER}->{store}->internalize ($_[1]);
				 }
                                 $_[1] = $_[0]->{USER}->{ctx}->[0];                                     # whatever that was, that's it
			     }
	],
	[#Rule 62
		 '@12-4', 0,
sub
#line 296 "yapp/astma2-fact.yp"
{ $_[0]->{USER}->{value} = 1 }
	],
	[#Rule 63
		 'characteristic', 6,
sub
#line 297 "yapp/astma2-fact.yp"
{
				my $ctype = $_[1];
				my $cclass;                                        # we do not yet know what this will be
				if ($_[3]) {                                       # there is a type specified
				    $cclass = $_[3];                               # take this to be the class of what ctype is
				} elsif ($_[1] =~ /.*name$/) {                     # looks like a name
				    if ($_[6]->[1] eq XSD_STRING) {                # but we check first what type the value is
					$cclass = 'name';                          # for a string we allow it to be a name
				    } else {
					$cclass = 'occurrence';                    # otherwise, we guess it is an occurrence
				    }
				} else {                                           # type does not end with 'name'
				    $cclass = 'occurrence';                        # this is then an occurrence
				}

				if ($cclass ne $ctype) { # a new instance was introduced
				    $store->assert ([ undef,                   	      # LID
						      undef,                   	      # SCOPE
						      'is-subclass-of',        	      # TYPE
						      TM->ASSOC,        	      # KIND
						      [ 'subclass', 'superclass' ],   # ROLES
						      [ $ctype,      $cclass ],	      # PLAYERS
						      undef ] );
				}
#  warn "char $_[1] ctx ".Dumper $_[0]->{USER}->{ctx};
				$_[0]->{USER}->{store}->assert (                                                  #
								[
								 undef,                                           # LID
								 $_[2],                                           # SCOPE (undef is ok)
								 $_[1],                                           # TYPE

								 $cclass eq 'name'       ? TM->NAME
                                                                 :
                                                                ($cclass eq 'occurrence' ? TM->OCC
                                                                                         : TM->ASSOC),            # KIND
								 [ 'thing', 'value' ],                            # ROLES
								 [ $_[0]->{USER}->{ctx}->[0],     $_[6] ],        # PLAYERS
								 undef
								 ]
								);
			    }
	],
	[#Rule 64
		 'scope', 0, undef
	],
	[#Rule 65
		 'scope', 2,
sub
#line 341 "yapp/astma2-fact.yp"
{ $_[2]; }
	],
	[#Rule 66
		 'type', 0, undef
	],
	[#Rule 67
		 'type', 2,
sub
#line 345 "yapp/astma2-fact.yp"
{ $_[2] }
	],
	[#Rule 68
		 'tid', 1,
sub
#line 353 "yapp/astma2-fact.yp"
{   $_[1]; }
	],
	[#Rule 69
		 'tid', 1,
sub
#line 354 "yapp/astma2-fact.yp"
{   undef; }
	],
	[#Rule 70
		 'tid', 1,
sub
#line 355 "yapp/astma2-fact.yp"
{ \ $_[1]; }
	],
	[#Rule 71
		 'tid', 2,
sub
#line 356 "yapp/astma2-fact.yp"
{   $_[2]; }
	],
	[#Rule 72
		 'tid', 2,
sub
#line 357 "yapp/astma2-fact.yp"
{ \ $_[2]; }
	],
	[#Rule 73
		 'tid', 1,
sub
#line 358 "yapp/astma2-fact.yp"
{
                                                     my $baseuri = $_[0]->{USER}->{store}->baseuri;
                                                     $_[1] =~ /^$baseuri(.+)/ ? $1 : \ $_[1];
                                                     }
	]
],
				   %options);
    $self->{USER}->{store}         = $store;
    return bless $self, $class;
}

#line 690 "yapp/astma2-fact.yp"


sub _Error {
    die "Syntax error: Found ".$_[0]->YYCurtok." but expected ".join (' or ', $_[0]->YYExpect);
}

sub _Lexer {
    my $parser = shift;
    my $refINPUT = \$parser->YYData->{INPUT};

#    study $$refINPUT;

    $$refINPUT                                        or  return ('',              undef);  # this is the end of the world, as we know it
    $$refINPUT =~ s/^[ \t]+//o;

#warn "lexer ($parser->{USER}->{string}):>>>".$parser->YYData->{INPUT};

    $$refINPUT =~ s/^\n\n//so                         and return ('DOT',       	   undef);
    $$refINPUT =~ s/^\n$//so                          and return ('DOT',       	   undef);
    $$refINPUT =~ s/^\.//so                           and return ('DOT',       	   undef);
    $$refINPUT =~ s/^\~//so                           and return ('TILDE',     	   undef);
    $$refINPUT =~ s/^=//o                             and return ('EQUAL',   	   undef);
    $$refINPUT =~ s/^://o                             and return ('COLON',         undef);
    $$refINPUT =~ s/^,\s*(which|who)\b//o             and return ('DOWNCOMMA',     undef);
    $$refINPUT =~ s/^,(?!\s*(which|who)\b)//o         and return ('COMMA',         undef);

    $$refINPUT =~ s/^is-?a\b//o                       and return ('ISA',       	   undef);
#    $$refINPUT =~ s/^has-?a\b//o                      and return ('TED',       	   'hasa');
    $$refINPUT =~ s/^subclasses\b//o                  and return ('SUBCL',     	   undef);

    $$refINPUT =~ s/^has\b//o                         and return ('HAS',       	   undef);

    unless ($parser->{USER}->{assoc}) {                                                    # in topic context this corresponds to HAS
	$$refINPUT =~ s/^\n\s*(?=\w+\s*[:<@]\s)//so   and return ('HAS',           undef); # positive look-ahead for things like <CR>bn :<blank>
    }

    $$refINPUT =~ s/^(which|who)\b//o                 and return ('WHICH',         undef);
    $$refINPUT =~ s/^and(\s+(which|who))?\b//so       and return ('WHICH',         undef); # (can go over lines)


    $$refINPUT =~ s/^\n//so                           and return ('EOL',       	   undef);

    $$refINPUT =~ s/^{//so                            and return ('BRA',     	   undef);
    $$refINPUT =~ s/^}//so                            and return ('KET',     	   undef);
    $$refINPUT =~ s/^\(//so                           and return ('LPAREN',        undef);
    $$refINPUT =~ s/^\)//so                           and return ('RPAREN',        undef);

    $$refINPUT =~ s/^<<//o                            and return ('REIFIES',   	   undef);
    $$refINPUT =~ s/^<//o                             and return ('SUBCL',   	   undef);

    $$refINPUT =~ s/^>>//o                            and return ('ISREIFIED', 	   undef);


    $$refINPUT =~ s/^\*//o                            and return ('WILDCARD',      undef);

    $$refINPUT =~ s/^(\d{4}-\d{1,2}-\d{1,2})(T(\d{1,2}):(\d{2}))?//o
                                                      and return ('DATE',          sprintf "urn:x-date:%s:%02d:%02d", $1, $3 || 0, $4 || 0); # is a date

    $$refINPUT =~ s/^bn\b//o                          and return ('ID',      	   "name");
    $$refINPUT =~ s/^oc\b//o                          and return ('ID',       	   "occurrence");
    $$refINPUT =~ s/^in\b//o                          and return ('ID',       	   "occurrence");

    if ($parser->{USER}->{value}) {  # parser said we should expect a value now
##warn "expect value >>".$$refINPUT."<<";
	$$refINPUT =~ s/^\"{3}(.*?)\"{3}(?=\n)//so    and
#            (warn "returning multi $1" or 1) and
	    (undef $parser->{USER}->{value}           or  return ('VALUE',         new TM::Literal ($1)));
	$$refINPUT =~ s/^\"(.*?)\"(^^(\S+))?//o       and
#            (warn "returning simlg $1" or 1) and
	    (undef $parser->{USER}->{value}           or  return ('VALUE',         new TM::Literal ($1, $3)));
	$$refINPUT =~ s/^(\d+\.\d+)//o                and
#            (warn "returning float $1" or 1) and
	    (undef $parser->{USER}->{value}           or  return ('VALUE',         new TM::Literal  ($1, TM::Literal->DECIMAL)));
	$$refINPUT =~ s/^(\d+)//o                     and
#            (warn "returning int $1" or 1) and
	    (undef $parser->{USER}->{value}           or  return ('VALUE',         new TM::Literal  ($1, TM::Literal->INTEGER)));
	$$refINPUT =~ s/^(\w+:\S+)//o                 and
#            (warn "returning uri $1" or 1) and
	    (undef $parser->{USER}->{value}           or  return ('VALUE',         new TM::Literal  ($1, TM::Literal->URI)));
	$$refINPUT =~ s/^(.+?)(?=\s*\n)//o            and
#            (warn "returning unquo $1" or 1) and
	    (undef $parser->{USER}->{value}           or  return ('VALUE',         new TM::Literal  ($1)));

##            (warn "returning $1" or 1) and
##	    (undef $parser->{USER}->{value}           or  return ('VALUE',         new TM::Literal ($1)));
##warn "no string";
    }

## unfortunately, this does not what I want:
##  $$refINPUT =~ s/^([A-Za-z][A-Za-z0-9_-]*)(?!:)//o and return ('ID',        $1); # negative look-ahead
## tricky optimization: don't ask
    my $aux;                                                                        # need this to store identifier/uri prefix temporarily (optimization)
    my $aux2;                                                                       # need this to store ontology URL, if there is one
    $$refINPUT =~ s/^([A-Za-z][.A-Za-z0-9_-]*)//o     and $aux = $1                 # save this for later
	                                              and $$refINPUT !~ /^:[\w\/]/
                                                      and return (_is_template ($parser->{USER}->{store},
										$aux) 
                                                               ? 'TED' : 'ID', $aux);

    $$refINPUT =~ s/^(:([^\s\)\(\]\[]+))//o           and return ('URI',       ( $aux2 = _is_ontology ($parser->{USER}->{store},
												       $parser->{USER}->{prefixes},
												       $aux)) ? $aux2."#$2" : $aux.$1); # is a URL/URN actually

    $$refINPUT =~ s/^@//so                            and return ('AT',        undef);


    $$refINPUT =~ s/^%include\s+(.*?)(?=\n)//so       and return ('INCLUDE',   $1); # positive look-ahead
    $$refINPUT =~ s/^%log\s+(.*?)(?=\n)//so           and return ('LOG',       $1); # positive look-ahead
    $$refINPUT =~ s/^%cancel(?=\n)//so                and return ('CANCEL',    $1); # positive look-ahead
    $$refINPUT =~ s/^%version\s+(\d+\.\d+)(?=\n)//so  and return ('VERSION',   $1); # positive look-ahead

    $$refINPUT =~ s/^%encoding\s+(.*?)(?=\n)//so      and return ('ENCODING',  $1); # positive look-ahead


#    $$refINPUT =~ s/^\[//so                           and return ('LBRACKET',  undef);
#    $$refINPUT =~ s/^\]//so                           and return ('RBRACKET',  undef);

    $$refINPUT =~ s/^(.)//so                          and return ($1,          $1); # should not be an issue except on error
}

sub _is_template {
    my $store = shift;
    my $id    = shift;

    my $t = $store->tids ($id) or return undef;
    return $store->is_a ($t, $store->tids (\ TEMPLATE));
}

sub _is_ontology {
    my $store    = shift;
    my $prefixes = shift;
    my $prefix   = shift;

#warn "texting prefix '$prefix' on ".Dumper $prefixes;
    return $prefixes->{$prefix} if $prefixes->{$prefix};                                  # cache

    if ($prefix eq 'astma') {                                                             # this is one predefined prefix
	$prefixes->{$prefix} = ASTMA;
    } elsif ($prefix eq 'xsd') {                                                          # this is the other predefined prefix
	$prefixes->{$prefix} = XSD;
    } else {
	my $p = $store->tids ($prefix);
	if ($p && $store->is_a ($p, $store->tids (\ ONTOLOGY))) {                         # is the topic an instance of astma:ontology?
	    $prefixes->{$prefix} = 
                $store->toplet ($store->tids ($prefix))->[TM->INDICATORS]->[0]            # then take its subject indicator as expanded URI
		or die "no subject indicator for '$prefix' provided";                     # if there is none, complain
	}
    }
#warn "prefixes now".Dumper $prefixes;
    return $prefixes->{$prefix};
}

sub parse {
    my $self               = shift;
    $self->YYData->{INPUT} = shift;

#warn "parse";

    $self->YYData->{INPUT} =~ s/\r/\n/sg;
    $self->YYData->{INPUT} =~ s/(?<!\\)\\\n//sg;   # a \, but not a \\
    $self->YYData->{INPUT} =~ s/ \+{3} /\n/g;      # replace _+++_ with \n
    $self->YYData->{INPUT} =~ s/\+{4}/+++/g;       # stuffed ++++ cleanout
    $self->YYData->{INPUT} =~ s/^\#.*?\n/\n/mg;    # # at there start of every line -> gone
    $self->YYData->{INPUT} =~ s/\s+\#.*?\n/\n/mg;  # anything which starts with <blank>#, all blanks are ignored
    $self->YYData->{INPUT} =~ s/\n\n\n+/\n\n/sg;
    $self->YYData->{INPUT} =~ s/\n\s+\n+/\n\n/sg;  # trimm lines with blanks only

    # we not only capture what is said EXPLICITELY in the map, we also collect implicit knowledge
    # we could add this immediately into the map at parsing, but it would slow the process down and
    # it would probably duplicate/complicate things
    $self->{USER}->{implicits} = {
	'isa-thing'  => undef,                                          # just let them spring into existence
	'isa-scope'  => undef,                                          # just let them spring into existence
	'subclasses' => undef
	};
#    $self->{USER}->{topic_count} = 0;

#   $self->{USER}->{templates} = new TM (psis => undef, baseuri => $self->{USER}->{store}->baseuri);
    $self->{USER}->{prefixes}  = {};

    eval {
	$self->YYParse ( yylex => \&_Lexer, yyerror => \&_Error); #, yydebug => 0x01 );
    }; if ($@ =~ /^Cancelled/) {
	warn $@;                                                         # de-escalate Cancelling to warning
    } elsif ($@) {
	die $@;                                                          # otherwise re-raise the exception
    }
#warn "in parse end ".Dumper $self->{USER}->{implicits};
    { # resolving implicit stuff
	my $implicits = $self->{USER}->{implicits};
	my $store     = $self->{USER}->{store};

	{ # all super/subclasses
	    foreach my $superclass (keys %{$implicits->{'subclasses'}}) {
		$store->assert ( map {
		    [ undef, undef, 'is-subclass-of', TM->ASSOC, [ 'superclass', 'subclass' ], [ $superclass, $_ ] ] 
		    }  keys %{$implicits->{'subclasses'}->{$superclass}});
	    }
	}
	{ # all things in isa-things are THINGS, simply add them
	    $store->internalize (map { $_ => undef } keys %{$implicits->{'isa-thing'}});
	}
	{ # establishing the scoping topics
	    $store->assert (map {
                                 [ undef, undef, 'isa', TM->ASSOC, [ 'class', 'instance' ], [ 'scope', $_ ] ] 
				 } keys %{$implicits->{'isa-scope'}});
	}
        $store->externalize ( $store->instances ($store->tids (\ TEMPLATE)) );                  # "removing templates now";
    }
    return $self->{USER}->{store};
}

#my $f = new TM::AsTMa::Fact;
#$f->Run;


1;
