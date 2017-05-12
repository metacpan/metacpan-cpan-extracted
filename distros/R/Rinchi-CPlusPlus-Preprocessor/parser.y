%{
/*
 * UUID: db754b9f-f2fd-11dc-b899-00502c05c241
 * Author: Brian M. Ames, bames@apk.net
 * Copyright: Copyright (C) 2008 by Brian M. Ames
 */

#include <stdio.h>
#include "parser_routines.h"
#include "tree.h"
#include "lexer.h"
#define YYDEBUG 1
#define YYERROR_VERBOSE 1
//define YYSTYPE int
char *getCurrentFilename();
void yyerror(char const *s);
int yypp_lex (void);

%}

%no-lines
%name-prefix="yypp_"
%locations

%union {
  float fval;
  char *sval;
  unsigned int uval;
  int ival;
  long lval;
}

%token ECS_NULL
%token ASC_SOH
%token ASC_STX
%token ASC_ETX
%token ASC_EOT
%token ASC_ENQ
%token ASC_ACK
%token ECS_ALERT
%token ECS_BACKSPACE
%token BCS_WHTSP_TAB
%token BCS_WHTSP_NEWLINE
%token BCS_WHTSP_VERTICAL_TAB
%token BCS_WHTSP_FORMFEED
%token ECS_CARRIAGE_RETURN
%token ASC_SHIFT_OUT
%token ASC_SHIFT_IN
%token ASC_DLE
%token ASC_DC1
%token ASC_DC2
%token ASC_DC3
%token ASC_DC4
%token ASC_NAK
%token ASC_SYN
%token ASC_ETB
%token ASC_CAN
%token ASC_EM
%token ASC_SUB
%token ASC_ESC
%token ASC_IS4
%token ASC_IS3
%token ASC_IS2
%token ASC_IS1
%token BCS_WHTSP_SPACE
%token BCS_PUNCT_EXCLAMATION
%token BCS_PUNCT_QUOTE
%token BCS_PUNCT_HASH
%token ASC_DOLLAR_SIGN
%token BCS_PUNCT_PERCENT
%token BCS_PUNCT_AMPERSAND
%token BCS_PUNCT_APOSTROPHE
%token BCS_PUNCT_OPEN_PARENTHESIS
%token BCS_PUNCT_CLOSE_PARENTHESIS
%token BCS_PUNCT_ASTERISK
%token BCS_PUNCT_PLUS
%token BCS_PUNCT_COMMA
%token BCS_PUNCT_MINUS
%token BCS_PUNCT_PERIOD
%token BCS_PUNCT_SLASH
%token BCS_DIGIT_0
%token BCS_DIGIT_1
%token BCS_DIGIT_2
%token BCS_DIGIT_3
%token BCS_DIGIT_4
%token BCS_DIGIT_5
%token BCS_DIGIT_6
%token BCS_DIGIT_7
%token BCS_DIGIT_8
%token BCS_DIGIT_9
%token BCS_PUNCT_COLON
%token BCS_PUNCT_SEMICOLON
%token BCS_PUNCT_LESS_THAN
%token BCS_PUNCT_EQUAL
%token BCS_PUNCT_GREATER_THAN
%token BCS_PUNCT_QUESTION
%token ASC_AT_SIGN
%token BCS_UPPER_A
%token BCS_UPPER_B
%token BCS_UPPER_C
%token BCS_UPPER_D
%token BCS_UPPER_E
%token BCS_UPPER_F
%token BCS_UPPER_G
%token BCS_UPPER_H
%token BCS_UPPER_I
%token BCS_UPPER_J
%token BCS_UPPER_K
%token BCS_UPPER_L
%token BCS_UPPER_M
%token BCS_UPPER_N
%token BCS_UPPER_O
%token BCS_UPPER_P
%token BCS_UPPER_Q
%token BCS_UPPER_R
%token BCS_UPPER_S
%token BCS_UPPER_T
%token BCS_UPPER_U
%token BCS_UPPER_V
%token BCS_UPPER_W
%token BCS_UPPER_X
%token BCS_UPPER_Y
%token BCS_UPPER_Z
%token BCS_PUNCT_OPEN_BRACKET
%token BCS_PUNCT_BACKSLASH
%token BCS_PUNCT_CLOSE_BRACKET
%token BCS_PUNCT_CARET
%token BCS_PUNCT_UNDERSCORE
%token BCS_LOWER_A
%token BCS_LOWER_B
%token BCS_LOWER_C
%token BCS_LOWER_D
%token BCS_LOWER_E
%token BCS_LOWER_F
%token BCS_LOWER_G
%token BCS_LOWER_H
%token BCS_LOWER_I
%token BCS_LOWER_J
%token BCS_LOWER_K
%token BCS_LOWER_L
%token BCS_LOWER_M
%token BCS_LOWER_N
%token BCS_LOWER_O
%token BCS_LOWER_P
%token BCS_LOWER_Q
%token BCS_LOWER_R
%token BCS_LOWER_S
%token BCS_LOWER_T
%token BCS_LOWER_U
%token BCS_LOWER_V
%token BCS_LOWER_W
%token BCS_LOWER_X
%token BCS_LOWER_Y
%token BCS_LOWER_Z
%token BCS_PUNCT_OPEN_BRACE
%token BCS_PUNCT_VERTICAL_BAR
%token BCS_PUNCT_CLOSE_BRACE
%token BCS_PUNCT_TILDE
%token ASC_DEL

%token ALT_PUNCT_OPEN_BRACE
%token ALT_PUNCT_CLOSE_BRACE
%token ALT_PUNCT_OPEN_BRACKET
%token ALT_PUNCT_CLOSE_BRACKET
%token ALT_PUNCT_HASH

