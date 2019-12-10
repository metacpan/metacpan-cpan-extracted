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

use Scalar::Util qw(blessed);

use OPTiMaDe::FilterParser::AndOr;
use OPTiMaDe::FilterParser::Comparison;
use OPTiMaDe::FilterParser::Known;
use OPTiMaDe::FilterParser::ListComparison;
use OPTiMaDe::FilterParser::Negation;
use OPTiMaDe::FilterParser::Property;
use OPTiMaDe::FilterParser::Zip;

our $VERSION = '0.4.1';
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
			'LENGTH' => 6,
			'identifier' => 13,
			'NOT' => 5,
			'string' => 8,
			'number' => 4,
			"(" => 3
		},
		GOTOS => {
			'expression' => 16,
			'constant_first_comparison' => 15,
			'comparison' => 12,
			'property' => 14,
			'expression_phrase' => 1,
			'property_first_comparison' => 11,
			'expression_clause' => 10,
			'length_comparison' => 2,
			'openingbrace' => 9,
			'constant' => 7,
			'filter' => 17,
			'predicate_comparison' => 18
		}
	},
	{#State 1
		ACTIONS => {
			'AND' => 19
		},
		DEFAULT => -20
	},
	{#State 2
		DEFAULT => -36
	},
	{#State 3
		DEFAULT => -60
	},
	{#State 4
		DEFAULT => -3
	},
	{#State 5
		ACTIONS => {
			"(" => 3,
			'number' => 4,
			'string' => 8,
			'LENGTH' => 6,
			'identifier' => 13
		},
		GOTOS => {
			'openingbrace' => 21,
			'property_first_comparison' => 11,
			'length_comparison' => 2,
			'property' => 14,
			'comparison' => 20,
			'constant_first_comparison' => 15,
			'predicate_comparison' => 22,
			'constant' => 7
		}
	},
	{#State 6
		ACTIONS => {
			'identifier' => 13
		},
		GOTOS => {
			'property' => 23
		}
	},
	{#State 7
		ACTIONS => {
			"!" => 29,
			">" => 25,
			"<" => 24,
			"=" => 27
		},
		GOTOS => {
			'value_op_rhs' => 26,
			'operator' => 28
		}
	},
	{#State 8
		DEFAULT => -2
	},
	{#State 9
		ACTIONS => {
			'number' => 4,
			"(" => 3,
			'NOT' => 5,
			'identifier' => 13,
			'LENGTH' => 6,
			'string' => 8
		},
		GOTOS => {
			'constant' => 7,
			'predicate_comparison' => 18,
			'constant_first_comparison' => 15,
			'expression' => 30,
			'comparison' => 12,
			'property' => 14,
			'expression_phrase' => 1,
			'length_comparison' => 2,
			'property_first_comparison' => 11,
			'expression_clause' => 10,
			'openingbrace' => 9
		}
	},
	{#State 10
		ACTIONS => {
			'OR' => 31
		},
		DEFAULT => -18
	},
	{#State 11
		DEFAULT => -29
	},
	{#State 12
		DEFAULT => -22
	},
	{#State 13
		DEFAULT => -58
	},
	{#State 14
		ACTIONS => {
			'LIKE' => 32,
			"!" => 29,
			">" => 25,
			'ENDS' => 33,
			'IS' => 35,
			":" => 40,
			'HAS' => 36,
			'CONTAINS' => 42,
			"<" => 24,
			'STARTS' => 44,
			"=" => 27,
			"." => 45
		},
		GOTOS => {
			'operator' => 28,
			'property_zip_addon' => 41,
			'set_zip_op_rhs' => 37,
			'fuzzy_string_op_rhs' => 47,
			'dot' => 46,
			'known_op_rhs' => 43,
			'colon' => 39,
			'set_op_rhs' => 34,
			'value_op_rhs' => 38
		}
	},
	{#State 15
		DEFAULT => -28
	},
	{#State 16
		DEFAULT => -1
	},
	{#State 17
		ACTIONS => {
			'' => 48
		}
	},
	{#State 18
		DEFAULT => -23
	},
	{#State 19
		ACTIONS => {
			'number' => 4,
			"(" => 3,
			'NOT' => 5,
			'identifier' => 13,
			'LENGTH' => 6,
			'string' => 8
		},
		GOTOS => {
			'comparison' => 12,
			'property' => 14,
			'constant_first_comparison' => 15,
			'openingbrace' => 9,
			'expression_phrase' => 1,
			'expression_clause' => 49,
			'length_comparison' => 2,
			'property_first_comparison' => 11,
			'constant' => 7,
			'predicate_comparison' => 18
		}
	},
	{#State 20
		DEFAULT => -25
	},
	{#State 21
		ACTIONS => {
			'NOT' => 5,
			'identifier' => 13,
			'LENGTH' => 6,
			'string' => 8,
			'number' => 4,
			"(" => 3
		},
		GOTOS => {
			'constant' => 7,
			'predicate_comparison' => 18,
			'constant_first_comparison' => 15,
			'expression' => 50,
			'comparison' => 12,
			'property' => 14,
			'expression_phrase' => 1,
			'property_first_comparison' => 11,
			'length_comparison' => 2,
			'expression_clause' => 10,
			'openingbrace' => 9
		}
	},
	{#State 22
		DEFAULT => -26
	},
	{#State 23
		ACTIONS => {
			"." => 45,
			"=" => 27,
			"<" => 24,
			">" => 25,
			"!" => 29
		},
		GOTOS => {
			'operator' => 51,
			'dot' => 46
		}
	},
	{#State 24
		ACTIONS => {
			"=" => 52
		},
		DEFAULT => -65
	},
	{#State 25
		ACTIONS => {
			"=" => 53
		},
		DEFAULT => -67
	},
	{#State 26
		DEFAULT => -35
	},
	{#State 27
		DEFAULT => -69
	},
	{#State 28
		ACTIONS => {
			'number' => 55,
			'string' => 54,
			'identifier' => 13
		},
		GOTOS => {
			'property' => 56,
			'value' => 57
		}
	},
	{#State 29
		ACTIONS => {
			"=" => 58
		}
	},
	{#State 30
		ACTIONS => {
			")" => 60
		},
		GOTOS => {
			'closingbrace' => 59
		}
	},
	{#State 31
		ACTIONS => {
			'NOT' => 5,
			'identifier' => 13,
			'LENGTH' => 6,
			'string' => 8,
			'number' => 4,
			"(" => 3
		},
		GOTOS => {
			'predicate_comparison' => 18,
			'constant' => 7,
			'expression_phrase' => 1,
			'property_first_comparison' => 11,
			'expression_clause' => 10,
			'length_comparison' => 2,
			'openingbrace' => 9,
			'constant_first_comparison' => 15,
			'expression' => 61,
			'comparison' => 12,
			'property' => 14
		}
	},
	{#State 32
		ACTIONS => {
			'string' => 62
		}
	},
	{#State 33
		ACTIONS => {
			'string' => 63,
			'WITH' => 64
		}
	},
	{#State 34
		DEFAULT => -33
	},
	{#State 35
		ACTIONS => {
			'KNOWN' => 66,
			'UNKNOWN' => 65
		}
	},
	{#State 36
		ACTIONS => {
			"=" => 27,
			"<" => 24,
			'string' => 54,
			'number' => 55,
			'identifier' => 13,
			'ONLY' => 69,
			">" => 25,
			"!" => 29,
			'ALL' => 68,
			'ANY' => 67
		},
		GOTOS => {
			'operator' => 71,
			'value' => 70,
			'property' => 56
		}
	},
	{#State 37
		DEFAULT => -34
	},
	{#State 38
		DEFAULT => -30
	},
	{#State 39
		ACTIONS => {
			'identifier' => 13
		},
		GOTOS => {
			'property' => 72
		}
	},
	{#State 40
		DEFAULT => -64
	},
	{#State 41
		ACTIONS => {
			'HAS' => 73,
			":" => 40
		},
		GOTOS => {
			'colon' => 74
		}
	},
	{#State 42
		ACTIONS => {
			'string' => 75
		}
	},
	{#State 43
		DEFAULT => -31
	},
	{#State 44
		ACTIONS => {
			'WITH' => 77,
			'string' => 76
		}
	},
	{#State 45
		DEFAULT => -62
	},
	{#State 46
		ACTIONS => {
			'identifier' => 78
		}
	},
	{#State 47
		DEFAULT => -32
	},
	{#State 48
		DEFAULT => 0
	},
	{#State 49
		DEFAULT => -21
	},
	{#State 50
		ACTIONS => {
			")" => 60
		},
		GOTOS => {
			'closingbrace' => 79
		}
	},
	{#State 51
		ACTIONS => {
			'identifier' => 13,
			'string' => 54,
			'number' => 55
		},
		GOTOS => {
			'property' => 56,
			'value' => 80
		}
	},
	{#State 52
		DEFAULT => -66
	},
	{#State 53
		DEFAULT => -68
	},
	{#State 54
		DEFAULT => -4
	},
	{#State 55
		DEFAULT => -5
	},
	{#State 56
		ACTIONS => {
			"." => 45
		},
		DEFAULT => -6,
		GOTOS => {
			'dot' => 46
		}
	},
	{#State 57
		DEFAULT => -37
	},
	{#State 58
		DEFAULT => -70
	},
	{#State 59
		DEFAULT => -24
	},
	{#State 60
		DEFAULT => -61
	},
	{#State 61
		DEFAULT => -19
	},
	{#State 62
		DEFAULT => -45
	},
	{#State 63
		DEFAULT => -43
	},
	{#State 64
		ACTIONS => {
			'string' => 81
		}
	},
	{#State 65
		DEFAULT => -39
	},
	{#State 66
		DEFAULT => -38
	},
	{#State 67
		ACTIONS => {
			"!" => 29,
			'number' => 55,
			">" => 25,
			"<" => 24,
			'string' => 54,
			'identifier' => 13,
			"=" => 27
		},
		GOTOS => {
			'property' => 56,
			'value_list' => 84,
			'value' => 83,
			'operator' => 82
		}
	},
	{#State 68
		ACTIONS => {
			'string' => 54,
			"<" => 24,
			"=" => 27,
			'identifier' => 13,
			"!" => 29,
			">" => 25,
			'number' => 55
		},
		GOTOS => {
			'value' => 83,
			'operator' => 82,
			'value_list' => 85,
			'property' => 56
		}
	},
	{#State 69
		ACTIONS => {
			'number' => 55,
			">" => 25,
			"!" => 29,
			'identifier' => 13,
			"=" => 27,
			"<" => 24,
			'string' => 54
		},
		GOTOS => {
			'operator' => 82,
			'value' => 83,
			'property' => 56,
			'value_list' => 86
		}
	},
	{#State 70
		DEFAULT => -46
	},
	{#State 71
		ACTIONS => {
			'number' => 55,
			'string' => 54,
			'identifier' => 13
		},
		GOTOS => {
			'property' => 56,
			'value' => 87
		}
	},
	{#State 72
		ACTIONS => {
			"." => 45
		},
		DEFAULT => -56,
		GOTOS => {
			'dot' => 46
		}
	},
	{#State 73
		ACTIONS => {
			'ANY' => 92,
			"!" => 29,
			'ALL' => 91,
			">" => 25,
			'ONLY' => 88,
			'identifier' => 13,
			'number' => 55,
			'string' => 54,
			"<" => 24,
			"=" => 27
		},
		GOTOS => {
			'value_zip' => 93,
			'property' => 56,
			'value' => 90,
			'operator' => 89
		}
	},
	{#State 74
		ACTIONS => {
			'identifier' => 13
		},
		GOTOS => {
			'property' => 94
		}
	},
	{#State 75
		DEFAULT => -40
	},
	{#State 76
		DEFAULT => -41
	},
	{#State 77
		ACTIONS => {
			'string' => 95
		}
	},
	{#State 78
		DEFAULT => -59
	},
	{#State 79
		DEFAULT => -27
	},
	{#State 80
		DEFAULT => -55
	},
	{#State 81
		DEFAULT => -44
	},
	{#State 82
		ACTIONS => {
			'string' => 54,
			'identifier' => 13,
			'number' => 55
		},
		GOTOS => {
			'property' => 56,
			'value' => 96
		}
	},
	{#State 83
		DEFAULT => -7
	},
	{#State 84
		ACTIONS => {
			"," => 97
		},
		DEFAULT => -49,
		GOTOS => {
			'comma' => 98
		}
	},
	{#State 85
		ACTIONS => {
			"," => 97
		},
		DEFAULT => -48,
		GOTOS => {
			'comma' => 98
		}
	},
	{#State 86
		ACTIONS => {
			"," => 97
		},
		DEFAULT => -50,
		GOTOS => {
			'comma' => 98
		}
	},
	{#State 87
		DEFAULT => -47
	},
	{#State 88
		ACTIONS => {
			"=" => 27,
			'identifier' => 13,
			'string' => 54,
			"<" => 24,
			">" => 25,
			'number' => 55,
			"!" => 29
		},
		GOTOS => {
			'value_zip' => 100,
			'property' => 56,
			'value_zip_list' => 99,
			'value' => 90,
			'operator' => 89
		}
	},
	{#State 89
		ACTIONS => {
			'string' => 54,
			'identifier' => 13,
			'number' => 55
		},
		GOTOS => {
			'property' => 56,
			'value' => 101
		}
	},
	{#State 90
		ACTIONS => {
			":" => 40
		},
		GOTOS => {
			'value_zip_part' => 102,
			'colon' => 103
		}
	},
	{#State 91
		ACTIONS => {
			">" => 25,
			'number' => 55,
			"!" => 29,
			"=" => 27,
			'identifier' => 13,
			'string' => 54,
			"<" => 24
		},
		GOTOS => {
			'operator' => 89,
			'value' => 90,
			'property' => 56,
			'value_zip_list' => 104,
			'value_zip' => 100
		}
	},
	{#State 92
		ACTIONS => {
			"!" => 29,
			">" => 25,
			'number' => 55,
			'string' => 54,
			"<" => 24,
			"=" => 27,
			'identifier' => 13
		},
		GOTOS => {
			'value_zip' => 100,
			'value_zip_list' => 105,
			'property' => 56,
			'value' => 90,
			'operator' => 89
		}
	},
	{#State 93
		ACTIONS => {
			":" => 40
		},
		DEFAULT => -51,
		GOTOS => {
			'colon' => 103,
			'value_zip_part' => 106
		}
	},
	{#State 94
		ACTIONS => {
			"." => 45
		},
		DEFAULT => -57,
		GOTOS => {
			'dot' => 46
		}
	},
	{#State 95
		DEFAULT => -42
	},
	{#State 96
		DEFAULT => -8
	},
	{#State 97
		DEFAULT => -63
	},
	{#State 98
		ACTIONS => {
			"!" => 29,
			'number' => 55,
			">" => 25,
			"<" => 24,
			'string' => 54,
			'identifier' => 13,
			"=" => 27
		},
		GOTOS => {
			'property' => 56,
			'operator' => 108,
			'value' => 107
		}
	},
	{#State 99
		ACTIONS => {
			"," => 97
		},
		DEFAULT => -52,
		GOTOS => {
			'comma' => 109
		}
	},
	{#State 100
		ACTIONS => {
			":" => 40
		},
		DEFAULT => -16,
		GOTOS => {
			'colon' => 103,
			'value_zip_part' => 106
		}
	},
	{#State 101
		ACTIONS => {
			":" => 40
		},
		GOTOS => {
			'value_zip_part' => 110,
			'colon' => 103
		}
	},
	{#State 102
		DEFAULT => -11
	},
	{#State 103
		ACTIONS => {
			"!" => 29,
			'number' => 55,
			">" => 25,
			"<" => 24,
			'string' => 54,
			'identifier' => 13,
			"=" => 27
		},
		GOTOS => {
			'operator' => 111,
			'value' => 112,
			'property' => 56
		}
	},
	{#State 104
		ACTIONS => {
			"," => 97
		},
		DEFAULT => -53,
		GOTOS => {
			'comma' => 109
		}
	},
	{#State 105
		ACTIONS => {
			"," => 97
		},
		DEFAULT => -54,
		GOTOS => {
			'comma' => 109
		}
	},
	{#State 106
		DEFAULT => -13
	},
	{#State 107
		DEFAULT => -9
	},
	{#State 108
		ACTIONS => {
			'string' => 54,
			'identifier' => 13,
			'number' => 55
		},
		GOTOS => {
			'value' => 113,
			'property' => 56
		}
	},
	{#State 109
		ACTIONS => {
			"<" => 24,
			'string' => 54,
			'identifier' => 13,
			"=" => 27,
			"!" => 29,
			'number' => 55,
			">" => 25
		},
		GOTOS => {
			'value_zip' => 114,
			'property' => 56,
			'value' => 90,
			'operator' => 89
		}
	},
	{#State 110
		DEFAULT => -12
	},
	{#State 111
		ACTIONS => {
			'number' => 55,
			'string' => 54,
			'identifier' => 13
		},
		GOTOS => {
			'value' => 115,
			'property' => 56
		}
	},
	{#State 112
		DEFAULT => -14
	},
	{#State 113
		DEFAULT => -10
	},
	{#State 114
		ACTIONS => {
			":" => 40
		},
		DEFAULT => -17,
		GOTOS => {
			'value_zip_part' => 106,
			'colon' => 103
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
#line 39 "FilterParser.yp"
{
                return [ [ '=', $_[1] ] ];
            }
	],
	[#Rule 8
		 'value_list', 2,
sub
#line 43 "FilterParser.yp"
{
                return [ [ @_[1..$#_] ] ];
            }
	],
	[#Rule 9
		 'value_list', 3,
sub
#line 47 "FilterParser.yp"
{
                push @{$_[1]}, [ '=', $_[3] ];
                return $_[1];
            }
	],
	[#Rule 10
		 'value_list', 4,
sub
#line 52 "FilterParser.yp"
{
                push @{$_[1]}, [ $_[3], $_[4] ];
                return $_[1];
            }
	],
	[#Rule 11
		 'value_zip', 2,
sub
#line 59 "FilterParser.yp"
{
                return [ [ '=', $_[1] ], $_[2] ];
            }
	],
	[#Rule 12
		 'value_zip', 3,
sub
#line 63 "FilterParser.yp"
{
                return [ [ $_[1], $_[2] ], $_[3] ];
            }
	],
	[#Rule 13
		 'value_zip', 2,
sub
#line 67 "FilterParser.yp"
{
                push @{$_[1]}, $_[2];
                return $_[1];
            }
	],
	[#Rule 14
		 'value_zip_part', 2,
sub
#line 74 "FilterParser.yp"
{
                    return [ '=', $_[2] ];
                }
	],
	[#Rule 15
		 'value_zip_part', 3,
sub
#line 78 "FilterParser.yp"
{
                    return [ $_[2], $_[3] ];
                }
	],
	[#Rule 16
		 'value_zip_list', 1,
sub
#line 84 "FilterParser.yp"
{
                    return [ $_[1] ];
                }
	],
	[#Rule 17
		 'value_zip_list', 3,
sub
#line 88 "FilterParser.yp"
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
#line 98 "FilterParser.yp"
{
                return OPTiMaDe::FilterParser::AndOr->new( @_[1..$#_] );
            }
	],
	[#Rule 20
		 'expression_clause', 1, undef
	],
	[#Rule 21
		 'expression_clause', 3,
sub
#line 105 "FilterParser.yp"
{
                        return OPTiMaDe::FilterParser::AndOr->new( @_[1..$#_] );
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
#line 113 "FilterParser.yp"
{
                        return $_[2];
                    }
	],
	[#Rule 25
		 'expression_phrase', 2,
sub
#line 117 "FilterParser.yp"
{
                        return OPTiMaDe::FilterParser::Negation->new( $_[2] );
                    }
	],
	[#Rule 26
		 'expression_phrase', 2,
sub
#line 121 "FilterParser.yp"
{
                        return OPTiMaDe::FilterParser::Negation->new( $_[2] );
                    }
	],
	[#Rule 27
		 'expression_phrase', 4,
sub
#line 125 "FilterParser.yp"
{
                        return OPTiMaDe::FilterParser::Negation->new( $_[3] );
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
#line 133 "FilterParser.yp"
{
                                    $_[2]->unshift_operand( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 31
		 'property_first_comparison', 2,
sub
#line 138 "FilterParser.yp"
{
                                    $_[2]->property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 32
		 'property_first_comparison', 2,
sub
#line 143 "FilterParser.yp"
{
                                    $_[2]->unshift_operand( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 33
		 'property_first_comparison', 2,
sub
#line 148 "FilterParser.yp"
{
                                    $_[2]->set_property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 34
		 'property_first_comparison', 2,
sub
#line 153 "FilterParser.yp"
{
                                    $_[2]->unshift_property( $_[1] );
                                    return $_[2];
                                }
	],
	[#Rule 35
		 'constant_first_comparison', 2,
sub
#line 160 "FilterParser.yp"
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
#line 169 "FilterParser.yp"
{
                    my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                    $cmp->push_operand( $_[2] );
                    return $cmp;
                }
	],
	[#Rule 38
		 'known_op_rhs', 2,
sub
#line 177 "FilterParser.yp"
{
                    return OPTiMaDe::FilterParser::Known->new( 1 );
                }
	],
	[#Rule 39
		 'known_op_rhs', 2,
sub
#line 181 "FilterParser.yp"
{
                    return OPTiMaDe::FilterParser::Known->new( 0 );
                }
	],
	[#Rule 40
		 'fuzzy_string_op_rhs', 2,
sub
#line 187 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 41
		 'fuzzy_string_op_rhs', 2,
sub
#line 193 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 42
		 'fuzzy_string_op_rhs', 3,
sub
#line 199 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( "$_[1] $_[2]" );
                            $cmp->push_operand( $_[3] );
                            return $cmp;
                        }
	],
	[#Rule 43
		 'fuzzy_string_op_rhs', 2,
sub
#line 205 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 44
		 'fuzzy_string_op_rhs', 3,
sub
#line 211 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( "$_[1] $_[2]" );
                            $cmp->push_operand( $_[3] );
                            return $cmp;
                        }
	],
	[#Rule 45
		 'fuzzy_string_op_rhs', 2,
sub
#line 217 "FilterParser.yp"
{
                            my $cmp = OPTiMaDe::FilterParser::Comparison->new( $_[1] );
                            $cmp->push_operand( $_[2] );
                            return $cmp;
                        }
	],
	[#Rule 46
		 'set_op_rhs', 2,
sub
#line 225 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( $_[1] );
                $lc->set_values( [ [ '=', $_[2] ] ] );
                return $lc;
            }
	],
	[#Rule 47
		 'set_op_rhs', 3,
sub
#line 231 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( $_[1] );
                $lc->set_values( [ [ $_[2], $_[3] ] ] );
                return $lc;
            }
	],
	[#Rule 48
		 'set_op_rhs', 3,
sub
#line 237 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( "$_[1] $_[2]" );
                $lc->set_values( $_[3] );
                return $lc;
            }
	],
	[#Rule 49
		 'set_op_rhs', 3,
sub
#line 243 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( "$_[1] $_[2]" );
                $lc->set_values( $_[3] );
                return $lc;
            }
	],
	[#Rule 50
		 'set_op_rhs', 3,
sub
#line 249 "FilterParser.yp"
{
                my $lc = OPTiMaDe::FilterParser::ListComparison->new( "$_[1] $_[2]" );
                $lc->set_values( $_[3] );
                return $lc;
            }
	],
	[#Rule 51
		 'set_zip_op_rhs', 3,
sub
#line 257 "FilterParser.yp"
{
                    $_[1]->set_operator( $_[2] );
                    $_[1]->set_values( [ $_[3] ] );
                    return $_[1];
                }
	],
	[#Rule 52
		 'set_zip_op_rhs', 4,
sub
#line 263 "FilterParser.yp"
{
                    $_[1]->set_operator( "$_[2] $_[3]" );
                    $_[1]->set_values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 53
		 'set_zip_op_rhs', 4,
sub
#line 269 "FilterParser.yp"
{
                    $_[1]->set_operator( "$_[2] $_[3]" );
                    $_[1]->set_values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 54
		 'set_zip_op_rhs', 4,
sub
#line 275 "FilterParser.yp"
{
                    $_[1]->set_operator( "$_[2] $_[3]" );
                    $_[1]->set_values( $_[4] );
                    return $_[1];
                }
	],
	[#Rule 55
		 'length_comparison', 4,
sub
#line 283 "FilterParser.yp"
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
#line 292 "FilterParser.yp"
{
                            my $zip = OPTiMaDe::FilterParser::Zip->new;
                            $zip->push_property( $_[2] );
                            return $zip;
                        }
	],
	[#Rule 57
		 'property_zip_addon', 3,
sub
#line 298 "FilterParser.yp"
{
                            $_[1]->push_property( $_[3] );
                            return $_[1];
                        }
	],
	[#Rule 58
		 'property', 1,
sub
#line 307 "FilterParser.yp"
{
                return OPTiMaDe::FilterParser::Property->new( $_[1] );
            }
	],
	[#Rule 59
		 'property', 3,
sub
#line 311 "FilterParser.yp"
{
                push @{$_[1]}, $_[3];
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
#line 333 "FilterParser.yp"
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
#line 338 "FilterParser.yp"
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
#line 343 "FilterParser.yp"
{
                return join( '', @_[1..$#_] );
            }
	]
],
                                  @_);
    bless($self,$class);
}

#line 348 "FilterParser.yp"


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
