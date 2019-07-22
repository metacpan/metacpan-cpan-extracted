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

our $VERSION = '0.1.0';
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
			'string' => 12,
			'number' => 8,
			'LENGTH' => 3,
			"(" => 16,
			'identifier' => 9,
			'NOT' => 10
		},
		GOTOS => {
			'property_first_comparison' => 17,
			'expression_clause' => 18,
			'comparison' => 6,
			'openingbrace' => 14,
			'constant' => 15,
			'predicate_comparison' => 5,
			'expression' => 13,
			'expression_phrase' => 4,
			'filter' => 11,
			'constant_first_comparison' => 2,
			'length_comparison' => 1,
			'property' => 7
		}
	},
	{#State 1
		DEFAULT => -36
	},
	{#State 2
		DEFAULT => -28
	},
	{#State 3
		ACTIONS => {
			'identifier' => 9
		},
		GOTOS => {
			'property' => 19
		}
	},
	{#State 4
		ACTIONS => {
			'AND' => 20
		},
		DEFAULT => -20
	},
	{#State 5
		DEFAULT => -23
	},
	{#State 6
		DEFAULT => -22
	},
	{#State 7
		ACTIONS => {
			"<" => 35,
			'STARTS' => 25,
			'CONTAINS' => 32,
			'LIKE' => 33,
			">" => 31,
			'ENDS' => 30,
			'IS' => 40,
			"!" => 29,
			"." => 39,
			":" => 28,
			'HAS' => 27,
			"=" => 37
		},
		GOTOS => {
			'set_op_rhs' => 41,
			'value_op_rhs' => 38,
			'set_zip_op_rhs' => 26,
			'property_zip_addon' => 36,
			'operator' => 24,
			'colon' => 34,
			'dot' => 21,
			'fuzzy_string_op_rhs' => 23,
			'known_op_rhs' => 22
		}
	},
	{#State 8
		DEFAULT => -3
	},
	{#State 9
		DEFAULT => -58
	},
	{#State 10
		ACTIONS => {
			'identifier' => 9,
			"(" => 16,
			'string' => 12,
			'number' => 8,
			'LENGTH' => 3
		},
		GOTOS => {
			'property' => 7,
			'length_comparison' => 1,
			'openingbrace' => 44,
			'predicate_comparison' => 42,
			'constant' => 15,
			'constant_first_comparison' => 2,
			'property_first_comparison' => 17,
			'comparison' => 43
		}
	},
	{#State 11
		ACTIONS => {
			'' => 45
		}
	},
	{#State 12
		DEFAULT => -2
	},
	{#State 13
		DEFAULT => -1
	},
	{#State 14
		ACTIONS => {
			'string' => 12,
			'number' => 8,
			'LENGTH' => 3,
			'identifier' => 9,
			'NOT' => 10,
			"(" => 16
		},
		GOTOS => {
			'comparison' => 6,
			'expression_clause' => 18,
			'property_first_comparison' => 17,
			'expression_phrase' => 4,
			'constant_first_comparison' => 2,
			'openingbrace' => 14,
			'expression' => 46,
			'constant' => 15,
			'predicate_comparison' => 5,
			'length_comparison' => 1,
			'property' => 7
		}
	},
	{#State 15
		ACTIONS => {
			"!" => 29,
			"<" => 35,
			"=" => 37,
			">" => 31
		},
		GOTOS => {
			'value_op_rhs' => 47,
			'operator' => 24
		}
	},
	{#State 16
		DEFAULT => -60
	},
	{#State 17
		DEFAULT => -29
	},
	{#State 18
		ACTIONS => {
			'OR' => 48
		},
		DEFAULT => -18
	},
	{#State 19
		ACTIONS => {
			"." => 39,
			"!" => 29,
			"<" => 35,
			">" => 31,
			"=" => 37
		},
		GOTOS => {
			'dot' => 21,
			'operator' => 49
		}
	},
	{#State 20
		ACTIONS => {
			"(" => 16,
			'NOT' => 10,
			'identifier' => 9,
			'string' => 12,
			'number' => 8,
			'LENGTH' => 3
		},
		GOTOS => {
			'length_comparison' => 1,
			'property' => 7,
			'expression_clause' => 50,
			'property_first_comparison' => 17,
			'comparison' => 6,
			'constant' => 15,
			'predicate_comparison' => 5,
			'openingbrace' => 14,
			'expression_phrase' => 4,
			'constant_first_comparison' => 2
		}
	},
	{#State 21
		ACTIONS => {
			'identifier' => 51
		}
	},
	{#State 22
		DEFAULT => -31
	},
	{#State 23
		DEFAULT => -32
	},
	{#State 24
		ACTIONS => {
			'identifier' => 9,
			'number' => 53,
			'string' => 52
		},
		GOTOS => {
			'value' => 55,
			'property' => 54
		}
	},
	{#State 25
		ACTIONS => {
			'string' => 56,
			'WITH' => 57
		}
	},
	{#State 26
		DEFAULT => -34
	},
	{#State 27
		ACTIONS => {
			">" => 31,
			'ANY' => 62,
			'string' => 52,
			"<" => 35,
			'identifier' => 9,
			'ALL' => 58,
			"=" => 37,
			'ONLY' => 61,
			"!" => 29,
			'number' => 53
		},
		GOTOS => {
			'operator' => 60,
			'value' => 59,
			'property' => 54
		}
	},
	{#State 28
		DEFAULT => -64
	},
	{#State 29
		ACTIONS => {
			"=" => 63
		}
	},
	{#State 30
		ACTIONS => {
			'WITH' => 64,
			'string' => 65
		}
	},
	{#State 31
		ACTIONS => {
			"=" => 66
		},
		DEFAULT => -67
	},
	{#State 32
		ACTIONS => {
			'string' => 67
		}
	},
	{#State 33
		ACTIONS => {
			'string' => 68
		}
	},
	{#State 34
		ACTIONS => {
			'identifier' => 9
		},
		GOTOS => {
			'property' => 69
		}
	},
	{#State 35
		ACTIONS => {
			"=" => 70
		},
		DEFAULT => -65
	},
	{#State 36
		ACTIONS => {
			":" => 28,
			'HAS' => 71
		},
		GOTOS => {
			'colon' => 72
		}
	},
	{#State 37
		DEFAULT => -69
	},
	{#State 38
		DEFAULT => -30
	},
	{#State 39
		DEFAULT => -62
	},
	{#State 40
		ACTIONS => {
			'KNOWN' => 73,
			'UNKNOWN' => 74
		}
	},
	{#State 41
		DEFAULT => -33
	},
	{#State 42
		DEFAULT => -26
	},
	{#State 43
		DEFAULT => -25
	},
	{#State 44
		ACTIONS => {
			'string' => 12,
			'number' => 8,
			'LENGTH' => 3,
			"(" => 16,
			'identifier' => 9,
			'NOT' => 10
		},
		GOTOS => {
			'property' => 7,
			'length_comparison' => 1,
			'predicate_comparison' => 5,
			'expression' => 75,
			'openingbrace' => 14,
			'constant' => 15,
			'expression_phrase' => 4,
			'constant_first_comparison' => 2,
			'expression_clause' => 18,
			'property_first_comparison' => 17,
			'comparison' => 6
		}
	},
	{#State 45
		DEFAULT => 0
	},
	{#State 46
		ACTIONS => {
			")" => 76
		},
		GOTOS => {
			'closingbrace' => 77
		}
	},
	{#State 47
		DEFAULT => -35
	},
	{#State 48
		ACTIONS => {
			'LENGTH' => 3,
			'number' => 8,
			'string' => 12,
			'identifier' => 9,
			'NOT' => 10,
			"(" => 16
		},
		GOTOS => {
			'length_comparison' => 1,
			'property' => 7,
			'comparison' => 6,
			'property_first_comparison' => 17,
			'expression_clause' => 18,
			'expression_phrase' => 4,
			'constant_first_comparison' => 2,
			'constant' => 15,
			'expression' => 78,
			'openingbrace' => 14,
			'predicate_comparison' => 5
		}
	},
	{#State 49
		ACTIONS => {
			'number' => 53,
			'string' => 52,
			'identifier' => 9
		},
		GOTOS => {
			'value' => 79,
			'property' => 54
		}
	},
	{#State 50
		DEFAULT => -21
	},
	{#State 51
		DEFAULT => -59
	},
	{#State 52
		DEFAULT => -4
	},
	{#State 53
		DEFAULT => -5
	},
	{#State 54
		ACTIONS => {
			"." => 39
		},
		DEFAULT => -6,
		GOTOS => {
			'dot' => 21
		}
	},
	{#State 55
		DEFAULT => -37
	},
	{#State 56
		DEFAULT => -41
	},
	{#State 57
		ACTIONS => {
			'string' => 80
		}
	},
	{#State 58
		ACTIONS => {
			"<" => 35,
			'string' => 52,
			"!" => 29,
			'number' => 53,
			"=" => 37,
			">" => 31,
			'identifier' => 9
		},
		GOTOS => {
			'operator' => 81,
			'value' => 82,
			'value_list' => 83,
			'property' => 54
		}
	},
	{#State 59
		DEFAULT => -46
	},
	{#State 60
		ACTIONS => {
			'identifier' => 9,
			'number' => 53,
			'string' => 52
		},
		GOTOS => {
			'property' => 54,
			'value' => 84
		}
	},
	{#State 61
		ACTIONS => {
			'number' => 53,
			'string' => 52,
			"!" => 29,
			"<" => 35,
			"=" => 37,
			">" => 31,
			'identifier' => 9
		},
		GOTOS => {
			'property' => 54,
			'value_list' => 85,
			'value' => 82,
			'operator' => 81
		}
	},
	{#State 62
		ACTIONS => {
			"=" => 37,
			">" => 31,
			'identifier' => 9,
			'string' => 52,
			"!" => 29,
			'number' => 53,
			"<" => 35
		},
		GOTOS => {
			'operator' => 81,
			'value_list' => 86,
			'property' => 54,
			'value' => 82
		}
	},
	{#State 63
		DEFAULT => -70
	},
	{#State 64
		ACTIONS => {
			'string' => 87
		}
	},
	{#State 65
		DEFAULT => -43
	},
	{#State 66
		DEFAULT => -68
	},
	{#State 67
		DEFAULT => -40
	},
	{#State 68
		DEFAULT => -45
	},
	{#State 69
		ACTIONS => {
			"." => 39
		},
		DEFAULT => -56,
		GOTOS => {
			'dot' => 21
		}
	},
	{#State 70
		DEFAULT => -66
	},
	{#State 71
		ACTIONS => {
			"=" => 37,
			'ALL' => 92,
			'identifier' => 9,
			"!" => 29,
			'number' => 53,
			'ONLY' => 89,
			'ANY' => 88,
			">" => 31,
			"<" => 35,
			'string' => 52
		},
		GOTOS => {
			'value' => 93,
			'property' => 54,
			'operator' => 91,
			'value_zip' => 90
		}
	},
	{#State 72
		ACTIONS => {
			'identifier' => 9
		},
		GOTOS => {
			'property' => 94
		}
	},
	{#State 73
		DEFAULT => -38
	},
	{#State 74
		DEFAULT => -39
	},
	{#State 75
		ACTIONS => {
			")" => 76
		},
		GOTOS => {
			'closingbrace' => 95
		}
	},
	{#State 76
		DEFAULT => -61
	},
	{#State 77
		DEFAULT => -24
	},
	{#State 78
		DEFAULT => -19
	},
	{#State 79
		DEFAULT => -55
	},
	{#State 80
		DEFAULT => -42
	},
	{#State 81
		ACTIONS => {
			'identifier' => 9,
			'string' => 52,
			'number' => 53
		},
		GOTOS => {
			'value' => 96,
			'property' => 54
		}
	},
	{#State 82
		DEFAULT => -7
	},
	{#State 83
		ACTIONS => {
			"," => 98
		},
		DEFAULT => -48,
		GOTOS => {
			'comma' => 97
		}
	},
	{#State 84
		DEFAULT => -47
	},
	{#State 85
		ACTIONS => {
			"," => 98
		},
		DEFAULT => -50,
		GOTOS => {
			'comma' => 97
		}
	},
	{#State 86
		ACTIONS => {
			"," => 98
		},
		DEFAULT => -49,
		GOTOS => {
			'comma' => 97
		}
	},
	{#State 87
		DEFAULT => -44
	},
	{#State 88
		ACTIONS => {
			'identifier' => 9,
			">" => 31,
			"=" => 37,
			"<" => 35,
			"!" => 29,
			'number' => 53,
			'string' => 52
		},
		GOTOS => {
			'value' => 93,
			'property' => 54,
			'operator' => 91,
			'value_zip_list' => 100,
			'value_zip' => 99
		}
	},
	{#State 89
		ACTIONS => {
			'string' => 52,
			'number' => 53,
			"!" => 29,
			"<" => 35,
			"=" => 37,
			">" => 31,
			'identifier' => 9
		},
		GOTOS => {
			'value_zip_list' => 101,
			'value_zip' => 99,
			'operator' => 91,
			'value' => 93,
			'property' => 54
		}
	},
	{#State 90
		ACTIONS => {
			":" => 28
		},
		DEFAULT => -51,
		GOTOS => {
			'value_zip_part' => 103,
			'colon' => 102
		}
	},
	{#State 91
		ACTIONS => {
			'string' => 52,
			'number' => 53,
			'identifier' => 9
		},
		GOTOS => {
			'value' => 104,
			'property' => 54
		}
	},
	{#State 92
		ACTIONS => {
			"=" => 37,
			'identifier' => 9,
			">" => 31,
			'string' => 52,
			"!" => 29,
			'number' => 53,
			"<" => 35
		},
		GOTOS => {
			'operator' => 91,
			'property' => 54,
			'value' => 93,
			'value_zip_list' => 105,
			'value_zip' => 99
		}
	},
	{#State 93
		ACTIONS => {
			":" => 28
		},
		GOTOS => {
			'colon' => 102,
			'value_zip_part' => 106
		}
	},
	{#State 94
		ACTIONS => {
			"." => 39
		},
		DEFAULT => -57,
		GOTOS => {
			'dot' => 21
		}
	},
	{#State 95
		DEFAULT => -27
	},
	{#State 96
		DEFAULT => -8
	},
	{#State 97
		ACTIONS => {
			">" => 31,
			'identifier' => 9,
			"=" => 37,
			'string' => 52,
			"!" => 29,
			'number' => 53,
			"<" => 35
		},
		GOTOS => {
			'operator' => 108,
			'value' => 107,
			'property' => 54
		}
	},
	{#State 98
		DEFAULT => -63
	},
	{#State 99
		ACTIONS => {
			":" => 28
		},
		DEFAULT => -16,
		GOTOS => {
			'colon' => 102,
			'value_zip_part' => 103
		}
	},
	{#State 100
		ACTIONS => {
			"," => 98
		},
		DEFAULT => -54,
		GOTOS => {
			'comma' => 109
		}
	},
	{#State 101
		ACTIONS => {
			"," => 98
		},
		DEFAULT => -52,
		GOTOS => {
			'comma' => 109
		}
	},
	{#State 102
		ACTIONS => {
			"<" => 35,
			"!" => 29,
			'string' => 52,
			'number' => 53,
			"=" => 37,
			'identifier' => 9,
			">" => 31
		},
		GOTOS => {
			'value' => 110,
			'property' => 54,
			'operator' => 111
		}
	},
	{#State 103
		DEFAULT => -13
	},
	{#State 104
		ACTIONS => {
			":" => 28
		},
		GOTOS => {
			'value_zip_part' => 112,
			'colon' => 102
		}
	},
	{#State 105
		ACTIONS => {
			"," => 98
		},
		DEFAULT => -53,
		GOTOS => {
			'comma' => 109
		}
	},
	{#State 106
		DEFAULT => -11
	},
	{#State 107
		DEFAULT => -9
	},
	{#State 108
		ACTIONS => {
			'string' => 52,
			'number' => 53,
			'identifier' => 9
		},
		GOTOS => {
			'value' => 113,
			'property' => 54
		}
	},
	{#State 109
		ACTIONS => {
			'identifier' => 9,
			">" => 31,
			"=" => 37,
			"<" => 35,
			'number' => 53,
			"!" => 29,
			'string' => 52
		},
		GOTOS => {
			'value_zip' => 114,
			'operator' => 91,
			'value' => 93,
			'property' => 54
		}
	},
	{#State 110
		DEFAULT => -14
	},
	{#State 111
		ACTIONS => {
			'identifier' => 9,
			'string' => 52,
			'number' => 53
		},
		GOTOS => {
			'value' => 115,
			'property' => 54
		}
	},
	{#State 112
		DEFAULT => -12
	},
	{#State 113
		DEFAULT => -10
	},
	{#State 114
		ACTIONS => {
			":" => 28
		},
		DEFAULT => -17,
		GOTOS => {
			'value_zip_part' => 103,
			'colon' => 102
		}
	},
	{#State 115
		DEFAULT => -15
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
                return [ @_[1..$#_] ];
            }
	],
	[#Rule 12
		 'value_zip', 3,
sub
#line 58 "FilterParser.yp"
{
                return [ @_[1..$#_] ];
            }
	],
	[#Rule 13
		 'value_zip', 2,
sub
#line 62 "FilterParser.yp"
{
                return [ @_[1..$#_] ];
            }
	],
	[#Rule 14
		 'value_zip_part', 2,
sub
#line 68 "FilterParser.yp"
{
                    return [ undef, $_[2] ];
                }
	],
	[#Rule 15
		 'value_zip_part', 3,
sub
#line 72 "FilterParser.yp"
{
                    return [ $_[2], $_[3] ];
                }
	],
	[#Rule 16
		 'value_zip_list', 1, undef
	],
	[#Rule 17
		 'value_zip_list', 3,
sub
#line 79 "FilterParser.yp"
{
                    return [ $_[1], $_[3] ];
                }
	],
	[#Rule 18
		 'expression', 1, undef
	],
	[#Rule 19
		 'expression', 3,
sub
#line 88 "FilterParser.yp"
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
#line 95 "FilterParser.yp"
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
#line 103 "FilterParser.yp"
{
                        return $_[2];
                    }
	],
	[#Rule 25
		 'expression_phrase', 2,
sub
#line 107 "FilterParser.yp"
{
                        return [ @_[1..$#_] ];
                    }
	],
	[#Rule 26
		 'expression_phrase', 2,
sub
#line 111 "FilterParser.yp"
{
                        return [ @_[1..$#_] ];
                    }
	],
	[#Rule 27
		 'expression_phrase', 4,
sub
#line 115 "FilterParser.yp"
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
#line 123 "FilterParser.yp"
{
                                    $_[2]->unshift_operand( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 31
		 'property_first_comparison', 2,
sub
#line 128 "FilterParser.yp"
{
                                    return [ $_[1], @{$_[2]} ];
                                }
	],
	[#Rule 32
		 'property_first_comparison', 2,
sub
#line 132 "FilterParser.yp"
{
                                    $_[2]->unshift_operand( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 33
		 'property_first_comparison', 2,
sub
#line 137 "FilterParser.yp"
{
                                    $_[2]->set_property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 34
		 'property_first_comparison', 2,
sub
#line 142 "FilterParser.yp"
{
                                    $_[2]->unshift_property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 35
		 'constant_first_comparison', 2,
sub
#line 149 "FilterParser.yp"
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
#line 158 "FilterParser.yp"
{
                    my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                    $cmp->push_operand( $_[2] );
                    return $cmp;
                }
	],
	[#Rule 38
		 'known_op_rhs', 2,
sub
#line 166 "FilterParser.yp"
{
                    return [ @_[1..$#_] ];
                }
	],
	[#Rule 39
		 'known_op_rhs', 2,
sub
#line 170 "FilterParser.yp"
{
                    return [ @_[1..$#_] ];
                }
	],
	[#Rule 40
		 'fuzzy_string_op_rhs', 2,
sub
#line 176 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 41
		 'fuzzy_string_op_rhs', 2,
sub
#line 182 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 42
		 'fuzzy_string_op_rhs', 3,
sub
#line 188 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( "$_[1] $_[2]" );
                            $cmp->push_operand( $_[3] );
                            return $cmp;
                        }
	],
	[#Rule 43
		 'fuzzy_string_op_rhs', 2,
sub
#line 194 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 44
		 'fuzzy_string_op_rhs', 3,
sub
#line 200 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( "$_[1] $_[2]" );
                            $cmp->push_operand( $_[3] );
                            return $cmp;
                        }
	],
	[#Rule 45
		 'fuzzy_string_op_rhs', 2,
sub
#line 206 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 46
		 'set_op_rhs', 2,
sub
#line 214 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( $_[1] );
                $lc->set_values( [ '=', $_[2] ] );
                return $lc;
            }
	],
	[#Rule 47
		 'set_op_rhs', 3,
sub
#line 220 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( $_[1] );
                $lc->set_values( [ $_[2], $_[3] ] );
                return $lc;
            }
	],
	[#Rule 48
		 'set_op_rhs', 3,
sub
#line 226 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( "$_[1] $_[2]" );
                $lc->set_values( $_[3] );
                return $lc;
            }
	],
	[#Rule 49
		 'set_op_rhs', 3,
sub
#line 232 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( "$_[1] $_[2]" );
                $lc->set_values( $_[3] );
                return $lc;
            }
	],
	[#Rule 50
		 'set_op_rhs', 3,
sub
#line 238 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( "$_[1] $_[2]" );
                $lc->set_values( $_[3] );
                return $lc;
            }
	],
	[#Rule 51
		 'set_zip_op_rhs', 3,
sub
#line 246 "FilterParser.yp"
{
                    $_[1]->set_operator( $_[2] );
                    $_[1]->set_values( $_[3] );
                    return $_[1];
                }
	],
	[#Rule 52
		 'set_zip_op_rhs', 4,
sub
#line 252 "FilterParser.yp"
{
                    $_[1]->set_operator( "$_[2] $_[3]" );
                    $_[1]->set_values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 53
		 'set_zip_op_rhs', 4,
sub
#line 258 "FilterParser.yp"
{
                    $_[1]->set_operator( "$_[2] $_[3]" );
                    $_[1]->set_values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 54
		 'set_zip_op_rhs', 4,
sub
#line 264 "FilterParser.yp"
{
                    $_[1]->set_operator( "$_[2] $_[3]" );
                    $_[1]->set_values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 55
		 'length_comparison', 4,
sub
#line 272 "FilterParser.yp"
{
                        my $cmp = OPTiMaDe::FilterParser::ListComparison->new( $_[1] );
                        $cmp->set_property( $_[2] );
                        $cmp->set_values( [ $_[3], $_[4] ] );
                        return $cmp;
                    }
	],
	[#Rule 56
		 'property_zip_addon', 2,
sub
#line 281 "FilterParser.yp"
{
                            my $zip = OPTiMaDe::FilterParser::Zip->new;
                            $zip->push_property( $_[2] );
                            return $zip;
                        }
	],
	[#Rule 57
		 'property_zip_addon', 3,
sub
#line 287 "FilterParser.yp"
{
                            $_[1]->push_property( $_[3] );
                            return $_[1];
                        }
	],
	[#Rule 58
		 'property', 1,
sub
#line 296 "FilterParser.yp"
{
                my $id = OPTiMaDe::FilterParser::Property->new;
                $id->push_identifier( $_[1] );
                return $id;
            }
	],
	[#Rule 59
		 'property', 3,
sub
#line 302 "FilterParser.yp"
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
#line 324 "FilterParser.yp"
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
#line 329 "FilterParser.yp"
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
#line 334 "FilterParser.yp"
{
                return join( '', @_[1..$#_] );
            }
	]
],
                                  @_);
    bless($self,$class);
}

#line 339 "FilterParser.yp"


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
