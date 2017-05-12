# Ensure that the output of Parse::RecDescent is the same, time after
# time.  This prevents automated builds with precompiled parsers from
# registering changes, with no change input.

use strict;
use warnings;
use Parse::RecDescent;
use Test::More tests => 41;

# Turn off the "build a -standalone parser" precompile warning
our $RD_HINT = 0;

# mask "subroutine element redefined" warnings
local $^W;

my $grammar = <<'EOGRAMMAR';


    translation_unit:
        external_declaration(s)
    |   <error>

    external_declaration:
        function_definition
    |   declaration
    |   <resync>
        {
            if ($::opt_SKIPPEDLINES || (defined $::opt_VERBOSE and $::opt_VERBOSE >= 1 ))
            {
                print "Skipping line $thisline\n"   # Try next line if possible...
            }
         }

    function_definition:
        declaration_specifiers(?) declarator declaration_list(?) compound_statement
        {
            if($::opt_FUNCTIONS)
            {
                $::functions_output .= ::flatten_list($item[1]);
                $::functions_output .= ::flatten_list($item[2]);
                $::functions_output .= ::flatten_list($item[3]) . ";\n";
            }
        }

    declaration:
        declaration_specifiers init_declarator_list(?) ';'
        {
            if($::opt_DECLARATIONS)
            {
                $::declarations_output .= ::flatten_list($item[1]);
                $::declarations_output .= ::flatten_list($item[2]);
                $::declarations_output .= ::flatten_list($item[3]) . "\n";
            }
        }

    declaration_list:
        declaration(s)

    declaration_specifiers:
        type_qualifier              declaration_specifiers(?)
    |   storage_class_specifier declaration_specifiers(?)
    |   type_specifier          declaration_specifiers(?)

    storage_class_specifier:
          'auto'
        | 'register'
        | 'static'
        | 'extern'
        | 'typedef'

    type_specifier:
          'int'
        | 'double'
        | 'void'
        | 'char'
        | 'long'
        | 'float'
        | 'signed'
        | 'unsigned'
        | 'short'
        | struct_or_union_specifier
        | enum_specifier
        | typedef_name ...typedef_name_lookahead { [$item[1] ] }

    typedef_name_lookahead:
        declarator
#   |   pointer
#   |   ',' ...parameter_type_list
#   |   ')'

    type_qualifier:
          'const'
        | 'volatile'

    struct_or_union_specifier:
          struct_or_union IDENTIFIER(?) '{' struct_declaration_list(?) '}'
          {
            if($::opt_STRUCTS){
                $::structs_output .= ::flatten_list($item[1]) . " ";
                $::structs_output .= ::flatten_list($item[2]);
                $::structs_output .= ::flatten_list($item[3]) . "\n";
                $::structs_output .= ::flatten_list_beautified($item[4]);
                $::structs_output .= ::flatten_list($item[5]) . ";\n\n";
            }
          }
        | struct_or_union IDENTIFIER

    struct_or_union:
          'struct'
        | 'union'


    struct_declaration_list:
        struct_declaration(s)

    init_declarator_list:
        init_declarator(s /(,)/)

    init_declarator:
        declarator '=' initializer
    |   declarator

    struct_declaration:
        specifier_qualifier_list struct_declarator_list ';'

    specifier_qualifier_list:
        type_specifier specifier_qualifier_list(?)
    |   type_qualifier specifier_qualifier_list(?)

    struct_declarator_list:
        struct_declarator(s /(,)/)

    struct_declarator:
        declarator(?) ':' constant_expression
    |   declarator

    enum_specifier:
        'enum' IDENTIFIER(?) '{' enumerator_list '}'
          {
            if($::opt_STRUCTS){
                $::structs_output .= ::flatten_list($item[1]) . " ";
                $::structs_output .= ::flatten_list($item[2]);
                $::structs_output .= ::flatten_list($item[3]) . "\n";
                $::structs_output .= ::flatten_list_beautified($item[4]);
                $::structs_output .= ::flatten_list($item[5]) . ";\n\n";
            }
          }
    |   'enum' IDENTIFIER

    enumerator_list:
        enumerator(s /(,)/)

    enumerator:
        IDENTIFIER ('=' constant_expression)(?)

    declarator:
        pointer(?) direct_declarator

    function_signature:
        '[' constant_expression(?) ']'
    |   '(' parameter_type_list ')'
    |   '(' identifier_list(?) ')'

    direct_declarator:
        IDENTIFIER function_signature(s?)
    |   '(' declarator ')' function_signature(s?)


    pointer:
      '*' type_qualifier_list(?) pointer(?)

    type_qualifier_list:
        type_qualifier(s)

    parameter_type_list:
        parameter_list (',' '...')(?)

    parameter_list:
        parameter_declaration(s /(,)/)

    parameter_declaration:
        declaration_specifiers declarator
    |   declaration_specifiers abstract_declarator(?)

    identifier_list:
        IDENTIFIER(s /(,)/)

    initializer:
        assignment_expression
    |   '{' initializer_list (',')(?) '}'

    initializer_list:
        initializer(s /(,)/)

    type_name:
        specifier_qualifier_list abstract_declarator(?)

    abstract_declarator:
        pointer(?) direct_abstract_declarator
    |   pointer

    abstract_type:
        '[' constant_expression(?) ']'
    |   '(' parameter_type_list(?) ')'

    direct_abstract_declarator:
        '(' abstract_declarator ')' abstract_type(s?)
    |   abstract_type(s)

    typedef_name:
        IDENTIFIER

    statement:
        selection_statement
    |   expression_statement
    |   iteration_statement
    |   compound_statement
    |   jump_statement
    |   labeled_statement


    labeled_statement:
        'case' constant_expression ':' statement
    |   IDENTIFIER ':' statement
    |   'default' ':' statement

    expression_statement:
        expression(?) ';'

    compound_statement:
        '{' declaration_list(?) statement_list(?) '}'

    statement_list:
        statement(s)

    selection_statement:
        'if'      '(' expression  ')' statement ('else' statement)(?)
    |   'switch'  '(' expression  ')' statement

    iteration_statement:
        'for'   '(' expression(?) ';' expression(?) ';' expression(?) ')' statement
    |   'while' '(' expression ')' statement
    |   'do' statement 'while' '(' expression ')'

    jump_statement:
        'return' expression(?) ';'
    |   'break' ';'
    |   'continue' ';'
    |   'goto' IDENTIFIER ';'

    expression:
        assignment_expression(s /(,)/)

    assignment_expression:
        unary_expression ASSIGNMENT_OPERATOR assignment_expression
    |   conditional_expression


    conditional_expression:
         logical_OR_expression  ('?' expression ':' conditional_expression)(?)

    constant_expression:
        conditional_expression

    logical_OR_expression:
        logical_AND_expression(s /(\|\|)/)

    logical_AND_expression:
        inclusive_OR_expression(s /(&&)/)

    inclusive_OR_expression:
        exclusive_OR_expression(s /(\|)/)

    exclusive_OR_expression:
        AND_expression(s /(\^)/)

    AND_expression:
        equality_expression(s /(&)/)

    equality_expression:
        relational_expression(s /(==|!=)/)

    relational_expression:
        shift_expression(s /(<=|>=|<|>)/)

    shift_expression:
        additive_expression(s /(<<|>>)/)

    additive_expression:
        multiplicative_expression(s /(\+|-)/)

    multiplicative_expression:
        cast_expression(s /(\*|\/|%)/)

    cast_expression:
        unary_expression
    |   '(' type_name ')' cast_expression

    unary_expression:
        postfix_expression
    |   '++'  unary_expression
    |   '--'  unary_expression
    |   'sizeof' '(' type_name ')'
    |   UNARY_OPERATOR cast_expression
    |   'sizeof'    unary_expression


    postfix_expression:
        primary_expression postfix_expression_token(s?)


    postfix_expression_token:
          '[' expression ']'
        | '(' argument_expression_list(?)')'
        | '.'  IDENTIFIER
        | '->' IDENTIFIER
        | '++'
        | '--'


    primary_expression:
        IDENTIFIER
    |   constant
    |   STRING
    |   '(' expression ')'

    argument_expression_list:
        assignment_expression(s /(,)/)

    constant:
        CHARACTER_CONSTANT
    |   FLOATING_CONSTANT
    |   INTEGER_CONSTANT
    |   ENUMERATION_CONSTANT