%token KWD_ASM
%token KWD_AUTO
%token KWD_BOOL
%token KWD_BREAK
%token KWD_CASE
%token KWD_CATCH
%token KWD_CHAR
%token KWD_CLASS
%token KWD_CONST
%token KWD_CONST_CAST
%token KWD_CONTINUE
%token KWD_DEFAULT
%token KWD_DEFINED
%token KWD_DELETE
%token KWD_DO
%token KWD_DOUBLE
%token KWD_DYNAMIC_CAST
%token KWD_ELSE
%token KWD_ENUM
%token KWD_EXPLICIT
%token KWD_EXPORT
%token KWD_EXTERN
%token KWD_FALSE
%token KWD_FLOAT
%token KWD_FOR
%token KWD_FRIEND
%token KWD_GOTO
%token KWD_IF
%token KWD_INLINE
%token KWD_INT
%token KWD_LONG
%token KWD_MUTABLE
%token KWD_NAMESPACE
%token KWD_NEW
%token KWD_OPERATOR
%token KWD_PRIVATE
%token KWD_PROTECTED
%token KWD_PUBLIC
%token KWD_REGISTER
%token KWD_REINTERPRET_CAST
%token KWD_RETURN
%token KWD_SHORT
%token KWD_SIGNED
%token KWD_SIZEOF
%token KWD_STATIC
%token KWD_STATIC_CAST
%token KWD_STRUCT
%token KWD_SWITCH
%token KWD_TEMPLATE
%token KWD_THIS
%token KWD_THROW
%token KWD_TRUE
%token KWD_TRY
%token KWD_TYPEDEF
%token KWD_TYPENAME
%token KWD_TYPEID
%token KWD_UNION
%token KWD_UNSIGNED
%token KWD_USING
%token KWD_VIRTUAL
%token KWD_VOID
%token KWD_VOLATILE
%token KWD_WCHAR_T
%token KWD_WHILE

%token PPD_NULL
%token PPD_DEFINE
%token PPD_ELIF
%token PPD_ELSE
%token PPD_ENDIF
%token PPD_ERROR
%token PPD_IF
%token PPD_IFDEF
%token PPD_IFNDEF
%token PPD_INCLUDE
%token PPD_LINE
%token PPD_PRAGMA
%token PPD_UNDEF

%token OP_LOGICAL_NOT
%token OP_NE
%token OP_STRINGIZE
%token OP_TOKEN_SPLICE
%token OP_MODULO
%token ALT_OP_TOKEN_SPLICE
%token OP_ASSIGN_MODULO
%token OP_BIT_AND
%token OP_ADDRESS
%token OP_LOGICAL_AND
%token OP_ASSIGN_BIT_AND
%token OP_DEREFERENCE
%token OP_MULTIPLY
%token OP_ASSIGN_MULTIPLY
%token OP_PLUS
%token OP_INCREMENT
%token OP_ASSIGN_PLUS
%token OP_MINUS
%token OP_DECREMENT
%token OP_ASSIGN_MINUS
%token OP_POINTER_MEMBER
%token OP_POINTER_POINTER_TO_MEMBER
%token OP_OBJECT_MEMBER
%token OP_OBJECT_POINTER_TO_MEMBER
%token OP_DIVIDE
%token OP_ASSIGN_DIVIDE
%token OP_ELSE
%token OP_SCOPE_REF
%token OP_LT
%token OP_SHIFT_LEFT
%token OP_ASSIGN_SHIFT_LEFT
%token OP_LE
%token OP_ASSIGN
%token OP_EQ
%token OP_GT
%token OP_GE
%token OP_SHIFT_RIGHT
%token OP_ASSIGN_SHIFT_RIGHT
%token OP_CONDITIONAL
%token OP_BIT_PLUS
%token OP_ASSIGN_BIT_PLUS
%token OP_BIT_OR
%token OP_ASSIGN_BIT_OR
%token OP_LOGICAL_OR
%token OP_BIT_NOT

%token OP_ALT_LOGICAL_AND
%token OP_ALT_ASSIGN_BIT_AND
%token OP_ALT_BIT_AND
%token OP_ALT_BIT_OR
%token OP_ALT_BIT_NOT
%token OP_ALT_LOGICAL_NOT
%token OP_ALT_NE
%token OP_ALT_LOGICAL_OR
%token OP_ALT_ASSIGN_BIT_OR
%token OP_ALT_BIT_PLUS
%token OP_ALT_ASSIGN_BIT_PLUS

%token INV_ALT_LOGICAL_AND
%token INV_ALT_ASSIGN_BIT_AND
%token INV_ALT_BIT_AND
%token INV_ALT_BIT_OR
%token INV_ALT_BIT_NOT
%token INV_ALT_LOGICAL_NOT
%token INV_ALT_NE
%token INV_ALT_LOGICAL_OR
%token INV_ALT_ASSIGN_BIT_OR
%token INV_ALT_BIT_PLUS
%token INV_ALT_ASSIGN_BIT_PLUS

%token INV_MFI_LOGICAL_AND
%token INV_MFI_ASSIGN_BIT_AND
%token INV_MFI_BIT_AND
%token INV_MFI_BIT_OR
%token INV_MFI_BIT_NOT
%token INV_MFI_LOGICAL_NOT
%token INV_MFI_NE
%token INV_MFI_LOGICAL_OR
%token INV_MFI_ASSIGN_BIT_OR
%token INV_MFI_BIT_PLUS
%token INV_MFI_ASSIGN_BIT_PLUS

%token DECL_REFERENCE
%token DECL_POINTER
%token DECL_VAR_ARGS

%token SYSTEM_HEADER_STRING
%token HEADER_STRING
%token IDENTIFIER
%token NON_REPLACEABLE_IDENTIFIER
%token MACRO_FUNCTION_IDENTIFIER
%token MACRO_OBJECT_IDENTIFIER
%token REPLACED_IDENTIFIER
%token PP_NUMBER
%token CHARACTER_LITERAL
%token L_CHARACTER_LITERAL
%token STRING_LITERAL
%token L_STRING_LITERAL
%token <lval> INTEGER_LITERAL
%token <lval> OCTAL_LITERAL
%token <lval> DECIMAL_LITERAL
%token <lval> HEXADECIMAL_LITERAL
%token FLOATING_LITERAL

%token <sval> UNIVERSAL_CHARACTER_NAME
%token <sval> USE_ON_CODE

%token PUNC_INITIALIZE
%token PUNC_SYNONYM
%token DONT_CARE

%token <sval> RESERVED_WORD
%token <sval> ACCESS_SPECIFIER
%token <ival> BOOLEAN_LITERAL
%token <sval> CV_QUALIFIER
%token <sval> INTRINSIC_TYPE
%token <sval> FUNCTION_SPECIFIER
%token <sval> STORAGE_CLASS_SPECIFIER


