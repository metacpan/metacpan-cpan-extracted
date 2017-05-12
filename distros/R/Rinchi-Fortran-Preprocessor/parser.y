%{
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

%token PUNC_DBL_COLON
%token PUNC_ARROW

%token KWD_ABSTRACT
%token KWD_ABSTRACT_INTERFACE
%token KWD_ACCESS
%token KWD_ACTION
%token KWD_ADVANCE
%token KWD_ALLOCATABLE
%token KWD_ALLOCATE
%token KWD_ASSIGN
%token KWD_ASSOCIATE
%token KWD_ASYNCHRONOUS
%token KWD_BACKSPACE
%token KWD_BIND
%token KWD_BLANK
%token KWD_BLOCK
%token KWD_BLOCK_DATA
%token KWD_CALL
%token KWD_CASE
%token KWD_CHARACTER
%token KWD_CLASS
%token KWD_CLASS_DEFAULT
%token KWD_CLASS_IS
%token KWD_CLOSE
%token KWD_COMMON
%token KWD_COMPLEX
%token KWD_CONTAINS
%token KWD_CONTIGUOUS
%token KWD_CONTINUE
%token KWD_CYCLE
%token KWD_DATA
%token KWD_DEALLOCATE
%token KWD_DEFAULT
%token KWD_DEFERRED
%token KWD_DIMENSION
%token KWD_DIRECT
%token KWD_DO
%token KWD_DOUBLE
%token KWD_DOUBLE_COMPLEX
%token KWD_DOUBLE_PRECISION
%token KWD_ELEMENTAL
%token KWD_ELSE
%token KWD_ELSE_IF
%token KWD_ELSE_WHERE
%token KWD_ENCODING
%token KWD_END
%token KWD_END_ASSOCIATE
%token KWD_END_BLOCK
%token KWD_END_BLOCK_DATA
%token KWD_END_DO
%token KWD_END_ENUM
%token KWD_END_FILE
%token KWD_END_FORALL
%token KWD_END_FUNCTION
%token KWD_END_IF
%token KWD_END_INTERFACE
%token KWD_END_MODULE
%token KWD_END_PROCEDURE
%token KWD_END_PROGRAM
%token KWD_END_SELECT
%token KWD_END_SUBMODULE
%token KWD_END_SUBROUTINE
%token KWD_END_TYPE
%token KWD_END_WHERE
%token KWD_ENTRY
%token KWD_EOR
%token KWD_EQUIVALENCE
%token KWD_ERR
%token KWD_ERRMSG
%token KWD_EXIST
%token KWD_EXIT
%token KWD_EXTENDS
%token KWD_EXTENSIBLE
%token KWD_EXTERNAL
%token KWD_FALSE
%token KWD_FILE
%token KWD_FINAL
%token KWD_FLUSH
%token KWD_FMT
%token KWD_FORALL
%token KWD_FORM
%token KWD_FORMAT
%token KWD_FORMATTED
%token KWD_FUNCTION
%token KWD_GENERIC
%token KWD_GOTO
%token KWD_IF
%token KWD_IMPLICIT
%token KWD_IMPLICIT_NONE
%token KWD_IMPORT
%token KWD_IMPURE
%token KWD_IN
%token KWD_IN_OUT
%token KWD_INCLUDE
%token KWD_INQUIRE
%token KWD_INTEGER
%token KWD_INTENT
%token KWD_INTERFACE
%token KWD_INTRINSIC
%token KWD_IOSTAT
%token KWD_IOMSG
%token KWD_KIND
%token KWD_LET
%token KWD_LOGICAL
%token KWD_MODULE
%token KWD_MOLD
%token KWD_NAME
%token KWD_NAMED
%token KWD_NAMELIST
%token KWD_NEXTREC
%token KWD_NON_INTRINSIC
%token KWD_NON_OVERRIDABLE
%token KWD_NONKIND
%token KWD_NONE
%token KWD_NOPASS
%token KWD_NULLIFY
%token KWD_NUMBER
%token KWD_OPEN
%token KWD_OPENED
%token KWD_OPERATOR
%token KWD_OPTIONAL
%token KWD_OUT
%token KWD_PAD
%token KWD_PARAMETER
%token KWD_PASS
%token KWD_PAUSE
%token KWD_PENDING
%token KWD_POINTER
%token KWD_POSITION
%token KWD_PRECISION
%token KWD_PRINT
%token KWD_PRIVATE
%token KWD_PROCEDURE
%token KWD_PROGRAM
%token KWD_PROTECTED
%token KWD_PUBLIC
%token KWD_PURE
%token KWD_READ
%token KWD_READ_FORMATTED
%token KWD_READ_UNFORMATTED
%token KWD_READWRITE
%token KWD_REAL
%token KWD_REC
%token KWD_RECL
%token KWD_RETURN
%token KWD_REWIND
%token KWD_ROUND
%token KWD_SAVE
%token KWD_SELECT_CASE
%token KWD_SELECT_TYPE
%token KWD_SEQUENCE
%token KWD_SEQUENTIAL
%token KWD_SIGN
%token KWD_SIZE
%token KWD_SOURCE
%token KWD_STATUS
%token KWD_STOP
%token KWD_STREAM
%token KWD_SUBMODULE
%token KWD_SUBROUTINE
%token KWD_TARGET
%token KWD_THEN
%token KWD_TRUE
%token KWD_TYPE
%token KWD_UNFORMATTED
%token KWD_UNIT
%token KWD_USE
%token KWD_VALUE
%token KWD_VOLATILE
%token KWD_WHERE
%token KWD_WRITE
%token KWD_WRITE_FORMATTED
%token KWD_WRITE_UNFORMATTED

%token PPD_NULL
%token PPD_DEFINE
%token PPD_ELIF
%token PPD_ELSE
%token PPD_ENDIF
%token PPD_ERROR
%token PPD_WARNING
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

%token OPEN_PARENTHESIS_SLASH
%token CLOSE_PARENTHESIS_SLASH

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

%token WHITE_SPACE
%token SYSTEM_HEADER_STRING
%token HEADER_STRING
%token IDENTIFIER
%token NON_REPLACEABLE_IDENTIFIER
%token MACRO_FUNCTION_IDENTIFIER
%token MACRO_OBJECT_IDENTIFIER
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
  | PPD_DEFINE mo_identifier string_literal_opt new_line { handle_macro_close (object_macro_index); }
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

preprocessing_token: white_space
  | header_name
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
  | key_word
  ;

pp_identifier: IDENTIFIER
  | NON_REPLACEABLE_IDENTIFIER

key_word: kwd_abstract
  | kwd_abstract_interface
  | kwd_access
  | kwd_action
  | kwd_advance
  | kwd_allocatable
  | kwd_allocate
  | kwd_assign
  | kwd_asynchronous
  | kwd_backspace
  | kwd_bind
  | kwd_blank
  | kwd_block
  | kwd_block_data
  | kwd_call
  | kwd_case
  | kwd_character
  | kwd_class
  | kwd_class_default
  | kwd_class_is
  | kwd_close
  | kwd_common
  | kwd_complex
  | kwd_contains
  | kwd_contiguous
  | kwd_continue
  | kwd_cycle
  | kwd_data
  | kwd_deallocate
  | kwd_default
  | kwd_deferred
  | kwd_dimension
  | kwd_direct
  | kwd_do
  | kwd_double
  | kwd_double_complex
  | kwd_double_precision
  | kwd_elemental
  | kwd_else
  | kwd_else_if
  | kwd_else_where
  | kwd_end
  | kwd_end_associate
  | kwd_end_block
  | kwd_end_block_data
  | kwd_end_do
  | kwd_end_enum
  | kwd_end_file
  | kwd_end_forall
  | kwd_end_function
  | kwd_end_if
  | kwd_end_interface
  | kwd_end_module
  | kwd_end_procedure
  | kwd_end_program
  | kwd_end_select
  | kwd_end_submodule
  | kwd_end_subroutine
  | kwd_end_type
  | kwd_end_where
  | kwd_entry
  | kwd_eor
  | kwd_equivalence
  | kwd_err
  | kwd_errmsg
  | kwd_exist
  | kwd_exit
  | kwd_extends
  | kwd_extensible
  | kwd_external
  | kwd_false
  | kwd_file
  | kwd_final
  | kwd_flush
  | kwd_fmt
  | kwd_forall
  | kwd_form
  | kwd_format
  | kwd_formatted
  | kwd_function
  | kwd_generic
  | kwd_goto
  | kwd_if
  | kwd_implicit
  | kwd_implicit_none
  | kwd_import
  | kwd_impure
  | kwd_in
  | kwd_include
  | kwd_inquire
  | kwd_integer
  | kwd_intrinsic
  | kwd_in_out
  | kwd_intent
  | kwd_interface
  | kwd_iostat
  | kwd_iomsg
  | kwd_kind
  | kwd_let
  | kwd_logical
  | kwd_module
  | kwd_mold
  | kwd_name
  | kwd_named
  | kwd_namelist
  | kwd_nextrec
  | kwd_non_intrinsic
  | kwd_non_overridable
  | kwd_nonkind
  | kwd_none
  | kwd_nopass
  | kwd_nullify
  | kwd_number
  | kwd_open
  | kwd_opened
  | kwd_operator
  | kwd_optional
  | kwd_out
  | kwd_pad
  | kwd_parameter
  | kwd_pass
  | kwd_pause
  | kwd_pointer
  | kwd_position
  | kwd_precision
  | kwd_print
  | kwd_private
  | kwd_procedure
  | kwd_program
  | kwd_protected
  | kwd_public
  | kwd_pure
  | kwd_read
  | kwd_read_formatted
  | kwd_read_unformatted
  | kwd_real
  | kwd_rec
  | kwd_recl
  | kwd_return
  | kwd_rewind
  | kwd_round
  | kwd_save
  | kwd_select_case
  | kwd_select_type
  | kwd_sequence
  | kwd_sequential
  | kwd_sign
  | kwd_size
  | kwd_status
  | kwd_stop
  | kwd_source
  | kwd_subroutine
  | kwd_target
  | kwd_then
  | kwd_true
  | kwd_type
  | kwd_unformatted
  | kwd_unit
  | kwd_use
  | kwd_value
  | kwd_volatile
  | kwd_where
  | kwd_write
  | kwd_write_formatted
  | kwd_write_unformatted
  ;

white_space_opt: /* empty */
  | white_space
  ;

white_space: WHITE_SPACE { handle_string_token(WHITE_SPACE_INDEX); }
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

string_literal_opt: /* empty */
  | string_literal
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
  | open_parenthesis_slash
  | close_parenthesis_slash
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
  | dbl_colon
  | arrow
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
  | alt_bit_and
  | alt_bit_or
  | alt_bit_not
  | alt_truth_not
  | alt_bit_xor
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

pp_unary_expression: pp_primary_expression {$$ = $1;}
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

kwd_abstract:          KWD_ABSTRACT         { handle_token(KWD_ABSTRACT_INDEX); }
  ;

kwd_abstract_interface:KWD_ABSTRACT_INTERFACE { handle_token(KWD_ABSTRACT_INTERFACE_INDEX); }
  ;

kwd_access:            KWD_ACCESS           { handle_token(KWD_ACCESS_INDEX); }
  ;

kwd_action:            KWD_ACTION           { handle_token(KWD_ACTION_INDEX); }
  ;

kwd_advance:           KWD_ADVANCE          { handle_token(KWD_ADVANCE_INDEX); }
  ;

kwd_allocatable:       KWD_ALLOCATABLE      { handle_token(KWD_ALLOCATABLE_INDEX); }
  ;

kwd_allocate:          KWD_ALLOCATE         { handle_token(KWD_ALLOCATE_INDEX); }
  ;

kwd_assign:            KWD_ASSIGN           { handle_token(KWD_ASSIGN_INDEX); }
  ;

kwd_asynchronous:      KWD_ASYNCHRONOUS     { handle_token(KWD_ASYNCHRONOUS_INDEX); }
  ;

kwd_backspace:         KWD_BACKSPACE        { handle_token(KWD_BACKSPACE_INDEX); }
  ;

kwd_bind:              KWD_BIND             { handle_token(KWD_BIND_INDEX); }
  ;

kwd_blank:             KWD_BLANK            { handle_token(KWD_BLANK_INDEX); }
  ;

kwd_block:             KWD_BLOCK            { handle_token(KWD_BLOCK_INDEX); }
  ;

kwd_block_data:        KWD_BLOCK_DATA       { handle_token(KWD_BLOCK_DATA_INDEX); }
  ;

kwd_call:              KWD_CALL             { handle_token(KWD_CALL_INDEX); }
  ;

kwd_case:              KWD_CASE             { handle_token(KWD_CASE_INDEX); }
  ;

kwd_character:         KWD_CHARACTER        { handle_token(KWD_CHARACTER_INDEX); }
  ;

kwd_class:             KWD_CLASS            { handle_token(KWD_CLASS_INDEX); }
  ;

kwd_class_default:     KWD_CLASS_DEFAULT    { handle_token(KWD_CLASS_DEFAULT_INDEX); }
  ;

kwd_class_is:          KWD_CLASS_IS         { handle_token(KWD_CLASS_IS_INDEX); }
  ;

kwd_close:             KWD_CLOSE            { handle_token(KWD_CLOSE_INDEX); }
  ;

kwd_common:            KWD_COMMON           { handle_token(KWD_COMMON_INDEX); }
  ;

kwd_complex:           KWD_COMPLEX          { handle_token(KWD_COMPLEX_INDEX); }
  ;

kwd_contains:          KWD_CONTAINS         { handle_token(KWD_CONTAINS_INDEX); }
  ;

kwd_contiguous:        KWD_CONTIGUOUS       { handle_token(KWD_CONTIGUOUS_INDEX); }
  ;

kwd_continue:          KWD_CONTINUE         { handle_token(KWD_CONTINUE_INDEX); }
  ;

kwd_cycle:             KWD_CYCLE            { handle_token(KWD_CYCLE_INDEX); }
  ;

kwd_data:              KWD_DATA             { handle_token(KWD_DATA_INDEX); }
  ;

kwd_deallocate:        KWD_DEALLOCATE       { handle_token(KWD_DEALLOCATE_INDEX); }
  ;

kwd_default:           KWD_DEFAULT          { handle_token(KWD_DEFAULT_INDEX); }
  ;

kwd_deferred:          KWD_DEFERRED         { handle_token(KWD_DEFERRED_INDEX); }
  ;

kwd_dimension:         KWD_DIMENSION        { handle_token(KWD_DIMENSION_INDEX); }
  ;

kwd_direct:            KWD_DIRECT           { handle_token(KWD_DIRECT_INDEX); }
  ;

kwd_do:                KWD_DO               { handle_token(KWD_DO_INDEX); }
  ;

kwd_double:            KWD_DOUBLE           { handle_token(KWD_DOUBLE_INDEX); }
  ;

kwd_double_complex:    KWD_DOUBLE_COMPLEX   { handle_token(KWD_DOUBLE_COMPLEX_INDEX); }
  ;

kwd_double_precision:  KWD_DOUBLE_PRECISION { handle_token(KWD_DOUBLE_PRECISION_INDEX); }
  ;

kwd_elemental:         KWD_ELEMENTAL        { handle_token(KWD_ELEMENTAL_INDEX); }
  ;

kwd_else:              KWD_ELSE             { handle_token(KWD_ELSE_INDEX); }
  ;

kwd_else_if:           KWD_ELSE_IF          { handle_token(KWD_ELSE_IF_INDEX); }
  ;

kwd_else_where:        KWD_ELSE_WHERE       { handle_token(KWD_ELSE_WHERE_INDEX); }
  ;

kwd_end:               KWD_END              { handle_token(KWD_END_INDEX); }
  ;

kwd_end_associate:     KWD_END_ASSOCIATE    { handle_token(KWD_END_ASSOCIATE_INDEX); }
  ;

kwd_end_block:         KWD_END_BLOCK        { handle_token(KWD_END_BLOCK_INDEX); }
  ;

kwd_end_block_data:    KWD_END_BLOCK_DATA   { handle_token(KWD_END_BLOCK_DATA_INDEX); }
  ;

kwd_end_do:            KWD_END_DO           { handle_token(KWD_END_DO_INDEX); }
  ;

kwd_end_enum:          KWD_END_ENUM         { handle_token(KWD_END_ENUM_INDEX); }
  ;

kwd_end_file:          KWD_END_FILE         { handle_token(KWD_END_FILE_INDEX); }
  ;

kwd_end_forall:        KWD_END_FORALL       { handle_token(KWD_END_FORALL_INDEX); }
  ;

kwd_end_function:      KWD_END_FUNCTION     { handle_token(KWD_END_FUNCTION_INDEX); }
  ;

kwd_end_if:            KWD_END_IF           { handle_token(KWD_END_IF_INDEX); }
  ;

kwd_end_interface:     KWD_END_INTERFACE    { handle_token(KWD_END_INTERFACE_INDEX); }
  ;

kwd_end_module:        KWD_END_MODULE       { handle_token(KWD_END_MODULE_INDEX); }
  ;

kwd_end_procedure:     KWD_END_PROCEDURE    { handle_token(KWD_END_PROCEDURE_INDEX); }
  ;

kwd_end_program:       KWD_END_PROGRAM      { handle_token(KWD_END_PROGRAM_INDEX); }
  ;

kwd_end_select:        KWD_END_SELECT       { handle_token(KWD_END_SELECT_INDEX); }
  ;

kwd_end_submodule:     KWD_END_SUBMODULE    { handle_token(KWD_END_SUBMODULE_INDEX); }
  ;

kwd_end_subroutine:    KWD_END_SUBROUTINE   { handle_token(KWD_END_SUBROUTINE_INDEX); }
  ;

kwd_end_type:          KWD_END_TYPE         { handle_token(KWD_END_TYPE_INDEX); }
  ;

kwd_end_where:         KWD_END_WHERE        { handle_token(KWD_END_WHERE_INDEX); }
  ;

kwd_entry:             KWD_ENTRY            { handle_token(KWD_ENTRY_INDEX); }
  ;

kwd_eor:               KWD_EOR              { handle_token(KWD_EOR_INDEX); }
  ;

kwd_equivalence:       KWD_EQUIVALENCE      { handle_token(KWD_EQUIVALENCE_INDEX); }
  ;

kwd_err:               KWD_ERR              { handle_token(KWD_ERR_INDEX); }
  ;

kwd_errmsg:            KWD_ERRMSG           { handle_token(KWD_ERRMSG_INDEX); }
  ;

kwd_exist:             KWD_EXIST            { handle_token(KWD_EXIST_INDEX); }
  ;

kwd_exit:              KWD_EXIT             { handle_token(KWD_EXIT_INDEX); }
  ;

kwd_extends:           KWD_EXTENDS          { handle_token(KWD_EXTENDS_INDEX); }
  ;

kwd_extensible:        KWD_EXTENSIBLE       { handle_token(KWD_EXTENSIBLE_INDEX); }
  ;

kwd_external:          KWD_EXTERNAL         { handle_token(KWD_EXTERNAL_INDEX); }
  ;

kwd_false:             KWD_FALSE            { handle_token(KWD_FALSE_INDEX); }
  ;

kwd_file:              KWD_FILE             { handle_token(KWD_FILE_INDEX); }
  ;

kwd_final:             KWD_FINAL            { handle_token(KWD_FINAL_INDEX); }
  ;

kwd_flush:             KWD_FLUSH            { handle_token(KWD_FLUSH_INDEX); }
  ;

kwd_fmt:               KWD_FMT              { handle_token(KWD_FMT_INDEX); }
  ;

kwd_forall:            KWD_FORALL           { handle_token(KWD_FORALL_INDEX); }
  ;

kwd_form:              KWD_FORM             { handle_token(KWD_FORM_INDEX); }
  ;

kwd_format:            KWD_FORMAT           { handle_token(KWD_FORMAT_INDEX); }
  ;

kwd_formatted:         KWD_FORMATTED        { handle_token(KWD_FORMATTED_INDEX); }
  ;

kwd_function:          KWD_FUNCTION         { handle_token(KWD_FUNCTION_INDEX); }
  ;

kwd_generic:           KWD_GENERIC          { handle_token(KWD_GENERIC_INDEX); }
  ;

kwd_goto:              KWD_GOTO             { handle_token(KWD_GOTO_INDEX); }
  ;

kwd_if:                KWD_IF               { handle_token(KWD_IF_INDEX); }
  ;

kwd_implicit:          KWD_IMPLICIT         { handle_token(KWD_IMPLICIT_INDEX); }
  ;

kwd_implicit_none:     KWD_IMPLICIT_NONE    { handle_token(KWD_IMPLICIT_NONE_INDEX); }
  ;

kwd_import:            KWD_IMPORT           { handle_token(KWD_IMPORT_INDEX); }
  ;

kwd_impure:            KWD_IMPURE           { handle_token(KWD_IMPURE_INDEX); }
  ;

kwd_in:                KWD_IN               { handle_token(KWD_IN_INDEX); }
  ;

kwd_in_out:            KWD_IN_OUT           { handle_token(KWD_IN_OUT_INDEX); }
  ;

kwd_include:           KWD_INCLUDE          { handle_token(KWD_INCLUDE_INDEX); }
  ;

kwd_inquire:           KWD_INQUIRE          { handle_token(KWD_INQUIRE_INDEX); }
  ;

kwd_integer:           KWD_INTEGER          { handle_token(KWD_INTEGER_INDEX); }
  ;

kwd_intent:            KWD_INTENT           { handle_token(KWD_INTENT_INDEX); }
  ;

kwd_interface:         KWD_INTERFACE        { handle_token(KWD_INTERFACE_INDEX); }
  ;

kwd_intrinsic:         KWD_INTRINSIC        { handle_token(KWD_INTRINSIC_INDEX); }
  ;

kwd_iostat:            KWD_IOSTAT           { handle_token(KWD_IOSTAT_INDEX); }
  ;

kwd_iomsg:             KWD_IOMSG            { handle_token(KWD_IOMSG_INDEX); }
  ;

kwd_kind:              KWD_KIND             { handle_token(KWD_KIND_INDEX); }
  ;

kwd_let:               KWD_LET              { handle_token(KWD_LET_INDEX); }
  ;

kwd_logical:           KWD_LOGICAL          { handle_token(KWD_LOGICAL_INDEX); }
  ;

kwd_module:            KWD_MODULE           { handle_token(KWD_MODULE_INDEX); }
  ;

kwd_mold:              KWD_MOLD             { handle_token(KWD_MOLD_INDEX); }
  ;

kwd_name:              KWD_NAME             { handle_token(KWD_NAME_INDEX); }
  ;

kwd_named:             KWD_NAMED            { handle_token(KWD_NAMED_INDEX); }
  ;

kwd_namelist:          KWD_NAMELIST         { handle_token(KWD_NAMELIST_INDEX); }
  ;

kwd_nextrec:           KWD_NEXTREC          { handle_token(KWD_NEXTREC_INDEX); }
  ;

kwd_non_intrinsic:     KWD_NON_INTRINSIC    { handle_token(KWD_NON_INTRINSIC_INDEX); }
  ;

kwd_non_overridable:   KWD_NON_OVERRIDABLE  { handle_token(KWD_NON_OVERRIDABLE_INDEX); }
  ;

kwd_nonkind:           KWD_NONKIND          { handle_token(KWD_NONKIND_INDEX); }
  ;

kwd_none:              KWD_NONE             { handle_token(KWD_NONE_INDEX); }
  ;

kwd_nopass:            KWD_NOPASS           { handle_token(KWD_NOPASS_INDEX); }
  ;

kwd_nullify:           KWD_NULLIFY          { handle_token(KWD_NULLIFY_INDEX); }
  ;

kwd_number:            KWD_NUMBER           { handle_token(KWD_NUMBER_INDEX); }
  ;

kwd_open:              KWD_OPEN             { handle_token(KWD_OPEN_INDEX); }
  ;

kwd_opened:            KWD_OPENED           { handle_token(KWD_OPENED_INDEX); }
  ;

kwd_operator:          KWD_OPERATOR         { handle_token(KWD_OPERATOR_INDEX); }
  ;

kwd_optional:          KWD_OPTIONAL         { handle_token(KWD_OPTIONAL_INDEX); }
  ;

kwd_out:               KWD_OUT              { handle_token(KWD_OUT_INDEX); }
  ;

kwd_pad:               KWD_PAD              { handle_token(KWD_PAD_INDEX); }
  ;

kwd_parameter:         KWD_PARAMETER        { handle_token(KWD_PARAMETER_INDEX); }
  ;

kwd_pass:              KWD_PASS             { handle_token(KWD_PASS_INDEX); }
  ;

kwd_pause:             KWD_PAUSE            { handle_token(KWD_PAUSE_INDEX); }
  ;

kwd_pointer:           KWD_POINTER          { handle_token(KWD_POINTER_INDEX); }
  ;

kwd_position:          KWD_POSITION         { handle_token(KWD_POSITION_INDEX); }
  ;

kwd_precision:         KWD_PRECISION        { handle_token(KWD_PRECISION_INDEX); }
  ;

kwd_print:             KWD_PRINT            { handle_token(KWD_PRINT_INDEX); }
  ;

kwd_private:           KWD_PRIVATE          { handle_token(KWD_PRIVATE_INDEX); }
  ;

kwd_procedure:         KWD_PROCEDURE        { handle_token(KWD_PROCEDURE_INDEX); }
  ;

kwd_program:           KWD_PROGRAM          { handle_token(KWD_PROGRAM_INDEX); }
  ;

kwd_protected:         KWD_PROTECTED        { handle_token(KWD_PROTECTED_INDEX); }
  ;

kwd_public:            KWD_PUBLIC           { handle_token(KWD_PUBLIC_INDEX); }
  ;

kwd_pure:              KWD_PURE             { handle_token(KWD_PURE_INDEX); }
  ;

kwd_read:              KWD_READ             { handle_token(KWD_READ_INDEX); }
  ;

kwd_read_formatted:    KWD_READ_FORMATTED   { handle_token(KWD_READ_FORMATTED_INDEX); }
  ;

kwd_read_unformatted:  KWD_READ_UNFORMATTED { handle_token(KWD_READ_UNFORMATTED_INDEX); }
  ;

kwd_real:              KWD_REAL             { handle_token(KWD_REAL_INDEX); }
  ;

kwd_rec:               KWD_REC              { handle_token(KWD_REC_INDEX); }
  ;

kwd_recl:              KWD_RECL             { handle_token(KWD_RECL_INDEX); }
  ;

kwd_return:            KWD_RETURN           { handle_token(KWD_RETURN_INDEX); }
  ;

kwd_rewind:            KWD_REWIND           { handle_token(KWD_REWIND_INDEX); }
  ;

kwd_round:             KWD_ROUND            { handle_token(KWD_ROUND_INDEX); }
  ;

kwd_save:              KWD_SAVE             { handle_token(KWD_SAVE_INDEX); }
  ;

kwd_select_case:       KWD_SELECT_CASE      { handle_token(KWD_SELECT_CASE_INDEX); }
  ;

kwd_select_type:       KWD_SELECT_TYPE      { handle_token(KWD_SELECT_TYPE_INDEX); }
  ;

kwd_sequence:          KWD_SEQUENCE         { handle_token(KWD_SEQUENCE_INDEX); }
  ;

kwd_sequential:        KWD_SEQUENTIAL       { handle_token(KWD_SEQUENTIAL_INDEX); }
  ;

kwd_sign:              KWD_SIGN             { handle_token(KWD_SIGN_INDEX); }
  ;

kwd_size:              KWD_SIZE             { handle_token(KWD_SIZE_INDEX); }
  ;

kwd_source:            KWD_SOURCE           { handle_token(KWD_SOURCE_INDEX); }
  ;

kwd_status:            KWD_STATUS           { handle_token(KWD_STATUS_INDEX); }
  ;

kwd_stop:              KWD_STOP             { handle_token(KWD_STOP_INDEX); }
  ;

kwd_subroutine:        KWD_SUBROUTINE       { handle_token(KWD_SUBROUTINE_INDEX); }
  ;

kwd_target:            KWD_TARGET           { handle_token(KWD_TARGET_INDEX); }
  ;

kwd_then:              KWD_THEN             { handle_token(KWD_THEN_INDEX); }
  ;

kwd_true:              KWD_TRUE             { handle_token(KWD_TRUE_INDEX); }
  ;

kwd_type:              KWD_TYPE             { handle_token(KWD_TYPE_INDEX); }
  ;

kwd_unformatted:       KWD_UNFORMATTED      { handle_token(KWD_UNFORMATTED_INDEX); }
  ;

kwd_unit:              KWD_UNIT             { handle_token(KWD_UNIT_INDEX); }
  ;

kwd_use:               KWD_USE              { handle_token(KWD_USE_INDEX); }
  ;

kwd_value:             KWD_VALUE            { handle_token(KWD_VALUE_INDEX); }
  ;

kwd_volatile:          KWD_VOLATILE         { handle_token(KWD_VOLATILE_INDEX); }
  ;

kwd_where:             KWD_WHERE            { handle_token(KWD_WHERE_INDEX); }
  ;

kwd_write:             KWD_WRITE            { handle_token(KWD_WRITE_INDEX); }
  ;

kwd_write_formatted:   KWD_WRITE_FORMATTED  { handle_token(KWD_WRITE_FORMATTED_INDEX); }
  ;

kwd_write_unformatted: KWD_WRITE_UNFORMATTED  { handle_token(KWD_WRITE_UNFORMATTED_INDEX); }
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

bcs_percent: member
  ;

member: BCS_PUNCT_PERCENT { handle_token(OP_MEMBER_INDEX); }
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

open_parenthesis_slash: OPEN_PARENTHESIS_SLASH { handle_token_open(OPEN_PARENTHESIS_SLASH_INDEX); }
  ;

close_parenthesis_slash: CLOSE_PARENTHESIS_SLASH { handle_token_close(CLOSE_PARENTHESIS_SLASH_INDEX); }
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

dbl_colon: PUNC_DBL_COLON                 { handle_token(PUNC_DBL_COLON_INDEX); }
  ;

arrow: PUNC_ARROW                 { handle_token(PUNC_ARROW_INDEX); }
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

const char *get_yytname(int token) {
  return yytname[yytranslate[token]];
}
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

