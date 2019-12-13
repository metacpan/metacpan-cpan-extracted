####################################################################
#
#    This file was generated using Parse::Yapp version 1.21.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package OPTiMaDe::Filter::Parser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 3 "Parser.yp"


use warnings;

use Scalar::Util qw(blessed);

use OPTiMaDe::Filter::AndOr;
use OPTiMaDe::Filter::Comparison;
use OPTiMaDe::Filter::Known;
use OPTiMaDe::Filter::ListComparison;
use OPTiMaDe::Filter::Negation;
use OPTiMaDe::Filter::Property;
use OPTiMaDe::Filter::Zip;

our $allow_LIKE_operator = 0;



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.21',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'string' => 10,
			'number' => 6,
			'NOT' => 14,
			"(" => 9,
			'identifier' => 8
		},
		GOTOS => {
			'comparison' => 5,
			'expression' => 4,
			'filter' => 2,
			'property_first_comparison' => 3,
			'constant' => 1,
			'constant_first_comparison' => 13,
			'property' => 12,
			'expression_phrase' => 15,
			'expression_clause' => 11,
			'openingbrace' => 7
		}
	},
	{#State 1
		ACTIONS => {
			"=" => 19,
			">" => 18,
			"<" => 16,
			"!" => 17
		},
		GOTOS => {
			'operator' => 20,
			'value_op_rhs' => 21
		}
	},
	{#State 2
		ACTIONS => {
			'' => 22
		}
	},
	{#State 3
		DEFAULT => -27
	},
	{#State 4
		DEFAULT => -1
	},
	{#State 5
		DEFAULT => -22
	},
	{#State 6
		DEFAULT => -3
	},
	{#State 7
		ACTIONS => {
			'number' => 6,
			'NOT' => 14,
			'string' => 10,
			'identifier' => 8,
			"(" => 9
		},
		GOTOS => {
			'expression_clause' => 11,
			'expression_phrase' => 15,
			'constant_first_comparison' => 13,
			'property' => 12,
			'openingbrace' => 7,
			'expression' => 23,
			'comparison' => 5,
			'constant' => 1,
			'property_first_comparison' => 3
		}
	},
	{#State 8
		DEFAULT => -57
	},
	{#State 9
		DEFAULT => -59
	},
	{#State 10
		DEFAULT => -2
	},
	{#State 11
		ACTIONS => {
			'OR' => 24
		},
		DEFAULT => -18
	},
	{#State 12
		ACTIONS => {
			'IS' => 42,
			">" => 18,
			'LIKE' => 30,
			'CONTAINS' => 31,
			"<" => 16,
			"!" => 17,
			'STARTS' => 28,
			"=" => 19,
			":" => 27,
			'LENGTH' => 26,
			"." => 40,
			'HAS' => 38,
			'ENDS' => 35
		},
		GOTOS => {
			'property_zip_addon' => 34,
			'colon' => 41,
			'known_op_rhs' => 33,
			'length_op_rhs' => 32,
			'fuzzy_string_op_rhs' => 29,
			'set_op_rhs' => 39,
			'set_zip_op_rhs' => 37,
			'operator' => 20,
			'value_op_rhs' => 25,
			'dot' => 36
		}
	},
	{#State 13
		DEFAULT => -26
	},
	{#State 14
		ACTIONS => {
			'identifier' => 8,
			"(" => 9,
			'number' => 6,
			'string' => 10
		},
		GOTOS => {
			'property' => 12,
			'comparison' => 43,
			'constant_first_comparison' => 13,
			'property_first_comparison' => 3,
			'constant' => 1,
			'openingbrace' => 44
		}
	},
	{#State 15
		ACTIONS => {
			'AND' => 45
		},
		DEFAULT => -20
	},
	{#State 16
		ACTIONS => {
			"=" => 46
		},
		DEFAULT => -64
	},
	{#State 17
		ACTIONS => {
			"=" => 47
		}
	},
	{#State 18
		ACTIONS => {
			"=" => 48
		},
		DEFAULT => -66
	},
	{#State 19
		DEFAULT => -68
	},
	{#State 20
		ACTIONS => {
			'identifier' => 8,
			'string' => 49,
			'number' => 52
		},
		GOTOS => {
			'property' => 50,
			'value' => 51
		}
	},
	{#State 21
		DEFAULT => -28
	},
	{#State 22
		DEFAULT => 0
	},
	{#State 23
		ACTIONS => {
			")" => 54
		},
		GOTOS => {
			'closingbrace' => 53
		}
	},
	{#State 24
		ACTIONS => {
			'NOT' => 14,
			'number' => 6,
			'string' => 10,
			'identifier' => 8,
			"(" => 9
		},
		GOTOS => {
			'property_first_comparison' => 3,
			'constant' => 1,
			'comparison' => 5,
			'expression' => 55,
			'openingbrace' => 7,
			'expression_phrase' => 15,
			'constant_first_comparison' => 13,
			'property' => 12,
			'expression_clause' => 11
		}
	},
	{#State 25
		DEFAULT => -29
	},
	{#State 26
		ACTIONS => {
			'identifier' => 8,
			"<" => 16,
			"!" => 17,
			">" => 18,
			"=" => 19,
			'number' => 52,
			'string' => 49
		},
		GOTOS => {
			'value' => 57,
			'property' => 50,
			'operator' => 56
		}
	},
	{#State 27
		DEFAULT => -63
	},
	{#State 28
		ACTIONS => {
			'identifier' => 8,
			'number' => 52,
			'WITH' => 58,
			'string' => 49
		},
		GOTOS => {
			'value' => 59,
			'property' => 50
		}
	},
	{#State 29
		DEFAULT => -31
	},
	{#State 30
		ACTIONS => {
			'number' => 52,
			'string' => 49,
			'identifier' => 8
		},
		GOTOS => {
			'property' => 50,
			'value' => 60
		}
	},
	{#State 31
		ACTIONS => {
			'identifier' => 8,
			'number' => 52,
			'string' => 49
		},
		GOTOS => {
			'property' => 50,
			'value' => 61
		}
	},
	{#State 32
		DEFAULT => -34
	},
	{#State 33
		DEFAULT => -30
	},
	{#State 34
		ACTIONS => {
			'HAS' => 63,
			":" => 27
		},
		GOTOS => {
			'colon' => 62
		}
	},
	{#State 35
		ACTIONS => {
			'identifier' => 8,
			'WITH' => 65,
			'string' => 49,
			'number' => 52
		},
		GOTOS => {
			'value' => 64,
			'property' => 50
		}
	},
	{#State 36
		ACTIONS => {
			'identifier' => 66
		}
	},
	{#State 37
		DEFAULT => -33
	},
	{#State 38
		ACTIONS => {
			">" => 18,
			'number' => 52,
			'ALL' => 68,
			'ANY' => 71,
			"<" => 16,
			'ONLY' => 67,
			"!" => 17,
			"=" => 19,
			'string' => 49,
			'identifier' => 8
		},
		GOTOS => {
			'property' => 50,
			'operator' => 69,
			'value' => 70
		}
	},
	{#State 39
		DEFAULT => -32
	},
	{#State 40
		DEFAULT => -61
	},
	{#State 41
		ACTIONS => {
			'identifier' => 8
		},
		GOTOS => {
			'property' => 72
		}
	},
	{#State 42
		ACTIONS => {
			'UNKNOWN' => 74,
			'KNOWN' => 73
		}
	},
	{#State 43
		DEFAULT => -24
	},
	{#State 44
		ACTIONS => {
			"(" => 9,
			'identifier' => 8,
			'number' => 6,
			'NOT' => 14,
			'string' => 10
		},
		GOTOS => {
			'expression_clause' => 11,
			'expression_phrase' => 15,
			'property' => 12,
			'constant_first_comparison' => 13,
			'openingbrace' => 7,
			'expression' => 75,
			'comparison' => 5,
			'constant' => 1,
			'property_first_comparison' => 3
		}
	},
	{#State 45
		ACTIONS => {
			'string' => 10,
			'NOT' => 14,
			'number' => 6,
			'identifier' => 8,
			"(" => 9
		},
		GOTOS => {
			'property' => 12,
			'constant_first_comparison' => 13,
			'expression_phrase' => 15,
			'expression_clause' => 76,
			'openingbrace' => 7,
			'comparison' => 5,
			'constant' => 1,
			'property_first_comparison' => 3
		}
	},
	{#State 46
		DEFAULT => -65
	},
	{#State 47
		DEFAULT => -69
	},
	{#State 48
		DEFAULT => -67
	},
	{#State 49
		DEFAULT => -4
	},
	{#State 50
		ACTIONS => {
			"." => 40
		},
		DEFAULT => -6,
		GOTOS => {
			'dot' => 36
		}
	},
	{#State 51
		DEFAULT => -35
	},
	{#State 52
		DEFAULT => -5
	},
	{#State 53
		DEFAULT => -23
	},
	{#State 54
		DEFAULT => -60
	},
	{#State 55
		DEFAULT => -19
	},
	{#State 56
		ACTIONS => {
			'identifier' => 8,
			'number' => 52,
			'string' => 49
		},
		GOTOS => {
			'value' => 77,
			'property' => 50
		}
	},
	{#State 57
		DEFAULT => -55
	},
	{#State 58
		ACTIONS => {
			'string' => 49,
			'number' => 52,
			'identifier' => 8
		},
		GOTOS => {
			'value' => 78,
			'property' => 50
		}
	},
	{#State 59
		DEFAULT => -39
	},
	{#State 60
		DEFAULT => -43
	},
	{#State 61
		DEFAULT => -38
	},
	{#State 62
		ACTIONS => {
			'identifier' => 8
		},
		GOTOS => {
			'property' => 79
		}
	},
	{#State 63
		ACTIONS => {
			"<" => 16,
			"!" => 17,
			'ONLY' => 84,
			">" => 18,
			'number' => 52,
			'ALL' => 83,
			'ANY' => 80,
			'identifier' => 8,
			"=" => 19,
			'string' => 49
		},
		GOTOS => {
			'value' => 81,
			'value_zip' => 82,
			'property' => 50,
			'operator' => 85
		}
	},
	{#State 64
		DEFAULT => -41
	},
	{#State 65
		ACTIONS => {
			'identifier' => 8,
			'string' => 49,
			'number' => 52
		},
		GOTOS => {
			'property' => 50,
			'value' => 86
		}
	},
	{#State 66
		DEFAULT => -58
	},
	{#State 67
		ACTIONS => {
			'identifier' => 8,
			"!" => 17,
			"<" => 16,
			">" => 18,
			"=" => 19,
			'number' => 52,
			'string' => 49
		},
		GOTOS => {
			'operator' => 87,
			'property' => 50,
			'value_list' => 88,
			'value' => 89
		}
	},
	{#State 68
		ACTIONS => {
			"<" => 16,
			"!" => 17,
			'identifier' => 8,
			'string' => 49,
			"=" => 19,
			'number' => 52,
			">" => 18
		},
		GOTOS => {
			'operator' => 87,
			'property' => 50,
			'value_list' => 90,
			'value' => 89
		}
	},
	{#State 69
		ACTIONS => {
			'string' => 49,
			'number' => 52,
			'identifier' => 8
		},
		GOTOS => {
			'property' => 50,
			'value' => 91
		}
	},
	{#State 70
		DEFAULT => -44
	},
	{#State 71
		ACTIONS => {
			'string' => 49,
			'number' => 52,
			">" => 18,
			"=" => 19,
			"<" => 16,
			"!" => 17,
			'identifier' => 8
		},
		GOTOS => {
			'property' => 50,
			'operator' => 87,
			'value' => 89,
			'value_list' => 92
		}
	},
	{#State 72
		ACTIONS => {
			"." => 40
		},
		DEFAULT => -53,
		GOTOS => {
			'dot' => 36
		}
	},
	{#State 73
		DEFAULT => -36
	},
	{#State 74
		DEFAULT => -37
	},
	{#State 75
		ACTIONS => {
			")" => 54
		},
		GOTOS => {
			'closingbrace' => 93
		}
	},
	{#State 76
		DEFAULT => -21
	},
	{#State 77
		DEFAULT => -56
	},
	{#State 78
		DEFAULT => -40
	},
	{#State 79
		ACTIONS => {
			"." => 40
		},
		DEFAULT => -54,
		GOTOS => {
			'dot' => 36
		}
	},
	{#State 80
		ACTIONS => {
			'identifier' => 8,
			"!" => 17,
			"<" => 16,
			"=" => 19,
			'number' => 52,
			">" => 18,
			'string' => 49
		},
		GOTOS => {
			'value_zip_list' => 95,
			'value_zip' => 94,
			'operator' => 85,
			'property' => 50,
			'value' => 81
		}
	},
	{#State 81
		ACTIONS => {
			":" => 27
		},
		GOTOS => {
			'value_zip_part' => 97,
			'colon' => 96
		}
	},
	{#State 82
		ACTIONS => {
			":" => 27
		},
		DEFAULT => -49,
		GOTOS => {
			'value_zip_part' => 98,
			'colon' => 96
		}
	},
	{#State 83
		ACTIONS => {
			'identifier' => 8,
			"!" => 17,
			"<" => 16,
			">" => 18,
			"=" => 19,
			'number' => 52,
			'string' => 49
		},
		GOTOS => {
			'value' => 81,
			'property' => 50,
			'operator' => 85,
			'value_zip' => 94,
			'value_zip_list' => 99
		}
	},
	{#State 84
		ACTIONS => {
			"!" => 17,
			"<" => 16,
			'identifier' => 8,
			'string' => 49,
			"=" => 19,
			'number' => 52,
			">" => 18
		},
		GOTOS => {
			'value' => 81,
			'property' => 50,
			'operator' => 85,
			'value_zip_list' => 100,
			'value_zip' => 94
		}
	},
	{#State 85
		ACTIONS => {
			'number' => 52,
			'string' => 49,
			'identifier' => 8
		},
		GOTOS => {
			'property' => 50,
			'value' => 101
		}
	},
	{#State 86
		DEFAULT => -42
	},
	{#State 87
		ACTIONS => {
			'string' => 49,
			'number' => 52,
			'identifier' => 8
		},
		GOTOS => {
			'property' => 50,
			'value' => 102
		}
	},
	{#State 88
		ACTIONS => {
			"," => 104
		},
		DEFAULT => -48,
		GOTOS => {
			'comma' => 103
		}
	},
	{#State 89
		DEFAULT => -7
	},
	{#State 90
		ACTIONS => {
			"," => 104
		},
		DEFAULT => -46,
		GOTOS => {
			'comma' => 103
		}
	},
	{#State 91
		DEFAULT => -45
	},
	{#State 92
		ACTIONS => {
			"," => 104
		},
		DEFAULT => -47,
		GOTOS => {
			'comma' => 103
		}
	},
	{#State 93
		DEFAULT => -25
	},
	{#State 94
		ACTIONS => {
			":" => 27
		},
		DEFAULT => -16,
		GOTOS => {
			'value_zip_part' => 98,
			'colon' => 96
		}
	},
	{#State 95
		ACTIONS => {
			"," => 104
		},
		DEFAULT => -52,
		GOTOS => {
			'comma' => 105
		}
	},
	{#State 96
		ACTIONS => {
			'identifier' => 8,
			"!" => 17,
			"<" => 16,
			"=" => 19,
			'number' => 52,
			">" => 18,
			'string' => 49
		},
		GOTOS => {
			'operator' => 107,
			'property' => 50,
			'value' => 106
		}
	},
	{#State 97
		DEFAULT => -11
	},
	{#State 98
		DEFAULT => -13
	},
	{#State 99
		ACTIONS => {
			"," => 104
		},
		DEFAULT => -51,
		GOTOS => {
			'comma' => 105
		}
	},
	{#State 100
		ACTIONS => {
			"," => 104
		},
		DEFAULT => -50,
		GOTOS => {
			'comma' => 105
		}
	},
	{#State 101
		ACTIONS => {
			":" => 27
		},
		GOTOS => {
			'value_zip_part' => 108,
			'colon' => 96
		}
	},
	{#State 102
		DEFAULT => -8
	},
	{#State 103
		ACTIONS => {
			'identifier' => 8,
			"<" => 16,
			"!" => 17,
			"=" => 19,
			">" => 18,
			'number' => 52,
			'string' => 49
		},
		GOTOS => {
			'property' => 50,
			'operator' => 109,
			'value' => 110
		}
	},
	{#State 104
		DEFAULT => -62
	},
	{#State 105
		ACTIONS => {
			"=" => 19,
			">" => 18,
			'number' => 52,
			'string' => 49,
			'identifier' => 8,
			"!" => 17,
			"<" => 16
		},
		GOTOS => {
			'value_zip' => 111,
			'property' => 50,
			'operator' => 85,
			'value' => 81
		}
	},
	{#State 106
		DEFAULT => -14
	},
	{#State 107
		ACTIONS => {
			'identifier' => 8,
			'string' => 49,
			'number' => 52
		},
		GOTOS => {
			'value' => 112,
			'property' => 50
		}
	},
	{#State 108
		DEFAULT => -12
	},
	{#State 109
		ACTIONS => {
			'identifier' => 8,
			'number' => 52,
			'string' => 49
		},
		GOTOS => {
			'value' => 113,
			'property' => 50
		}
	},
	{#State 110
		DEFAULT => -9
	},
	{#State 111
		ACTIONS => {
			":" => 27
		},
		DEFAULT => -17,
		GOTOS => {
			'colon' => 96,
			'value_zip_part' => 98
		}
	},
	{#State 112
		DEFAULT => -15
	},
	{#State 113
		DEFAULT => -10
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'filter', 1, undef
	],
	[#Rule 2
		 'constant', 1, undef
	],
	[#Rule 3
		 'constant', 1, undef
	],
	[#Rule 4
		 'value', 1, undef
	],
	[#Rule 5
		 'value', 1, undef
	],
	[#Rule 6
		 'value', 1, undef
	],
	[#Rule 7
		 'value_list', 1,
sub
#line 36 "Parser.yp"
{
                return [ [ '=', $_[1] ] ];
            }
	],
	[#Rule 8
		 'value_list', 2,
sub
#line 40 "Parser.yp"
{
                return [ [ @_[1..$#_] ] ];
            }
	],
	[#Rule 9
		 'value_list', 3,
sub
#line 44 "Parser.yp"
{
                push @{$_[1]}, [ '=', $_[3] ];
                return $_[1];
            }
	],
	[#Rule 10
		 'value_list', 4,
sub
#line 49 "Parser.yp"
{
                push @{$_[1]}, [ $_[3], $_[4] ];
                return $_[1];
            }
	],
	[#Rule 11
		 'value_zip', 2,
sub
#line 56 "Parser.yp"
{
                return [ [ '=', $_[1] ], $_[2] ];
            }
	],
	[#Rule 12
		 'value_zip', 3,
sub
#line 60 "Parser.yp"
{
                return [ [ $_[1], $_[2] ], $_[3] ];
            }
	],
	[#Rule 13
		 'value_zip', 2,
sub
#line 64 "Parser.yp"
{
                push @{$_[1]}, $_[2];
                return $_[1];
            }
	],
	[#Rule 14
		 'value_zip_part', 2,
sub
#line 71 "Parser.yp"
{
                    return [ '=', $_[2] ];
                }
	],
	[#Rule 15
		 'value_zip_part', 3,
sub
#line 75 "Parser.yp"
{
                    return [ $_[2], $_[3] ];
                }
	],
	[#Rule 16
		 'value_zip_list', 1,
sub
#line 81 "Parser.yp"
{
                    return [ $_[1] ];
                }
	],
	[#Rule 17
		 'value_zip_list', 3,
sub
#line 85 "Parser.yp"
{
                    push @{$_[1]}, $_[3];
                    return $_[1];
                }
	],
	[#Rule 18
		 'expression', 1, undef
	],
	[#Rule 19
		 'expression', 3,
sub
#line 95 "Parser.yp"
{
                return OPTiMaDe::Filter::AndOr->new( @_[1..$#_] );
            }
	],
	[#Rule 20
		 'expression_clause', 1, undef
	],
	[#Rule 21
		 'expression_clause', 3,
sub
#line 102 "Parser.yp"
{
                        return OPTiMaDe::Filter::AndOr->new( @_[1..$#_] );
                    }
	],
	[#Rule 22
		 'expression_phrase', 1, undef
	],
	[#Rule 23
		 'expression_phrase', 3,
sub
#line 109 "Parser.yp"
{
                        return $_[2];
                    }
	],
	[#Rule 24
		 'expression_phrase', 2,
sub
#line 113 "Parser.yp"
{
                        return OPTiMaDe::Filter::Negation->new( $_[2] );
                    }
	],
	[#Rule 25
		 'expression_phrase', 4,
sub
#line 117 "Parser.yp"
{
                        return OPTiMaDe::Filter::Negation->new( $_[3] );
                    }
	],
	[#Rule 26
		 'comparison', 1, undef
	],
	[#Rule 27
		 'comparison', 1, undef
	],
	[#Rule 28
		 'constant_first_comparison', 2,
sub
#line 125 "Parser.yp"
{
                                $_[2]->unshift_operand( $_[1] );
                                return $_[2];
                            }
	],
	[#Rule 29
		 'property_first_comparison', 2,
sub
#line 132 "Parser.yp"
{
                                    $_[2]->unshift_operand( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 30
		 'property_first_comparison', 2,
sub
#line 137 "Parser.yp"
{
                                    $_[2]->property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 31
		 'property_first_comparison', 2,
sub
#line 142 "Parser.yp"
{
                                    $_[2]->unshift_operand( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 32
		 'property_first_comparison', 2,
sub
#line 147 "Parser.yp"
{
                                    $_[2]->property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 33
		 'property_first_comparison', 2,
sub
#line 152 "Parser.yp"
{
                                    $_[2]->unshift_property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 34
		 'property_first_comparison', 2,
sub
#line 157 "Parser.yp"
{
                                    $_[2]->property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 35
		 'value_op_rhs', 2,
sub
#line 164 "Parser.yp"
{
                    my $cmp = OPTiMaDe::Filter::Comparison->new( $_[1] );
                    $cmp->push_operand( $_[2] );
                    return $cmp;
                }
	],
	[#Rule 36
		 'known_op_rhs', 2,
sub
#line 172 "Parser.yp"
{
                    return OPTiMaDe::Filter::Known->new( 1 );
                }
	],
	[#Rule 37
		 'known_op_rhs', 2,
sub
#line 176 "Parser.yp"
{
                    return OPTiMaDe::Filter::Known->new( 0 );
                }
	],
	[#Rule 38
		 'fuzzy_string_op_rhs', 2,
sub
#line 182 "Parser.yp"
{
                            my $cmp = OPTiMaDe::Filter::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 39
		 'fuzzy_string_op_rhs', 2,
sub
#line 188 "Parser.yp"
{
                            my $cmp = OPTiMaDe::Filter::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 40
		 'fuzzy_string_op_rhs', 3,
sub
#line 194 "Parser.yp"
{
                            my $cmp = OPTiMaDe::Filter::Comparison->new( "$_[1] $_[2]" );
                            $cmp->push_operand( $_[3] );
                            return $cmp;
                        }
	],
	[#Rule 41
		 'fuzzy_string_op_rhs', 2,
sub
#line 200 "Parser.yp"
{
                            my $cmp = OPTiMaDe::Filter::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 42
		 'fuzzy_string_op_rhs', 3,
sub
#line 206 "Parser.yp"
{
                            my $cmp = OPTiMaDe::Filter::Comparison->new( "$_[1] $_[2]" );
                            $cmp->push_operand( $_[3] );
                            return $cmp;
                        }
	],
	[#Rule 43
		 'fuzzy_string_op_rhs', 2,
sub
#line 212 "Parser.yp"
{
                            my $cmp = OPTiMaDe::Filter::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 44
		 'set_op_rhs', 2,
sub
#line 220 "Parser.yp"
{
                my $lc = OPTiMaDe::Filter::ListComparison->new( $_[1] );
                $lc->values( [ [ '=', $_[2] ] ] );
                return $lc;
            }
	],
	[#Rule 45
		 'set_op_rhs', 3,
sub
#line 226 "Parser.yp"
{
                my $lc = OPTiMaDe::Filter::ListComparison->new( $_[1] );
                $lc->values( [ [ $_[2], $_[3] ] ] );
                return $lc;
            }
	],
	[#Rule 46
		 'set_op_rhs', 3,
sub
#line 232 "Parser.yp"
{
                my $lc = OPTiMaDe::Filter::ListComparison->new( "$_[1] $_[2]" );
                $lc->values( $_[3] );
                return $lc;
            }
	],
	[#Rule 47
		 'set_op_rhs', 3,
sub
#line 238 "Parser.yp"
{
                my $lc = OPTiMaDe::Filter::ListComparison->new( "$_[1] $_[2]" );
                $lc->values( $_[3] );
                return $lc;
            }
	],
	[#Rule 48
		 'set_op_rhs', 3,
sub
#line 244 "Parser.yp"
{
                my $lc = OPTiMaDe::Filter::ListComparison->new( "$_[1] $_[2]" );
                $lc->values( $_[3] );
                return $lc;
            }
	],
	[#Rule 49
		 'set_zip_op_rhs', 3,
sub
#line 252 "Parser.yp"
{
                    $_[1]->operator( $_[2] );
                    $_[1]->values( [ $_[3] ] );
                    return $_[1];
                }
	],
	[#Rule 50
		 'set_zip_op_rhs', 4,
sub
#line 258 "Parser.yp"
{
                    $_[1]->operator( "$_[2] $_[3]" );
                    $_[1]->values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 51
		 'set_zip_op_rhs', 4,
sub
#line 264 "Parser.yp"
{
                    $_[1]->operator( "$_[2] $_[3]" );
                    $_[1]->values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 52
		 'set_zip_op_rhs', 4,
sub
#line 270 "Parser.yp"
{
                    $_[1]->operator( "$_[2] $_[3]" );
                    $_[1]->values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 53
		 'property_zip_addon', 2,
sub
#line 278 "Parser.yp"
{
                            my $zip = OPTiMaDe::Filter::Zip->new;
                            $zip->push_property( $_[2] );
                            return $zip;
                        }
	],
	[#Rule 54
		 'property_zip_addon', 3,
sub
#line 284 "Parser.yp"
{
                            $_[1]->push_property( $_[3] );
                            return $_[1];
                        }
	],
	[#Rule 55
		 'length_op_rhs', 2,
sub
#line 291 "Parser.yp"
{
                    my $cmp = OPTiMaDe::Filter::ListComparison->new( $_[1] );
                    $cmp->values( [ [ '=', $_[2] ] ] );
                    return $cmp;
                }
	],
	[#Rule 56
		 'length_op_rhs', 3,
sub
#line 297 "Parser.yp"
{
                    my $cmp = OPTiMaDe::Filter::ListComparison->new( $_[1] );
                    $cmp->values( [ [ $_[2], $_[3] ] ] );
                    return $cmp;
                }
	],
	[#Rule 57
		 'property', 1,
sub
#line 307 "Parser.yp"
{
                return OPTiMaDe::Filter::Property->new( $_[1] );
            }
	],
	[#Rule 58
		 'property', 3,
sub
#line 311 "Parser.yp"
{
                push @{$_[1]}, $_[3];
                return $_[1];
            }
	],
	[#Rule 59
		 'openingbrace', 1, undef
	],
	[#Rule 60
		 'closingbrace', 1, undef
	],
	[#Rule 61
		 'dot', 1, undef
	],
	[#Rule 62
		 'comma', 1, undef
	],
	[#Rule 63
		 'colon', 1, undef
	],
	[#Rule 64
		 'operator', 1, undef
	],
	[#Rule 65
		 'operator', 2,
sub
#line 333 "Parser.yp"
{
                return join( '', @_[1..$#_] );
            }
	],
	[#Rule 66
		 'operator', 1, undef
	],
	[#Rule 67
		 'operator', 2,
sub
#line 338 "Parser.yp"
{
                return join( '', @_[1..$#_] );
            }
	],
	[#Rule 68
		 'operator', 1, undef
	],
	[#Rule 69
		 'operator', 2,
sub
#line 343 "Parser.yp"
{
                return join( '', @_[1..$#_] );
            }
	]
],
                                  @_);
    bless($self,$class);
}

#line 348 "Parser.yp"


# Footer section

sub _Error
{
    my( $self ) = @_;
    close $self->{USER}{FILEIN} if $self->{USER}{FILEIN};
    my $msg = "$0: syntax error at line $self->{USER}{LINENO}, " .
              "position $self->{USER}{CHARNO}";
    if( $self->YYData->{INPUT} ) {
        $self->YYData->{INPUT} =~ s/\n$//;
        die "$msg: '" . $self->YYData->{INPUT} . "'.\n";
    } else {
        die "$msg.\n";
    }
}

sub _Lexer
{
    my( $self ) = @_;

    # If the line is empty and the input is originating from the file,
    # another line is read.
    if( !$self->YYData->{INPUT} && $self->{USER}{FILEIN} ) {
        my $filein = $self->{USER}{FILEIN};
        $self->YYData->{INPUT} = <$filein>;
        $self->{USER}{LINENO} = -1 unless exists $self->{USER}{LINENO};
        $self->{USER}{LINENO}++;
        $self->{USER}{CHARNO} = 0;
    }

    $self->YYData->{INPUT} =~ s/^(\s+)//;
    $self->{USER}{CHARNO} += length( $1 ) if defined $1;

    # Escaped double quote or backslash are detected here and returned
    # as is to the caller in order to be detected as syntax errors.
    if( $self->YYData->{INPUT} =~ s/^(\\"|\\\\)// ) {
        $self->{USER}{CHARNO} += length( $1 );
        return( $1, $1 );
    }

    # Handling strings
    if( $self->YYData->{INPUT} =~ s/^"// ) {
        $self->{USER}{CHARNO} ++;
        my $string = '';
        while( 1 ) {
            if( $self->YYData->{INPUT} =~
                    s/^([A-Za-z_0-9 \t!#\$\%&\'\(\)\*\+,\-\.\/\:;<=>\?@\[\]\^`\{\|\}\~\P{ASCII}]+)// ) {
                $self->{USER}{CHARNO} += length( $1 );
                $string .= $1;
            } elsif( $self->YYData->{INPUT} =~ s/^\\([\\"])// ) {
                $self->{USER}{CHARNO} ++;
                $string .= $1;
                next;
            } elsif( $self->YYData->{INPUT} =~ s/^"// ) {
                $self->{USER}{CHARNO} ++;
                return( 'string', $string );
            } else {
                return( undef, undef );
            }
        }
    }

    # Handling identifiers
    if( $self->YYData->{INPUT} =~ s/^([a-z_][a-z0-9_]*)// ) {
        $self->{USER}{CHARNO} += length( $1 );
        return( 'identifier', $1 );
    }

    # Handling boolean relations
    if( $self->YYData->{INPUT} =~ s/^(AND|NOT|OR|
                                      IS|UNKNOWN|KNOWN|
                                      CONTAINS|STARTS|ENDS|WITH|
                                      LENGTH|HAS|ALL|ONLY|ANY)//x ) {
        $self->{USER}{CHARNO} += length( $1 );
        return( $1, $1 );
    }

    # Handling LIKE operator if allowed
    if( $allow_LIKE_operator && $self->YYData->{INPUT} =~ s/^(LIKE)// ) {
        $self->{USER}{CHARNO} += length( $1 );
        return( $1, $1 );
    }

    # Handling numbers
    if( $self->YYData->{INPUT} =~ s/^([+-]?
                                     (\d+\.?\d*|\.\d+)
                                     ([eE][+-]?\d+)?)//x ) {
        $self->{USER}{CHARNO} += length( $1 );
        return( 'number', $1 );
    }

    my $char = substr( $self->YYData->{INPUT}, 0, 1 );
    if( $char ne '' ) {
        $self->YYData->{INPUT} = substr( $self->YYData->{INPUT}, 1 );
    }
    $self->{USER}{CHARNO}++;
    return( $char, $char );
}

sub Run
{
    my( $self, $filename ) = @_;
    open $self->{USER}{FILEIN}, $filename;
    my $result = $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error );
    close $self->{USER}{FILEIN};
    return $result;
}

sub parse_string
{
    my( $self, $string ) = @_;
    $self->YYData->{INPUT} = $string;
    $self->{USER}{LINENO} = 0;
    $self->{USER}{CHARNO} = 0;
    return $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error );
}

sub modify
{
    my $node = shift;
    my $code = shift;

    if( blessed $node && $node->can( 'modify' ) ) {
        return $node->modify( $code, @_ );
    } elsif( ref $node eq 'ARRAY' ) {
        return [ map { modify( $_, $code, @_ ) } @$node ];
    } else {
        return $code->( $node, @_ );
    }
}

1;

1;