%token <sval> USER_TOKEN
%token <sval> SYMBOL
%token <sval> COMMENT
%token <sval> BLOCK_COMMENT
%token END_OF_STATEMENT
%token BLOCK_OPEN
%token BLOCK_CLOSE
%token LIST_OPEN
%token LIST_SEPARATOR
%token LIST_CLOSE

%type <lval> pp_constant_expression
%type <lval> pp_expression
%type <lval> pp_conditional_expression
%type <lval> pp_logical_or_expression
%type <lval> pp_logical_and_expression
%type <lval> pp_inclusive_or_expression
%type <lval> pp_exclusive_or_expression
%type <lval> pp_and_expression
%type <lval> pp_equality_expression
%type <lval> pp_relational_expression
%type <lval> pp_shift_expression
%type <lval> pp_additive_expression
%type <lval> pp_multiplicative_expression
%type <lval> pp_unary_expression
%type <lval> pp_primary_expression
%type <lval> pp_boolean_literal
%type <lval> pp_integer_literal
%type <lval> pp_octal_literal
%type <lval> pp_decimal_literal
%type <lval> pp_hexadecimal_literal

%%

preprocessing_file: { handle_file_begin(preprocessing_file_index); } group_part_seq_opt {handle_file_end(preprocessing_file_index); } 
  ;

group_part_seq_opt: /* empty */
  | group_part_seq
  ;

group_part_seq: group_part
  | group_part_seq group_part
  ;

group_part: { /* handle_token(group_part_index); */ } preprocessing_token_seq_opt new_line 
  | if_section
  | control_line
  ;

if_section: if_group elif_group_seq_opt else_group_opt endif_line 
  ;

if_open: PPD_IF pp_constant_expression { handle_if_open(PPD_IF_INDEX, $2); } 
  |  PPD_IF string_literal { handle_if_open(PPD_IF_INDEX, 0); }
  ;

ifdef_open: PPD_IFDEF 
  ;

ifndef_open: PPD_IFNDEF 
  ;

ifdef_identifier: IDENTIFIER { handle_ifdef_open(PPD_IFDEF_INDEX); } 
  ;

ifndef_identifier: IDENTIFIER { handle_ifndef_open(PPD_IFNDEF_INDEX); } 
  ;

if_group: if_open new_line group_part_seq_opt
  | ifdef_open ifdef_identifier new_line group_part_seq_opt
  | ifndef_open ifndef_identifier new_line group_part_seq_opt
  | ifdef_open invalid_ifdef_identifier new_line group_part_seq_opt
  | ifndef_open invalid_ifndef_identifier new_line group_part_seq_opt
  ;

elif_group_seq_opt: /* empty */
  | elif_group_seq
  ;

elif_group_seq: elif_group
  | elif_group_seq elif_group
  ;

elif_group_open: PPD_ELIF pp_constant_expression { handle_elif_open(PPD_ELIF_INDEX, $2); } 
  ;

elif_group: elif_group_open new_line group_part_seq_opt { handle_elif_close(PPD_ELIF_INDEX); }
  ;

else_group_opt: /* empty */
  | else_group
  ;

else_open: PPD_ELSE { handle_else_open(PPD_ELSE_INDEX); }
  ;

else_group: else_open new_line group_part_seq_opt
  ;

endif_open: PPD_ENDIF { handle_endif(PPD_ENDIF_INDEX); }
  ;

endif_line: endif_open new_line
  ;

control_line: PPD_INCLUDE preprocessing_token_seq new_line { handle_include(PPD_INCLUDE_INDEX); };
  | PPD_DEFINE mo_identifier replacement_list new_line { handle_macro_close (object_macro_index); }
  | PPD_DEFINE mf_identifier mf_args replacement_list new_line  { handle_macro_close (function_macro_index); }
  | PPD_UNDEF mu_identifier new_line
  | PPD_LINE { handle_token_open (PPD_LINE_INDEX); } preprocessing_token_seq new_line { handle_token_close (PPD_LINE_INDEX); }
  | PPD_ERROR { handle_token_open (PPD_ERROR_INDEX); } preprocessing_token_seq_opt new_line { handle_token_close (PPD_ERROR_INDEX); }
  | PPD_PRAGMA { handle_token_open (PPD_PRAGMA_INDEX); } preprocessing_token_seq_opt new_line { handle_token_close (PPD_PRAGMA_INDEX); }
  | PPD_NULL new_line
  ;

mf_args: BCS_PUNCT_OPEN_PARENTHESIS clean_identifier_list_opt BCS_PUNCT_CLOSE_PARENTHESIS
  ;

replacement_list: { handle_replacement_open (replacement_list_index); } preprocessing_token_seq_opt { handle_replacement_close (replacement_list_index); }
  ;

preprocessing_token_seq_opt: /* empty */
  | preprocessing_token_seq
  ;

preprocessing_token_seq: preprocessing_token
  | preprocessing_token_seq preprocessing_token
  ;

preprocessing_token: header_name
  | identifier
  | pp_number
  | character_literal
  | string_literal
  | preprocessing_op_or_punc
  | BCS_PUNCT_BACKSLASH { handle_token(BCS_PUNCT_BACKSLASH_INDEX); }
  ;

header_name: SYSTEM_HEADER_STRING { handle_header_name(SYSTEM_HEADER_STRING_INDEX); }
  | HEADER_STRING { handle_header_name(HEADER_STRING_INDEX); }
  ;

clean_identifier_list_opt: /* empty */
  | clean_identifier_list
  ;

clean_identifier_list: identifier
  | clean_identifier_list BCS_PUNCT_COMMA identifier
  ;

identifier: IDENTIFIER   { handle_identifier(IDENTIFIER_INDEX); }
  | NON_REPLACEABLE_IDENTIFIER { handle_nonrepl_identifier(IDENTIFIER_INDEX); }
  | REPLACED_IDENTIFIER { handle_identifier(REPLACED_IDENTIFIER_INDEX); }
  | key_word
  ;

pp_identifier: IDENTIFIER
  | NON_REPLACEABLE_IDENTIFIER
  ;

pp_replaced_identifier_seq_opt: /* empty */
  | pp_replaced_identifier_seq
  ;