###     TERMINALS


    INTEGER_CONSTANT:
        /(?:0[xX][\da-fA-F]+)                   # Hexadecimal
         |(?:0[0-7]*)                           # Octal or Zero
         |(?:[1-9]\d*)                          # Decimal
         [uUlL]?                                # Suffix
         /x

    CHARACTER_CONSTANT:
        /'([^\\'"]                          # None of these
         |\\['\\ntvbrfa'"]                  # or a backslash followed by one of those
         |\\[0-7]{1,3}|\\x\d+)'             # or an octal or hex constant
        /x

    FLOATING_CONSTANT:
        /(?:\d+|(?=\.\d+))                  # No leading digits only if '.moreDigits' follows
         (?:\.|(?=[eE]))                        # There may be no floating point only if an exponent is present
         \d*                                    # Zero or more floating digits
         ([eE][+-]?\d+)?                        # expontent
         [lLfF]?                                # Suffix
        /x

    ENUMERATION_CONSTANT:
        INTEGER_CONSTANT

    STRING:
        /"(([^\\'"])                            # None of these
        |(\\[\\ntvbrfa'"])                  # or a backslash followed by one of those
        |(\\[0-7]{1,3})|(\\x\d+))*"/x       # or an octal or hex

    IDENTIFIER:
        /(?!(auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto      # LOOKAHEAD FOR KEYWORDS
            |if|int|long|register|return|signed|sizeof|short|static|struct|switch|typedef           # NONE OF THE KEYWORDS
            |union|unsigned|void|volatile|while)[^a-zA-Z_])                                             # SHOULD FULLY MATCH!
            (([a-zA-Z]\w*)|(_\w+))/x                                                                # Check for valid identifier

    ASSIGNMENT_OPERATOR:
        '=' | '*=' | '/=' | '%=' | '+=' | '-=' | '<<=' | '>>=' | '&=' | '^=' | '|='

    UNARY_OPERATOR:
        '&' | '*' | '+' | '-' | '~' | '!'

EOGRAMMAR


# Create the reference output
my $class = "TestParser";

sub CompileParser {
    my $pm_filename = $class . '.pm';

    eval {
        Parse::RecDescent->Precompile({-standalone => 1,},
                                      $grammar,
                                      $class);
    };
    ok(!$@, qq{created a precompiled parser: } . $@);
    ok(-e $pm_filename, "found the precompiled parser file");

    my $fh;
    ok((open $fh, '<', $pm_filename), "opened the precompiled parser");
    my $parser_text;

    local $/;
    $parser_text = <$fh>;
    close $fh;

    ok((defined($parser_text) and length($parser_text)),
       "parser contains data");

    unlink $pm_filename;
    ok(!-e $pm_filename, "deleted precompiled parser");

    return $parser_text;
}

my $reference_parser = CompileParser();

for (0..5) {
    my $new_parser = CompileParser($_);

    ok($new_parser eq $reference_parser, "parsers match");
}
