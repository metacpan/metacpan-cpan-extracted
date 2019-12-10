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
			'identifier' => 7,
			'LENGTH' => 2,
			"(" => 8,
			'NOT' => 9,
			'string' => 6,
			'number' => 13
		},
		GOTOS => {
			'expression' => 18,
			'constant' => 17,
			'expression_clause' => 16,
			'length_comparison' => 14,
			'property_first_comparison' => 15,
			'constant_first_comparison' => 5,
			'openingbrace' => 4,
			'comparison' => 12,
			'expression_phrase' => 3,
			'property' => 10,
			'predicate_comparison' => 1,
			'filter' => 11
		}
	},
	{#State 1
		DEFAULT => -23
	},
	{#State 2
		ACTIONS => {
			'identifier' => 7
		},
		GOTOS => {
			'property' => 19
		}
	},
	{#State 3
		ACTIONS => {
			'AND' => 20
		},
		DEFAULT => -20
	},
	{#State 4
		ACTIONS => {
			'identifier' => 7,
			'LENGTH' => 2,
			"(" => 8,
			'NOT' => 9,
			'string' => 6,
			'number' => 13
		},
		GOTOS => {
			'constant_first_comparison' => 5,
			'comparison' => 12,
			'openingbrace' => 4,
			'expression_phrase' => 3,
			'property' => 10,
			'predicate_comparison' => 1,
			'expression' => 21,
			'constant' => 17,
			'expression_clause' => 16,
			'property_first_comparison' => 15,
			'length_comparison' => 14
		}
	},
	{#State 5
		DEFAULT => -28
	},
	{#State 6
		DEFAULT => -2
	},
	{#State 7
		DEFAULT => -60
	},
	{#State 8
		DEFAULT => -62
	},
	{#State 9
		ACTIONS => {
			'string' => 6,
			"(" => 8,
			'LENGTH' => 2,
			'identifier' => 7,
			'number' => 13
		},
		GOTOS => {
			'property_first_comparison' => 15,
			'length_comparison' => 14,
			'constant' => 17,
			'predicate_comparison' => 23,
			'property' => 10,
			'constant_first_comparison' => 5,
			'comparison' => 22,
			'openingbrace' => 24
		}
	},
	{#State 10
		ACTIONS => {
			'ENDS' => 31,
			'IS' => 43,
			":" => 29,
			'STARTS' => 44,
			"!" => 32,
			"=" => 36,
			'CONTAINS' => 26,
			'LIKE' => 35,
			'HAS' => 33,
			"." => 28,
			"<" => 38,
			">" => 37
		},
		GOTOS => {
			'known_op_rhs' => 34,
			'fuzzy_string_op_rhs' => 25,
			'operator' => 40,
			'value_op_rhs' => 39,
			'dot' => 27,
			'property_zip_addon' => 41,
			'colon' => 42,
			'set_zip_op_rhs' => 30,
			'set_op_rhs' => 45
		}
	},
	{#State 11
		ACTIONS => {
			'' => 46
		}
	},
	{#State 12
		DEFAULT => -22
	},
	{#State 13
		DEFAULT => -3
	},
	{#State 14
		DEFAULT => -36
	},
	{#State 15
		DEFAULT => -29
	},
	{#State 16
		ACTIONS => {
			'OR' => 47
		},
		DEFAULT => -18
	},
	{#State 17
		ACTIONS => {
			"=" => 36,
			"<" => 38,
			">" => 37,
			"!" => 32
		},
		GOTOS => {
			'value_op_rhs' => 48,
			'operator' => 40
		}
	},
	{#State 18
		DEFAULT => -1
	},
	{#State 19
		ACTIONS => {
			"." => 28,
			"<" => 38,
			"!" => 32,
			">" => 37,
			"=" => 36
		},
		GOTOS => {
			'dot' => 27,
			'operator' => 49
		}
	},
	{#State 20
		ACTIONS => {
			'number' => 13,
			'string' => 6,
			'NOT' => 9,
			"(" => 8,
			'LENGTH' => 2,
			'identifier' => 7
		},
		GOTOS => {
			'expression_clause' => 50,
			'length_comparison' => 14,
			'property_first_comparison' => 15,
			'constant' => 17,
			'predicate_comparison' => 1,
			'property' => 10,
			'expression_phrase' => 3,
			'constant_first_comparison' => 5,
			'openingbrace' => 4,
			'comparison' => 12
		}
	},
	{#State 21
		ACTIONS => {
			")" => 52
		},
		GOTOS => {
			'closingbrace' => 51
		}
	},
	{#State 22
		DEFAULT => -25
	},
	{#State 23
		DEFAULT => -26
	},
	{#State 24
		ACTIONS => {
			'LENGTH' => 2,
			'identifier' => 7,
			'string' => 6,
			'NOT' => 9,
			"(" => 8,
			'number' => 13
		},
		GOTOS => {
			'constant_first_comparison' => 5,
			'openingbrace' => 4,
			'comparison' => 12,
			'predicate_comparison' => 1,
			'expression_phrase' => 3,
			'property' => 10,
			'constant' => 17,
			'expression' => 53,
			'expression_clause' => 16,
			'length_comparison' => 14,
			'property_first_comparison' => 15
		}
	},
	{#State 25
		DEFAULT => -32
	},
	{#State 26
		ACTIONS => {
			'identifier' => 7,
			'string' => 56
		},
		GOTOS => {
			'string_property' => 54,
			'property' => 55
		}
	},
	{#State 27
		ACTIONS => {
			'identifier' => 57
		}
	},
	{#State 28
		DEFAULT => -64
	},
	{#State 29
		DEFAULT => -66
	},
	{#State 30
		DEFAULT => -34
	},
	{#State 31
		ACTIONS => {
			'WITH' => 58,
			'string' => 56,
			'identifier' => 7
		},
		GOTOS => {
			'string_property' => 59,
			'property' => 55
		}
	},
	{#State 32
		ACTIONS => {
			"=" => 60
		}
	},
	{#State 33
		ACTIONS => {
			'identifier' => 7,
			'string' => 62,
			"!" => 32,
			'ALL' => 61,
			"=" => 36,
			'ANY' => 68,
			'ONLY' => 63,
			">" => 37,
			"<" => 38,
			'number' => 66
		},
		GOTOS => {
			'property' => 67,
			'value' => 64,
			'operator' => 65
		}
	},
	{#State 34
		DEFAULT => -31
	},
	{#State 35
		ACTIONS => {
			'identifier' => 7,
			'string' => 56
		},
		GOTOS => {
			'string_property' => 69,
			'property' => 55
		}
	},
	{#State 36
		DEFAULT => -71
	},
	{#State 37
		ACTIONS => {
			"=" => 70
		},
		DEFAULT => -69
	},
	{#State 38
		ACTIONS => {
			"=" => 71
		},
		DEFAULT => -67
	},
	{#State 39
		DEFAULT => -30
	},
	{#State 40
		ACTIONS => {
			'identifier' => 7,
			'string' => 62,
			'number' => 66
		},
		GOTOS => {
			'value' => 72,
			'property' => 67
		}
	},
	{#State 41
		ACTIONS => {
			'HAS' => 74,
			":" => 29
		},
		GOTOS => {
			'colon' => 73
		}
	},
	{#State 42
		ACTIONS => {
			'identifier' => 7
		},
		GOTOS => {
			'property' => 75
		}
	},
	{#State 43
		ACTIONS => {
			'UNKNOWN' => 76,
			'KNOWN' => 77
		}
	},
	{#State 44
		ACTIONS => {
			'WITH' => 78,
			'string' => 56,
			'identifier' => 7
		},
		GOTOS => {
			'string_property' => 79,
			'property' => 55
		}
	},
	{#State 45
		DEFAULT => -33
	},
	{#State 46
		DEFAULT => 0
	},
	{#State 47
		ACTIONS => {
			'number' => 13,
			'LENGTH' => 2,
			'identifier' => 7,
			'string' => 6,
			'NOT' => 9,
			"(" => 8
		},
		GOTOS => {
			'property_first_comparison' => 15,
			'length_comparison' => 14,
			'expression_clause' => 16,
			'expression' => 80,
			'constant' => 17,
			'predicate_comparison' => 1,
			'property' => 10,
			'expression_phrase' => 3,
			'comparison' => 12,
			'openingbrace' => 4,
			'constant_first_comparison' => 5
		}
	},
	{#State 48
		DEFAULT => -35
	},
	{#State 49
		ACTIONS => {
			'identifier' => 7,
			'string' => 62,
			'number' => 66
		},
		GOTOS => {
			'value' => 81,
			'property' => 67
		}
	},
	{#State 50
		DEFAULT => -21
	},
	{#State 51
		DEFAULT => -24
	},
	{#State 52
		DEFAULT => -63
	},
	{#State 53
		ACTIONS => {
			")" => 52
		},
		GOTOS => {
			'closingbrace' => 82
		}
	},
	{#State 54
		DEFAULT => -42
	},
	{#State 55
		ACTIONS => {
			"." => 28
		},
		DEFAULT => -41,
		GOTOS => {
			'dot' => 27
		}
	},
	{#State 56
		DEFAULT => -40
	},
	{#State 57
		DEFAULT => -61
	},
	{#State 58
		ACTIONS => {
			'string' => 56,
			'identifier' => 7
		},
		GOTOS => {
			'string_property' => 83,
			'property' => 55
		}
	},
	{#State 59
		DEFAULT => -45
	},
	{#State 60
		DEFAULT => -72
	},
	{#State 61
		ACTIONS => {
			"=" => 36,
			'string' => 62,
			'identifier' => 7,
			"<" => 38,
			'number' => 66,
			"!" => 32,
			">" => 37
		},
		GOTOS => {
			'property' => 67,
			'value_list' => 86,
			'value' => 85,
			'operator' => 84
		}
	},
	{#State 62
		DEFAULT => -4
	},
	{#State 63
		ACTIONS => {
			'identifier' => 7,
			'string' => 62,
			"=" => 36,
			"!" => 32,
			">" => 37,
			'number' => 66,
			"<" => 38
		},
		GOTOS => {
			'value' => 85,
			'operator' => 84,
			'property' => 67,
			'value_list' => 87
		}
	},
	{#State 64
		DEFAULT => -48
	},
	{#State 65
		ACTIONS => {
			'identifier' => 7,
			'string' => 62,
			'number' => 66
		},
		GOTOS => {
			'property' => 67,
			'value' => 88
		}
	},
	{#State 66
		DEFAULT => -5
	},
	{#State 67
		ACTIONS => {
			"." => 28
		},
		DEFAULT => -6,
		GOTOS => {
			'dot' => 27
		}
	},
	{#State 68
		ACTIONS => {
			">" => 37,
			"!" => 32,
			"<" => 38,
			'number' => 66,
			'identifier' => 7,
			"=" => 36,
			'string' => 62
		},
		GOTOS => {
			'property' => 67,
			'value_list' => 89,
			'value' => 85,
			'operator' => 84
		}
	},
	{#State 69
		DEFAULT => -47
	},
	{#State 70
		DEFAULT => -70
	},
	{#State 71
		DEFAULT => -68
	},
	{#State 72
		DEFAULT => -37
	},
	{#State 73
		ACTIONS => {
			'identifier' => 7
		},
		GOTOS => {
			'property' => 90
		}
	},
	{#State 74
		ACTIONS => {
			'identifier' => 7,
			'string' => 62,
			"!" => 32,
			'ALL' => 96,
			"=" => 36,
			'ANY' => 92,
			'ONLY' => 95,
			">" => 37,
			"<" => 38,
			'number' => 66
		},
		GOTOS => {
			'property' => 67,
			'value' => 94,
			'operator' => 93,
			'value_zip' => 91
		}
	},
	{#State 75
		ACTIONS => {
			"." => 28
		},
		DEFAULT => -58,
		GOTOS => {
			'dot' => 27
		}
	},
	{#State 76
		DEFAULT => -39
	},
	{#State 77
		DEFAULT => -38
	},
	{#State 78
		ACTIONS => {
			'identifier' => 7,
			'string' => 56
		},
		GOTOS => {
			'property' => 55,
			'string_property' => 97
		}
	},
	{#State 79
		DEFAULT => -43
	},
	{#State 80
		DEFAULT => -19
	},
	{#State 81
		DEFAULT => -57
	},
	{#State 82
		DEFAULT => -27
	},
	{#State 83
		DEFAULT => -46
	},
	{#State 84
		ACTIONS => {
			'number' => 66,
			'identifier' => 7,
			'string' => 62
		},
		GOTOS => {
			'property' => 67,
			'value' => 98
		}
	},
	{#State 85
		DEFAULT => -7
	},
	{#State 86
		ACTIONS => {
			"," => 100
		},
		DEFAULT => -50,
		GOTOS => {
			'comma' => 99
		}
	},
	{#State 87
		ACTIONS => {
			"," => 100
		},
		DEFAULT => -52,
		GOTOS => {
			'comma' => 99
		}
	},
	{#State 88
		DEFAULT => -49
	},
	{#State 89
		ACTIONS => {
			"," => 100
		},
		DEFAULT => -51,
		GOTOS => {
			'comma' => 99
		}
	},
	{#State 90
		ACTIONS => {
			"." => 28
		},
		DEFAULT => -59,
		GOTOS => {
			'dot' => 27
		}
	},
	{#State 91
		ACTIONS => {
			":" => 29
		},
		DEFAULT => -53,
		GOTOS => {
			'value_zip_part' => 102,
			'colon' => 101
		}
	},
	{#State 92
		ACTIONS => {
			'number' => 66,
			"<" => 38,
			">" => 37,
			"!" => 32,
			'string' => 62,
			"=" => 36,
			'identifier' => 7
		},
		GOTOS => {
			'value_zip' => 104,
			'operator' => 93,
			'value' => 94,
			'property' => 67,
			'value_zip_list' => 103
		}
	},
	{#State 93
		ACTIONS => {
			'string' => 62,
			'identifier' => 7,
			'number' => 66
		},
		GOTOS => {
			'value' => 105,
			'property' => 67
		}
	},
	{#State 94
		ACTIONS => {
			":" => 29
		},
		GOTOS => {
			'colon' => 101,
			'value_zip_part' => 106
		}
	},
	{#State 95
		ACTIONS => {
			'identifier' => 7,
			"=" => 36,
			'string' => 62,
			"!" => 32,
			">" => 37,
			"<" => 38,
			'number' => 66
		},
		GOTOS => {
			'property' => 67,
			'value_zip_list' => 107,
			'value_zip' => 104,
			'operator' => 93,
			'value' => 94
		}
	},
	{#State 96
		ACTIONS => {
			'number' => 66,
			"<" => 38,
			">" => 37,
			"!" => 32,
			'string' => 62,
			"=" => 36,
			'identifier' => 7
		},
		GOTOS => {
			'value_zip_list' => 108,
			'property' => 67,
			'value' => 94,
			'operator' => 93,
			'value_zip' => 104
		}
	},
	{#State 97
		DEFAULT => -44
	},
	{#State 98
		DEFAULT => -8
	},
	{#State 99
		ACTIONS => {
			'identifier' => 7,
			"=" => 36,
			'string' => 62,
			"!" => 32,
			">" => 37,
			"<" => 38,
			'number' => 66
		},
		GOTOS => {
			'operator' => 110,
			'value' => 109,
			'property' => 67
		}
	},
	{#State 100
		DEFAULT => -65
	},
	{#State 101
		ACTIONS => {
			'number' => 66,
			"<" => 38,
			">" => 37,
			"!" => 32,
			"=" => 36,
			'string' => 62,
			'identifier' => 7
		},
		GOTOS => {
			'property' => 67,
			'value' => 111,
			'operator' => 112
		}
	},
	{#State 102
		DEFAULT => -13
	},
	{#State 103
		ACTIONS => {
			"," => 100
		},
		DEFAULT => -56,
		GOTOS => {
			'comma' => 113
		}
	},
	{#State 104
		ACTIONS => {
			":" => 29
		},
		DEFAULT => -16,
		GOTOS => {
			'colon' => 101,
			'value_zip_part' => 102
		}
	},
	{#State 105
		ACTIONS => {
			":" => 29
		},
		GOTOS => {
			'colon' => 101,
			'value_zip_part' => 114
		}
	},
	{#State 106
		DEFAULT => -11
	},
	{#State 107
		ACTIONS => {
			"," => 100
		},
		DEFAULT => -54,
		GOTOS => {
			'comma' => 113
		}
	},
	{#State 108
		ACTIONS => {
			"," => 100
		},
		DEFAULT => -55,
		GOTOS => {
			'comma' => 113
		}
	},
	{#State 109
		DEFAULT => -9
	},
	{#State 110
		ACTIONS => {
			'number' => 66,
			'identifier' => 7,
			'string' => 62
		},
		GOTOS => {
			'property' => 67,
			'value' => 115
		}
	},
	{#State 111
		DEFAULT => -14
	},
	{#State 112
		ACTIONS => {
			'number' => 66,
			'string' => 62,
			'identifier' => 7
		},
		GOTOS => {
			'value' => 116,
			'property' => 67
		}
	},
	{#State 113
		ACTIONS => {
			'identifier' => 7,
			'string' => 62,
			"=" => 36,
			"!" => 32,
			">" => 37,
			"<" => 38,
			'number' => 66
		},
		GOTOS => {
			'value_zip' => 117,
			'value' => 94,
			'operator' => 93,
			'property' => 67
		}
	},
	{#State 114
		DEFAULT => -12
	},
	{#State 115
		DEFAULT => -10
	},
	{#State 116
		DEFAULT => -15
	},
	{#State 117
		ACTIONS => {
			":" => 29
		},
		DEFAULT => -17,
		GOTOS => {
			'colon' => 101,
			'value_zip_part' => 102
		}
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
		 'expression_phrase', 1, undef
	],
	[#Rule 24
		 'expression_phrase', 3,
sub
#line 110 "Parser.yp"
{
                        return $_[2];
                    }
	],
	[#Rule 25
		 'expression_phrase', 2,
sub
#line 114 "Parser.yp"
{
                        return OPTiMaDe::Filter::Negation->new( $_[2] );
                    }
	],
	[#Rule 26
		 'expression_phrase', 2,
sub
#line 118 "Parser.yp"
{
                        return OPTiMaDe::Filter::Negation->new( $_[2] );
                    }
	],
	[#Rule 27
		 'expression_phrase', 4,
sub
#line 122 "Parser.yp"
{
                        return OPTiMaDe::Filter::Negation->new( $_[3] );
                    }
	],
	[#Rule 28
		 'comparison', 1, undef
	],
	[#Rule 29
		 'comparison', 1, undef
	],
	[#Rule 30
		 'property_first_comparison', 2,
sub
#line 130 "Parser.yp"
{
                                    $_[2]->unshift_operand( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 31
		 'property_first_comparison', 2,
sub
#line 135 "Parser.yp"
{
                                    $_[2]->property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 32
		 'property_first_comparison', 2,
sub
#line 140 "Parser.yp"
{
                                    $_[2]->unshift_operand( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 33
		 'property_first_comparison', 2,
sub
#line 145 "Parser.yp"
{
                                    $_[2]->property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 34
		 'property_first_comparison', 2,
sub
#line 150 "Parser.yp"
{
                                    $_[2]->unshift_property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 35
		 'constant_first_comparison', 2,
sub
#line 157 "Parser.yp"
{
                                $_[2]->unshift_operand( $_[1] );
                                return $_[2];
                            }
	],
	[#Rule 36
		 'predicate_comparison', 1, undef
	],
	[#Rule 37
		 'value_op_rhs', 2,
sub
#line 166 "Parser.yp"
{
                    my $cmp = OPTiMaDe::Filter::Comparison->new( $_[1] );
                    $cmp->push_operand( $_[2] );
                    return $cmp;
                }
	],
	[#Rule 38
		 'known_op_rhs', 2,
sub
#line 174 "Parser.yp"
{
                    return OPTiMaDe::Filter::Known->new( 1 );
                }
	],
	[#Rule 39
		 'known_op_rhs', 2,
sub
#line 178 "Parser.yp"
{
                    return OPTiMaDe::Filter::Known->new( 0 );
                }
	],
	[#Rule 40
		 'string_property', 1, undef
	],
	[#Rule 41
		 'string_property', 1, undef
	],
	[#Rule 42
		 'fuzzy_string_op_rhs', 2,
sub
#line 186 "Parser.yp"
{
                            my $cmp = OPTiMaDe::Filter::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 43
		 'fuzzy_string_op_rhs', 2,
sub
#line 192 "Parser.yp"
{
                            my $cmp = OPTiMaDe::Filter::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 44
		 'fuzzy_string_op_rhs', 3,
sub
#line 198 "Parser.yp"
{
                            my $cmp = OPTiMaDe::Filter::Comparison->new( "$_[1] $_[2]" );
                            $cmp->push_operand( $_[3] );
                            return $cmp;
                        }
	],
	[#Rule 45
		 'fuzzy_string_op_rhs', 2,
sub
#line 204 "Parser.yp"
{
                            my $cmp = OPTiMaDe::Filter::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 46
		 'fuzzy_string_op_rhs', 3,
sub
#line 210 "Parser.yp"
{
                            my $cmp = OPTiMaDe::Filter::Comparison->new( "$_[1] $_[2]" );
                            $cmp->push_operand( $_[3] );
                            return $cmp;
                        }
	],
	[#Rule 47
		 'fuzzy_string_op_rhs', 2,
sub
#line 216 "Parser.yp"
{
                            my $cmp = OPTiMaDe::Filter::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 48
		 'set_op_rhs', 2,
sub
#line 224 "Parser.yp"
{
                my $lc = OPTiMaDe::Filter::ListComparison->new( $_[1] );
                $lc->values( [ [ '=', $_[2] ] ] );
                return $lc;
            }
	],
	[#Rule 49
		 'set_op_rhs', 3,
sub
#line 230 "Parser.yp"
{
                my $lc = OPTiMaDe::Filter::ListComparison->new( $_[1] );
                $lc->values( [ [ $_[2], $_[3] ] ] );
                return $lc;
            }
	],
	[#Rule 50
		 'set_op_rhs', 3,
sub
#line 236 "Parser.yp"
{
                my $lc = OPTiMaDe::Filter::ListComparison->new( "$_[1] $_[2]" );
                $lc->values( $_[3] );
                return $lc;
            }
	],
	[#Rule 51
		 'set_op_rhs', 3,
sub
#line 242 "Parser.yp"
{
                my $lc = OPTiMaDe::Filter::ListComparison->new( "$_[1] $_[2]" );
                $lc->values( $_[3] );
                return $lc;
            }
	],
	[#Rule 52
		 'set_op_rhs', 3,
sub
#line 248 "Parser.yp"
{
                my $lc = OPTiMaDe::Filter::ListComparison->new( "$_[1] $_[2]" );
                $lc->values( $_[3] );
                return $lc;
            }
	],
	[#Rule 53
		 'set_zip_op_rhs', 3,
sub
#line 256 "Parser.yp"
{
                    $_[1]->operator( $_[2] );
                    $_[1]->values( [ $_[3] ] );
                    return $_[1];
                }
	],
	[#Rule 54
		 'set_zip_op_rhs', 4,
sub
#line 262 "Parser.yp"
{
                    $_[1]->operator( "$_[2] $_[3]" );
                    $_[1]->values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 55
		 'set_zip_op_rhs', 4,
sub
#line 268 "Parser.yp"
{
                    $_[1]->operator( "$_[2] $_[3]" );
                    $_[1]->values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 56
		 'set_zip_op_rhs', 4,
sub
#line 274 "Parser.yp"
{
                    $_[1]->operator( "$_[2] $_[3]" );
                    $_[1]->values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 57
		 'length_comparison', 4,
sub
#line 282 "Parser.yp"
{
                        my $cmp = OPTiMaDe::Filter::ListComparison->new( $_[1] );
                        $cmp->property( $_[2] );
                        $cmp->values( [ [ $_[3], $_[4] ] ] );
                        return $cmp;
                    }
	],
	[#Rule 58
		 'property_zip_addon', 2,
sub
#line 291 "Parser.yp"
{
                            my $zip = OPTiMaDe::Filter::Zip->new;
                            $zip->push_property( $_[2] );
                            return $zip;
                        }
	],
	[#Rule 59
		 'property_zip_addon', 3,
sub
#line 297 "Parser.yp"
{
                            $_[1]->push_property( $_[3] );
                            return $_[1];
                        }
	],
	[#Rule 60
		 'property', 1,
sub
#line 306 "Parser.yp"
{
                return OPTiMaDe::Filter::Property->new( $_[1] );
            }
	],
	[#Rule 61
		 'property', 3,
sub
#line 310 "Parser.yp"
{
                push @{$_[1]}, $_[3];
                return $_[1];
            }
	],
	[#Rule 62
		 'openingbrace', 1, undef
	],
	[#Rule 63
		 'closingbrace', 1, undef
	],
	[#Rule 64
		 'dot', 1, undef
	],
	[#Rule 65
		 'comma', 1, undef
	],
	[#Rule 66
		 'colon', 1, undef
	],
	[#Rule 67
		 'operator', 1, undef
	],
	[#Rule 68
		 'operator', 2,
sub
#line 332 "Parser.yp"
{
                return join( '', @_[1..$#_] );
            }
	],
	[#Rule 69
		 'operator', 1, undef
	],
	[#Rule 70
		 'operator', 2,
sub
#line 337 "Parser.yp"
{
                return join( '', @_[1..$#_] );
            }
	],
	[#Rule 71
		 'operator', 1, undef
	],
	[#Rule 72
		 'operator', 2,
sub
#line 342 "Parser.yp"
{
                return join( '', @_[1..$#_] );
            }
	]
],
                                  @_);
    bless($self,$class);
}

#line 347 "Parser.yp"


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