pp_replaced_identifier_seq: pp_replaced_identifier
  | pp_replaced_identifier_seq pp_replaced_identifier
  ;

pp_replaced_identifier: REPLACED_IDENTIFIER
  ;

key_word: kwd_asm
  | kwd_auto
  | kwd_bool
  | kwd_break
  | kwd_case
  | kwd_catch
  | kwd_char
  | kwd_class
  | kwd_const
  | kwd_const_cast
  | kwd_continue
  | kwd_default
  | kwd_do
  | kwd_double
  | kwd_dynamic_cast
  | kwd_else
  | kwd_enum
  | kwd_explicit
  | kwd_export
  | kwd_extern
  | kwd_float
  | kwd_for
  | kwd_friend
  | kwd_goto
  | kwd_if
  | kwd_inline
  | kwd_int
  | kwd_long
  | kwd_mutable
  | kwd_namespace
  | kwd_operator
  | kwd_private
  | kwd_protected
  | kwd_public
  | kwd_register
  | kwd_reinterpret_cast
  | kwd_return
  | kwd_short
  | kwd_signed
  | kwd_static
  | kwd_static_cast
  | kwd_struct
  | kwd_switch
  | kwd_template
  | kwd_this
  | kwd_throw
  | kwd_try
  | kwd_typedef
  | kwd_typename
  | kwd_typeid
  | kwd_union
  | kwd_unsigned
  | kwd_using
  | kwd_virtual
  | kwd_void
  | kwd_volatile
  | kwd_wchar_t
  | kwd_while
  ;

pp_number: PP_NUMBER { handle_pp_number(); }
  | integer_literal
  | floating_literal
  ;

integer_literal: INTEGER_LITERAL { handle_string_token(INTEGER_LITERAL_INDEX); }
  | octal_literal
  | decimal_literal
  | hexadecimal_literal
  ;

octal_literal: OCTAL_LITERAL { handle_string_token(OCTAL_LITERAL_INDEX); }
  ;

decimal_literal: DECIMAL_LITERAL { handle_string_token(DECIMAL_LITERAL_INDEX); }
  ;

hexadecimal_literal: HEXADECIMAL_LITERAL { handle_string_token(HEXADECIMAL_LITERAL_INDEX); }
  ;

pp_integer_literal: INTEGER_LITERAL { $$ = $1; }
  | pp_octal_literal { $$ = $1; }
  | pp_decimal_literal { $$ = $1; }
  | pp_hexadecimal_literal { $$ = $1; }
  ;

pp_octal_literal: OCTAL_LITERAL { $$ = $1; }
  ;

pp_decimal_literal: DECIMAL_LITERAL { $$ = $1; }
  ;

pp_hexadecimal_literal: HEXADECIMAL_LITERAL { $$ = $1; }
  ;

character_literal: CHARACTER_LITERAL { handle_string_token(CHARACTER_LITERAL_INDEX); }
  | L_CHARACTER_LITERAL { handle_string_token(L_CHARACTER_LITERAL_INDEX); }
  ;

string_literal: STRING_LITERAL { handle_string_token(STRING_LITERAL_INDEX); }
  | L_STRING_LITERAL { handle_string_token(L_STRING_LITERAL_INDEX); }
  ;

floating_literal: FLOATING_LITERAL { handle_string_token(FLOATING_LITERAL_INDEX); }
  ;

pp_boolean_literal: KWD_FALSE { $$ = 0; }
  | KWD_TRUE { $$ = 1; }
  | BOOLEAN_LITERAL { $$ = $1; }
  ;

preprocessing_op_or_punc: bcs_exclamation
  | bcs_hash
  | op_stringize
  | bcs_percent
  | bcs_ampersand
  | bcs_open_parenthesis
  | bcs_close_parenthesis
  | bcs_asterisk
  | bcs_plus
  | bcs_comma
  | bcs_minus
  | bcs_period
  | bcs_slash
  | bcs_colon
  | bcs_semicolon
  | bcs_less_than
  | bcs_equal
  | bcs_greater_than
  | bcs_question
  | bcs_open_bracket
  | bcs_caret
  | bcs_close_bracket
  | bcs_open_brace
  | bcs_vertical_bar
  | bcs_close_brace
  | bcs_tilde
  | ne
  | token_splice
  | assign_modulo
  | truth_and
  | assign_bit_and
  | assign_multiply
  | increment
  | assign_plus
  | decrement
  | assign_minus
  | pointer_member
  | pointer_ptm
  | object_ptm
  | assign_divide
  | scope_ref
  | shift_left
  | assign_shift_left
  | le
  | eq
  | ge
  | shift_right
  | assign_shift_right
  | assign_bit_xor
  | assign_bit_or
  | truth_or
  | var_args
  | kwd_new
  | kwd_delete
  | alt_bit_and
  | alt_bit_or
  | alt_bit_not
  | alt_truth_not
  | alt_bit_xor
  | kwd_sizeof
  ;

pp_constant_expression: pp_expression {$$ = $1;}
  ;

pp_expression: pp_conditional_expression {$$ = $1;}
  | pp_expression pp_comma_op pp_conditional_expression {$$ = $3;}
  ;

pp_conditional_expression: pp_logical_or_expression {$$ = $1;}
  | pp_logical_or_expression pp_conditional_operator pp_expression pp_conditional_separator pp_conditional_expression {$$ = ($1) ? $3 : $5;}
  ;

pp_logical_or_expression: pp_logical_and_expression {$$ = $1;}
  | pp_logical_or_expression pp_truth_or pp_logical_and_expression {$$ = $1 || $3;}
  ;

pp_logical_and_expression: pp_inclusive_or_expression {$$ = $1;}
  | pp_logical_and_expression pp_truth_and pp_inclusive_or_expression {$$ = $1 && $3;}
  ;

pp_inclusive_or_expression: pp_exclusive_or_expression {$$ = $1;}
  | pp_inclusive_or_expression pp_bit_or pp_exclusive_or_expression  {$$ = $1 | $3;}
  ;

pp_exclusive_or_expression: pp_and_expression {$$ = $1;}
  | pp_exclusive_or_expression pp_bit_xor pp_and_expression {$$ = $1 ^ $3;}
  ;

