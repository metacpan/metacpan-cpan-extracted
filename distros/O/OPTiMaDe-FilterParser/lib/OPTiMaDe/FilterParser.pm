####################################################################
#
#    This file was generated using Parse::Yapp version 1.21.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package OPTiMaDe::FilterParser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 3 "FilterParser.yp"


use warnings;

use OPTiMaDe::FilterParser::Comparison;
use OPTiMaDe::FilterParser::ListComparison;
use OPTiMaDe::FilterParser::Property;
use OPTiMaDe::FilterParser::Zip;

our $VERSION = '0.2.0';
our $OPTiMaDe_VERSION = '0.10.0';

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
			'string' => 9,
			'LENGTH' => 16,
			'identifier' => 1,
			"(" => 6,
			'NOT' => 3,
			'number' => 2
		},
		GOTOS => {
			'comparison' => 5,
			'constant' => 4,
			'expression_phrase' => 17,
			'filter' => 18,
			'constant_first_comparison' => 7,
			'openingbrace' => 8,
			'predicate_comparison' => 11,
			'length_comparison' => 10,
			'expression' => 12,
			'property' => 13,
			'expression_clause' => 15,
			'property_first_comparison' => 14
		}
	},
	{#State 1
		DEFAULT => -58
	},
	{#State 2
		DEFAULT => -3
	},
	{#State 3
		ACTIONS => {
			'number' => 2,
			'string' => 9,
			"(" => 6,
			'identifier' => 1,
			'LENGTH' => 16
		},
		GOTOS => {
			'predicate_comparison' => 19,
			'length_comparison' => 10,
			'property' => 13,
			'property_first_comparison' => 14,
			'comparison' => 21,
			'constant' => 4,
			'constant_first_comparison' => 7,
			'openingbrace' => 20
		}
	},
	{#State 4
		ACTIONS => {
			"!" => 22,
			">" => 27,
			"<" => 26,
			"=" => 23
		},
		GOTOS => {
			'value_op_rhs' => 25,
			'operator' => 24
		}
	},
	{#State 5
		DEFAULT => -22
	},
	{#State 6
		DEFAULT => -60
	},
	{#State 7
		DEFAULT => -28
	},
	{#State 8
		ACTIONS => {
			'NOT' => 3,
			'number' => 2,
			'string' => 9,
			'LENGTH' => 16,
			'identifier' => 1,
			"(" => 6
		},
		GOTOS => {
			'comparison' => 5,
			'constant' => 4,
			'expression_phrase' => 17,
			'constant_first_comparison' => 7,
			'openingbrace' => 8,
			'predicate_comparison' => 11,
			'length_comparison' => 10,
			'expression' => 28,
			'property' => 13,
			'property_first_comparison' => 14,
			'expression_clause' => 15
		}
	},
	{#State 9
		DEFAULT => -2
	},
	{#State 10
		DEFAULT => -36
	},
	{#State 11
		DEFAULT => -23
	},
	{#State 12
		DEFAULT => -1
	},
	{#State 13
		ACTIONS => {
			'HAS' => 40,
			"!" => 22,
			":" => 38,
			'STARTS' => 30,
			'LIKE' => 37,
			'CONTAINS' => 42,
			"=" => 23,
			'ENDS' => 33,
			"<" => 26,
			"." => 32,
			'IS' => 41,
			">" => 27
		},
		GOTOS => {
			'property_zip_addon' => 31,
			'set_zip_op_rhs' => 39,
			'value_op_rhs' => 29,
			'set_op_rhs' => 44,
			'operator' => 24,
			'dot' => 36,
			'fuzzy_string_op_rhs' => 35,
			'colon' => 43,
			'known_op_rhs' => 34
		}
	},
	{#State 14
		DEFAULT => -29
	},
	{#State 15
		ACTIONS => {
			'OR' => 45
		},
		DEFAULT => -18
	},
	{#State 16
		ACTIONS => {
			'identifier' => 1
		},
		GOTOS => {
			'property' => 46
		}
	},
	{#State 17
		ACTIONS => {
			'AND' => 47
		},
		DEFAULT => -20
	},
	{#State 18
		ACTIONS => {
			'' => 48
		}
	},
	{#State 19
		DEFAULT => -26
	},
	{#State 20
		ACTIONS => {
			'number' => 2,
			'NOT' => 3,
			'string' => 9,
			"(" => 6,
			'identifier' => 1,
			'LENGTH' => 16
		},
		GOTOS => {
			'property' => 13,
			'property_first_comparison' => 14,
			'expression_clause' => 15,
			'length_comparison' => 10,
			'predicate_comparison' => 11,
			'expression' => 49,
			'constant_first_comparison' => 7,
			'openingbrace' => 8,
			'constant' => 4,
			'comparison' => 5,
			'expression_phrase' => 17
		}
	},
	{#State 21
		DEFAULT => -25
	},
	{#State 22
		ACTIONS => {
			"=" => 50
		}
	},
	{#State 23
		DEFAULT => -69
	},
	{#State 24
		ACTIONS => {
			'number' => 54,
			'identifier' => 1,
			'string' => 52
		},
		GOTOS => {
			'property' => 51,
			'value' => 53
		}
	},
	{#State 25
		DEFAULT => -35
	},
	{#State 26
		ACTIONS => {
			"=" => 55
		},
		DEFAULT => -65
	},
	{#State 27
		ACTIONS => {
			"=" => 56
		},
		DEFAULT => -67
	},
	{#State 28
		ACTIONS => {
			")" => 58
		},
		GOTOS => {
			'closingbrace' => 57
		}
	},
	{#State 29
		DEFAULT => -30
	},
	{#State 30
		ACTIONS => {
			'string' => 60,
			'WITH' => 59
		}
	},
	{#State 31
		ACTIONS => {
			'HAS' => 61,
			":" => 38
		},
		GOTOS => {
			'colon' => 62
		}
	},
	{#State 32
		DEFAULT => -62
	},
	{#State 33
		ACTIONS => {
			'WITH' => 63,
			'string' => 64
		}
	},
	{#State 34
		DEFAULT => -31
	},
	{#State 35
		DEFAULT => -32
	},
	{#State 36
		ACTIONS => {
			'identifier' => 65
		}
	},
	{#State 37
		ACTIONS => {
			'string' => 66
		}
	},
	{#State 38
		DEFAULT => -64
	},
	{#State 39
		DEFAULT => -34
	},
	{#State 40
		ACTIONS => {
			'identifier' => 1,
			'string' => 52,
			"!" => 22,
			'number' => 54,
			'ANY' => 71,
			"=" => 23,
			"<" => 26,
			">" => 27,
			'ONLY' => 67,
			'ALL' => 69
		},
		GOTOS => {
			'value' => 68,
			'property' => 51,
			'operator' => 70
		}
	},
	{#State 41
		ACTIONS => {
			'KNOWN' => 73,
			'UNKNOWN' => 72
		}
	},
	{#State 42
		ACTIONS => {
			'string' => 74
		}
	},
	{#State 43
		ACTIONS => {
			'identifier' => 1
		},
		GOTOS => {
			'property' => 75
		}
	},
	{#State 44
		DEFAULT => -33
	},
	{#State 45
		ACTIONS => {
			'string' => 9,
			"(" => 6,
			'LENGTH' => 16,
			'identifier' => 1,
			'NOT' => 3,
			'number' => 2
		},
		GOTOS => {
			'property' => 13,
			'property_first_comparison' => 14,
			'expression_clause' => 15,
			'predicate_comparison' => 11,
			'length_comparison' => 10,
			'expression' => 76,
			'constant_first_comparison' => 7,
			'openingbrace' => 8,
			'comparison' => 5,
			'constant' => 4,
			'expression_phrase' => 17
		}
	},
	{#State 46
		ACTIONS => {
			"." => 32,
			"=" => 23,
			"<" => 26,
			">" => 27,
			"!" => 22
		},
		GOTOS => {
			'operator' => 77,
			'dot' => 36
		}
	},
	{#State 47
		ACTIONS => {
			'identifier' => 1,
			'LENGTH' => 16,
			"(" => 6,
			'string' => 9,
			'number' => 2,
			'NOT' => 3
		},
		GOTOS => {
			'comparison' => 5,
			'constant' => 4,
			'expression_phrase' => 17,
			'constant_first_comparison' => 7,
			'openingbrace' => 8,
			'predicate_comparison' => 11,
			'length_comparison' => 10,
			'property' => 13,
			'property_first_comparison' => 14,
			'expression_clause' => 78
		}
	},
	{#State 48
		DEFAULT => 0
	},
	{#State 49
		ACTIONS => {
			")" => 58
		},
		GOTOS => {
			'closingbrace' => 79
		}
	},
	{#State 50
		DEFAULT => -70
	},
	{#State 51
		ACTIONS => {
			"." => 32
		},
		DEFAULT => -6,
		GOTOS => {
			'dot' => 36
		}
	},
	{#State 52
		DEFAULT => -4
	},
	{#State 53
		DEFAULT => -37
	},
	{#State 54
		DEFAULT => -5
	},
	{#State 55
		DEFAULT => -66
	},
	{#State 56
		DEFAULT => -68
	},
	{#State 57
		DEFAULT => -24
	},
	{#State 58
		DEFAULT => -61
	},
	{#State 59
		ACTIONS => {
			'string' => 80
		}
	},
	{#State 60
		DEFAULT => -41
	},
	{#State 61
		ACTIONS => {
			'ANY' => 83,
			"=" => 23,
			"<" => 26,
			">" => 27,
			'ALL' => 82,
			'ONLY' => 84,
			'identifier' => 1,
			'string' => 52,
			"!" => 22,
			'number' => 54
		},
		GOTOS => {
			'value' => 85,
			'property' => 51,
			'operator' => 81,
			'value_zip' => 86
		}
	},
	{#State 62
		ACTIONS => {
			'identifier' => 1
		},
		GOTOS => {
			'property' => 87
		}
	},
	{#State 63
		ACTIONS => {
			'string' => 88
		}
	},
	{#State 64
		DEFAULT => -43
	},
	{#State 65
		DEFAULT => -59
	},
	{#State 66
		DEFAULT => -45
	},
	{#State 67
		ACTIONS => {
			'identifier' => 1,
			"<" => 26,
			"=" => 23,
			">" => 27,
			'string' => 52,
			"!" => 22,
			'number' => 54
		},
		GOTOS => {
			'property' => 51,
			'operator' => 89,
			'value' => 91,
			'value_list' => 90
		}
	},
	{#State 68
		DEFAULT => -46
	},
	{#State 69
		ACTIONS => {
			'identifier' => 1,
			"=" => 23,
			"<" => 26,
			">" => 27,
			'string' => 52,
			"!" => 22,
			'number' => 54
		},
		GOTOS => {
			'value' => 91,
			'value_list' => 92,
			'property' => 51,
			'operator' => 89
		}
	},
	{#State 70
		ACTIONS => {
			'number' => 54,
			'string' => 52,
			'identifier' => 1
		},
		GOTOS => {
			'property' => 51,
			'value' => 93
		}
	},
	{#State 71
		ACTIONS => {
			"=" => 23,
			'identifier' => 1,
			"<" => 26,
			'string' => 52,
			">" => 27,
			"!" => 22,
			'number' => 54
		},
		GOTOS => {
			'property' => 51,
			'operator' => 89,
			'value' => 91,
			'value_list' => 94
		}
	},
	{#State 72
		DEFAULT => -39
	},
	{#State 73
		DEFAULT => -38
	},
	{#State 74
		DEFAULT => -40
	},
	{#State 75
		ACTIONS => {
			"." => 32
		},
		DEFAULT => -56,
		GOTOS => {
			'dot' => 36
		}
	},
	{#State 76
		DEFAULT => -19
	},
	{#State 77
		ACTIONS => {
			'identifier' => 1,
			'string' => 52,
			'number' => 54
		},
		GOTOS => {
			'value' => 95,
			'property' => 51
		}
	},
	{#State 78
		DEFAULT => -21
	},
	{#State 79
		DEFAULT => -27
	},
	{#State 80
		DEFAULT => -42
	},
	{#State 81
		ACTIONS => {
			'number' => 54,
			'string' => 52,
			'identifier' => 1
		},
		GOTOS => {
			'property' => 51,
			'value' => 96
		}
	},
	{#State 82
		ACTIONS => {
			"<" => 26,
			"=" => 23,
			'identifier' => 1,
			">" => 27,
			'string' => 52,
			"!" => 22,
			'number' => 54
		},
		GOTOS => {
			'value_zip_list' => 98,
			'value_zip' => 97,
			'operator' => 81,
			'property' => 51,
			'value' => 85
		}
	},
	{#State 83
		ACTIONS => {
			'number' => 54,
			"!" => 22,
			'string' => 52,
			">" => 27,
			'identifier' => 1,
			"=" => 23,
			"<" => 26
		},
		GOTOS => {
			'property' => 51,
			'value_zip' => 97,
			'value_zip_list' => 99,
			'operator' => 81,
			'value' => 85
		}
	},
	{#State 84
		ACTIONS => {
			"!" => 22,
			'number' => 54,
			"<" => 26,
			'identifier' => 1,
			"=" => 23,
			">" => 27,
			'string' => 52
		},
		GOTOS => {
			'property' => 51,
			'value_zip_list' => 100,
			'value_zip' => 97,
			'operator' => 81,
			'value' => 85
		}
	},
	{#State 85
		ACTIONS => {
			":" => 38
		},
		GOTOS => {
			'colon' => 102,
			'value_zip_part' => 101
		}
	},
	{#State 86
		ACTIONS => {
			":" => 38
		},
		DEFAULT => -51,
		GOTOS => {
			'value_zip_part' => 103,
			'colon' => 102
		}
	},
	{#State 87
		ACTIONS => {
			"." => 32
		},
		DEFAULT => -57,
		GOTOS => {
			'dot' => 36
		}
	},
	{#State 88
		DEFAULT => -44
	},
	{#State 89
		ACTIONS => {
			'string' => 52,
			'identifier' => 1,
			'number' => 54
		},
		GOTOS => {
			'value' => 104,
			'property' => 51
		}
	},
	{#State 90
		ACTIONS => {
			"," => 105
		},
		DEFAULT => -50,
		GOTOS => {
			'comma' => 106
		}
	},
	{#State 91
		DEFAULT => -7
	},
	{#State 92
		ACTIONS => {
			"," => 105
		},
		DEFAULT => -48,
		GOTOS => {
			'comma' => 106
		}
	},
	{#State 93
		DEFAULT => -47
	},
	{#State 94
		ACTIONS => {
			"," => 105
		},
		DEFAULT => -49,
		GOTOS => {
			'comma' => 106
		}
	},
	{#State 95
		DEFAULT => -55
	},
	{#State 96
		ACTIONS => {
			":" => 38
		},
		GOTOS => {
			'value_zip_part' => 107,
			'colon' => 102
		}
	},
	{#State 97
		ACTIONS => {
			":" => 38
		},
		DEFAULT => -16,
		GOTOS => {
			'value_zip_part' => 103,
			'colon' => 102
		}
	},
	{#State 98
		ACTIONS => {
			"," => 105
		},
		DEFAULT => -53,
		GOTOS => {
			'comma' => 108
		}
	},
	{#State 99
		ACTIONS => {
			"," => 105
		},
		DEFAULT => -54,
		GOTOS => {
			'comma' => 108
		}
	},
	{#State 100
		ACTIONS => {
			"," => 105
		},
		DEFAULT => -52,
		GOTOS => {
			'comma' => 108
		}
	},
	{#State 101
		DEFAULT => -11
	},
	{#State 102
		ACTIONS => {
			"!" => 22,
			'number' => 54,
			'identifier' => 1,
			"<" => 26,
			"=" => 23,
			">" => 27,
			'string' => 52
		},
		GOTOS => {
			'property' => 51,
			'operator' => 109,
			'value' => 110
		}
	},
	{#State 103
		DEFAULT => -13
	},
	{#State 104
		DEFAULT => -8
	},
	{#State 105
		DEFAULT => -63
	},
	{#State 106
		ACTIONS => {
			'number' => 54,
			"!" => 22,
			'string' => 52,
			">" => 27,
			"=" => 23,
			'identifier' => 1,
			"<" => 26
		},
		GOTOS => {
			'value' => 112,
			'operator' => 111,
			'property' => 51
		}
	},
	{#State 107
		DEFAULT => -12
	},
	{#State 108
		ACTIONS => {
			'number' => 54,
			"!" => 22,
			'string' => 52,
			">" => 27,
			"=" => 23,
			'identifier' => 1,
			"<" => 26
		},
		GOTOS => {
			'property' => 51,
			'value_zip' => 113,
			'operator' => 81,
			'value' => 85
		}
	},
	{#State 109
		ACTIONS => {
			'number' => 54,
			'identifier' => 1,
			'string' => 52
		},
		GOTOS => {
			'property' => 51,
			'value' => 114
		}
	},
	{#State 110
		DEFAULT => -14
	},
	{#State 111
		ACTIONS => {
			'number' => 54,
			'identifier' => 1,
			'string' => 52
		},
		GOTOS => {
			'value' => 115,
			'property' => 51
		}
	},
	{#State 112
		DEFAULT => -9
	},
	{#State 113
		ACTIONS => {
			":" => 38
		},
		DEFAULT => -17,
		GOTOS => {
			'value_zip_part' => 103,
			'colon' => 102
		}
	},
	{#State 114
		DEFAULT => -15
	},
	{#State 115
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
#line 34 "FilterParser.yp"
{
                return [ [ '=', $_[1] ] ];
            }
	],
	[#Rule 8
		 'value_list', 2,
sub
#line 38 "FilterParser.yp"
{
                return [ [ @_[1..$#_] ] ];
            }
	],
	[#Rule 9
		 'value_list', 3,
sub
#line 42 "FilterParser.yp"
{
                push @{$_[1]}, [ '=', $_[3] ];
                return $_[1];
            }
	],
	[#Rule 10
		 'value_list', 4,
sub
#line 47 "FilterParser.yp"
{
                push @{$_[1]}, [ $_[3], $_[4] ];
                return $_[1];
            }
	],
	[#Rule 11
		 'value_zip', 2,
sub
#line 54 "FilterParser.yp"
{
                return [ [ '=', $_[1] ], $_[2] ];
            }
	],
	[#Rule 12
		 'value_zip', 3,
sub
#line 58 "FilterParser.yp"
{
                return [ [ $_[1], $_[2] ], $_[3] ];
            }
	],
	[#Rule 13
		 'value_zip', 2,
sub
#line 62 "FilterParser.yp"
{
                push @{$_[1]}, $_[2];
                return $_[1];
            }
	],
	[#Rule 14
		 'value_zip_part', 2,
sub
#line 69 "FilterParser.yp"
{
                    return [ '=', $_[2] ];
                }
	],
	[#Rule 15
		 'value_zip_part', 3,
sub
#line 73 "FilterParser.yp"
{
                    return [ $_[2], $_[3] ];
                }
	],
	[#Rule 16
		 'value_zip_list', 1,
sub
#line 79 "FilterParser.yp"
{
                    return [ $_[1] ];
                }
	],
	[#Rule 17
		 'value_zip_list', 3,
sub
#line 83 "FilterParser.yp"
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
#line 93 "FilterParser.yp"
{
                return [ @_[1..$#_] ];
            }
	],
	[#Rule 20
		 'expression_clause', 1, undef
	],
	[#Rule 21
		 'expression_clause', 3,
sub
#line 100 "FilterParser.yp"
{
                        return [ @_[1..$#_] ];
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
#line 108 "FilterParser.yp"
{
                        return $_[2];
                    }
	],
	[#Rule 25
		 'expression_phrase', 2,
sub
#line 112 "FilterParser.yp"
{
                        return [ @_[1..$#_] ];
                    }
	],
	[#Rule 26
		 'expression_phrase', 2,
sub
#line 116 "FilterParser.yp"
{
                        return [ @_[1..$#_] ];
                    }
	],
	[#Rule 27
		 'expression_phrase', 4,
sub
#line 120 "FilterParser.yp"
{
                        return [ $_[1], $_[3] ];
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
#line 128 "FilterParser.yp"
{
                                    $_[2]->unshift_operand( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 31
		 'property_first_comparison', 2,
sub
#line 133 "FilterParser.yp"
{
                                    return [ $_[1], @{$_[2]} ];
                                }
	],
	[#Rule 32
		 'property_first_comparison', 2,
sub
#line 137 "FilterParser.yp"
{
                                    $_[2]->unshift_operand( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 33
		 'property_first_comparison', 2,
sub
#line 142 "FilterParser.yp"
{
                                    $_[2]->set_property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 34
		 'property_first_comparison', 2,
sub
#line 147 "FilterParser.yp"
{
                                    $_[2]->unshift_property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 35
		 'constant_first_comparison', 2,
sub
#line 154 "FilterParser.yp"
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
#line 163 "FilterParser.yp"
{
                    my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                    $cmp->push_operand( $_[2] );
                    return $cmp;
                }
	],
	[#Rule 38
		 'known_op_rhs', 2,
sub
#line 171 "FilterParser.yp"
{
                    return [ "$_[1] $_[2]" ];
                }
	],
	[#Rule 39
		 'known_op_rhs', 2,
sub
#line 175 "FilterParser.yp"
{
                    return [ "$_[1] $_[2]" ];
                }
	],
	[#Rule 40
		 'fuzzy_string_op_rhs', 2,
sub
#line 181 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 41
		 'fuzzy_string_op_rhs', 2,
sub
#line 187 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 42
		 'fuzzy_string_op_rhs', 3,
sub
#line 193 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( "$_[1] $_[2]" );
                            $cmp->push_operand( $_[3] );
                            return $cmp;
                        }
	],
	[#Rule 43
		 'fuzzy_string_op_rhs', 2,
sub
#line 199 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 44
		 'fuzzy_string_op_rhs', 3,
sub
#line 205 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( "$_[1] $_[2]" );
                            $cmp->push_operand( $_[3] );
                            return $cmp;
                        }
	],
	[#Rule 45
		 'fuzzy_string_op_rhs', 2,
sub
#line 211 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 46
		 'set_op_rhs', 2,
sub
#line 219 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( $_[1] );
                $lc->set_values( [ [ '=', $_[2] ] ] );
                return $lc;
            }
	],
	[#Rule 47
		 'set_op_rhs', 3,
sub
#line 225 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( $_[1] );
                $lc->set_values( [ [ $_[2], $_[3] ] ] );
                return $lc;
            }
	],
	[#Rule 48
		 'set_op_rhs', 3,
sub
#line 231 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( "$_[1] $_[2]" );
                $lc->set_values( $_[3] );
                return $lc;
            }
	],
	[#Rule 49
		 'set_op_rhs', 3,
sub
#line 237 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( "$_[1] $_[2]" );
                $lc->set_values( $_[3] );
                return $lc;
            }
	],
	[#Rule 50
		 'set_op_rhs', 3,
sub
#line 243 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( "$_[1] $_[2]" );
                $lc->set_values( $_[3] );
                return $lc;
            }
	],
	[#Rule 51
		 'set_zip_op_rhs', 3,
sub
#line 251 "FilterParser.yp"
{
                    $_[1]->set_operator( $_[2] );
                    $_[1]->set_values( [ $_[3] ] );
                    return $_[1];
                }
	],
	[#Rule 52
		 'set_zip_op_rhs', 4,
sub
#line 257 "FilterParser.yp"
{
                    $_[1]->set_operator( "$_[2] $_[3]" );
                    $_[1]->set_values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 53
		 'set_zip_op_rhs', 4,
sub
#line 263 "FilterParser.yp"
{
                    $_[1]->set_operator( "$_[2] $_[3]" );
                    $_[1]->set_values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 54
		 'set_zip_op_rhs', 4,
sub
#line 269 "FilterParser.yp"
{
                    $_[1]->set_operator( "$_[2] $_[3]" );
                    $_[1]->set_values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 55
		 'length_comparison', 4,
sub
#line 277 "FilterParser.yp"
{
                        my $cmp = OPTiMaDe::FilterParser::ListComparison->new( $_[1] );
                        $cmp->set_property( $_[2] );
                        $cmp->set_values( [ [ $_[3], $_[4] ] ] );
                        return $cmp;
                    }
	],
	[#Rule 56
		 'property_zip_addon', 2,
sub
#line 286 "FilterParser.yp"
{
                            my $zip = OPTiMaDe::FilterParser::Zip->new;
                            $zip->push_property( $_[2] );
                            return $zip;
                        }
	],
	[#Rule 57
		 'property_zip_addon', 3,
sub
#line 292 "FilterParser.yp"
{
                            $_[1]->push_property( $_[3] );
                            return $_[1];
                        }
	],
	[#Rule 58
		 'property', 1,
sub
#line 301 "FilterParser.yp"
{
                my $id = OPTiMaDe::FilterParser::Property->new;
                $id->push_identifier( $_[1] );
                return $id;
            }
	],
	[#Rule 59
		 'property', 3,
sub
#line 307 "FilterParser.yp"
{
                $_[1]->push_identifier( $_[3] );
                return $_[1];
            }
	],
	[#Rule 60
		 'openingbrace', 1, undef
	],
	[#Rule 61
		 'closingbrace', 1, undef
	],
	[#Rule 62
		 'dot', 1, undef
	],
	[#Rule 63
		 'comma', 1, undef
	],
	[#Rule 64
		 'colon', 1, undef
	],
	[#Rule 65
		 'operator', 1, undef
	],
	[#Rule 66
		 'operator', 2,
sub
#line 329 "FilterParser.yp"
{
                return join( '', @_[1..$#_] );
            }
	],
	[#Rule 67
		 'operator', 1, undef
	],
	[#Rule 68
		 'operator', 2,
sub
#line 334 "FilterParser.yp"
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
#line 339 "FilterParser.yp"
{
                return join( '', @_[1..$#_] );
            }
	]
],
                                  @_);
    bless($self,$class);
}

#line 344 "FilterParser.yp"


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

1;

1;