pp_and_expression: pp_equality_expression {$$ = $1;}
  | pp_and_expression pp_bit_and pp_equality_expression {$$ = $1 & $3;}
  ;

pp_equality_expression: pp_relational_expression {$$ = $1;}
  | pp_equality_expression pp_eq pp_relational_expression {$$ = ($1 == $3);}
  | pp_equality_expression pp_ne pp_relational_expression {$$ = ($1 != $3);}
  ;

pp_relational_expression: pp_shift_expression {$$ = $1;}
  | pp_relational_expression pp_lt pp_shift_expression {$$ = ($1 < $3);}
  | pp_relational_expression pp_gt pp_shift_expression {$$ = ($1 > $3);}
  | pp_relational_expression pp_le pp_shift_expression {$$ = ($1 <= $3);}
  | pp_relational_expression pp_ge pp_shift_expression {$$ = ($1 >= $3);}
  ;

pp_shift_expression: pp_additive_expression {$$ = $1;}
  | pp_shift_expression pp_shift_left pp_additive_expression {$$ = ($1 << $3);}
  | pp_shift_expression pp_shift_right pp_additive_expression {$$ = ($1 >> $3);}
  ;

pp_additive_expression: pp_multiplicative_expression {$$ = $1;}
  | pp_additive_expression pp_plus pp_multiplicative_expression {$$ = ($1 + $3);}
  | pp_additive_expression pp_minus pp_multiplicative_expression {$$ = ($1 - $3);}
  ;

pp_multiplicative_expression: pp_unary_expression {$$ = $1;}
  | pp_multiplicative_expression pp_multiply pp_unary_expression {$$ = ($1 * $3);}
  | pp_multiplicative_expression pp_divide pp_unary_expression {$$ = ($1 / $3);}
  | pp_multiplicative_expression pp_modulo pp_unary_expression {$$ = ($1 % $3);}
  ;

pp_unary_expression: pp_replaced_identifier_seq_opt pp_primary_expression {$$ = $2;}
  | pp_unary_plus pp_unary_expression {$$ = $2;}
  | pp_unary_minus pp_unary_expression {$$ = -$2;}
  | pp_truth_not pp_unary_expression {$$ = !$2;}
  | pp_bit_not pp_unary_expression {$$ = ~$2;}
  ;

pp_primary_expression: pp_boolean_literal {$$ = $1;}
  | pp_integer_literal {$$ = $1;}
  | BCS_PUNCT_OPEN_PARENTHESIS pp_expression BCS_PUNCT_CLOSE_PARENTHESIS {$$ = $2;}
  | pp_identifier {$$ = 0;}
  ;

kwd_asm:               KWD_ASM              { handle_token(KWD_ASM_INDEX); }
  ;

kwd_auto:              KWD_AUTO             { handle_token(KWD_AUTO_INDEX); }
  ;

kwd_bool:              KWD_BOOL             { handle_token(KWD_BOOL_INDEX); }
  ;

kwd_break:             KWD_BREAK            { handle_token(KWD_BREAK_INDEX); }
  ;

kwd_case:              KWD_CASE             { handle_token(KWD_CASE_INDEX); }
  ;

kwd_catch:             KWD_CATCH            { handle_token(KWD_CATCH_INDEX); }
  ;

kwd_char:              KWD_CHAR             { handle_token(KWD_CHAR_INDEX); }
  ;

kwd_class:             KWD_CLASS            { handle_token(KWD_CLASS_INDEX); }
  ;

kwd_const:             KWD_CONST            { handle_token(KWD_CONST_INDEX); }
  ;

kwd_const_cast:        KWD_CONST_CAST       { handle_token(KWD_CONST_CAST_INDEX); }
  ;

kwd_continue:          KWD_CONTINUE         { handle_token(KWD_CONTINUE_INDEX); }
  ;

kwd_default:           KWD_DEFAULT          { handle_token(KWD_DEFAULT_INDEX); }
  ;

kwd_delete:            KWD_DELETE           { handle_token(KWD_DELETE_INDEX); }
  ;

kwd_do:                KWD_DO               { handle_token(KWD_DO_INDEX); }
  ;

kwd_double:            KWD_DOUBLE           { handle_token(KWD_DOUBLE_INDEX); }
  ;

kwd_dynamic_cast:      KWD_DYNAMIC_CAST     { handle_token(KWD_DYNAMIC_CAST_INDEX); }
  ;

kwd_else:              KWD_ELSE             { handle_token(KWD_ELSE_INDEX); }
  ;

kwd_enum:              KWD_ENUM             { handle_token(KWD_ENUM_INDEX); }
  ;

kwd_explicit:          KWD_EXPLICIT         { handle_token(KWD_EXPLICIT_INDEX); }
  ;

kwd_export:            KWD_EXPORT           { handle_token(KWD_EXPORT_INDEX); }
  ;

kwd_extern:            KWD_EXTERN           { handle_token(KWD_EXTERN_INDEX); }
  ;

kwd_float:             KWD_FLOAT            { handle_token(KWD_FLOAT_INDEX); }
  ;

kwd_for:               KWD_FOR              { handle_token(KWD_FOR_INDEX); }
  ;

kwd_friend:            KWD_FRIEND           { handle_token(KWD_FRIEND_INDEX); }
  ;

kwd_goto:              KWD_GOTO             { handle_token(KWD_GOTO_INDEX); }
  ;

kwd_if:                KWD_IF               { handle_token(KWD_IF_INDEX); }
  ;

kwd_inline:            KWD_INLINE           { handle_token(KWD_INLINE_INDEX); }
  ;

kwd_int:               KWD_INT              { handle_token(KWD_INT_INDEX); }
  ;

kwd_long:              KWD_LONG             { handle_token(KWD_LONG_INDEX); }
  ;

kwd_mutable:           KWD_MUTABLE          { handle_token(KWD_MUTABLE_INDEX); }
  ;

kwd_namespace:         KWD_NAMESPACE        { handle_token(KWD_NAMESPACE_INDEX); }
  ;

kwd_new:               KWD_NEW              { handle_token(KWD_NEW_INDEX); }
  ;

kwd_operator:          KWD_OPERATOR         { handle_token(KWD_OPERATOR_INDEX); }
  ;

kwd_private:           KWD_PRIVATE          { handle_token(KWD_PRIVATE_INDEX); }
  ;

kwd_protected:         KWD_PROTECTED        { handle_token(KWD_PROTECTED_INDEX); }
  ;

kwd_public:            KWD_PUBLIC           { handle_token(KWD_PUBLIC_INDEX); }
  ;

kwd_register:          KWD_REGISTER         { handle_token(KWD_REGISTER_INDEX); }
  ;

kwd_reinterpret_cast:  KWD_REINTERPRET_CAST { handle_token(KWD_REINTERPRET_CAST_INDEX); }
  ;

kwd_return:            KWD_RETURN           { handle_token(KWD_RETURN_INDEX); }
  ;

kwd_short:             KWD_SHORT            { handle_token(KWD_SHORT_INDEX); }
  ;

kwd_signed:            KWD_SIGNED           { handle_token(KWD_SIGNED_INDEX); }
  ;

kwd_sizeof:            KWD_SIZEOF           { handle_token(KWD_SIZEOF_INDEX); }
  ;

kwd_static:            KWD_STATIC           { handle_token(KWD_STATIC_INDEX); }
  ;

kwd_static_cast:       KWD_STATIC_CAST      { handle_token(KWD_STATIC_CAST_INDEX); }
  ;

kwd_struct:            KWD_STRUCT           { handle_token(KWD_STRUCT_INDEX); }
  ;

kwd_switch:            KWD_SWITCH           { handle_token(KWD_SWITCH_INDEX); }
  ;

kwd_template:          KWD_TEMPLATE         { handle_token(KWD_TEMPLATE_INDEX); }
  ;

kwd_this:              KWD_THIS             { handle_token(KWD_THIS_INDEX); }
  ;

kwd_throw:             KWD_THROW            { handle_token(KWD_THROW_INDEX); }
  ;

kwd_try:               KWD_TRY              { handle_token(KWD_TRY_INDEX); }
  ;

kwd_typedef:           KWD_TYPEDEF          { handle_token(KWD_TYPEDEF_INDEX); }
  ;

kwd_typename:          KWD_TYPENAME         { handle_token(KWD_TYPENAME_INDEX); }
  ;

kwd_typeid:            KWD_TYPEID           { handle_token(KWD_TYPEID_INDEX); }
  ;

kwd_union:             KWD_UNION            { handle_token(KWD_UNION_INDEX); }
  ;

kwd_unsigned:          KWD_UNSIGNED         { handle_token(KWD_UNSIGNED_INDEX); }
  ;

kwd_using:             KWD_USING            { handle_token(KWD_USING_INDEX); }
  ;

kwd_virtual:           KWD_VIRTUAL          { handle_token(KWD_VIRTUAL_INDEX); }
  ;

kwd_void:              KWD_VOID             { handle_token(KWD_VOID_INDEX); }
  ;

kwd_volatile:          KWD_VOLATILE         { handle_token(KWD_VOLATILE_INDEX); }
  ;

kwd_wchar_t:           KWD_WCHAR_T          { handle_token(KWD_WCHAR_T_INDEX); }
  ;

kwd_while:             KWD_WHILE            { handle_token(KWD_WHILE_INDEX); }
  ;

new_line: BCS_WHTSP_NEWLINE
  ;

bcs_hash: BCS_PUNCT_HASH { handle_token(BCS_PUNCT_HASH_INDEX); }
  | ALT_PUNCT_HASH { handle_token(ALT_PUNCT_HASH_INDEX); }
  ;

op_stringize: OP_STRINGIZE { handle_token(OP_STRINGIZE_INDEX); }
  ;

token_splice: OP_TOKEN_SPLICE { handle_token(OP_TOKEN_SPLICE_INDEX); }
  | ALT_OP_TOKEN_SPLICE { handle_token(ALT_OP_TOKEN_SPLICE_INDEX); }
  ;

mf_identifier: MACRO_FUNCTION_IDENTIFIER { handle_macro_open(function_macro_index /*MACRO_FUNCTION_IDENTIFIER_INDEX*/); }
  | INV_MFI_LOGICAL_AND  { handle_invalid_macro_id(OP_ALT_LOGICAL_AND_INDEX); }
  | INV_MFI_ASSIGN_BIT_AND  { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_AND_INDEX); }
  | INV_MFI_BIT_AND  { handle_invalid_macro_id(OP_ALT_BIT_AND_INDEX); }
  | INV_MFI_BIT_OR  { handle_invalid_macro_id(OP_ALT_BIT_OR_INDEX); }
  | INV_MFI_BIT_NOT  { handle_invalid_macro_id(OP_ALT_BIT_NOT_INDEX); }
  | INV_MFI_LOGICAL_NOT  { handle_invalid_macro_id(OP_ALT_LOGICAL_NOT_INDEX); }
  | INV_MFI_NE  { handle_invalid_macro_id(OP_ALT_NE_INDEX); }
  | INV_MFI_LOGICAL_OR  { handle_invalid_macro_id(OP_ALT_LOGICAL_OR_INDEX); }
  | INV_MFI_ASSIGN_BIT_OR  { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_OR_INDEX); }
  | INV_MFI_BIT_PLUS  { handle_invalid_macro_id(OP_ALT_BIT_PLUS_INDEX); }
  | INV_MFI_ASSIGN_BIT_PLUS  { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_PLUS_INDEX); }
  ;

mo_identifier: MACRO_OBJECT_IDENTIFIER { handle_macro_open(object_macro_index/*MACRO_OBJECT_IDENTIFIER_INDEX*/); }
  | invalid_macro_identifier
  ;

mu_identifier: IDENTIFIER { handle_macro_undef(PPD_UNDEF_INDEX); }
  | invalid_macro_identifier { pop(); }
  ;

invalid_ifdef_identifier: invalid_macro_identifier
  ;

invalid_ifndef_identifier: invalid_macro_identifier
  ;

invalid_macro_identifier: INV_ALT_LOGICAL_AND  { handle_invalid_macro_id(OP_ALT_LOGICAL_AND_INDEX); }
  | INV_ALT_ASSIGN_BIT_AND  { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_AND_INDEX); }
  | INV_ALT_BIT_AND  { handle_invalid_macro_id(OP_ALT_BIT_AND_INDEX); }
  | INV_ALT_BIT_OR  { handle_invalid_macro_id(OP_ALT_BIT_OR_INDEX); }
  | INV_ALT_BIT_NOT  { handle_invalid_macro_id(OP_ALT_BIT_NOT_INDEX); }
  | INV_ALT_LOGICAL_NOT  { handle_invalid_macro_id(OP_ALT_LOGICAL_NOT_INDEX); }
  | INV_ALT_NE  { handle_invalid_macro_id(OP_ALT_NE_INDEX); }
  | INV_ALT_LOGICAL_OR  { handle_invalid_macro_id(OP_ALT_LOGICAL_OR_INDEX); }
  | INV_ALT_ASSIGN_BIT_OR  { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_OR_INDEX); }
  | INV_ALT_BIT_PLUS  { handle_invalid_macro_id(OP_ALT_BIT_PLUS_INDEX); }
  | INV_ALT_ASSIGN_BIT_PLUS  { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_PLUS_INDEX); }
  ;

bcs_exclamation: BCS_PUNCT_EXCLAMATION { handle_token(OP_LOGICAL_NOT_INDEX); }
  ;

alt_truth_not: OP_ALT_LOGICAL_NOT { handle_token(OP_ALT_LOGICAL_NOT_INDEX); }
  ;

pp_truth_not: BCS_PUNCT_EXCLAMATION
  | OP_ALT_LOGICAL_NOT
  ;

ne: OP_NE { handle_token(OP_NE_INDEX); }
  | OP_ALT_NE { handle_token(OP_ALT_NE_INDEX); }
  ;

pp_ne: OP_NE
  | OP_ALT_NE
  ;

bcs_percent: modulo
  ;

modulo: BCS_PUNCT_PERCENT { handle_token(OP_MODULO_INDEX); }
  ;

pp_modulo: BCS_PUNCT_PERCENT
  ;

assign_modulo: OP_ASSIGN_MODULO  { handle_token(OP_ASSIGN_MODULO_INDEX); }
  ;

bcs_ampersand: BCS_PUNCT_AMPERSAND { handle_token(BCS_PUNCT_AMPERSAND_INDEX); }
  ;

alt_bit_and:  OP_ALT_BIT_AND { handle_token(OP_ALT_BIT_AND_INDEX); }
  ;

pp_bit_and: BCS_PUNCT_AMPERSAND
  |  OP_ALT_BIT_AND
  ;

truth_and: OP_LOGICAL_AND { handle_token(OP_LOGICAL_AND_INDEX); }
  |  OP_ALT_LOGICAL_AND { handle_token(OP_ALT_LOGICAL_AND_INDEX); }
  ;

pp_truth_and: OP_LOGICAL_AND
  |  OP_ALT_LOGICAL_AND
  ;

assign_bit_and: OP_ASSIGN_BIT_AND { handle_token(OP_ASSIGN_BIT_AND_INDEX); }
  |  OP_ALT_ASSIGN_BIT_AND { handle_token(OP_ALT_ASSIGN_BIT_AND_INDEX); }
  ;

bcs_open_parenthesis: BCS_PUNCT_OPEN_PARENTHESIS { handle_token_open(BCS_PUNCT_OPEN_PARENTHESIS_INDEX); }
  ;

bcs_close_parenthesis: BCS_PUNCT_CLOSE_PARENTHESIS { handle_token_close(BCS_PUNCT_CLOSE_PARENTHESIS_INDEX); }
  ;

bcs_asterisk: BCS_PUNCT_ASTERISK { handle_token(BCS_PUNCT_ASTERISK_INDEX); }
  ;

pp_multiply: BCS_PUNCT_ASTERISK
  ;

assign_multiply: OP_ASSIGN_MULTIPLY  { handle_token(OP_ASSIGN_MULTIPLY_INDEX); }
  ;

bcs_plus: BCS_PUNCT_PLUS { handle_token(BCS_PUNCT_PLUS_INDEX); }
  ;

pp_plus: BCS_PUNCT_PLUS
  ;

pp_unary_plus: BCS_PUNCT_PLUS
  ;

increment: OP_INCREMENT { handle_token(OP_INCREMENT_INDEX); }
  ;

assign_plus: OP_ASSIGN_PLUS { handle_token(OP_ASSIGN_PLUS_INDEX); }
  ;

bcs_comma: BCS_PUNCT_COMMA { handle_token(BCS_PUNCT_COMMA_INDEX); }
  ;

pp_comma_op: BCS_PUNCT_COMMA
  ;

bcs_minus: BCS_PUNCT_MINUS { handle_token(BCS_PUNCT_MINUS_INDEX); }
  ;

pp_minus: BCS_PUNCT_MINUS
  ;

pp_unary_minus: BCS_PUNCT_MINUS
  ;

decrement: OP_DECREMENT { handle_token(OP_DECREMENT_INDEX); }
  ;

assign_minus: OP_ASSIGN_MINUS { handle_token(OP_ASSIGN_MINUS_INDEX); }
  ;

pointer_member: OP_POINTER_MEMBER { handle_token(OP_POINTER_MEMBER_INDEX); }
  ;

pointer_ptm: OP_POINTER_POINTER_TO_MEMBER { handle_token(OP_POINTER_POINTER_TO_MEMBER_INDEX); }
  ;

bcs_period: BCS_PUNCT_PERIOD { handle_token(BCS_PUNCT_PERIOD_INDEX); }
  ;

var_args: DECL_VAR_ARGS { handle_token(DECL_VAR_ARGS_INDEX); }
  ;

object_ptm: OP_OBJECT_POINTER_TO_MEMBER  { handle_token(OP_OBJECT_POINTER_TO_MEMBER_INDEX); }
  ;

bcs_slash: divide
  ;

divide: BCS_PUNCT_SLASH { handle_token(OP_DIVIDE_INDEX); }
  ;

pp_divide: BCS_PUNCT_SLASH
  ;

assign_divide: OP_ASSIGN_DIVIDE { handle_token(OP_ASSIGN_DIVIDE_INDEX); }
  ;

bcs_colon: BCS_PUNCT_COLON { handle_token(BCS_PUNCT_COLON_INDEX); }
  ;

pp_conditional_separator: BCS_PUNCT_COLON
  ;

scope_ref: OP_SCOPE_REF                 { handle_token(OP_SCOPE_REF_INDEX); }
  ;

bcs_semicolon: BCS_PUNCT_SEMICOLON { handle_token(BCS_PUNCT_SEMICOLON_INDEX); }
  ;

bcs_less_than: BCS_PUNCT_LESS_THAN { handle_token(BCS_PUNCT_LESS_THAN_INDEX); }
  ;

pp_lt: BCS_PUNCT_LESS_THAN
  ;

shift_left: OP_SHIFT_LEFT  { handle_token(OP_SHIFT_LEFT_INDEX); }
  ;

pp_shift_left: OP_SHIFT_LEFT
  ;

assign_shift_left: OP_ASSIGN_SHIFT_LEFT  { handle_token(OP_ASSIGN_SHIFT_LEFT_INDEX); }
  ;

le: OP_LE { handle_token(OP_LE_INDEX); }
  ;

pp_le: OP_LE
  ;

bcs_equal: BCS_PUNCT_EQUAL { handle_token(BCS_PUNCT_EQUAL_INDEX); }
  ;

eq: OP_EQ { handle_token(OP_EQ_INDEX); }
  ;

pp_eq: OP_EQ
  ;

bcs_greater_than: BCS_PUNCT_GREATER_THAN { handle_token(BCS_PUNCT_GREATER_THAN_INDEX); }
  ;

pp_gt: BCS_PUNCT_GREATER_THAN
  ;

ge: OP_GE { handle_token(OP_GE_INDEX); }
  ;

pp_ge: OP_GE
  ;

shift_right: OP_SHIFT_RIGHT { handle_token(OP_SHIFT_RIGHT_INDEX); }
  ;

pp_shift_right: OP_SHIFT_RIGHT { handle_token(OP_SHIFT_RIGHT_INDEX); }
  ;

assign_shift_right: OP_ASSIGN_SHIFT_RIGHT { handle_token(OP_ASSIGN_SHIFT_RIGHT_INDEX); }
  ;

bcs_question: conditional_operator           

conditional_operator: OP_CONDITIONAL  { handle_token(OP_CONDITIONAL_INDEX); }
  ;

pp_conditional_operator: OP_CONDITIONAL
  ;

bcs_open_bracket: BCS_PUNCT_OPEN_BRACKET { handle_token_open(BCS_PUNCT_OPEN_BRACKET_INDEX); }
  | ALT_PUNCT_OPEN_BRACKET { handle_token_open(ALT_PUNCT_OPEN_BRACKET_INDEX); }
  ;

bcs_close_bracket: BCS_PUNCT_CLOSE_BRACKET { handle_token_close(BCS_PUNCT_CLOSE_BRACKET_INDEX); }
  | ALT_PUNCT_CLOSE_BRACKET { handle_token_close(ALT_PUNCT_CLOSE_BRACKET_INDEX); }
  ;

bcs_caret: BCS_PUNCT_CARET  { handle_token(OP_BIT_PLUS_INDEX); }
  ;

alt_bit_xor: OP_ALT_BIT_PLUS  { handle_token(OP_ALT_BIT_PLUS_INDEX); }
  ;

pp_bit_xor: BCS_PUNCT_CARET
  | OP_ALT_BIT_PLUS
  ;

assign_bit_xor: OP_ASSIGN_BIT_PLUS  { handle_token(OP_ASSIGN_BIT_PLUS_INDEX); }
  |  OP_ALT_ASSIGN_BIT_PLUS  { handle_token(OP_ALT_ASSIGN_BIT_PLUS_INDEX); }
  ;

bcs_open_brace: BCS_PUNCT_OPEN_BRACE { handle_token_open(BCS_PUNCT_OPEN_BRACE_INDEX); }
  | ALT_PUNCT_OPEN_BRACE { handle_token_open(ALT_PUNCT_OPEN_BRACE_INDEX); }
  ;

bcs_close_brace: BCS_PUNCT_CLOSE_BRACE { handle_token_close(BCS_PUNCT_CLOSE_BRACE_INDEX); }
  | ALT_PUNCT_CLOSE_BRACE { handle_token_close(ALT_PUNCT_CLOSE_BRACE_INDEX); }
  ;

bcs_vertical_bar: BCS_PUNCT_VERTICAL_BAR { handle_token(OP_BIT_OR_INDEX); }
  ;

alt_bit_or: OP_ALT_BIT_OR { handle_token(OP_BIT_OR_INDEX); }
  ;

pp_bit_or: BCS_PUNCT_VERTICAL_BAR
  | OP_ALT_BIT_OR
  ;

assign_bit_or: OP_ASSIGN_BIT_OR { handle_token(OP_ASSIGN_BIT_OR_INDEX); }
  |  OP_ALT_ASSIGN_BIT_OR { handle_token(OP_ALT_ASSIGN_BIT_OR_INDEX); }
  ;

truth_or: OP_LOGICAL_OR { handle_token(OP_LOGICAL_OR_INDEX); }
  |  OP_ALT_LOGICAL_OR { handle_token(OP_ALT_LOGICAL_OR_INDEX); }
  ;

pp_truth_or: OP_LOGICAL_OR
  |  OP_ALT_LOGICAL_OR
  ;

bcs_tilde: BCS_PUNCT_TILDE { handle_token(OP_BIT_NOT_INDEX); }
  ;

alt_bit_not: OP_ALT_BIT_NOT { handle_token(OP_ALT_BIT_NOT_INDEX); }
  ;

pp_bit_not: BCS_PUNCT_TILDE
  | OP_ALT_BIT_NOT
  ;

%%

/*
 *
 */
const char *get_yytname(int token) {
  return yytname[yytranslate[token]];
}

/*
 *
 */
void yyerror(char const *s) {
  extern int error_count;
  extern int yychar;
  fprintf(stderr, "%s\n", s);
    if (yychar > 126) {
      fprintf(stderr, "File %s; line %d: yychar = %s(%d)\n",getCurrentFilename(), getCurrentLineNumber(), get_yytname(yychar), yychar);
    } else {
      fprintf(stderr, "File %s; line %d: yychar = %c\n",getCurrentFilename(),getCurrentLineNumber(), yychar);
    }
  error_count++;
}

