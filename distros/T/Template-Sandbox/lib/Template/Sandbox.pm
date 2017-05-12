#
#  Template::Sandbox: Yet Another Template System.
#
#  Known issues:
#    - ${VALUE} define replacement breaks char-count and potentially
#      line count values (if ${VALUE} has newlines).
#
#  Future ideas:
#

package Template::Sandbox;

use strict;
use warnings;

use Carp;
use Class::Handle;
use Clone;
use Data::Dumper;
use Digest::MD5;
use IO::File;
use File::Spec;
use Log::Any;
use Scalar::Util;
use Storable;
#use Time::HiRes;

#my ( @function_table );

#  Array indices.
sub SELF()   { 0; }
sub OP_LHS() { 1; }
sub OP_RHS() { 2; }

#  Compiled line indices.
#  TODO: currently unused.
sub LINE_INSTR() { 0; }
sub LINE_POS()   { 1; }
sub LINE_ARG()   { 2; }

#  Instruction opcodes.
sub LITERAL()      { 0; }
sub DEBUG()        { 1; }
sub EXPR()         { 2; }
sub JUMP()         { 3; }
sub JUMP_IF()      { 4; }
sub FOR()          { 5; }
sub END_FOR()      { 6; }
sub CONTEXT_PUSH() { 7; }
sub CONTEXT_POP()  { 8; }

#  Starting point for opcodes for locally registered syntaxes.
sub LOCAL_SYNTAX() { 1_000_000; }

#  Expression opcodes.
sub OP_TREE()  { 100; }
sub UNARY_OP() { 101; }
sub FUNC()     { 102; }
sub METHOD()   { 103; }
sub VAR()      { 104; }
sub TEMPLATE() { 105; }

#  Template function array indices.
sub FUNC_FUNC()           { 0; }
sub FUNC_ARG_NUM()        { 1; }
sub FUNC_NEEDS_TEMPLATE() { 2; }
sub FUNC_INCONST()        { 3; }
sub FUNC_UNDEF_OK()       { 4; }

#  Special values in loop vars.
sub LOOP_COUNTER()        { 0; };
sub LOOP_EVEN()           { 1; };
sub LOOP_ODD()            { 2; };
sub LOOP_FIRST()          { 3; };
sub LOOP_INNER()          { 4; };
sub LOOP_LAST()           { 5; };
sub LOOP_PREV()           { 6; };
sub LOOP_NEXT()           { 7; };
sub LOOP_VALUE()          { 8; };

my %special_values_names = (
    __counter__ => LOOP_COUNTER,
    __even__    => LOOP_EVEN,
    __odd__     => LOOP_ODD,
    __first__   => LOOP_FIRST,
    __inner__   => LOOP_INNER,
    __last__    => LOOP_LAST,
    __prev__    => LOOP_PREV,
    __next__    => LOOP_NEXT,
    __value__   => LOOP_VALUE,
    );

sub LOOP_STACK_COUNTER()  { 0; }
sub LOOP_STACK_LAST()     { 1; }
sub LOOP_STACK_SET()      { 2; }
sub LOOP_STACK_HASH()     { 3; }
sub LOOP_STACK_CONTEXT()  { 4; }
sub LOOP_STACK_SPECIALS() { 5; }

#  The lower the weight the tighter it binds.
my %operators = (
    #  Logic operators
    'or'  => [ 100, sub { $_[ SELF ]->_eval_expression( $_[ OP_LHS ], 1 ) or
                          $_[ SELF ]->_eval_expression( $_[ OP_RHS ], 1 ) },
               1 ],
    'and' => [ 99,  sub { $_[ SELF ]->_eval_expression( $_[ OP_LHS ], 1 ) and
                          $_[ SELF ]->_eval_expression( $_[ OP_RHS ], 1 ) },
               1 ],
    '||'  => [ 98,  sub { $_[ SELF ]->_eval_expression( $_[ OP_LHS ], 1 ) ||
                          $_[ SELF ]->_eval_expression( $_[ OP_RHS ], 1 ) },
               1 ],
    '&&'  => [ 96,  sub { $_[ SELF ]->_eval_expression( $_[ OP_LHS ], 1 ) &&
                          $_[ SELF ]->_eval_expression( $_[ OP_RHS ], 1 ) },
               1 ],
    #  Comparison operators
    'cmp' => [ 95,  sub { $_[ OP_LHS ] cmp $_[ OP_RHS ] } ],
    'ne'  => [ 94,  sub { $_[ OP_LHS ] ne  $_[ OP_RHS ] ? 1 : 0 } ],
    'eq'  => [ 93,  sub { $_[ OP_LHS ] eq  $_[ OP_RHS ] ? 1 : 0 } ],
    '<=>' => [ 92,  sub { $_[ OP_LHS ] <=> $_[ OP_RHS ] } ],
    '!='  => [ 91,  sub { $_[ OP_LHS ] !=  $_[ OP_RHS ] ? 1 : 0 } ],
    '=='  => [ 90,  sub { $_[ OP_LHS ] ==  $_[ OP_RHS ] ? 1 : 0 } ],
    'ge'  => [ 89,  sub { $_[ OP_LHS ] ge  $_[ OP_RHS ] ? 1 : 0 } ],
    'le'  => [ 88,  sub { $_[ OP_LHS ] le  $_[ OP_RHS ] ? 1 : 0 } ],
    'gt'  => [ 87,  sub { $_[ OP_LHS ] gt  $_[ OP_RHS ] ? 1 : 0 } ],
    'lt'  => [ 86,  sub { $_[ OP_LHS ] lt  $_[ OP_RHS ] ? 1 : 0 } ],
    '>='  => [ 85,  sub { $_[ OP_LHS ] >=  $_[ OP_RHS ] ? 1 : 0 } ],
    '<='  => [ 84,  sub { $_[ OP_LHS ] <=  $_[ OP_RHS ] ? 1 : 0 } ],
    '>'   => [ 83,  sub { $_[ OP_LHS ] >   $_[ OP_RHS ] ? 1 : 0 } ],
    '<'   => [ 82,  sub { $_[ OP_LHS ] <   $_[ OP_RHS ] ? 1 : 0 } ],

    #  Assignment
    '='   => [ 75,  sub { $_[ SELF ]->_assign_var( $_[ OP_LHS ],
                              $_[ SELF ]->_eval_expression( $_[ OP_RHS ] ) )
                        },
               1 ],

    #  Arithmetic/concat
    '.'   => [ 70,  sub { $_[ OP_LHS ] .  $_[ OP_RHS ] } ],
    '+'   => [ 69,  sub { $_[ OP_LHS ] +  $_[ OP_RHS ] } ],
    '-'   => [ 68,  sub { $_[ OP_LHS ] -  $_[ OP_RHS ] } ],
    '%'   => [ 67,  sub { $_[ OP_LHS ] %  $_[ OP_RHS ] } ],
    '/'   => [ 66,  sub { $_[ OP_LHS ] /  $_[ OP_RHS ] } ],
    '*'   => [ 65,  sub { $_[ OP_LHS ] *  $_[ OP_RHS ] } ],
    );

sub def_func
{
    my ( $ret, $flag, $val ) = @_;
    $ret = [ $ret ] if ref( $ret ) ne 'ARRAY';
    $ret->[ $flag ] = $val;
#warn "def_func: ..." . _tersedump( $ret );
    return( $ret );
}

sub inconstant { return( def_func( @_, FUNC_INCONST, 1 ) ); }
sub needs_template { return( def_func( @_, FUNC_NEEDS_TEMPLATE, 1 ) ); }
sub undef_ok   { return( def_func( @_, FUNC_UNDEF_OK, 1 ) ); }
sub has_args   { return( def_func( $_[ 0 ], FUNC_ARG_NUM, $_[ 1 ] ) ); }
sub no_args    { return( has_args( @_, 0 ) ); }
sub one_arg    { return( has_args( @_, 1 ) ); }
sub two_args   { return( has_args( @_, 2 ) ); }
sub three_args { return( has_args( @_, 3 ) ); }
sub any_args   { return( has_args( @_, -1 ) ); }


#  These void() and size() are required since they get used internally
#  for certain backwards-compat behaviours/syntax sugars.
#  defined() is required by the test suite, so it stays here too.
my %functions = (
    #  Takes any arg and returns '', useful for hiding expression results.
    void    => ( any_args sub { '' } ),

    size    => ( one_arg
        sub
        {
            return( undef ) unless defined( $_[ 0 ] );
            my $type = Scalar::Util::reftype( $_[ 0 ] );
            return( $type eq 'HASH'   ? scalar( keys( %{$_[ 0 ]} ) ) :
                    $type eq 'ARRAY'  ? scalar( @{$_[ 0 ]} ) :
                    $type eq 'SCALAR' ? length( ${$_[ 0 ]} ) :
                                        length( $_[ 0 ] ) );
        } ),

    defined => ( one_arg undef_ok sub { defined( $_[ 0 ] ) ? 1 : 0 } ),
    );

#print "Content-type: text/plain\n\n" . Data::Dumper::Dumper( \%functions );

my %token_aliases = (
    'foreach'     => 'for',
    'end for'     => 'endfor',
    'endforeach'  => 'endfor',
    'end foreach' => 'endfor',
    'end include' => 'endinclude',
    'els if'      => 'elsif',
    'else if'     => 'elsif',
    'elseif'      => 'elsif',
    'end if'      => 'endif',
    'els unless'  => 'elsunless',
    'else unless' => 'elsunless',
    'elseunless'  => 'elsunless',
    'end unless'  => 'endunless',
    );

#  zero_width => boolean,
#    Zero-width tokens gobble one of the surrounding \n if they're
#    on a line by themselves, preventing "blank-line spam" in the
#    template output.
#  TODO: move syntaxes into substructure to avoid .key hackery.
my %syntaxes = (
    #  Faux values to define the auto opcode generation for local syntaxes.
    '.next_instr'      => LOCAL_SYNTAX,
    '.instr_increment' => 1,
    '.instr'           => {},

    #  Actual syntax definitions.
    'var'     => {
        positional_args => [ 'var' ],
        valid_args      => [ 'var' ],
        },
    'debug'   => {
        positional_args => [ 'type', 'state' ],
        valid_args      => [ 'type', 'state' ],
        zero_width => 1,
        },
    '#'       => {
        zero_width => 1,
        },
    'include' => {
        positional_args => [ 'filename' ],
        zero_width => 1,
        },
    'endinclude'      => {
        zero_width => 1,
        },
    'for'     => {
        zero_width => 1,
        },
    'endfor'      => {
        zero_width => 1,
        },
    'if'      => {
        zero_width => 1,
        },
    'unless'  => {
        zero_width => 1,
        },
    'else'      => {
        zero_width => 1,
        },
    'elsif'      => {
        zero_width => 1,
        },
    'elsunless'      => {
        zero_width => 1,
        },
    'endif'      => {
        zero_width => 1,
        },
    'endunless'      => {
        zero_width => 1,
        },
    );

#  Special vars that are symbolic literals.
my %symbolic_literals = (
    'undef' => [ LITERAL, 'undef', undef ],
    'null'  => [ LITERAL, 'null',  undef ],
    'cr'    => [ LITERAL, 'cr', "\n" ],
    );

#  "our" declarations are to work around problem in some perls where
#  "my" scope variables aren't seen by (??{ ... }).
our ( $single_quoted_text_regexp );

$single_quoted_text_regexp = qr/
    \'
    (?:
        #  Quoteless, backslashless text.
        (?> [^\'\\]+ )
        |
        #  Escaped characters.
        (?> (?:\\\\)* \\ . )
    )*
    \'
    /sxo;

our ( $double_quoted_text_regexp );

$double_quoted_text_regexp = qr/
    \"
    (?:
        #  Quoteless, backslashless text.
        (?> [^\"\\]+ )
        |
        #  Escaped characters.
        (?> (?:\\\\)* \\ . )
    )*
    \"
    /sxo;

our ( $matching_square_brackets_regexp );

$matching_square_brackets_regexp = qr/
    \[
    (?:
        #  Bracketless, quoteless subtext.
        (?> [^\[\]\"\']+ )
        |
        #  Quoted text.
        (??{ $double_quoted_text_regexp }) |
        (??{ $single_quoted_text_regexp })
        |
        #  Expression containing sub-brackets.
        (??{ $matching_square_brackets_regexp })
    )*
    \]
    /sxo;

our ( $matching_round_brackets_regexp );

$matching_round_brackets_regexp = qr/
    \(
    (?:
        #  Bracketless, quoteless subtext.
        (?> [^\(\)\"\']+ )
        |
        #  Quoted text.
        (??{ $double_quoted_text_regexp }) |
        (??{ $single_quoted_text_regexp })
        |
        #  Expression containing sub-brackets.
        (??{ $matching_round_brackets_regexp })
    )*
    \)
    /sxo;

my $bare_identifier_regexp = qr/
    [a-zA-Z_][a-zA-Z0-9_]*
    /sxo;

my $function_regexp = qr/
    #  abc( expr )
    $bare_identifier_regexp
    $matching_round_brackets_regexp
    /sxo;

my $capture_function_regexp = qr/
    ^
    #  abc( expr )
    ($bare_identifier_regexp)
    \(
    \s*
    (.*?)
    \s*
    \)
    $
    /sxo;

#  Chained structure:
#  var.sub.sub
#  var.sub['sub']
#  var['sub'].sub
#  var['sub']['sub'] fails!
#  var.sub.method()
#  var['sub'].method()
#  var.method().sub
#  var.method()['sub']
#  func().sub.sub ?
#  func().method().sub

my $subscript_operator_regexp = qr/
    (?: \. | \-\> )
    /sxo;

my $expr_subscript_regexp    = $matching_square_brackets_regexp;
my $capture_expr_subscript_regexp = qr/
    ^
    \[
    \s*
    (.*?)
    \s*
    \]
    $
    /sxo;
my $literal_subscript_regexp = qr/
    $subscript_operator_regexp
    $bare_identifier_regexp
    /sxo;
my $capture_literal_subscript_regexp = qr/
    ^
    $subscript_operator_regexp
    ($bare_identifier_regexp)
    $
    /sxo;
my $method_subscript_regexp  = qr/
    $subscript_operator_regexp
    $function_regexp
    /sxo;
my $capture_method_subscript_regexp = qr/
    ^
    #  . | ->
    $subscript_operator_regexp
    #  abc( expr )
    ($bare_identifier_regexp)
    \(
    \s*
    (.*?)
    \s*
    \)
#    ($matching_round_brackets_regexp)
    $
    /sxo;

my $chained_operation_top_regexp = qr/
    (?:
    #  Function goes first to take matching precedence over bareword
    $function_regexp |
    $bare_identifier_regexp
    )
    /sxo;
my $chained_operation_subscript_regexp = qr/
    (?:
    $expr_subscript_regexp |
    #  Method goes first to take matching precedence over bareword
    $method_subscript_regexp |
    $literal_subscript_regexp
    )
    /sxo;
my $chained_operation_regexp = qr/
    $chained_operation_top_regexp
    (?: $chained_operation_subscript_regexp )*
    /sxo;

my $capture_chained_operation_top_regexp = qr/
    ^
    ($chained_operation_top_regexp)
    #  we don't care at this point what the rest of the crud is.
    (.*)
    $
    /sxo;
my $capture_chained_operation_subscript_regexp = qr/
    ^
    ($chained_operation_subscript_regexp)
    #  we don't care at this point what the rest of the crud is.
    (.*)
    $
    /sxo;

my $literal_number_regexp = qr/
    #  1 or more digits.
    \d+
    #  Optionally a decimal fraction.
    (?: \. \d+ )?
    /sxo;

my $unary_operator_regexp = qr/
    (?: \! | not (?=\s) | - )
    /sxo;
my $capture_unary_operator_regexp = qr/
    ^
    ( \! | not (?=\s) | - )
    \s*
    (.*)
    $
    /sxo;

my $atomic_expr_regexp = qr/
    #  Optionally a unary operator
    (?: $unary_operator_regexp \s* )?
    #  Followed by an atomic value
    (?:
        #  A bracketed sub-expression.
        $matching_round_brackets_regexp
        |
        #  A chained operation.
        $chained_operation_regexp
        |
        #  A literal number
        $literal_number_regexp
        |
        #  A literal string
        $single_quoted_text_regexp
    )
    /sxo;

my $operator_regexp = join( '|', map { "\Q$_\E" } keys( %operators ) );
$operator_regexp = qr/
    (?: $operator_regexp )
    /sxo;

my $expr_regexp = qr/
    \s*
    (?:
        #  A sequence of atomic epressions and operators.
        $atomic_expr_regexp
        (?:
            \s+
            $operator_regexp
            \s+
            $atomic_expr_regexp
        )*
    )
    \s*
    /sxo;
#            (?:
#                \s+
#                $operator_regexp
#                \s+
#                $atomic_expr_regexp
#            )
#            |
#            (?:
#                \s+
#                \?
#                \s+
#                $atomic_expr_regexp
#                \s+
#                \:
#                $atomic_expr_regexp
#            )

my $capture_expr_op_remain_regexp = qr/
    ^
    \s*
    ($atomic_expr_regexp)
    \s+
    ($operator_regexp)
    \s+
    (.*)
    $
    /sxo;

#my $capture_expr_if_else_remain_regexp = qr/
#    ^
#    \s*
#    ($atomic_expr_regexp)
#    \s+ \? \s+
#    ($atomic_expr_regexp)
#    \s+ \: \s+
#    ($atomic_expr_regexp)
#    \s*
#    (.*?)
#    \s*
#    $
#    /sx;

my $capture_expr_comma_remain_regexp = qr/
    ^
    ($expr_regexp)
    (?:
        (?: , | => )
        \s*
        (.*)
    )?
    $
    /sxo;

BEGIN
{
    use Exporter   ();

    $Template::Sandbox::VERSION     = '1.04';
    @Template::Sandbox::ISA         = qw( Exporter );

    @Template::Sandbox::EXPORT      = qw();
    @Template::Sandbox::EXPORT_OK   = qw(
        inconstant
        needs_template
        undef_ok
        has_args no_args
        one_arg two_args three_args any_args
        def_func
        );
    %Template::Sandbox::EXPORT_TAGS = (
        function_sugar => [ qw(
            inconstant
            needs_template
            undef_ok
            has_args no_args
            one_arg two_args three_args any_args
            ) ],
        );
}

sub _find_local_functions
{
    my ( $self ) = @_;

    return( \%functions ) unless ref( $self );

    $self->{ local_functions } ||= {};
    return( $self->{ local_functions } );
}

sub register_template_function
{
    my $self = shift;
    my ( $local_functions );

    $local_functions = $self->_find_local_functions();

    while( my $name = shift )
    {
        my ( $func );

        $func = shift;

        #  TODO:  Carp has errors croaking from here.
        $self->caller_error(
            "Bad template function '$name' to register_template_function(), " .
            "expected sub ref or 'function_sugar'ed sub ref, got: " .
            ( ref( $func ) || "'$func'" ) )
            unless ref( $func ) eq 'ARRAY' or ref( $func ) eq 'CODE';

        #  do local $^W = undef; in calling block to suppress.
        $self->caller_warning(
            "Template function '$name' exists, overwriting." )
            if $^W and $local_functions->{ $name };

        #  If they don't use the function sugar, we assume they're not fussy
#  TODO: probably safer to error since constant/inconstant shouldn't be assumed
        $func = any_args $func if ref( $func ) eq 'CODE';

        $local_functions->{ $name } = $func;
    }
}

sub add_template_function
{
    my $self = shift;

    $self->register_template_function( @_ );
}

sub unregister_template_function
{
    my $self = shift;
    my ( $local_functions );

    $local_functions = $self->_find_local_functions();

    while( my $name = shift )
    {
        $self->caller_warning(
            "Template function '$name' does not exist, cannot be removed." )
            if $^W and not $local_functions->{ $name };

        delete $local_functions->{ $name };
    }
}

sub delete_template_function
{
    my $self = shift;

    $self->unregister_template_function( @_ );
}

sub _find_local_syntaxes
{
    my ( $self ) = @_;

    return( \%syntaxes ) unless ref( $self );

    $self->{ local_syntaxes } ||= {
        #  Faux values to define the auto opcode generation for local syntaxes.
        #  We use negative values to avoid clash with class-level opcodes.
        '.next_instr'      => -(LOCAL_SYNTAX),
        '.instr_increment' => -1,
        '.instr'           => {},
        };
    $self->{ local_token_aliases } ||= {};
    return( $self->{ local_syntaxes } );
}

sub register_template_syntax
{
    my $self = shift;
    my ( $local_syntaxes );

    $local_syntaxes = $self->_find_local_syntaxes();

    while( my $name = shift )
    {
        my ( $syntax );

        $syntax = shift;

        #  TODO:  Carp has errors when croaking from here.
        $self->caller_error(
            "Bad template syntax '$name' to register_template_syntax(), " .
            "expected hash ref, got: " . ( ref( $syntax ) || "'$syntax'" ) )
            unless ref( $syntax ) eq 'HASH';

        $self->caller_error( "Missing compile callback for syntax $name" )
             unless $syntax->{ compile };
        $self->caller_error( "Missing run callback for syntax $name" )
             unless $syntax->{ run };

        #  do local $^W = undef; in calling block to suppress.
        $self->caller_warning(
            "Template syntax '$name' exists, overwriting." )
            if $^W and $local_syntaxes->{ $name };

        $syntax = { %{$syntax} };

        #  Icky.
        $syntax->{ instr } = $local_syntaxes->{ '.next_instr' };
        $local_syntaxes->{ '.next_instr' } +=
            $local_syntaxes->{ '.instr_increment' };

        $local_syntaxes->{ $name } = { %{$syntax} };
        $local_syntaxes->{ '.instr' }->{ $syntax->{ instr } } = $name;
    }
}

sub add_template_syntax
{
    my $self = shift;

    $self->register_template_syntax( @_ );
}

sub unregister_template_syntax
{
    my $self = shift;
    my ( $local_syntaxes );

    $local_syntaxes = $self->_find_local_syntaxes();

    while( my $name = shift )
    {
        unless( $local_syntaxes->{ $name } )
        {
            $self->caller_warning(
                "Template syntax '$name' does not exist, cannot be removed." )
                if $^W;
            next;
        }

        delete $local_syntaxes->{ '.instr' }->{
            $local_syntaxes->{ $name }->{ instr } };
        delete $local_syntaxes->{ $name };
    }
}

sub delete_template_syntax
{
    my $self = shift;

    $self->unregister_template_syntax( @_ );
}

sub get_valid_singular_constructor_param
{
    my ( $self ) = @_;

    return( qw/template cache logger template_root allow_bare_expr
        ignore_module_dependencies open_delimiter close_delimiter
        vmethods template_toolkit_compat/ );
}

sub get_valid_multiple_constructor_param
{
    my ( $self ) = @_;

    return( qw/copy_global_functions template_function template_syntax
        library/ );
}

#  TODO: implement these constructor options:
#    -
sub new
{
    my $this = shift;
    my ( $self, $class, %param, %valid_singular, %valid_multiple );

    $self = {};
    $class = ref( $this ) || $this;
    bless $self, $class;

    %valid_singular =
        map { $_ => 1 } $self->get_valid_singular_constructor_param();
    %valid_multiple =
        map { $_ => 1 } $self->get_valid_multiple_constructor_param();

    #  Read remaining args.
    %param = ();
    while( my $param_name = shift )
    {
        my $param_value = shift;

        if( $valid_singular{ $param_name } )
        {
            $param{ $param_name } = $param_value;
        }
        elsif( $valid_multiple{ $param_name } )
        {
            $param{ $param_name } ||= [];
            push @{$param{ $param_name }}, $param_value;
        }
        else
        {
            $self->caller_error( "Unknown constructor param: '$param_name'" );
        }
    }

    $self->{ phase } = 'initialization';
    $self->initialize( \%param );
    $self->{ phase } = 'post-initialization';

    return( $self );
}

sub initialize
{
    my ( $self, $param ) = @_;

    #  Do this early in case anything needs logging.
    if( exists $param->{ logger } )
    {
        $self->{ logger } = $param->{ logger } if $param->{ logger };
    }
    else
    {
        $self->{ logger } = Log::Any->get_logger();
    }

    #  For the paranoid, to prevent other code changing them after
    #  we initialize.
    $self->{ local_functions } = Clone::clone( \%functions )
        if exists $param->{ copy_global_functions };

    if( exists $param->{ template_function } )
    {
        foreach my $arg ( @{$param->{ template_function }} )
        {
            $self->register_template_function( @{$arg} );
        }
    }
    if( exists $param->{ template_syntax } )
    {
        foreach my $arg ( @{$param->{ template_syntax }} )
        {
            $self->register_template_syntax( @{$arg} );
        }
    }
    if( exists $param->{ library } )
    {
        foreach my $arg ( @{$param->{ library }} )
        {
#  Neccessary?
#            eval "use $arg->[ 0 ];";
            $arg->[ 0 ]->export_template_functions( $self,
                @{$arg}[ 1..@{$arg} - 1 ] );
        }
    }

    $self->{ ignore_module_dependencies } =
        $param->{ ignore_module_dependencies }
        if exists $param->{ ignore_module_dependencies };

    if( $param->{ template_toolkit_compat } )
    {
        $self->{ open_delimiter }  = '[%'
            unless exists $param->{ open_delimiter };
        $self->{ close_delimiter } = '%]'
            unless exists $param->{ close_delimiter };
        $self->{ allow_bare_expr } = 1
            unless exists $param->{ allow_bare_expr };
        $self->{ vmethods }        = 1
            unless exists $param->{ vmethods };
    }

    $self->{ open_delimiter } = $param->{ open_delimiter }
        if exists $param->{ open_delimiter };
    $self->{ close_delimiter } = $param->{ close_delimiter }
        if exists $param->{ close_delimiter };
    $self->{ allow_bare_expr } = $param->{ allow_bare_expr }
        if exists $param->{ allow_bare_expr };
    $self->{ vmethods } = $param->{ vmethods }
        if exists $param->{ vmethods };

    $self->set_cache( $param->{ cache } )
        if exists $param->{ cache };
    $self->set_template_root( $param->{ template_root } )
        if exists $param->{ template_root };
    $self->set_template( $param->{ template } )
        if exists $param->{ template };

    $self->{ vars }   = {};
    $self->{ debug }  = {};
}

sub set_cache
{
    my ( $self, $cache ) = @_;

    $self->{ cache } = $cache;
    delete $self->{ cache_uses_extended_set };
}

sub _cache_uses_extended_set
{
    my ( $self ) = @_;
    my ( $cache );

    return( $self->{ cache_uses_extended_set } )
        if exists $self->{ cache_uses_extended_set };

    $cache = $self->{ cache };
    return( $self->{ cache_uses_extended_set } = 1 )
        if $cache->isa( 'Cache::CacheFactory' ) or
           ( $cache->can( 'set_takes_named_param' ) and
             $cache->set_takes_named_param() );
    return( $self->{ cache_uses_extended_set } = 0 );
}

sub set_template_root
{
    my ( $self, $dir ) = @_;

    $self->{ template_root } = $dir;
}

sub get_template_candidates
{
    my ( $self, $filename, $current_dir ) = @_;

    return( $self->{ template_root } ?
        File::Spec->catfile( $self->{ template_root }, $filename ) :
        $filename );
}

sub get_include_candidates
{
    my ( $self, $filename, $current_dir ) = @_;

    return( $current_dir ?
        File::Spec->catfile( $current_dir, $filename ) :
        $filename );
}

sub find_template
{
    my ( $self, $filename, $current_dir ) = @_;
    my ( @candidates );

    @candidates = $self->get_template_candidates( $filename, $current_dir );
    foreach my $candidate ( @candidates )
    {
        return( $candidate ) if -e $candidate;
    }

    $self->error( "Unable to find matching template from candidates:\n" .
        join( "\n", @candidates ) );
}

sub find_include
{
    my ( $self, $filename, $current_dir ) = @_;
    my ( @candidates );

    @candidates = $self->get_include_candidates( $filename, $current_dir );

    foreach my $candidate ( @candidates )
    {
        return( $candidate ) if -e $candidate;
    }

    $self->error( "Unable to find matching include from candidates:\n" .
        join( "\n", @candidates ) );
}

sub cache_key
{
    my ( $self, $keys ) = @_;
    local $Storable::canonical = 1;

    return( Digest::MD5::md5_hex( Storable::nfreeze( $keys ) ) );
}

sub get_additional_dependencies
{
#    my ( $self ) = @_;

    return( [] );
}

sub set_template
{
    my ( $self, $filename, $defines ) = @_;
    my ( $cache_key );

#my $start_time = Time::HiRes::time();

    #  Shallow copy is safe, keys/values should only be scalars.
    $defines = $defines ? { %{$defines} } : {};
    $self->{ defines }        = $defines;
    $self->{ special_values } = {};
    delete $self->{ template };

    $self->{ filename }    = $self->find_template( $filename );
    $defines->{ FILENAME } = $self->{ filename };

    if( $self->{ cache } )
    {
#my $fetchstart = Time::HiRes::time();
        #  $defines at this stage includes all unique compile-time
        #  parameters that effect the final compiled template, this
        #  is more than just the filename, so we need to generate
        #  a simple string key from multiple inputs.
        $cache_key = $self->cache_key( $defines );
        $self->{ template } = $self->{ cache }->get( $cache_key );
#warn "Cache fetch: " . $self->{ filename } . " " .
#  sprintf( "%.6fs", Time::HiRes::time() - $fetchstart );
    }

    unless( $self->{ template } )
    {
        my ( $compiletime );

        $compiletime = time();  #  Before the compile, to be safe.

        $self->{ dependencies } = $self->get_additional_dependencies();

        #  If we're caching, the validity of the cache depends on the
        #  last-modified of the template module as well as the template
        #  files, unless we've been told to ignore it.
        if( $self->{ cache } and not $self->{ ignore_module_dependencies } )
        {
            my ( $class_handle );

            $class_handle = Class::Handle->new( ref( $self ) );
            push @{$self->{ dependencies }},
                #  TODO: Ew, ugly and non-portable.
                grep { defined( $_ ) }
                map  { s/\:\:/\//g; s/$/\.pm/; $INC{ $_ }; }
                $class_handle->self_and_super_path();
        }

        $self->{ template } =
            $self->_read_template( $self->{ filename }, $defines );

        $self->_compile_template();

        if( $self->{ cache } )
        {
            #  If they're using Cache::CacheFactory we can make use of
            #  the dependencies and created at timestamps, if not we
            #  fall back on the basic Cache::Cache style API.
#  TODO: wrap compat cache behaviour with our own dependencies checking.
            if( $self->_cache_uses_extended_set() )
            {
                $self->{ cache }->set(
                    key          => $cache_key,
                    data         => $self->{ template },
                    dependencies => $self->{ dependencies },
                    created_at   => $compiletime,
                    );
            }
            else
            {
                $self->{ cache }->set( $cache_key, $self->{ template } );
            }
        }
    }

#CORE::warn( "set_template( $filename ) took " .
#  sprintf( "%.3f", Time::HiRes::time() - $start_time ) . "s" );
}

#  TODO: split/merge parts from set_template() above.
sub set_template_string
{
    my ( $self, $template_string, $defines ) = @_;
    my ( $cache_key );

#my $start_time = Time::HiRes::time();

    #  Shallow copy is safe, keys/values should only be scalars.
    $defines = $defines ? { %{$defines} } : {};
    $self->{ defines }        = $defines;
    $self->{ special_values } = {};
    delete $self->{ template };

    #  Erk.  Better way of making this cacheable surely?
    $self->{ filename }    = 'string:///' . $template_string;
    $defines->{ FILENAME } = $self->{ filename };

    if( $self->{ cache } )
    {
#my $fetchstart = Time::HiRes::time();
        #  $defines at this stage includes all unique compile-time
        #  parameters that effect the final compiled template, this
        #  is more than just the filename, so we need to generate
        #  a simple string key from multiple inputs.
        $cache_key = $self->cache_key( $defines );
        $self->{ template } = $self->{ cache }->get( $cache_key );
#warn "Cache fetch: " . $self->{ filename } . " " .
#  sprintf( "%.6fs", Time::HiRes::time() - $fetchstart );
    }

    unless( $self->{ template } )
    {
        my ( $compiletime );

        $compiletime = time();  #  Before the compile, to be safe.

        $self->{ dependencies } = $self->get_additional_dependencies();

        #  If we're caching, the validity of the cache depends on the
        #  last-modified of the template module as well as the template
        #  files, unless we've been told to ignore it.
        if( $self->{ cache } and not $self->{ ignore_module_dependencies } )
        {
            my ( $class_handle );

            $class_handle = Class::Handle->new( ref( $self ) );
            push @{$self->{ dependencies }},
                #  TODO: Ew, ugly and non-portable.
                grep { defined( $_ ) }
                map  { s/\:\:/\//g; s/$/\.pm/; $INC{ $_ }; }
                $class_handle->self_and_super_path();
        }

        $self->{ template } =
            $self->_read_template_from_string( $template_string, $defines );

        $self->_compile_template();

        if( $self->{ cache } )
        {
            #  If they're using Cache::CacheFactory we can make use of
            #  the dependencies and created at timestamps, if not we
            #  fall back on the basic Cache::Cache style API.
#  TODO: wrap compat cache behaviour with our own dependencies checking.
            if( $self->_cache_uses_extended_set() )
            {
                $self->{ cache }->set(
                    key          => $cache_key,
                    data         => $self->{ template },
                    dependencies => $self->{ dependencies },
                    created_at   => $compiletime,
                    );
            }
            else
            {
                $self->{ cache }->set( $cache_key, $self->{ template } );
            }
        }
    }

#CORE::warn( "set_template( $filename ) took " .
#  sprintf( "%.3f", Time::HiRes::time() - $start_time ) . "s" );
}

sub _error_message
{
    my $self = shift;
    my ( $error, $pos );

    $self = {} unless ref( $self );  #  Hack for calling as a class method.

    $error = join( '', @_ );
    $error = "Template " . ( $self->{ phase } ? $self->{ phase } . ' ' : '' ) .
        "error: $error";
    $pos = $self->{ current_pos };
    if( $pos )
    {
        my ( $files );

        if( $self->{ template } and
            ( ref( $self->{ template } ) eq 'HASH' ) and
            $self->{ template }->{ files } )
        {
            $files = $self->{ template }->{ files };
        }
        elsif( $self->{ files } )
        {
            $files = $self->{ files };
        }
        else
        {
            $files = [];
        }
        $error .= " at line $pos->[ 1 ], char $pos->[ 2 ] of " .
            "'$files->[ $pos->[ 0 ] ]'";
        if( $self->{ pos_stack } )
        {
            my ( $first );

            $first = 1;
            foreach $pos ( @{$self->{ pos_stack }} )
            {
                $error .= "\n  called from " .
                    "line $pos->[ 1 ], char $pos->[ 2 ] of " .
                    "'$files->[ $pos->[ 0 ] ]'"
                    unless $first;
                $first = 0;
            }
        }
    }
    return( $error );
}

sub log_error
{
    my ( $self, $message ) = @_;

    return unless ref( $self );  #  No logging if class method.
    $self->{ logger }->error( $message ) if $self->{ logger };
}

sub log_warning
{
    my ( $self, $message ) = @_;

    return unless ref( $self );  #  No logging if class method.
    $self->{ logger }->warning( $message ) if $self->{ logger };
}

sub error
{
    my $self = shift;
    my ( $message );

    $message = $self->_error_message( @_ );
    $self->log_error( $message );
    $self->fatal_exit( $message );
}

sub caller_error
{
    my $self = shift;
    my ( $message );

    $message = $self->_error_message( @_ );
    $self->log_error( $message );
    $self->caller_fatal_exit( $message );
}

sub fatal_exit
{
    my ( $self, $message ) = @_;

    die $message;
}

sub caller_fatal_exit
{
    my ( $self, $message ) = @_;

#  TODO: restore once Carp stops dying with:
#     Bizarre copy of HASH in sassign at [...]/Carp/Heavy.pm line 96.
#    croak $message;
    die $message;
}

sub warning
{
    my $self = shift;
    my ( $message );

    $message = $self->_error_message( @_ );
    $self->log_warning( $message );
    warn $message;
}

sub caller_warning
{
    my $self = shift;
    my ( $message );

    $message = $self->_error_message( @_ );
    $self->log_warning( $message );
    carp $message;
}

sub add_var
{
    my ( $self, $var, $value ) = @_;

    $self->caller_error(
        "Bad argument to add_var, expected top-level variable name, got: $var"
        )
        if $var =~ /\./o;

    $self->{ vars }->{ $var } = $value;
}

sub add_vars
{
    my ( $self, $vars ) = @_;
    my ( @bad_vars );

    $self->caller_error(
        "Bad var(s) in add_vars, expected top-level variable name, got: " .
        join( ', ', @bad_vars )
        )
        if @bad_vars = grep /\./o, keys( %{$vars} );

    foreach my $var ( keys( %{$vars} ) )
    {
        $self->{ vars }->{ $var } = $vars->{ $var };
    }
}

sub _var_value
{
    my ( $self, $var ) = @_;

    return( $self->{ vars }->{ $var } );
}

sub merge_var
{
    my ( $self, $var, $value, $ref ) = @_;

    $ref = $self->{ vars } unless $ref;

#CORE::warn( "merge_var( ",
#  Data::Dumper::Dumper( $var ), ", ",
#  Data::Dumper::Dumper( $value ), ", ",
#  Data::Dumper::Dumper( $ref->{ $var } ), ")\n" );

    unless( exists( $ref->{ $var } ) and ref( $value ) and
        ( ref( $value ) eq 'HASH' or ref( $value ) eq 'ARRAY' ) )
    {
#CORE::warn( "Doesn't exist, setting\n" );
        $ref->{ $var } = $value;
        return;
    }

    if( ref( $value ) eq 'HASH' )
    {
        foreach my $key ( keys( %{$value} ) )
        {
            $self->merge_var( $key, $value->{ $key }, $ref->{ $var } );
        }
    }
    elsif( ref( $value ) eq 'ARRAY' )
    {
        if( ref( $ref->{ $var } ) eq 'ARRAY' )
        {
            push @{$ref->{ $var }}, @{$value};
        }
        else
        {
            #  Ew, trying to merge array with non-array?
            #  TODO: error?
            $ref->{ $var } = $value;
        }
    }
}

sub merge_vars
{
    my ( $self, $vars ) = @_;

    foreach my $var ( keys( %{$vars} ) )
    {
        $self->merge_var( $var, $vars->{ $var } );
    }
}

sub clear_vars
{
    my ( $self ) = @_;

    $self->{ vars } = {};
}

sub _escape_string
{
    my ( $self, $string ) = @_;

    $string =~ s/\'/\\\'/go;
    return( $string );
}

sub _define_value
{
    my ( $self, $defines, $define, $default, $quote, $pos ) = @_;
    my ( $value );

#$self->warning( "replacing define '$define', default '$default', quote is $quote, pos '$pos'" );
    if( $self->{ seen_defines }->{ $define }++ )
    {
        $value = "[recursive define '$define']";
    }
    elsif( defined( $defines->{ $define } ) )
    {
        $value = $defines->{ $define };
    }
    elsif( defined( $default ) )
    {
        $value = $default;
    }
    else
    {
        $value = "[undefined preprocessor define '$define']";
    }

    $value = $self->_replace_defines( $value, $defines );
    $self->{ seen_defines }->{ $define }--;

    $value = "'" . $self->_escape_string( $value ) . "'" if $quote;

    if( defined( $pos ) )
    {
        my ( $lines, $definelen, $valuelen );

        $lines     = $value =~ tr/\n//;
        $definelen = 3 + ( $quote ? 2 : 0 ) + length( $define ) +
            ( defined( $default ) ? length( $default ) : 0 );
        $valuelen  = length( $value );

        if( $lines )
        {
            push @{$self->{ offsets }}, [ $pos, $valuelen, -$lines,
                $definelen - $valuelen,
                ]
        }
        else
        {
            push @{$self->{ offsets }}, [ $pos, $valuelen, 0,
                $definelen - $valuelen,
                ]
        }
    }

    return( $value );
}

sub _replace_defines
{
    my ( $self, $template_content, $defines ) = @_;
    my ( $top );

    #  Replace any preprocessor defines.
    unless( $self->{ seen_defines } )
    {
        $self->{ seen_defines } = {};
        $self->{ offsets } = [];
        $top = 1;
    }
    1 while $template_content =~ s/\$\{('?)([A-Z0-9_]+)(?::([^\}]*))?\1\}/
        $self->_define_value( $defines, $2, $3, $1,
            $top ? pos( $template_content ) : undef )/geox;
    if( $top )
    {
        delete $self->{ seen_defines };
        delete $self->{ offsets } unless @{$self->{ offsets }};
        if( $self->{ offsets } )
        {
            #  pos() gives us position in original string, we need to
            #  renumber to be position in replaced string.
            my $carry = 0;
            foreach my $offset ( @{$self->{ offsets }} )
            {
                $offset->[ 0 ] -= $carry;
                $carry += $offset->[ 3 ];
            }
#my $t = $template_content;
#foreach my $offset ( reverse( @{$self->{ offsets }} ) )
#{
#    substr( $t, $offset->[ 0 ] + $offset->[ 1 ], 0 ) = "XXX";
#    substr( $t, $offset->[ 0 ], 0 ) = "XXX";
#}
#print "Replaced template:\n$t\n";
#use Data::Dumper;
#print "Using offsets: " . Data::Dumper::Dumper( $self->{ offsets } ) . "\n";
        }
    }

    return( $template_content );
}

sub _read_template
{
    my ( $self, $filename, $defines ) = @_;
    my ( $fh, $template );

    push @{$self->{ dependencies }}, $filename;

    $fh = IO::File->new( $filename, '<' );
    #  TODO: $! can get trashed if $filename is interpolated - investigate
    #  TODO: is this perl 5.10.0's $! bug, or mine?
#    $self->caller_error( "Unable to read $filename: $!" ) unless $fh;
    $self->caller_error( "Unable to read ", $filename, ": $!" ) unless $fh;
    {
        local $/;
        $template = <$fh>;
    }
    $fh->close;

    #  Replace any preprocessor defines.
    $template = $self->_replace_defines( $template, $defines );

    return( $template );
}

sub _read_template_from_string
{
    my ( $self, $template, $defines ) = @_;

    #  Replace any preprocessor defines.
    $template = $self->_replace_defines( $template, $defines );

    return( $template );
}

#  Looks for combination of positional and named parameters to a syntax
#  token and returns a hashref of named parameters.
#  TODO: this is largely obsolete for everything except includes,
#  TODO: should be retired in favour of something specialized and faster.
sub _parse_args
{
    my ( $self, $args, $type ) = @_;
    my ( $count, %param, @words, @pos_param, @keyword_param, $instr,
         @positions, @valid, $syntax );

#    #  Heeeello hackery.
#    $args = "iterator=\"$1\" set=\"$2\""
#        if $type eq 'for' and $args =~ /^(.*) in (.*)$/o;

    $syntax = $self->{ local_syntaxes }->{ $type } || $syntaxes{ $type };

    @positions = $syntax->{ positional_args } ?
        @{$syntax->{ positional_args }} : ();
    @valid     = $syntax->{ valid_args } ? @{$syntax->{ valid_args }} : undef;

    %param = ();

    @words = split( /\s+/, $args );
    #  Merge quoted args.
#  TODO: rename instr to in_str for semantic clarity vs "instr"uction.
    $instr = 0;
    for( $count = 0; $count < @words; $count++ )
    {
        if( $instr )
        {
            $instr = 0 if $words[ $count ] =~ /\"$/;
            $words[ $count - 1 ] .= ' ' . $words[ $count ];
            @words =
                ( @words[ 0..$count - 1 ], @words[ $count + 1..@words - 1 ] );
            $count--;
        }
        else
        {
            next unless $words[ $count ] =~ /^\"/ or $words[ $count ] =~ /=\"/;
            next if $words[ $count ] =~ /\"$/;
            $instr = 1;
        }
    }

    #  Split into positional parameters and keyword paramaters.
    for( $count = 0; $count < @words; $count++ )
    {
        last if $words[ $count ] =~ /=/;
    }

    @pos_param     = $count ? @words[ 0..$count - 1 ]   : ();
    @keyword_param = $count < @words ?
        @words[ $count..@words - 1 ] : ();

    #  Squidge any "overshoot" positional param onto the final pos param.
    #  TODO: splice!
    @pos_param = ( @pos_param[ 0..@positions - 2 ],
        join( ' ', @pos_param[ @positions - 1..@pos_param - 1 ] ) )
        if @pos_param > @positions;

    $count = 0;
    foreach my $word ( @pos_param )
    {
        $word = $1 if $word =~ /^\"(.*)\"$/;
        $param{ $positions[ $count++ ] } = $word;
    }

    foreach my $word ( @keyword_param )
    {
        my ( $keyword, $value );

        ( $keyword, $value ) = split( /=/, $word, 2 );

        unless( defined( $value ) )
        {
            $self->error( "Undefined value for keyword: '$keyword' on " .
                "parse_args( $args, $type )" );
        }

        $value = $1 if $value =~ /^\"(.*)\"$/;

        #  TODO: validate arg names.
        $param{ $keyword } = $value;
    }

    return( { %param } );
}

sub _compile_template
{
    my ( $self ) = @_;
    my ( $i, @hunks, @files, @pos_stack, @nest_stack, @compiled, %includes,
         %trim, $trim_next, %file_numbers, @define_stack,
         $local_syntaxes, $local_token_aliases, $local_syntax_regexp,
         $hunk_regexp, $syntax_regexp,
         $open_delimiter, $close_delimiter, $open_regexp, $close_regexp );

    @files           = ( $self->{ filename } );
    %file_numbers    = ( $self->{ filename } => 0 );
    $self->{ files } = \@files;
    
    #  Stack of what position in which file we're currently at.
    @pos_stack    = ( [
        $file_numbers{ $self->{ filename } }, 1, 1, 0, $self->{ offsets },
        ] );
    delete $self->{ offsets };
    #  Stack of what defines are available.
    @define_stack = ( $self->{ defines } );
    #  Stack of unclosed block-level statements.
    @nest_stack   = ();
    #  The tokenized/compiled template.
    @compiled     = ();
    #  Files we're currently including.
    %includes     = ( $self->{ filename } => 1 );
    #  Stuff we're going to trim later.
    %trim         = ();

    $open_delimiter  = $self->{ open_delimiter }  || '<:';
    $close_delimiter = $self->{ close_delimiter } || ':>';

    $open_regexp  = qr/\Q$open_delimiter\E/;
    $close_regexp = qr/\Q$close_delimiter\E/;

    $local_token_aliases = $self->{ local_token_aliases } || {};
    $local_syntaxes      = $self->{ local_syntaxes } || {};

#  TODO: class-level syntax aliases
#  TODO: split into class/instance versions and unroll to construct time?
#  TODO: or generate-on-demand but class/instance copy invalidated on change.
    #  Egads!
    $local_syntax_regexp = join( ' | ',
        map { join( ' \s+ ', split( /\s+/, $_ ) ) }
        grep( /^[^\.]/,
            keys( %{$local_token_aliases} ), keys( %{$local_syntaxes} ),
            values( %{$syntaxes{ '.instr' }} ) ) );
    $local_syntax_regexp = ' | ' . $local_syntax_regexp
        if $local_syntax_regexp;

    $syntax_regexp = qr/(
          var | expr |
          (?:if|unless) | else? \s* (?:if|unless) | else |
          end \s* (?:if|unless) |
          for(?:each)? | end \s* for(?:each)? | end |
          include | end \s* include |
          \# |
          debug
          $local_syntax_regexp
        ) \s+
        /ix;
    $syntax_regexp = qr/(?:$syntax_regexp)?/ if $self->{ allow_bare_expr };
    $hunk_regexp = qr/^$open_regexp \s*
         $syntax_regexp (.*?) \s* $close_regexp (.+)? $/sx;

    @hunks = split( /(?=$open_regexp)/s, $self->{ template }, -1 );
    delete $self->{ template };

    $self->{ pos_stack } = \@pos_stack;
    $self->{ phase }     = 'compile';

#my ( $dumpme );
    for( $i = 0; $i < @hunks; $i++ )
    {
        my ( $hunk, $pos, $lines, $queue_pos, $last, $hunklen, $hunkstart,
             $offset_index );

        $hunk = $hunks[ $i ];

        $pos = [ @{$pos_stack[ 0 ]}[ 0..2 ] ];
        $self->{ current_pos } = $pos;

        if( $hunk =~ $hunk_regexp )
        {
            my ( $token, $syntax, $args, $rest );

            $token = lc( $1 || 'expr' );
            $args  = $2;
            $rest  = $3;

            #  TODO:  still possible?  What triggers it?
            #  error, unclosed token?
            $self->error( "unexepected $open_delimiter, ",
                "possibly unterminated $close_delimiter" )
                if $args =~ $open_regexp;

            if( defined( $rest ) )
            {
                $hunk =~ s/$close_regexp(?:.*)$/$close_delimiter/s;
                splice( @hunks, $i, 1, $hunk, $rest );
            }

            $token =~ s/\s+/ /go;

            if( $token eq 'end' )
            {
                $self->error( "end found without opening block" )
                    unless @nest_stack;
                $token = ( $nest_stack[ 0 ][ 0 ] eq FOR ) ?
                    'endfor' : 'endif';
            }

            $token = $local_token_aliases->{ $token }
                if $local_token_aliases->{ $token };
            $token = $token_aliases{ $token }
                if $token_aliases{ $token };
            $syntax = $local_syntaxes->{ $token } || $syntaxes{ $token };

            #  Fudge things a little so that flow-control tokens
            #  on a line by themselves don't produce a bunch of
            #  empty lines in the output.
            #  Are we a zero-width token on a line by itself?
            if( $syntax->{ zero_width } and
                $i < @hunks - 1 and
                ( ( not @compiled ) or
                  ( $compiled[ @compiled - 1 ]->[ 0 ] == LITERAL and
                    $compiled[ @compiled - 1 ]->[ 2 ] =~ /\n\ *$/ ) or
                  ( $compiled[ @compiled - 1 ]->[ 0 ] == CONTEXT_PUSH ) ) and
                $hunks[ $i + 1 ] =~ /^\n\ */ )
            {
                $trim_next = 1;
            }
            else
            {
                $trim_next = 0;
            }

            if( $syntax->{ compile } )
            {
                my ( $compiler, $opcode );

                $args = $self->_parse_args( $args, $token );

                $compiler = $syntax->{ compile };
                $opcode   = $syntax->{ instr };
                $args = $compiler->( $self, $token, $pos, $args );
                push @compiled, [ $opcode, $pos, $args ] if defined $args;
            }
            elsif( $token eq 'debug' )
            {
                $args = $self->_parse_args( $args, $token );

                $args = 0 unless keys( %{$args} );

                push @compiled,
                    [ DEBUG, $pos, $args ];
            }
            elsif( $token eq 'expr' or $token eq 'var' )
            {
                my ( $expr );

                $expr = $self->_compile_expression( $args );

                push @compiled,
                    [ EXPR, $pos, $expr,
                      #  Void-wrap assign expressions.
                      ( ( $expr->[ 0 ] == OP_TREE ) and
                        ( $expr->[ 2 ] eq '=' ) ) ? 1 : 0 ];
            }
            elsif( $token eq 'if' or $token eq 'unless' )
            {
                my ( $expr );

                $expr = $self->_compile_expression( $args );
                if( $token ne 'if' )
                {
                    if( $expr->[ 0 ] == LITERAL )
                    {
                        $expr->[ 2 ] = not $expr->[ 2 ];
                    }
                    else
                    {
                        $expr = [ UNARY_OP, 'unless', 'not', $expr ];
                    }
                }
                push @compiled,
                    [ JUMP_IF, $pos, undef, $expr ];
#                push @compiled,
#                    [ JUMP_IF, $pos, undef,
#                       $self->_compile_expression( $args ),
#                       $token eq 'if' ? 1 : 0 ];
                unshift @nest_stack, [ 'if', @compiled - 1 ];
            }
            elsif( $token eq 'elsif' or $token eq 'elsunless' )
            {
                my ( $expr );

                if( ( not @nest_stack ) or
                    ( $nest_stack[ 0 ][ 0 ] ne 'if' and
                      $nest_stack[ 0 ][ 0 ] ne 'elsif' ) )
                {
                    $self->error( "elsif found without opening if or elsif" );
                }
                #  Closing jump of previous block.
                push @compiled,
                    [ JUMP, $pos, undef ];

                $expr = $self->_compile_expression( $args );
                if( $token ne 'elsif' )
                {
                    if( $expr->[ 0 ] == LITERAL )
                    {
                        $expr->[ 2 ] = not $expr->[ 2 ];
                    }
                    else
                    {
                        $expr = [ UNARY_OP, 'elsunless', 'not', $expr ];
                    }
                }
                push @compiled, [ JUMP_IF, $pos, undef, $expr ];
#                push @compiled,
#                    [ JUMP_IF, $pos, undef,
#                       $self->_compile_expression( $args ),
#                       $token eq 'elsif' ? 1 : 0 ];
                #  Now, update jump address of previous if/elsif
                $compiled[ $nest_stack[ 0 ][ 1 ] ][ 2 ] =
                    @compiled - 1;
                unshift @nest_stack, [ 'elsif', @compiled - 1 ];
            }
            elsif( $token eq 'else' )
            {
                if( ( not @nest_stack ) or
                    ( $nest_stack[ 0 ][ 0 ] ne 'if' and
                      $nest_stack[ 0 ][ 0 ] ne 'elsif' ) )
                {
                    $self->error( "else found without opening if or elsif" );
                }
                #  Closing jump of previous block.
                push @compiled,
                    [ JUMP, $pos, undef ];
                #  Now, update jump address of previous if/elsif
                $compiled[ $nest_stack[ 0 ][ 1 ] ][ 2 ] = @compiled;
                unshift @nest_stack, [ 'else', scalar( @compiled ) ];
            }
            elsif( $token eq 'endif' or $token eq 'endunless' )
            {
                if( ( not @nest_stack ) or
                    ( $nest_stack[ 0 ][ 0 ] ne 'if' and
                      $nest_stack[ 0 ][ 0 ] ne 'elsif' and
                      $nest_stack[ 0 ][ 0 ] ne 'else' ) )
                {
                    $self->error(
                        "endif found without opening if, elsif or else" );
                }

                #  Update jump address of previous if/elsif
                $compiled[ $nest_stack[ 0 ][ 1 ] ][ 2 ] = @compiled
                    unless $nest_stack[ 0 ][ 0 ] eq 'else';

                while( @nest_stack )
                {
                    my $last = shift @nest_stack;

                    if( $last->[ 0 ] eq 'if' )
                    {
                        #  It's our opening if, stop popping.
                        last;
                    }
                    elsif( $last->[ 0 ] eq 'elsif' or $last->[ 0 ] eq 'else' )
                    {
                        #  Need to update the jump address of the closing
                        #  jump of the block _prior_ to this elsif/else.
                        $compiled[ $last->[ 1 ] - 1 ][ 2 ] = @compiled;
                    }
                    else
                    {
                        #  "cannot happen".
                        $self->error(
                            "nesting stack appears to be corrupted" );
                    }
                }
            }
            elsif( $token eq 'for' )
            {
                my ( $iterator, $set );

                #  TODO: syntax checking/error check needed here.
                ( $iterator, $set ) = $args =~ /^(.*) in (.*)$/io;

                push @compiled,
                    [ FOR, $pos, undef, $iterator,
                      $self->_compile_expression( $set ),
                      1 ];
                unshift @nest_stack, [ FOR, @compiled - 1 ];
            }
            elsif( $token eq 'endfor' )
            {
                if( ( not @nest_stack ) or
                    $nest_stack[ 0 ][ 0 ] ne FOR )
                {
                    $self->error(
                         "endfor found without opening for" );
                }

                my $last = shift @nest_stack;

                #  Grab our iterator and set from the opening for
                #  TODO: needed anymore?  run grabs it from for-stack.
                push @compiled,
                    [ END_FOR, $pos, $last->[ 1 ] + 1,
                      $compiled[ $last->[ 1 ] ][ 3 ],
                      $compiled[ $last->[ 1 ] ][ 4 ] ];
                #  Update jump address of opening for.
                $compiled[ $last->[ 1 ] ][ 2 ] = @compiled;
            }
            elsif( $token eq 'include' )
            {
                my ( $filename, $inc_template, @inc_hunks, %defines );

                #  We support var renaming:
                #  ie: <: include pagerwidget offset=param.offset
                #         total=results.__size__ pagesize=param.n :>

                $args = $self->_parse_args( $args, 'include' );

                #  Extract the filename.
                #  If the filename is empty-string then we ignore the
                #  include statement, allowing us to do things like
                #  <: include ${DEFINE:} :> without knowing if the define
                #  exists or not.
                if( $filename = $args->{ filename } )
                {
                    my ( $volume, $current_dir );

                    delete $args->{ filename };

                    ( $volume, $current_dir ) = File::Spec->splitpath(
                        $define_stack[ 0 ]->{ FILENAME } );
                    #  Make sure volume is part of the current dir so
                    #  windows doesn't choke.
                    $current_dir = File::Spec->catpath(
                        $volume, $current_dir, '' );

                    %defines = %{$define_stack[ 0 ]};

                    $self->{ defines } = \%defines;
                    unshift @define_stack, \%defines;

                    #  Parse out any defines.
                    foreach my $key (
                        grep { $_ eq uc( $_ ) } keys( %{$args} ) )
                    {
                        $defines{ $key } = $args->{ $key };
                        delete $args->{ $key };
                    }
                    $args = { map
                        { $_ => $self->_compile_expression( $args->{ $_ } ) }
                        keys( %{$args} ) };
                    $args = 0 unless keys( %{$args} );

                    $filename = $self->find_include( $filename, $current_dir );

                    $self->error( "recursive include of $filename" )
                        if $includes{ $filename };

                    $defines{ FILENAME } = $filename;

                    $includes{ $filename } = 1;
                    $inc_template =
                        $self->_read_template( $filename, \%defines );
                    $inc_template =~ s/\n$//;
                    @inc_hunks = split( /(?=<:)/, $inc_template, -1 );
                    $inc_template = 0;

                    splice( @hunks, $i + 1, 0,
                        @inc_hunks, '<: endinclude :>' );

                    push @compiled,
                        [ CONTEXT_PUSH, $pos, $args ];
                    unless( exists( $file_numbers{ $filename } ) )
                    {
                        $file_numbers{ $filename } = @files;
                        push @files, $filename;
                    }
                    $queue_pos = [ $file_numbers{ $filename }, 1, 1, 0,
                        $self->{ offsets } ];
                    delete $self->{ offsets };
                }
            }
            elsif( $token eq 'endinclude' )
            {
                #  <: endinclude :> is a faux-token, it never gets read
                #  in from a template (isn't valid syntax even), but gets
                #  inserted to mark the end of the inserted hunks from
                #  an <: include :>
                #  "cannot happen".
                $self->error( "endinclude found while not within an include" )
                    unless @pos_stack;

                my $last = shift @pos_stack;
                delete $includes{ $files[ $last->[ 0 ] ] };
                shift @define_stack;
                $self->{ defines } = $define_stack[ 0 ];
                push @compiled,
                    [ CONTEXT_POP, $pos ];
                next;  #  So we don't update pos with this faux-token.
            }
            elsif( $token eq '#' )
            {
                #  We're a comment, don't compile it.
            }
            else
            {
                #  Shouldn't be possible to get through the regexp to this.
                $self->error( "unrecognised token ($token)" );
            }
        }
        else
        {
            #  We're a literal unless we're a malformed token
            if( $hunk =~ /^$open_regexp/ )
            {
                #  Trim bits after the close token if there is one,
                #  makes a clearer error message.
                $hunk =~ s/($close_regexp).*$/$1/;
                $self->error( "unrecognised token ($hunk)" );
            }
            if( length( $hunk ) )
            {
                $trim{ @compiled } = 1 if $trim_next;
                push @compiled, [ LITERAL, $pos, $hunk ];
            }
            $trim_next = 0;
        }

# +--------------------+------------------------+-----------------------------+
# |  define >          |           nl           |         !nl                 |
# +--- hunk v ---------+------------------------+-----------------------------+
# |        !nl         |   not possible (1)     | offsets: char               |
# |  nl after defines  |  offsets: nl, !char    | offsets: nl, !char (no-op)  |
# | nl before defines  | offset: nl             | offsets: char               |
# |                    | char:                  |                             |
# |                    |  chars between nl &    |                             |
# |                    |  start of define (2) + |                             |
# |                    |  original define len + |                             |
# |                    |  chars after define    |                             |
# | nl between defines |      treat in reverse series as after/before         |
# +--------------------+------------------------+-----------------------------+
#
#  TODO: (1) define spans hunks? (add test case!)
#  TODO: define spans defines?   (add test case!)
#  (2) characters is "fudged count", there may be other defines there. :(
#
# Detection:
#   nl in define: nl offset != 0
#   nl in hunk: nl in final hunk != total nl in offsets
#


        #  Update pos.
        $hunklen    = length( $hunk );
        $pos        = $pos_stack[ 0 ];
        $hunkstart  = $pos->[ 3 ];
        $pos->[ 3 ] += $hunklen;

#use Data::Dumper;
#print "After hunk: xxx${hunk}xxx\nPos is: " . Data::Dumper::Dumper( $pos ) . "\n";

        #  Do we have offsets, and have we just passed one?
        $offset_index = -1;
        while( $pos->[ 4 ] and $offset_index < @{$pos->[ 4 ]} - 1 and
               $pos->[ 4 ]->[ $offset_index + 1 ]->[ 0 ] <= $pos->[ 3 ] )
        {
            my ( $offset );

            $offset_index++;
            $offset = $pos->[ 4 ]->[ $offset_index ];
            #  Replace any newlines in the section that was the contents
            #  of a define, this is so that they don't count towards line
            #  counts or finding the "most recent newline" for character
            #  position counts.
            #  This is inelegant but much simpler (and possibly faster)
            #  than trying to compensate and find the "right" newline
            #  to count from, especially since defines containing newlines
            #  are hopefully a corner-case.
#print "Offset index: $offset_index\nOffset: " . Data::Dumper::Dumper( $offset ) . "\n";
#print "substr( hunk, " . ( $offset->[ 0 ] - $hunkstart ) . ", " . ( $offset->[ 1 ] ) . " )\n" if $offset->[ 2 ];

            substr( $hunk, $offset->[ 0 ] - $hunkstart, $offset->[ 1 ] ) =~
                s/\n/ /go
                if $offset->[ 2 ];
        }

#        $lines = () = $hunk =~ /\n/g;
#        $lines = $#{ [ $hunk =~ /\n/g ] } + 1;
        $lines   = $hunk =~ tr/\n//;
        if( $lines )
        {
            $pos->[ 1 ] += $lines;
            $pos->[ 2 ] =
                ( $hunk =~ /\n(.+)\z/mo ) ? ( length( $1 ) + 1 ) : 1;
        }
        else
        {
            $pos->[ 2 ] += $hunklen;
        }

        if( $offset_index != -1 )
        {
            my ( @offsets, $nlpos );

            @offsets = splice( @{$pos->[ 4 ]}, 0, $offset_index + 1 );
            $pos->[ 4 ] = undef unless @{$pos->[ 4 ]};

            $nlpos = $lines ? ( $pos->[ 3 ] - $pos->[ 2 ] ) : 0;

            foreach my $offset ( @offsets )
            {
                #  Don't apply the offset if it was before the final
                #  non-define newline
                next if $offset->[ 0 ] < $nlpos;
#use Data::Dumper;
#print "Applying offset: " . Data::Dumper::Dumper( $offset ) . "\n";
#                $pos->[ 1 ] += $offset->[ 2 ];
                $pos->[ 2 ] += $offset->[ 3 ];
            }
        }

        unshift @pos_stack, $queue_pos if $queue_pos;
    }

    $self->error( "unterminated if or for block" ) if @nest_stack;

    #  "cannot happen".
    $self->error( "include stack not empty, corrupted?" ) if @pos_stack > 1;

    #  TODO: scan for undef jump addresses.

    foreach my $addr ( keys( %trim ) )
    {
        #  "cannot happen".
        $self->error( "trim on non-literal, trim-stack corrupted?" )
            unless $compiled[ $addr ]->[ 0 ] == LITERAL;
        $compiled[ $addr ]->[ 2 ] =~ s/^\n//o;
    }

    #  We're done.
#    $self->{ template } = {
#            program => [ @compiled ],
#            files   => [ @files ],
#        };
    $self->{ template } = {
            program => \@compiled,
            files   => \@files,
        };
    $self->_optimize_template();
    $self->{ template }->{ last_instr } =
        @{$self->{ template }->{ program }} - 1;

    delete $self->{ current_pos };
    delete $self->{ pos_stack };
    delete $self->{ files };
    delete $self->{ phase };

#$dumpme = 1;
#use CGI;
#print CGI->header('text/plain');

#if( $dumpme )
#{
#print "\n----\n" . $self->dumpable_template() . "----\n";
#exit(0);
#}
}

sub _optimize_template
{
    my ( $self ) = @_;
    my ( $program, @nest_stack, %deletes, %jump_targets, @loop_blocks,
         $value );

#    my ( @function_table, %function_index );

    #  Optimization pass:
    #    TODO: unroll constant low-count fors?

    $program = $self->{ template }->{ program };

    #  Fold constant expr into constant instr.
    for( my $i = 0; $i < @{$program}; $i++ )
    {
        #  Are we an EXPR instr and is our expr a LITERAL expr?
        next unless $program->[ $i ]->[ 0 ] == EXPR and
                    $program->[ $i ]->[ 2 ]->[ 0 ] == LITERAL;

#warn "Folding literal expr $i (val: " . $program->[ $i ]->[ 2 ]->[ 2 ] . ") (orig: " . $program->[ $i ]->[ 2 ]->[ 1 ] . ") into literal instr.";

        $program->[ $i ]->[ 0 ] = LITERAL;
        $program->[ $i ]->[ 2 ] = $program->[ $i ]->[ 2 ]->[ 2 ];
    }


    #  Fold constant JUMP_IF into JUMP or delete.
    %deletes    = ();
    for( my $i = 0; $i < @{$program}; $i++ )
    {
        next unless $program->[ $i ]->[ 0 ] == JUMP_IF and
                    $program->[ $i ]->[ 3 ]->[ 0 ] == LITERAL;

        $value = $self->_eval_expression( $program->[ $i ]->[ 3 ], 1 );
#        $value = not $value if $program->[ $i ]->[ 4 ];

        if( $value )
        {
            #  Always true, remove the JUMP.
#warn "Folding constant JUMP_IF into no-op.";
            $deletes{ $i } = 1;
        }
        else
        {
            #  Always false, fold it into a JUMP.
#warn "Folding constant JUMP_IF into JUMP.";
            $program->[ $i ] = [ JUMP, $program->[ $i ]->[ 1 ],
                $program->[ $i ]->[ 2 ] ];
        }
    }
    $self->_delete_instr( $program, keys( %deletes ) ) if %deletes;


    #  Trim empty context pushes (TODO: that have no assigns in top level)
    %deletes    = ();
    @nest_stack = ();
    for( my $i = 0; $i < @{$program}; $i++ )
    {
        if( $program->[ $i ]->[ 0 ] == CONTEXT_PUSH )
        {
            unshift @nest_stack, $i;
            $deletes{ $i } = 1 unless $program->[ $i ]->[ 2 ];
            next;
        }
        if( $program->[ $i ]->[ 0 ] == CONTEXT_POP )
        {
            my ( $match );

            $match = shift @nest_stack;
            $deletes{ $i } = 1 if $deletes{ $match };
            next;
        }
    }
    $self->_delete_instr( $program, keys( %deletes ) ) if %deletes;


    #  Now scan for adjacent literals to merge where the second
    #  isn't a jump target.
    %deletes = ();

    #  For speed, prebuild a list of all jump targets.
    %jump_targets = ();
    foreach my $line ( @{$program} )
    {
        next unless $line->[ 0 ] == JUMP or
                    $line->[ 0 ] == JUMP_IF or
                    $line->[ 0 ] == FOR or
                    $line->[ 0 ] == END_FOR;
        $jump_targets{ $line->[ 2 ] } = 1;
    }

    #  Now scan for adjacent literals.
    for( my $i = @{$program} - 1; $i > 0; $i-- )
    {
        #  Are both ourself and our previous instr a literal?
        next if $program->[ $i ]->[ 0 ]     != LITERAL or
                $program->[ $i - 1 ]->[ 0 ] != LITERAL;

        #  Do any jumps lead to the second literal?
        next if $jump_targets{ $i };

#warn "Merging literal $i to previous.";
#warn "Merging literals [" . $program->[ $i - 1 ]->[ 2 ] . "] and [" . $program->[ $i ]->[ 2 ] . "]";

        #  Ok, no reason for us to remain apart, let's get married.
        $program->[ $i - 1 ]->[ 2 ] .= $program->[ $i ]->[ 2 ];
        $deletes{ $i } = 1;
    }
#warn "Literal merges: " . scalar( keys( %deletes ) );
    $self->_delete_instr( $program, keys( %deletes ) ) if %deletes;

    #  Look for loops that make no use of special loop vars.
    @loop_blocks = ();
    for( my $i = 0; $i < @{$program}; $i++ )
    {
        #  Are we a for statement?
        next if $program->[ $i ]->[ 0 ] != FOR;
        push @loop_blocks,
            [ $i, $program->[ $i ]->[ 2 ], $program->[ $i ]->[ 3 ] ];
    }
    #  TODO: this should be moved into the above loop to keep it single-pass.
    foreach my $block ( @loop_blocks )
    {
        my ( $special_vars_needed, $line );

        $special_vars_needed = 0;
        FORBLOCK: for( my $i = $block->[ 0 ] + 1; $i < $block->[ 1 ]; $i++ )
        {
            my ( @exprs );

            $line = $program->[ $i ];
            if( $line->[ 0 ] == EXPR )
            {
                @exprs = ( $line->[ 2 ] );
            }
            elsif( $line->[ 0 ] == FOR )
            {
                @exprs = ( $line->[ 4 ] );
            }
            elsif( $line->[ 0 ] == JUMP_IF )
            {
                @exprs = ( $line->[ 3 ] );
            }
            elsif( $line->[ 0 ] == CONTEXT_PUSH )
            {
                @exprs = values( %{$line->[ 2 ]} );
            }

            next unless @exprs;

            while( my $expr = shift( @exprs ) )
            {
                my ( $type );

                $type = $expr->[ 0 ];
                if( $type == VAR )
                {
                    my ( $segments );

                    $segments = $expr->[ 2 ];
                    #  Needs to have two or more segments.
                    next unless $expr->[ 4 ] > 0;
                    #  Top stem isn't our loop var, we're not interested.
                    next unless $segments->[ 0 ] eq $block->[ 2 ];

                    #  OK, it's refering to our loop var, is it a special?
                    if( ref( $segments->[ 1 ] ) or
                        exists( $special_values_names{ $segments->[ 1 ] } ) )
                    {
                        #  Yes, it's either a special or an inconstant
                        #  expression subscript that we can't rule out
                        #  as evaluating to a special at runtime.
                        $special_vars_needed = 1;
                        last FORBLOCK;
                    }
                }
                elsif( $type == OP_TREE )
                {
                    push @exprs, $expr->[ 3 ], $expr->[ 4 ];
                }
                elsif( $type == UNARY_OP )
                {
                    push @exprs, $expr->[ 3 ];
                }
                elsif( $type == FUNC )
                {
                    push @exprs, @{$expr->[ 3 ]};
                }
                elsif( $type == METHOD )
                {
                    push @exprs, @{$expr->[ 4 ]};
                }
            }
        }
        $program->[ $block->[ 0 ] ]->[ 5 ] = 0 unless $special_vars_needed;
    }


#    #  walk program looking for functions, adding to function table.
#    #  NOTE: turned out to not make a difference in run-time, but may revisit.
#    @function_table = ();
#    %function_index = ();
#    foreach my $line ( @{$program} )
#    {
#        my ( $op, @op_queue );
#        @op_queue = ();
#
#        if( $line->[ 0 ] == EXPR )
#        {
#            push @op_queue, $line->[ 2 ];
#        }
#        elsif( $line->[ 0 ] == JUMP_IF )
#        {
#            push @op_queue, $line->[ 3 ];
#        }
#        elsif( $line->[ 0 ] == URL )
#        {
#            push @op_queue, %{$line->[ 2 ]};
#        }
#        elsif( $line->[ 0 ] == FOR )
#        {
#            push @op_queue, $line->[ 4 ];
#        }
#        elsif( $line->[ 0 ] == CONTEXT_PUSH )
#        {
#            push @op_queue, values( %{$line->[ 2 ]} );
#        }
#        while( defined( $op = shift( @op_queue ) ) )
#        {
#            next if not ref( $op ) or $op->[ 0 ] == VAR or
#                    $op->[ 0 ] == LITERAL or $op->[ 0 ] == TEMPLATE;
#            if( $op->[ 0 ] == OP_TREE )
#            {
#                push @op_queue, $op->[ 3 ], $op->[ 4 ];
#                next;
#            }
#            if( $op->[ 0 ] == UNARY_OP )
#            {
#                push @op_queue, $op->[ 3 ];
#                next;
#            }
#            if( $op->[ 0 ] == METHOD )
#            {
#                push @op_queue, @{$op->[ 4 ]};
#                next;
#            }
#            $self->error( "Unknown EXPR opcode: " . $op->[ 0 ] .
#                " in function table construction." )
#                unless $op->[ 0 ] == FUNC;
#
##warn "Looking at op " . _tinydump( $op );
##warn "  Is function $op->[ 2 ]().";
#            if( not $function_index{ $op->[ 2 ] } )
#            {
#                push @function_table, $op->[ 2 ];
#                $function_index{ $op->[ 2 ] } = $#function_table;
#            }
#            $op->[ 2 ] = $function_index{ $op->[ 2 ] };
##warn "  Replaced with $op->[ 2 ].";
#            push @op_queue, @{$op->[ 3 ]};
#        }
#    }
#    $template->{ function_table } = [ @function_table ];
}

#  Warning, pass-by-ref: modifies $program.
sub _delete_instr
{
    my ( $self, $program, @addrs ) = @_;
    my ( %renumbers, $instr, $num, $lastnum, $lastoffset, $offset, $numaddr );

#warn "** Deleting instr: " . join( ', ', @addrs ) . ".";
#warn "-- Pre:\n" . $self->dumpable_template();

    #  Delete all the stuff we've marked for deletion.

    #  First we need to sort the deletes.
    @addrs = sort { $a <=> $b } @addrs;

    #  Then we delete the instructions from last to first.
    #  (To avoid renumbering issues).
    foreach my $addr ( reverse( @addrs ) )
    {
        splice( @{$program}, $addr, 1 );
    }

#warn "-- Deleted:\n" . $self->dumpable_template();

    #  Now we need to renumber any jump and loop targets affected.
    %renumbers = ();
    $lastnum = $lastoffset = 0;
    $numaddr = @addrs - 1;
    foreach my $line ( @{$program} )
    {
        next unless ( $instr = $line->[ 0 ] ) == JUMP or
                      $instr == JUMP_IF or
                      $instr == FOR     or
                      $instr == END_FOR;

        if( exists( $renumbers{ $num = $line->[ 2 ] } ) )
        {
            $line->[ 2 ] = $renumbers{ $num };
            next;
        }

        #  This contraption takes advantages of the fact that jumps
        #  tend to have fairly local targets to other local jumps'
        #  targets, rather than searching from the start of the
        #  template each time.
        if( $lastnum <= $num )
        {
#use Data::Dumper;
#print "Jump target: $num.\nDeleted: ", Data::Dumper::Dumper( \@addrs ), "\n";
            #  This jump is forwards from our last, search forwards.
            for( $offset = $lastoffset; $offset <= $numaddr; $offset++ )
            {
#print "  Offset is $offset, addrs[ $offset ] is $addrs[ $offset ]\n";
                last if $addrs[ $offset ] >= $num;
            }
        }
        else
        {
            #  This jump is before our last, search backwards.
            for( $offset = $lastoffset; $offset > 0; $offset-- )
            {
                last if $addrs[ $offset - 1 ] < $num;
            }
        }
        $lastnum    = $num;
        $lastoffset = $offset;

        #  Cache the result, if-elsif-else will have lots of the same targets.
        $renumbers{ $num } = ( $line->[ 2 ] -= $offset );
    }

#warn "-- Renumbered:\n" . $self->dumpable_template();
}

sub _compile_expression
{
    my ( $self, $expression ) = @_;
    my ( @top_level, $highest_weight, $highest_pos );

    $expression =~ s/^\s+//;
    $expression =~ s/\s+$//;

    $self->error( "Not a well-formed expression: $expression" )
        unless $expression =~ /^$expr_regexp$/so;

    while( $expression =~ $capture_expr_op_remain_regexp )
    {
        # $lhs = $1;
        # $op  = $2;
        # $rhs = $3;
        push @top_level, $1, $2;
        $expression = $3;
    }

    return( $self->_build_op_tree( [ @top_level, $expression ] ) )
        if @top_level;

    #  Not a compound statement, must be atomic.

    #  Is it a unary op?
    if( my ( $op, $subexpr ) =
            $expression =~ $capture_unary_operator_regexp )
    {
        $subexpr = $self->_compile_expression( $subexpr );

        #  Fold constant values.
        return( [ LITERAL, $expression,
            $self->_eval_unary_op( $op, $subexpr ) ] )
            if $subexpr->[ 0 ] == LITERAL;

        return( [ UNARY_OP, $expression, $op, $subexpr ] );
    }

    #  Is it a bracketed expression?
    #  TODO: Do I care at this point if it's matching?
#    return( $self->_compile_expression( substr( $expression, 1, -1 ) ) )
#        if $expression =~ /^$matching_round_brackets_regexp$/so;
    return( $self->_compile_expression( $1 ) )
        if $expression =~ /^\((.*)\)$/so;

    #  A literal number
    return( [ LITERAL, $expression, $expression, 0 ] )
        if $expression =~ /^$literal_number_regexp$/so;

    #  A literal string
    if( $expression =~ /^$single_quoted_text_regexp$/so )
    {
        my ( $string );

        #  Strip leading/trailing ' and unescape backslashed characters.
        $string = substr( $expression, 1, -1 );
        $string =~ s/\\(.)/$1/go;
        return( [ LITERAL, $expression, $string, 0 ] );
    }

    #  A variable or chained construct (including functions)
    return( $self->_compile_chained_operation( $expression ) )
        if $expression =~ /^$chained_operation_regexp$/so;

    #  "cannot happen".
    $self->error( "Unrecognised atomic expression element: $expression" );
}

#  TODO: replace with "replace tightest-binding operator with subtree"
#        while-loop, rather than recursive divide-and-conquer by
#        loosest-binding operator.
#        will eleminate the depth*depth cartesian loops.
sub _build_op_tree
{
    my ( $self, $arr ) = @_;
    my ( $highest_weight, $highest_pos, $op, $lhs, $rhs );

#print "build_op_tree( ", Data::Dumper::Dumper( $arr ), "\n";

    #  "cannot happen"
    $self->error( "Empty expression" ) unless @{$arr};

#  TODO: cache @{$arr} size.
    for( my $i = 0; $i < @{$arr}; $i += 2 )
    {
        #  TODO: this is a crappy hack to provide compat with recursion.
        next if ref( $arr->[ $i ] );
        $arr->[ $i ] = $self->_compile_expression( $arr->[ $i ] );
    }

    return( $arr->[ 0 ] ) if @{$arr} == 1;

    #  Look for literals to fold together.
#print "Looking at: ", Data::Dumper::Dumper( $arr ), "\n";
    for( my $i = 1; $i < @{$arr} - 1; $i += 2 )
    {
        my ( $op, $weight );

        $op = $arr->[ $i ];
        $weight = $operators{ $op }->[ 0 ];

        $lhs = $arr->[ $i - 1 ];
        $rhs = $arr->[ $i + 1 ];

#print "  Looking at op $i: '$op'\n";
        #  If we're higher or equal precedence to the operators either
        #  side of us, and our lhs and rhs are literal values, we're
        #  eligible for folding.
        if( ( ( $i < 3 ) or
              ( $weight <= $operators{ $arr->[ $i - 2 ] }->[ 0 ] ) ) and
            ( ( $i >= @{$arr} - 2 ) or
              ( $weight <= $operators{ $arr->[ $i + 2 ] }->[ 0 ] ) ) and
            ( $lhs->[ 0 ] == LITERAL ) and ( $rhs->[ 0 ] == LITERAL ) )
        {
            my ( $original );

            #  Rebuild of "original" is surely hackery of the finest order. :(
            $original = ( $lhs->[ 3 ] ? "( $lhs->[ 1 ] )" : $lhs->[ 1 ] ) .
                " $op " .
                ( $rhs->[ 3 ] ? "( $rhs->[ 1 ] )" : $rhs->[ 1 ] );

            splice( @{$arr}, $i - 1, 3,
                [ LITERAL, $original,
                  $self->_eval_op( $op, $lhs, $rhs ), 1 ] );
            $i = ( $i <= 3 ) ? 1 : $i - 4;
#print "  Folding, arr becomes: ", Data::Dumper::Dumper( $arr ), ", i = $i\n";
        }
    }

    return( $arr->[ 0 ] ) if @{$arr} == 1;

    $highest_weight = 0;
    for( my $i = 1; $i < @{$arr} - 1; $i += 2 )
    {
        my ( $op );

        $op = $arr->[ $i ];
#print "looking at op $i: $op\n";
        if( $operators{ $op }->[ 0 ] > $highest_weight )
        {
            $highest_weight = $operators{ $op }->[ 0 ];
            $highest_pos    = $i;
        }
    }
#print "highest_pos = $highest_pos, highest_op = $highest_op\n";

    $op  = $arr->[ $highest_pos ];
    $lhs = $self->_build_op_tree( [ @{$arr}[ 0..$highest_pos - 1 ] ] );
    $rhs = $self->_build_op_tree( [ @{$arr}[ $highest_pos + 1..@{$arr} - 1 ] ] );

    return( [ OP_TREE, '', $op, $lhs, $rhs ] );
}

sub _build_var
{
    my ( $self, $segments, $originals, $original ) = @_;
    my @segments  = @{$segments};
    my @originals = @{$originals};

    #  If we're just a subexpression with no subscripts, just return
    #  the subexpression.
    return( $segments[ 0 ] )
        if @segments == 1 and ref( $segments[ 0 ] );

    if( $segments[ @segments - 1 ] eq '__size__' )
    {
        pop @segments;
        pop @originals;
        return( [ FUNC, $original, 'size',
            [ $self->_build_var( \@segments, \@originals, $original ) ],
            ] );
    }

    return( [ VAR, $original, \@segments, \@originals, @segments - 1 ] );
}

sub _compile_chained_operation
{
    my ( $self, $chain ) = @_;
    my ( $original, $original_so_far, @segments, @originals, $segment,
         $subscript );

#print "compile_chained_operation( $chain )\n";

    return( $symbolic_literals{ $chain } )
        if exists( $symbolic_literals{ $chain } );


    $original = $chain;

    @segments = @originals = ();
    if( ( $segment, $chain ) =
            $chain =~ $capture_chained_operation_top_regexp )
    {
#        $segment = $1;
#        $chain   = $2 || '';
        $original_so_far = $segment;

#print "Capture top on '$original', segment '$segment', chain '$chain'\n";

        if( $segment =~ $capture_function_regexp )
        {
            push @originals, $segment;
            $segment = $self->_compile_function( $1, $2, $original );
            return( $segment ) unless $chain;
            $segment = $segment->[ 2 ] if $segment->[ 0 ] == LITERAL;
            push @segments, $segment;
        }
        else
        {
            push @segments, $segment;
            push @originals, $segment;
        }
    }
    else
    {
        #  TODO FIXME: error.
        die "FIXME";
    }

    while( $chain and
           ( $segment, $chain ) =
                $chain =~ $capture_chained_operation_subscript_regexp )
    {
#        $segment = $1;
#        $chain   = $2 || '';
#print "Segment: $segment\nRest: $chain\n";

        #  TODO: use a capture rather than m// and s///
        if( $segment =~ $capture_literal_subscript_regexp )
        {
#print "  Literal\n";
            $original_so_far .= $segment;
            push @segments,  $1;
            push @originals, $1;
            next;
        }
        if( ( $subscript ) = $segment =~ $capture_expr_subscript_regexp )
        {
#print "  Expr\n";
            #  var[ ... ] expression subscript notation.

            $original_so_far .= $segment;
#            $subscript = $1;
            my $index = $self->_compile_expression( $subscript );

            #  If it's a constant push it up as if it
            #  was a dotted literal index.
            if( $index->[ 0 ] == LITERAL )
            {
                push @segments, $index->[ 2 ];
            }
            else
            {
                push @segments, $index;
            }
#            $subscript =~ s/^\s+//o;
#            $subscript =~ s/\s+$//o;
            push @originals, $subscript;
            next;
        }
        #  TODO: use a capture rather than m// and s///
        if( my ( $method, $args ) =
                $segment =~ $capture_method_subscript_regexp )
        {
#print "  Method\n";

            my $var = $self->_build_var( \@segments, \@originals,
                $original_so_far );

            if( $self->{ vmethods } )
            {
                #  We convert "vmethods" into our normal function style.

                my $func = $self->_compile_function(
                    $method, $args, $original, [ $var ] );

                #  Fold if it's a literal.
                $func = $func->[ 2 ] if $func->[ 0 ] == LITERAL;
                @segments = ( $func );
            }
            else
            {
                $args = $self->_compile_function_args( $args );
                @segments  = ( [ METHOD, $original, $var, $method, $args ] );
            }
            @originals = ( $original_so_far );
            $original_so_far .= $segment;
            next;
        }
        #  TODO FIXME: error.
        die "FIXME";
    }

    $self->error( "Malformed variable segment: '$chain' in '$original'" )
        if $chain;

    return( $self->_build_var( \@segments, \@originals, $original ) );
}

sub _compile_function
{
    my ( $self, $func, $args, $expression, $prepend_args ) = @_;
    my ( $numargs, $func_def );

#    $args = length( $args) > 2 ? substr( $args, 1, -2 ) : '';

    $func_def = $functions{ $func } if $functions{ $func };
    $func_def = $self->{ local_functions }->{ $func }
        if $self->{ local_functions } and
           $self->{ local_functions }->{ $func };

    $self->error( "Unknown function: $func" ) unless $func_def;

    $args = $self->_compile_function_args( $args );
    unshift @{$args}, @{$prepend_args} if $prepend_args;

    #  Check the number of args.
    if( ( $numargs = $func_def->[ FUNC_ARG_NUM ] ) >= 0 )
    {
        $self->error( "too few args to $func(), expected $numargs " .
            "and got " . @{$args} . " in $expression" )
            if @{$args} < $numargs;
        $self->error( "too many args to $func(), expected $numargs " .
            "and got " . @{$args} . " in $expression" )
            if @{$args} > $numargs;
    }

    unless( $func_def->[ FUNC_INCONST ] )
    {
        my ( $nonliteral );

        foreach my $arg ( @{$args} )
        {
            next if $arg->[ 0 ] == LITERAL;
            $nonliteral = 1;
            last;
        }

#CORE::warn( "$expression has " . ( $nonliteral ? "nonliteral" : "literal" ) . " args" );
        unless( $nonliteral )
        {
            my ( $ret );

            $ret = $self->_eval_function( $func, $args );

            return( [ LITERAL, $expression,
                ( ( ref( $ret ) eq 'SCALAR' ) ? ${$ret} : $ret ), 1 ] );
        }
    }

    unshift @{$args}, [ TEMPLATE ]
        if $func_def->[ FUNC_NEEDS_TEMPLATE ];

    return( [ FUNC, $expression, $func, $args ] );
}

sub _compile_function_args
{
    my ( $self, $arglist ) = @_;
    my ( $original, @args, $nextarg );

    $arglist =~ s/^\s+//;
    $arglist =~ s/\s+$//;

    $original = $arglist;

    @args = ();
    while( defined( $arglist ) and length( $arglist ) and
        ( $nextarg, $arglist ) =
            ( $arglist =~ $capture_expr_comma_remain_regexp ) )
    {
#        $nextarg = $1;
#        $arglist = $2;
        push @args, $self->_compile_expression( $nextarg );
    }
    $self->error(
        "Malformed function arguments list: '$arglist' in '$original'" )
        if $arglist;
    return( \@args );
}

sub _eval_expression
{
    my ( $self, $expr, $undef_ok ) = @_;
    my ( $type, $val );

#  "can't happen" in normal use, will error on next line anyway.
#    $self->error( "Bad arg to _eval_expression(): $expr" )
#        unless ref( $expr );

#$self->{ exprcount }->{ $type }++;
#my $exprstart = Time::HiRes::time();
    if( ( $type = $expr->[ 0 ] ) == LITERAL )
    {
        $val = $expr->[ 2 ];
    }
    elsif( $type == VAR )
    {
        $val = $self->_eval_var( @{$expr}, $undef_ok );
    }
    elsif( $type == OP_TREE )
    {
#        $val = $self->_eval_op( $expr->[ 2 ], $expr->[ 3 ], $expr->[ 4 ] );
        #  WARNING: this is unrolled below from _eval_op: keep in sync.
#eval
#{
        $val = $operators{ $expr->[ 2 ] };
        #  Do we defer evaluation or not?
        if( $val->[ 2 ] )
        {
            $val = $val->[ 1 ]->( $self, $expr->[ 3 ], $expr->[ 4 ] );
        }
        else
        {
            $val = $val->[ 1 ]->( $self,
                $self->_eval_expression( $expr->[ 3 ] ),
                $self->_eval_expression( $expr->[ 4 ] ) );
        }
#};
#$self->error( "$@" ) if $@;
    }
    elsif( $type == UNARY_OP )
    {
        #  TODO: unroll?  common enough to bother?
        $val = $self->_eval_unary_op( $expr->[ 2 ], $expr->[ 3 ] );
    }
    elsif( $type == FUNC )
    {
#        $val = $self->_eval_function( $expr->[ 2 ], $expr->[ 3 ] );
        #  WARNING: this is unrolled below from _eval_function: keep in sync.

#warn "Eval func $expr->[ 2 ] against " . _tinydump( [ @function_table ] );
#        $val = $function_table[ $expr->[ 2 ] ];

        #  TODO: should copy_global_functions block class-function lookup?
        $val = $functions{ $expr->[ 2 ] } if $functions{ $expr->[ 2 ] };
        $val = $self->{ local_functions }->{ $expr->[ 2 ] }
            if $self->{ local_functions } and
               $self->{ local_functions }->{ $expr->[ 2 ] };
        $self->error( "Unknown function: $expr->[ 2 ]" ) unless $val;
        if( $val->[ FUNC_UNDEF_OK ] )
        {
            $val = $val->[ FUNC_FUNC ]->(
                map { $self->_eval_expression( $_, 1 ) } @{$expr->[ 3 ]} );
        }
        else
        {
            $val = $val->[ FUNC_FUNC ]->(
                map { $self->_eval_expression( $_ ) } @{$expr->[ 3 ]} );
        }
    }
    elsif( $type == METHOD )
    {
        $val = $self->_eval_method( $expr->[ 2 ], $expr->[ 3 ], $expr->[ 4 ] );
    }
    elsif( $type == TEMPLATE )
    {
        return( $self );
    }
    else
    {
        $self->error( "Unknown expression opcode: $type" );
    }
#$self->{ exprprofile }->{ $type } += Time::HiRes::time() - $exprstart;

    #  Undef warning.
    $self->warning( "undefined template value '$expr->[ 1 ]'" )
        unless defined( $val ) or $undef_ok or $expr->[ 1 ] eq 'undef';

    return( $val );
}

sub _eval_op
{
    my ( $self, $op, $lhs, $rhs ) = @_;

#my $ret;
#$self->{ opcount }->{ $op }++;
#my $opstart = Time::HiRes::time();
#$ret = $operators{ $op }->[ 1 ]->( $self, $lhs, $rhs );
#$self->{ opprofile }->{ $op } += Time::HiRes::time() - $opstart;
#return( $ret );

    #  WARNING: this function is unrolled above in _eval_expr: keep in sync.

    $op = $operators{ $op };

    #  Do we defer evaluation or not?
    return( $op->[ 1 ]->( $self,
        $self->_eval_expression( $lhs ),
        $self->_eval_expression( $rhs ) ) )
        unless $op->[ 2 ];

    return( $op->[ 1 ]->( $self, $lhs, $rhs ) );
}

sub _eval_unary_op
{
    my ( $self, $op, $expr ) = @_;

    #  "|| 0" is there because !1 in perl is '' but we want 0.
    #  !'' gives 1, so seems reasonable !'whatever' should be 0 too not ''.
    return( !$self->_eval_expression( $expr, 1 ) || 0 )
        if $op eq '!';
    return( ( not $self->_eval_expression( $expr, 1 ) ) || 0 )
        if $op eq 'not';
    #  TODO: This is odd for strings, probably should error or warn.
    return( -$self->_eval_expression( $expr ) )
        if $op eq '-';

    $self->error( "Unknown unary operator: '$op'" );
}

sub _assign_var
{
    my ( $self, $lhs, $rhs ) = @_;
    my ( $var_stack, $counter, $sz, $var );

    #  TODO: this should be compile-time ideally.
    $self->error( "Invalid LHS to assignment: $lhs->[ 1 ]" )
        if $lhs->[ 0 ] != VAR;

    #  TODO: this should be compile-time ideally.
    $self->error( "Can only assign to top-level variables: $lhs->[ 1 ]" )
        if @{$lhs->[ 2 ]} > 1;

    $var = $lhs->[ 2 ]->[ 0 ];

    $var_stack = $self->{ var_stack };
    $var_stack->[ 0 ]->{ $var } = $rhs;
    $sz      = @{$var_stack};
    $counter = 1;
    while( $counter < $sz )
    {
        return( $rhs ) unless exists( $var_stack->[ $counter ]->{ $var } );
        $var_stack->[ $counter ]->{ $var } = $rhs;
        $counter++;
    }

    return( $rhs );
}

sub _eval_var
{
    #  The stem value _is_ the value if there's no other segments.
    #  This is pulled above the sub's argument extraction for speed, I
    #  will rot in hell for this, but it _is_ performance-critical.
    return( $_[ 0 ]->{ var_stack_top }->{ $_[ 3 ]->[ 0 ] } )
        unless $_[ 5 ];

    my ( $self, $instr, $original, $segments, $originals, $last, $undef_ok ) = @_;
    my ( $val, $stem, $i, $special_values, $leaf, $type );

    $stem = $segments->[ 0 ];
    $special_values = $self->{ special_values };

    #  Check to see if it's a special loop variable or something.
    if( $last >= 1 and
        $special_values->{ $stem } and
        exists( $special_values_names{ $segments->[ 1 ] } ) )
    {
        #  Don't bother checking that the leaf isn't a ref, it won't
        #  match a key and saves on a ref() call when it isn't.
        $val = $special_values->{ $stem }->[
            $special_values_names{ $segments->[ 1 ] } ];
        $i = 2;
    }
    else
    {
        $i = 1;
        #  Determine the stem (top-level) value
        if( ref( $stem ) )
        {
            #  Top level is an expression not a var.
            $val = $self->_eval_expression( $stem );
        }
        else
        {
            $val = $self->{ var_stack_top }->{ $stem };
        }
    }

    #  Navigate our way down the remaining segments.
    for( ; $i <= $last; $i++ )
    {
        if( ref( $leaf = $segments->[ $i ] ) )
        {
            #  It's an index expression of the style var[index]
            unless( defined( $leaf = $self->_eval_expression( $leaf ) ) )
            {
                return( undef ) if $undef_ok;
                $self->error(
                    "Undefined index '$originals->[ $i ]' in " .
                    "'$original'" );
            }

            #  Check to see if it's a special loop variable or something.
            #  Only need to do this if we're an EXPR subscript, constant
            #  ones will have been checked outside the loop.
            if( $i == 1 )
            {
                if( $special_values->{ $stem } and
                    exists( $special_values_names{ $leaf } ) )
                {
                    $val = $special_values->{ $stem }->[
                        $special_values_names{ $leaf } ];
                    next;
                }
            }
        }

        unless( defined( $val ) )
        {
            return( undef ) if $undef_ok;
            $self->error(
                "Can't get key '$leaf' " .
                ( $originals->[ $i ] ne $leaf ?
                  "(from '$originals->[ $i ]') " : "" ) .
#"(with segments " . Data::Dumper::Dumper( $segments ) . ") " .
                  "of undefined parent in '$original'" );
        }

        if( not ( $type = ref( $val ) ) )
        {
#use Data::Dumper;
#warn "originals = " . Data::Dumper::Dumper( $originals ) . "\ni = $i\nleaf = $leaf\noriginal = $original\nsegments = " . Data::Dumper::Dumper( $segments ) . "\n";

            $self->error(
                "Can't get key '$leaf' " .
                ( $originals->[ $i ] ne $leaf ?
                    "(from '$originals->[ $i ]') " : "" ) .
                "of non-reference parent in '$original'" );
        }
        elsif( $type eq 'ARRAY' )
        {
            $self->error(
                "Can't index array-reference with string '$leaf' " .
                ( $originals->[ $i ] ne $leaf ?
                    "(from '$originals->[ $i ]') " : "" ) .
                "in '$original'" )
                unless $leaf =~ /^\d+$/o;
            $val = defined( $val->[ $leaf ] ) ? $val->[ $leaf ] : undef;
        }
        else
        {
            $val = defined( $val->{ $leaf } ) ? $val->{ $leaf } : undef;
        }
    }

    return( $val );
}

sub _eval_function
{
    my ( $self, $func, $args ) = @_;
    my ( $val );

    #  WARNING: this function is unrolled above in _eval_expr: keep in sync.

    #  TODO: should copy_global_functions block class-function lookup?
    $val = $functions{ $func } if $functions{ $func };
    $val = $self->{ local_functions }->{ $func }
        if $self->{ local_functions } and
           $self->{ local_functions }->{ $func };
    $self->error( "Unknown function: $func" ) unless $val;

    if( $val->[ FUNC_UNDEF_OK ] )
    {
        $args = [ map { $self->_eval_expression( $_, 1 ) } @{$args} ];
    }
    else
    {
        $args = [ map { $self->_eval_expression( $_ ) } @{$args} ];
    }

#$self->{ funccount }->{ $func }++;
#my $ret;
#my $start_time = Time::HiRes::time();
#    $ret = $functions{ $func }->[ 1 ]->( $self, @{$args} );
#$self->{ funcprofile }->{ $func } += Time::HiRes::time() - $start_time;
#    return( $ret );

    if( $val->[ FUNC_NEEDS_TEMPLATE ] )
    {
        return( $val->[ FUNC_FUNC ]->( $self, @{$args} ) );
    }
    else
    {
        return( $val->[ FUNC_FUNC ]->( @{$args} ) );
    }
}

sub _eval_method
{
    my ( $self, $expr, $method, $args ) = @_;
    my ( $exprdesc, $ret );

    $exprdesc = $expr->[ 1 ];
    $expr = $self->_eval_expression( $expr );

    $self->error( "Can't call method on undefined value $exprdesc" )
        unless defined $expr;
    $self->error( "Can't call method on non-reference value $exprdesc: $expr" )
        unless ref( $expr );

    #  For security reasons we don't want to allow calling
    #  just any old method on any old object from within a
    #  potentially user-defined template.
    $self->error( 'Invalid method to call from within a template: ' .
        ref( $expr ) . "->$method" )
        unless $expr->valid_template_method( $method );

    $args = [ map { $self->_eval_expression( $_ ) } @{$args} ];

    $ret = $expr->$method( @{$args} );

    return( $ret );
}

sub run
{
    my $self = $_[ 0 ];
    #  $line, $instr, $value lexically belong inside the loop,
    #  but in such a tight loop it's a performance hit, they're
    #  initialized at the start of each use anyway.
    #  If oddness ensues, move this line into the head of the loop and
    #  see if oddness abates.
    my ( $lineno, $ret, @var_stack, @for_stack, $run_start,
        $program, $last_instr, $special_values, $line, $instr, $value );

    #  For large templates this tricks perl's memory handling into
    #  giving us a big chunk of contiguous memory so that $ret .= $whatever
    #  doesn't have to keep incrementally adding more memory, this can
    #  give a minor-but-not-insignificant speed boost of ~2-3%.
    #  This may be highly sensitive to perl version and OS, and I'm
    #  not sure it does nice things to the memory profile of the process
    #  either...
    $ret = ' ' x 80_000;
    $ret = '';
    $lineno = 0;

    @var_stack = ( $self->{ vars } );
    @for_stack = ();

    $self->{ var_stack }     = \@var_stack;
    $self->{ var_stack_top } = $var_stack[ 0 ];

    $self->{ phase } = 'runtime';

#my $total_instr = 0;

#foreach my $prof ( qw/instr expr func op/ )
#{
#    $self->{ "${prof}count" }   = {};
#    $self->{ "${prof}profile" } = {};
#}

    #  Local unroll of some of our properties
    $program        = $self->{ template }->{ program };
    $last_instr     = $self->{ template }->{ last_instr };
#    @function_table =
#        map { $functions{ $_ } } @{$self->{ template }->{ function_table }};
    $special_values = $self->{ special_values };

    while( $lineno <= $last_instr )
    {
        $line  = $program->[ $lineno++ ];
        $self->{ current_pos } = $line->[ 1 ];

        #  TODO: look at $pos->[ 0 ] to determine file and recreate
        #    the "stack" for error traces if neccessary.

#$self->{ instrcount }->{ $line->[ 0 ] }++;
#my $instrstart = Time::HiRes::time();
        if( ( $instr = $line->[ 0 ] ) == LITERAL )
        {
            $ret .= $line->[ 2 ];
        }
        elsif( $instr == EXPR )
        {
            $value = $self->_eval_expression( $line->[ 2 ] );
            $ret .= ( ( ref( $value ) eq 'SCALAR' ) ? ${$value} : $value )
                unless $line->[ 3 ];
        }
        elsif( $instr == JUMP )
        {
#$ret .= "[jump]";
            $lineno = $line->[ 2 ];
        }
        elsif( $instr == JUMP_IF )
        {
#$ret .= "[jump if/unless $line->[3]]";
            $value = $self->_eval_expression( $line->[ 3 ], 1 );
#            $value = not $value if $line->[ 4 ];
            $lineno = $line->[ 2 ] unless $value;
        }
        elsif( $instr == FOR )
        {
            my ( $iterator, $set, $set_value, $hash, $last, $specials_needed );

            $iterator        = $line->[ 3 ];
            $set             = $line->[ 4 ];
            $specials_needed = $line->[ 5 ];

            $set_value = $self->_eval_expression( $set, 1 );
            $set_value = [] unless defined $set_value;

            if( ref( $set_value ) eq 'HASH' )
            {
                $hash      = $set_value;
                $set_value = [ sort( keys( %{$set_value} ) ) ];
            }
            elsif( not ref( $set_value ) )
            {
                #  If it's a number make it into a loop of 0..number.
                #  If they want 1..number they can <: if x != 1 :> inside it.
                $set_value = [ 0..int( $set_value ) ];
            }

#  TODO: assign and compare
            $last = @{$set_value} - 1;
            if( $last == -1 )
            {
                $lineno = $line->[ 2 ];
            }
            else
            {
                my ( $context );

                $value = $set_value->[ 0 ];
                $special_values->{ $iterator } =
                    [
                        0,
                        1,
                        0,
                        1,
                        0,
                        $last == 0 ? 1 : 0,
                        undef,
                        $last == 0 ?
                            undef : $set_value->[ 1 ],
                        $hash ? $hash->{ $value } : undef,
                    ]
                    if $specials_needed;
                #  Optimization: only create a new context if needed.
                if( $var_stack[ 0 ]->{ $iterator } )
                {
                    $context = { %{$var_stack[ 0 ]} };
                    $context->{ $iterator } = $value;
                    unshift @var_stack, $context;
                    $self->{ var_stack_top } = $context;
                }
                else
                {
                    $var_stack[ 0 ]->{ $iterator } = $value;
                }
                unshift @for_stack, [
                    0, $last, $set_value, $hash, $context ? 1 : 0,
                    $specials_needed,
                    ];
            }
        }
        elsif( $instr == END_FOR )
        {
            my ( $iterator, $set_value, $counter, $hash, $last,
                 $specials_needed );

            $iterator = $line->[ 3 ];

            $counter = ++$for_stack[ 0 ]->[ LOOP_STACK_COUNTER ];
            $last    = $for_stack[ 0 ]->[ LOOP_STACK_LAST ];

            if( $counter <= $last )
            {
                $set_value       = $for_stack[ 0 ]->[ LOOP_STACK_SET ];
                $hash            = $for_stack[ 0 ]->[ LOOP_STACK_HASH ];
                $specials_needed = $for_stack[ 0 ]->[ LOOP_STACK_SPECIALS ];

                $var_stack[ 0 ]->{ $iterator } = $set_value->[ $counter ];
                $special_values->{ $iterator } =
                    [
                        $counter,
                        ( $counter % 2 ) ? 0 : 1,
                        $counter % 2,
                        0,
                        $counter == $last ? 0 : 1,
                        $counter == $last ? 1 : 0,
                        $set_value->[ $counter - 1 ],
                        $counter == $last ?
                            undef :
                            $set_value->[ $counter + 1 ],
                        $hash ? $hash->{ $set_value->[ $counter ] } : undef,
                    ]
                    if $specials_needed;

                $lineno = $line->[ 2 ];
            }
            else
            {
                if( $for_stack[ 0 ]->[ LOOP_STACK_CONTEXT ] )
                {
                    shift @var_stack;
                    $self->{ var_stack_top } = $var_stack[ 0 ];
                }
                else
                {
                    delete $var_stack[ 0 ]->{ $iterator };
                }
                shift @for_stack;
                delete $special_values->{ $iterator };
            }
        }
        elsif( $instr == CONTEXT_PUSH )
        {
            my ( $context, $new_context );

            #  TODO: needed ||?  empty contexts should be optimized away now.
            $new_context = $line->[ 2 ] || {};
            $context = { %{$var_stack[ 0 ]} };
            foreach my $var ( keys( %{$new_context} ) )
            {
                $context->{ $var } = $self->_eval_expression(
                    $new_context->{ $var }, 1 )
            }
            unshift @var_stack, $context;
            $self->{ var_stack_top } = $context;
        }
        elsif( $instr == CONTEXT_POP )
        {
#$ret .= "[context_pop]";
            shift @var_stack;
            $self->{ var_stack_top } = $var_stack[ 0 ];
        }
#  TODO:  ick, hate cut-n-paste code.
#  TODO:  unroll constant parts of hash lookups to local var
        elsif( $self->{ local_syntaxes }->{ '.instr' }->{ $instr } )
        {
            my ( $executor, $token );

            $token    = $self->{ local_syntaxes }->{ '.instr' }->{ $instr };
            $executor = $self->{ local_syntaxes }->{ $token }->{ run };
            $value    = $executor->( $self, $token, $line->[ 2 ] );
            $ret .= $value if defined $value;
        }
#  TODO:  ick, hate cut-n-paste code.
#  TODO:  unroll constant parts of hash lookups to local var
        elsif( $syntaxes{ '.instr' }->{ $instr } )
        {
            my ( $executor, $token );

            $token    = $syntaxes{ '.instr' }->{ $instr };
            $executor = $syntaxes{ $token }->{ run };
            $value    = $executor->( $self, $token, $line->[ 2 ] );
            $ret .= $value if defined $value;
        }
        elsif( $instr == DEBUG )
        {
            $self->{ debug }->{ $line->[ 2 ]->{ type } } =
                ( $line->[ 2 ]->{ state } eq 'on' );
        }
#$self->{ instrprofile }->{ $instr } += Time::HiRes::time() - $instrstart;
    }

    delete $self->{ current_pos };
    delete $self->{ var_stack };
    delete $self->{ var_stack_top };
    delete $self->{ phase };

    return( \$ret );
}

sub _tersedump
{
    return( Data::Dumper->new( [ @_ ] )->Terse(1)->Useqq(1)->Dump() );
}

sub _tinydump
{
    return( Data::Dumper->new( [ @_ ] )->Indent(0)->Quotekeys(0)->Pair('=>')->Terse(1)->Useqq(1)->Dump() );
}

sub dumpable_template
{
    my ( $self ) = @_;
    my ( $lineno, $ret, %instr_names );

    $ret = '';
    $lineno = 0;
    %instr_names = (
        (LITERAL)      => 'literal',
        (EXPR)         => 'expr',
        (JUMP)         => 'jump',
        (JUMP_IF)      => 'jump_if',
        (FOR)          => 'for',
        (END_FOR)      => 'end_for',
        (CONTEXT_PUSH) => 'context_push',
        (CONTEXT_POP)  => 'context_pop',
        );

    foreach my $line ( @{$self->{ template }->{ program }} )
    {
        my ( $instr, $file );

        $file = $self->{ template }->{ files }->[ $line->[ 1 ][ 0 ] ];
        $file = 'template-string' if $file =~ m{^string:///};
        $ret .= sprintf( "%04d: [%-20s %3d %3d][%-12s] ", $lineno++,
            $file, $line->[ 1 ][ 1 ], $line->[ 1 ][ 2 ],
            $instr_names{ $line->[ 0 ] } || $line->[ 0 ] );

        $instr = $line->[ 0 ];
        if( $instr == LITERAL )
        {
#            $ret .= "\"$line->[2]\"\n";
            $ret .= _tinydump( $line->[ 2 ] ) . "\n";
        }
        elsif( $instr == EXPR )
        {
            $ret .= _tinydump( $line->[ 2 ] ) .
                ( $line->[ 3 ] ? " (void)" : "" ). "\n";
        }
        elsif( $instr == JUMP )
        {
            $ret .= "$line->[2]\n";
        }
        elsif( $instr == JUMP_IF )
        {
            $ret .= $line->[ 2 ] . ' unless ' .
                _tinydump( $line->[ 3 ] ) . "\n";
        }
        elsif( $instr == FOR )
        {
            $ret .= "$line->[ 3 ] in " . _tinydump( $line->[ 4 ] ) .
                " then $line->[ 2 ]";
            $ret .= " (no special-vars)" unless $line->[ 5 ];
            $ret .= "\n";
        }
        elsif( $instr == END_FOR )
        {
            $ret .= "$line->[ 3 ] in " . _tinydump( $line->[ 4 ] ) .
                " repeat $line->[ 2 ]\n";
        }
        elsif( $instr == CONTEXT_PUSH )
        {
            $ret .= "context push of " . _tinydump( $line->[ 2 ] ) . "\n";
        }
        elsif( $instr == CONTEXT_POP )
        {
            $ret .= "context pop\n";
        }
#  TODO: local syntax support.
    }

    return( $ret );
}

#sub _decompile_template
#{
#    my ( $self ) = @_;
#    my ( $lineno, $ret );
#
#    $ret = '';
#    $lineno = 0;
#
#    foreach my $line ( @{$self->{ template }->{ program }} )
#    {
#        my ( $instr );
#
#        $instr = $line->[ 0 ];
#        if( $instr == LITERAL )
#        {
#            $ret .= ( $line->[ 2 ] =~ /^$/ ) ?
#                "<: empty literal :>" : $line->[ 2 ];
#            next;
#        }
#        $ret .= "<: $instr ";
#        if( $instr == EXPR )
#        {
#            my ( $dump );
#
#            $dump = Data::Dumper::Dumper( $line->[ 2 ] );
#            $dump =~ s/^\$VAR1 = //;
#            $dump =~ s/;\n$//;
#            $ret .= $line->[ 2 ]->[ 1 ] . " ($dump)";
#        }
#        elsif( $instr == JUMP )
#        {
#            $ret .= "$line->[2]";
#        }
#        elsif( $instr == JUMP_IF )
#        {
#            $ret .= $line->[ 2 ] .
#                ( $line->[ 4 ] ? ' unless ' : ' if ' ) .
#                "$line->[3]";
#        }
#        elsif( $instr == FOR )
#        {
#            $ret .= "$line->[ 3 ] in $line->[ 4 ] then $line->[ 2 ]";
#        }
#        elsif( $instr == END_FOR )
#        {
#            $ret .= "$line->[ 3 ] in $line->[ 4 ] repeat $line->[ 2 ]";
#        }
#        elsif( $instr == CONTEXT_PUSH )
#        {
#            my ( $dump );
#
#            $dump = defined( $line->[ 2 ] ) ? Data::Dumper::Dumper( $line->[ 2 ] ) : 'undef';
#            $dump =~ s/^\$VAR1 = //;
#            $dump =~ s/;\n$//;
#            $dump =~ s/\s+/ /g;
#            $ret .= "context push of $dump";
#        }
#        elsif( $instr == CONTEXT_POP )
#        {
#            $ret = substr( $ret, 0, -1 );
#        }
##  TODO: support for local syntax
#        else
#        {
#            $ret .= "(unhandled by decompile)";
#        }
#        $ret .= " :>";
#    }
#
#    return( $ret );
#}

1;

__END__

=pod

=head1 NAME

Template::Sandbox - Fast template engine sandboxed from your application.

=head1 SYNOPSIS

   use Template::Sandbox;

   my $template = Template::Sandbox->new();
   $template->set_template( '/path/to/my/templates/accounts.html' );
   $template->add_var( customers    => $customers );
   $template->add_var( transactions => $transactions );
   $template->add_vars( {
       session => $session_info,
       user    => $user_info,
       } );
   print ${$template->run()};

   my $template = Template::Sandbox->new(
       template_root => '/path/to/my/templates',
       template      => 'accounts.html',
       cache         => $cache,
       );
   $template->add_vars( {
       transactions => $transactions,
       customers    => $customers,
       session      => $session_info,
       user         => $user_info,
       } );
   print ${$template->run()};

   Within /path/to/my/templates/accounts.html:

   <: if user :>
   <p>Welcome back, <: expr user.name :>.</p>
   <: else :>
   <p>Welcome.</p>
   <: endif :>
   <p>Recent Transactions:</p>
   <table>
       <tr>
        <th>Transaction ID</th>
        <th>Customer</th>
        <th>Date</th>
        <th>Description</th>
       </tr>
   <: foreach transaction in transactions :>
       <tr bgcolor="#<: if transaction.__odd__ :>ccffcc<: else :>ccccff<: endif :>">
        <td><: expr transaction.id :></td>
        <td><: expr customers[ transaction.customer ].name :></td>
        <td><: expr transaction.date :></td>
        <td><: expr transaction.description :></td>
       </tr>
   <: endfor :>
   </table>

=head1 DESCRIPTION

L<Template::Sandbox> is Yet Another Templating module, designed primarily
for use in a webserver environment but usable anywhere, providing a more
secure "sandboxed" environment than most templating systems.

The core design philosophy for L<Template::Sandbox> is that the template
logic should have no access outside the template beyond that which you
choose to permit it, this is frequently known as sandboxing.

Unlike many other template systems, available on CPAN or in other languages,
L<Template::Sandbox> doesn't give the template access to the global variables
of your application or to the core functions of the language.

This means that your template authors only have access to the data and
functionality that your application developers choose to grant them,
this encourages both to work with "published" interfaces between the
two systems - your template authors can't reach into the application's
internal-only data, and so your application developers can change that
internal data without worrying that the templates will stop working or
expose confidential information.

L<Template::Sandbox> also provides exceptional performance, ranking among
the fastest of the fully-featured template engines that don't rely on
embedding perl within the templates.

L<Template::Sandbox> also provides the usual gamut of behaviours and
optional features: caching compiled templates, includes, flow control,
embedded expressions, cascading template candidates, and useful
debugging information in case of errors.

Furthermore, L<Template::Sandbox> is designed to be subclassable should
you wish to customize or extend other of its features.

=head1 IMPORTANT CONCEPTS AND TERMINOLOGY

This section contains some important concepts and terminology that will
help you get started and to understand the rest of this document.

=head2 Template Workflow

The workflow to use a template consists primarily of two stages,
preparation and execution:

=over

=item Template Preparation

The preparation stage consists of constructing a new template object,
initializing it, setting template variables and loading and compiling
the template.

Most of these operations can be done in any order, except that you need
to register all functions you are going to use B<before> you load and
compile the template.

Some examples of things you might do in the preparation stage:

  $template = Template::Sandbox->new();

  #  Fine to add vars before the template is set.
  $template->add_var( session => $session );

  $template->set_template( 'control_panel/personal_details.html' );

  #  Fine to add vars after the template is set too.
  $template->add_var( {
    private_messages => $session->{ user }->get_private_messages(),
    recommendations  => $session->{ user }->get_recommendations(),
    } );

=item Template Execution

The execution stage on the other hand only happens once you're done
preparing, anything you want to do change the output of the template
needs to happen before this point.

It's fairly easy to understand since execution consists of only
one action:

  $outputref = $template->run();

It is currently assumed that after template execution you will have
no further use for the template, so while some cleanup is done of the
stateful information required by execution, running the same template
instance multiple times is not currently supported. (Although it might work.)

=back

=head2 Template Variables

Each template instance has its own namespace of I<template variables>,
these are added via the C<< $template->add_var() >> and
C<< $template->add_vars() >> methods, throughout this document any
reference to I<variables> is assumed to mean I<template variables>
unless otherwise noted.

I<Template variables> are the only variables your template can see,
you cannot access the contents of a perl variable unless you either
directly pass it as a template variable, indirectly pass it as a
reference within a structure that you have added as a template variable,
or return it as a value from within a I<template function>.

=head2 Template Functions

Much like I<template variables>, each template instance has its
own namespace of I<template functions>, there is also a common
namespace across all templates that can contain I<template functions>.

Also like I<template variables>, your template cannot access any perl
function unless the function has been directly registered with
either the instance or the entire L<Template::Sandbox> class, or
is used within a function that has itself been registered.

=head1 OPTIONS

New L<Template::Sandbox> objects can be created with the constructor
C<< Template::Sandbox->new( %options ) >>, using any (or none) of the
options below.

=over

=item B<template> => I<template filename>

Specifies the template file to be loaded.

=item B<template_root> => I<directory>

Sets the base directory to which template filenames will be relative.

This is not enforced as a restriction, if someone wants to traverse
outside the C<template_root> with C<..> or other mechanics, they can
do so.

=item B<logger> => I<logging object>

Sets the object to be used for logging purposes, by default L<Log::Any>
is invoked via C<< Log::Any->get_logger() >>, if you're passing some
other form of logger, you're responsible for ensuring it meets the
same API as provided by L<Log::Any>.

=item B<cache> => I<cache object>

Sets the template to search the given cache for compiled templates
rather than compiling them anew.

The cache may be any that conforms to the L<Cache::Cache> API.

L<Template::Sandbox> however also detects the use of
L<Cache::CacheFactory> in order to make use of its last-modified
dependencies checking, if you're using other caching mechanics
you will need to ensure cache freshness via your own mechanisms.

See the section L</"Caching"> for further discussion.

=item B<ignore_module_dependencies> => I<1> | I<0>

When using L<Cache::CacheFactory> for caching, a list of dependencies
for the cached version of the template is produced, this includes
the template file itself and any included templates.  By default this
list also includes the module files for the template class and its
superclasses, since if they change the compiled template may be
invalidated.

Setting C<ignore_module_dependencies> to a true value will prevent
this list of module files from being appended, potentially a performance
gain, however you probably should ensure that the cache is flushed between
any updates to the L<Template::Sandbox> module or any subclasses you
have made, if they contain functional changes.

See the section L</"Caching"> for further discussion.

=item B<template_function> => I<template function definition>

This lets you register a custom template function to the new template
instance.

See the section L</"Custom Template Functions"> for more details.

=item B<copy_global_functions> => I<1> | I<0>

On initializing the new template object, if this option is set to a true
value, all template functions added at the class level will be copied as
custom template functions local to that instance, this ensures that if
the class function is later removed then the function will still be
available to templates run by this instance.

See the section L</"Custom Template Functions"> for more details.

=item B<library> => [ I<$library> => I<@import> ]

This will import the list of I<template functions> or I<import tags>
listed in I<@import> from the template function library I<$library>.

This is equivilent to calling:

  $library->export_template_functions( $template, @import );

For more details see L<Template::Sandbox::Library>.

=item B<template_syntax> => I<template syntax definition>

This lets you register a custom template syntax to the new template
instance.

See the section L</"Custom Template Syntaxes"> for more details.

=item B<open_delimiter> => I<$open_delimiter>

=item B<close_delimiter> => I<$close_delimiter>

Optionally set the delimiters that indicate, respectively, the start
and end of a I<template token>.
By default the opening delimiter is C<< <: >> and the closing delimiter
is C<< :> >>.

The C<open_delimiter> and C<close_delimiter> options were added in v1.02_01.

=item B<allow_bare_expr> => I<0> | I<1>

If set to a true value, this allows the C<expr> token to be ommited from
I<template expressions>.

By default this is turned off.

For example:

  $template = Template::Sandbox->new(
      allow_bare_expr => 1,
      );
  $template->add_var( a => 'a is a fine letter' );
  #  This would usually be a syntax error:
  $template->set_template_string( '<: a :>' );
  print ${$template->run()};

  #  Output:
  a is a fine letter

The C<allow_bare_expr> option was added in v1.02_01.

=item B<vmethods> => I<0> | I<1>

If a set to a true value, this disables the usual behaviour of
methods in L<Template::Sandbox> and instead causes any method
calls to be rewritten as I<template function> calls with the
"object" of the vmethod pushed onto the front of the arguments to
the I<template function>.

  $template = Template::Sandbox->new(
      vmethods => 1,
      );
  #  With vmethods enabled, this:
  $template->set_template_string( '<: expr aaa.substr( 2, 4 ) :>' );
  #  is compiled to the equivilent of:
  $template->set_template_string( '<: expr substr( aaa, 2, 4 ) :>' );

This rewriting happens during compilation, so at runtime the
behaviour is identical to if you had written the functional
form directly.

This also has the effect that when retreiving cached templates,
only the value of C<vmethods> in the I<compiling> template instance
matters, it is ignored in the I<executing> template instance entirely:
avoid mixing and matching this option within template instances sharing
the same cache, unless you want inconsistent and confusing behaviour.

Also note that all the behaviour of I<template functions> apply,
you will need to either add them yourself or import them from
a I<template function library>, this option does not itself add
any new functions.

The C<vmethods> option was added in v1.02_02.

=item B<template_toolkit_compat> => I<0> | I<1>

If set to a true value, this in turn sets several other constructor
options to provide a degree of compatibility with the syntax of
L<Template::Toolkit>, easing a transition to L<Template::Sandbox>.

By default this is turned off.

The options currently set make these two lines equivilent:

  $template = Template::Sandbox->new(
      template_toolkit_compat => 1,
      );

  #  is shorthand for

  $template = Template::Sandbox->new(
      open_delimiter  => '[%',
      close_delimiter => '%]',
      allow_bare_expr => 1,
      vmethods        => 1,
      );

If you provide values explictly for any of these constructor options, then
the values you have set will be used rather than those provided by
C<template_toolkit_compat>.

More compatibility options may be added and set by this option in
the future.

Here's an example of it in use:

  $template = Template::Sandbox->new(
      template_toolkit_compat => 1,
      );
  $template->add_var( list => [ 1, 2, 4, 5, ] );
  $template->set_template_string( <<'END_OF_TEMPLATE' );
  [% FOREACH v IN list %]
  [% v %]
  [% END %]
  END_OF_TEMPLATE
  print ${$template->run()};

  #  Output:
  1
  2
  4
  5

Some incompatable gotchas are:

C<iterator.key> and C<iterator.value> in hash loops need to change to
C<iterator> and C<iterator.__value__>.

While vmethod syntax is supported, none of the standard
L<Template::Toolkit> vmethods are provided.
You can, however, write your own and L<Template::Sandbox::StringFunctions>
and L<Template::Sandbox::NumberFunctions> might give you a good
start.

Any feature of L<Template::Toolkit> that doesn't have a corresponding
feature in L<Template::Sandbox> will also be unsupported.

Still, it may ease the pain if you're converting simple templates.

The C<template_toolkit_compat> option was added in v1.02_01.

=back

=head1 PUBLIC METHODS

=over

=item B<< $template = Template::Sandbox->new( >> I<< %options >> B<)>

This is the constructor for L<Template::Sandbox>, it will return
a newly constructed template object, or throw an exception explaining
why it couldn't.

The options you can pass in are covered in the L</"OPTIONS"> section
above.

=item B<< $template->register_template_function( >> I<$function_definition> B<)>

=item B<< $template->add_template_function( >> I<$function_definition> B<)>

=item B<< $template->unregister_template_function( >> I<$function_name> B<)>

=item B<< $template->delete_template_function( >> I<$function_name> B<)>

These methods let you register a custom template function to the new template
instance, or to unregister one so that it is no longer available.

See the section L</"Custom Template Functions"> for more details.

=item B<< $template->register_template_syntax( >> I<$syntax_definition> B<)>

=item B<< $template->add_template_syntax( >> I<$syntax_definition> B<)>

=item B<< $template->unregister_template_syntax( >> I<$syntax_token> B<)>

=item B<< $template->delete_template_syntax( >> I<$syntax_token> B<)>

These methods let you register a custom template syntax to the new template
instance, or to unregister one so that it is no longer available.

See the section L</"Custom Template Syntax"> for more details.

=item B<< $template->get_valid_singular_constructor_param() >>

=item B<< $template->get_valid_multiple_constructor_param() >>

=item B<< $template->initialize( >> I<%options> B<)>

These three methods are used by the template constructor to
determine valid parameters and initialize from them.

Each is detailed further in L</"SUBCLASSING Template::Sandbox">.

=item B<< $template->get_template_candidates( >> I<$filename>, I<$dir> B<)>

=item B<< $template->get_include_candidates( >> I<$filename>, I<$dir> B<)>

These two methods govern how to find a template file from the
requested filename.

Each is detailed further in L</"SUBCLASSING Template::Sandbox">.

=item B<< $template->get_additional_dependencies() >>

Returns if there are any additional file dependencies beyond the usual
for the current template.

This method is detailed further in L</"SUBCLASSING Template::Sandbox">.

=item B<< $template->set_cache( >> I<$cache> B<)>

Sets the C<cache> to C<$cache>, as per the C<cache>
constructor option.

=item B<< $template->set_template_root( >> I<$dir> B<)>

Sets the C<template_root> to C<$dir>, as per the C<template_root>
constructor option.

=item B<< $template->set_template( >> I<$filename> B<)>

=item B<< $template->set_template( >> I<$filename>, I<$defines> B<)>

Loads and compiles the template in I<$filename>, optionally setting
I<compile defines> from the hashref I<$defines>.

=item B<< $template->set_template_string( >> I<$template> B<)>

=item B<< $template->set_template_string( >> I<$template>, I<$defines> B<)>

Loads and compiles the template given in the string I<$template>, optionally
setting I<compile defines> from the hashref I<$defines>.

=item B<< $template->add_var( >> I<$name>, I<$value> B<)>

Sets the I<template variable> named I<$name> to have value I<$value>.

Note that you can only add "top-level variables", that is you can do
the first of these but not the second:

  $template->add_var( 'user' => { profile => $profile, }, );  #  Works.
  $template->add_var( 'user.profile' => $profile );           #  Wrong!

=item B<< $template->add_vars( >> I<$vars> B<)>

Adds a I<template variable> with name and value from each key and value
of the hashref I<$vars>.

Like C<< $template->add_var() >>, this can only add top-level variables.

=item B<< $template->merge_var( >> I<$name>, I<$value> B<)>

Merges the contents of I<$value> into the I<template variable> named
I<$name>.

How the merge is performed depends on the nature of of I<$value>:

=over

=item I<$value> is a scalar

If the named I<template variable> does not already exist, it is set to
I<$value>. If the variable already has a value, it remains unchanged.

=item I<$value> is an arrayref

If I<$value> is an arrayref, then the contents of the arrayref are pushed
onto the arrayref contents of the I<template variable>, or assigned if
no arrayref already exists.

=item I<$value> is a hashref

Each key and value of I<$value> is merged with each key and value of
the hashref in the named I<template variable>.

=back

If this seems a little complicated, think of it that arrayref variables
get appended to, and hashrefs "have any missing entries filled in":

  #  In one part of your app:
  $template->merge_var(
      stylesheets => [ 'login_widget.css' ],
      );

  #  Then elsewhere:
  $template->merge_var(
      stylesheets => [ 'search.css', 'advertising.css' ],
      );

  #  Contents of 'stylesheets' is now:
  [ 'login_widget.css', 'search.css', 'advertising.css' ]
  

  #  Or a more complicated (and contrived) example:
  $template->merge_var(
      userprefs => {
          private_messages => {
              message_order      => 'oldest-first',
              delete_when_viewed => 1,
              fave_tags          => [ 'music', 'video' ],
              },
          },
      );
  $template->merge_var(
      userprefs => {
          private_messages => {
              delete_when_viewed => 0,
              friends_only       => 1,
              fave_tags          => [ 'computers' ],
              },
          },
          public_messages  => {
              message_order      => 'newest-first',
          },
      );

  #  Contents of 'userprefs' is now:
  {
      private_messages =>
          {
              message_order      => 'oldest-first',
              #  This already existed and remained unchanged.
              delete_when_viewed => 1,
              #  This didn't exist and was added.
              friends_only       => 1,
              #  This already existed and was appended to.
              fave_tags          => [ 'music', 'video', 'computers' ],
          },
      #  This didn't exist and was added.
      public_messages  =>
          {
              message_order      => 'newest-first',
          },
  }

=item B<< $template->merge_vars( >> I<$vars> B<)>

For each key and value in the hashref I<$vars>, perform a
C<< $template->merge_var() >> with that key and value.

=item B<< $template->clear_vars() >>

Clears all I<template variables> that have been added so far, as if
no I<template variables> had been added at all.

This method added in version 1.01_11 of L<Template::Sandbox>.

=item B<< $template->run() >>

Runs the template, returning a reference to the output.

C<< $template->run() >> will I<always> return a valid string reference,
or raise an exception trying: even if no output is produced a reference
to the empty string will be returned, so the following is safe (if ugly):

  print ${$template->run()};

=item B<< $template->dumpable_template() >>

Returns a somewhat human-readable dump of the compiled template program,
this probably isn't very useful unless you're me, or doing me the kindness
of debugging something for me. :)

=back

=head1 TEMPLATE SYNTAX

With the exception of I<compile defines> (detailed below in
L</"Compile Defines">), all L<Template::Sandbox> syntax is written
as statements enclosed within
C<< <: >> and C<< :> >> symbols, for example:

  <: if a :>some content<: else :>some other content<: endif :>
  <: for x in y :>some loop content<: endfor :>

Everything outside the C<< <: :> >> delimiters is considered to be
template content and will be reproduced unaltered in the template's
output.

A short summary of what statements are available and their arguments
follows, with a more detailed section on each further below.

=over

=item B<< <: expr >> I<< expression >> B<< :> >>

Substitutes the statement with value of I<< expression >> when the template
is run.  The expression itself may be a literal value, a variable or the
result of function calls or operators.

For further details please see L</"EXPRESSIONS">.

=item B<< <: if >> I<< condition >> B<< :> >> I<< branch content >> B<< <: endif :> >>

The C<if> statement conditionally chooses from several different branches of
content and only one of those branches will be in the final template
output.  Collectively the C<if>, C<else>, C<else if>, C<end if>, and variant
statements are refered to as L</"CONDITIONAL STATEMENTS">.

=item B<< <: for >> I<< iterator >> B<< in >> I<< group >> B<< :> >> I<< loop content >> B<< <: endfor :> >>

The C<for> or C<foreach> statement cycles an I<< iterator >> variable through
each element in the I<group> array or hash and substitutes the
I<< loop content >> into the template output each time.

See L</"LOOPS> for further details.

=item B<< <: end :> >>

The C<end> statement terminates the current C<if>, C<for> or C<foreach>
statement as if the corressponding C<endif> or C<endfor> statement was
provided.

This statement is mostly provided for people used to the syntax
of L<Template::Toolkit>.  You are strongly encouraged to use C<endif>
or C<endfor> instead, as it makes it far easier to debug that
you've got the wrong closing statement in the wrong place if your
if blocks and for loops don't all have the same ending statement.

=item B<< <: include >> I<< filename >> B<< :> >>

Includes the contents of the given I<< filename >> at the current location
within the template, the included file will itself be treated as a template
and any template statements within it will also be run.

This is further detailed in the  L</"INCLUDES"> section.

=item B<< <: # >> I<< comment >> B<< :> >>

The C<#> statement is removed entirely from the template output (it's
entirely removed from the compiled template in fact), behaving like a
normal perl comment.

This allows you to easily and quickly comment out statements while
developing the template:

  <: # if session.user :>
  This is where we'd display their control panel link once we've
  written the session.user object.
  <: # endif :>

Note that, in this example, only the C<if> and C<endif> statements are
commented out, the template content between them will still be in the
template.

=back

=head1 EXPRESSIONS

Template expressions are much like those in any language, they can be
formed by combinations of literal values, variables, operators and
in some circumstances method calls.

=head2 Literal Values

Literal values can be either numbers or they can be string
values enclosed in single-quotes, for example:

  <: expr 'a literal string' :>
  <: expr 42 :>

Strings have no interpolation done except backslash escaping: backslash
followed by another character represents that character devoid of any
special meaning, so if you wish to have a string containing a literal
single-quote or backslash you could do the following:

  <: expr 'a string with a single-quote (\') within it' :>
  <: expr 'a string with a backslash (\\) within it' :>

Note that one consequence of the "no interpolation" rule is that you
will B<not> be able to embed a C<\n> in your string and receive a
newline/carriage-return, you'll just get a literal C<n> instead,
this may change in a future release, but for now you can make use
of the C<cr> special variable as detailed in L</"SPECIAL VARIABLES">.

=head2 Variables

I<Template variables> are refered to by bare names using a syntax
designed to be familiar to javascript developers rather than perl
developers. As such, it uses a 'dotted index' notation interchangably
with square-bracket indices.

For example, C<user> would refer to the template variable known as I<user>,
and both C<user.name> and C<< user[ 'name' ] >> would refer to the
I<name> index of the I<user> template variable.

When using the square-bracket notation, the contents of the brackets are
evaluated as an expression and the result is used as the index value, so
the following is valid (if nasty to read):

  customers[ transactions[ transaction.id ].customerid ]

As you can see from the example, you can also mix and match the notations,
the following expressions are all identical:

  customer.address.street
  customer[ 'address' ].street
  customer.address[ 'street' ]
  customer[ 'address' ][ 'street' ]

Which you use is largely a matter of choice although the usual convention
for clarity is to use the dotted notation for 'constant indices' (ones that
don't change) and the square-bracket notation for ones that may vary.

When indexing arrays it's customary to use square-brackets too:

  results[ 12 ]

Variables usually refer to I<template variables> added via
C<< $template->add_var() >> or C<< $template->add_vars() >>, however
in some circumstances they can refer to locally-scoped variables set
with the assign operator or include variables, both detailed in the
L</"Operators"> and L</"INCLUDES> sections and further under
L</"SCOPED VARIABLES">.

There are a number of I<special variables> that exist as indexes of
other variables, you can recognise these as they are surrounded by
double-underscores, some examples:

  customers.__size__
  transaction.__odd__

These variables are described in the L</"SPECIAL VARIABLES"> section.

A quirk of the parsing for I<methods> as well as I<template variables>
means that you can use the C<< -> >> operator in place of the C<.>
operator to seperate variable segments, permitting:

  customer->address->street
  customer[ 'address' ]->street
  customer->address[ 'street' ]

This is likely to confuse your perl programmers into trying this sort of
thing though:

  #  Won't work!
  customer->[ 'address' ]->[ 'street' ]
  #  Even further from working...
  customer->{ 'address' }->{ 'street' }

So my humble advice is to stick to using the dotted notation, so that
it looks like Javascript.

=head2 Operators

Operators exist to combine various subexpressions into a larger
expression, L<Template::Sandbox> supports most standard operators,
listed below in order of precedence (with the exception of comparision
operators, see their notes if precedence is important.)

=over

=item Arithmetic operators (*, /, %, -, +)

These perform their standard arithmetic functions on numeric values.
Note that C<< + >> behaves like Perl's C<< + >> operator, not that
of Javascript: it expects a numeric value, if you want to concatinate
strings you should use the C<< . >> string concatination operator below.

=item String concatination (.)

Concatinates two strings into a single string.

=item Logic operators (!, not, &&, ||, and, or)

Perform logical negation, ANDing and ORing.

Note that the C<< && >>, C<< || >>, C<< and >>, C<< or >>
operators all perform left-wise "short circuit" behaviour: that is, if
the left-hand expression is sufficient to determine the result of the
operator as a whole, the right-hand expression will never be evaluated.

=item String comparison operators (lt, gt, le, ge, eq, ne, cmp)

These operators compare two strings as in the equivilent Perl operators.

Although grouped together in this document for convenience, the
precedence of the string comparison operaters is interleaved with the
matching numeric comparison operators: lt, <, gt, >, le, <=, etc.

=item Numeric comparison operators (<, >, <=, >=, ==, !=, <=>)

These operators compare two numbers as in the equivilent Perl operators,
note that if you supply strings to them, like you would to the equivilent
operators in Javascript, then you will cause warnings.

=item Assignment operator (=)

This assigns the right-hand value to the I<scoped variable> on the
left-hand side. If there is no I<scoped variable> of that name visible
in the current scope, a new one will be created within the current scope.

See L</"SCOPED VARIABLES"> for more details on this behaviour.

Note that you can only assign to a 'top-level' variable, ie you can assign
to C<day_name> but not C<date.day_name>. This is intentional to reduce
complexity and performance on variable evaluation, and because if you
really need it, you're probably trying to do something that should be
in your application layer, and not trying to write the application within
the template.

Variable assignment returns the value assigned as its value, ie, the
following template produces C<< "blue" >> when run:

  <: if ( a = 4 + 1 ) == 5 :>
  blue
  <: else :>
  red
  <: endif :>

However, if the assign is at the top level of an C<< expr >> statement,
it will return the empty string '', so that it leaves your template output
unmarked, ie:

  x<: expr a = 4 + 1 :>x

produces:

  xx

and not:

  x5x

Generally this will mean it will just "Do What I Want".

=back

=head2 Brackets

If you're combining several expressions and are uncertain of the
operator precedence, or simply want to make things clearer, you can
use C<< () >> round-brackets in the traditional way to group expressions
in order of execution.

Some examples:

  <: expr ( 1 + 2 ) * 5 :>
  <: expr config.baseurl . '?page=' . ( param.page + 1 ) :>

=head2 Functions

Function calls may be made within an expression using the, familiar to
many languages, syntax of:

  functionname( arg1, arg2, ... )

For convenience and familiarity to Perl developers you can also use C<< => >>
as an argument separator, ie the following are equivilent, but the
second two may be more readable:

  <: expr url( 'q', 'bald-headed eagle', 'lang', 'en' ) :>
  <: expr url( 'q' => 'bald-headed eagle', 'lang' => 'en' ) :>
  <: expr url(
    'q'    => 'bald-headed eagle',
    'lang' => 'en',
    ) :>

Note however that unlike Perl, C<< => >> does not auto-quote barewords
on its left-hand side:

  <: # Probably not going to do what you want :>
  <: expr url( q => 'bald-headed eagle', lang => 'en' ) :>

This will pass the contents of template variable C<q> as the first argument
and the contents of C<lang> as the third.

Note also that these function calls are not directly calls to perl functions,
instead they are calls to functions that have been registered as I<template
functions> with the current template.

By default only three functions are registered, those three are needed
for internal behaviour of certain I<special variables> and for the test
suite, it is part of L<Template::Sandbox>'s core philosophy that, like
template variables, you must explicitly grant access to more than this
if you wish to do so.

Ideally L<Template::Sandbox> would ship with no functions enabled, and
so these functions may be moved to the optional functions libraries in a
future release if possible.

The three default functions are:

=over

=item C<void()>

Takes any args and returns the empty string.

This function is retained for legacy reasons as it was previously used
internally to provide the void-context for variable assigns at the top
level of an C<< expr >> statement.

B<This function may be removed in a future release.>

=item C<size( arg )>

Takes a single argument and returns the "size" of it.  For hashes that's
the number of keys, for arrays it's the number of elements and for strings
it's the length of the string. 

Note that supplying a numeric argument will result in the number being
converted to and treated as a string, and so will most likely result in
returning the number of digits in the number.  This behaviour is undefined
and subject to change.

This function is required for global use since it is used internally to
implement the __size__ special variable.  (See L</"SPECIAL VARIABLES">.)

=item C<defined( arg )>

Takes a single argument and returns 1 or 0 to indicate whether the
value was defined or not.

This function is required by the test suite at a stage before the function
registration has been confirmed as working, as such will remain for at
least the initial few releases to simplify CPAN smoke-testing feedback.

=back

=head2 Methods

Methods on objects can be used within an expression, using a syntax familar
to either Javascript or Perl developers, for example both of these are
identical:

  message.mark_as_read( 1 )
  message->mark_as_read( 1 )

In either case the C<< mark_as_read >> method will be called on the object
in the template variable C<< message >>, with an argument of C<< 1 >>.

However, in keeping with the purpose of L<Template::Sandbox>, you cannot
just call methods on any old object, every method call is preceded by a
call to C<< valid_template_method >> as a method on the target object,
with the method to be called as an argument.

In the example above this would be
C<< message->valid_template_method( 'mark_as_read' ) >>.

If this method returns true, then the C<< mark_as_read >> method call is
permitted to go ahead, if it returns false then an error will be raised.

Methods are mostly provided for completeness, there are performance
implications in using them detailed in
L</"PERFORMANCE CONSIDERATIONS AND METRICS">, however it may be that
someone will find them invaluable. Maybe.

If you have set the C<vmethods> option to a true value then methods
as detailed in this section cannot be compiled, instead they become
equivilent to I<template functions> with the "object" pushed onto
the front of the list of arguments.  See the L</"OPTIONS"> section
for more details and examples.

=head1 CONDITIONAL STATEMENTS

L<Template::Sandbox> provides C<< if >>, C<< else if >>, C<< else >>,
C<< end if >>, C<< unless >>, C<< else unless >> and C<< end unless >>
constructs to conditionally choose between different sections of
template content, much like if statements in other languages choose
between blocks of statements.

Any valid I<template expression> (see L</"EXPRESSIONS">) may be used as
the condition, the true/false value of the result is all that the
conditional statement cares about.

Each condtional construct is made up of an opening C<if> or C<unless>
statement, optionally one or more C<else if> or C<else unless> statements,
optionally a single C<else> statement and is closed by a C<end if> or
C<end unless>.

All template content between each of these statements is considered to
be the "branch content" for the immediately preceding condition, and only
appears in the final template output if the statement is the first true
statement of the entire construct.

You can also nest as many C<if> constructs as you wish, provided each one
is entirely contained within a single content block of its parent (ie, is
properly nested and not "overlapping".)

Simply put, it behaves like an C<if> construct in every other language.

The following statements are available:

=over

=item B<< <: if >> I<< condition >> B<< :> >>

=item B<< <: unless >> I<< condition >> B<< :> >>

All conditional constructs must open with an C<if> or C<unless> statement.
Like in Perl the C<unless> statement is just a convenience syntax for the
logical negation of the condition.

=item B<< <: else if >> I<< condition >> B<< :> >>

=item B<< <: elseif >> I<< condition >> B<< :> >>

=item B<< <: elsif >> I<< condition >> B<< :> >>

=item B<< <: else unless >> I<< condition >> B<< :> >>

=item B<< <: elseunless >> I<< condition >> B<< :> >>

=item B<< <: elsunless >> I<< condition >> B<< :> >>

Depending on preference, you can choose from several functionally-equivilent
spellings of the C<else if> statement.

You can have no C<else if> statements, or you can have as many as you like,
the only restriction is that they must come before any C<else> statement
for the construct.

=item B<< <: else :> >>

This optionally defines the block that will be used if no other condition
within the statement is true, there can only be one of them in each C<if>
construct, and it must be the last branch - since it's a "catch all", having
anything after it wouldn't make sense...

=item B<< <: end if :> >>

=item B<< <: endif :> >>

=item B<< <: end unless :> >>

=item B<< <: endunless :> >>

This marks the end of the conditional construct, whatever form of C<if> or
C<unless> you have used to open your construct, you can use any of the above
close it, for clarity you may wish to use a matching one.

=back

=head1 LOOPS

L<Template::Sandbox> provides a "loop" mechanism like the foreach statement
of Perl, it creates and sets a locally I<scoped variable>, sets it to the
first value in a set of values and executes the contents of the loop,
sets the loop variable to the next in the set of values and repeats,
until there are no more entries in the set to loop through, whereupon
the loop exits.

Unlike Perl or Javascript there is currently no C<last> or
C<continue> mechanism to exit from a loop or jump to the next
iteration directly.

Each C<for> loop takes the following format:

  <: for iterator in set :>
  loop content
  <: end for :>

The iterator is created as a I<scoped variable> (see L</"SCOPED VARIABLES">)
within a new scope context, so it will mask the existence of any
previous variable with that name within the scope of the loop.

Additionally the iterator has several special variable subscripts
attached for convenience, such as C<< iterator.__first__ >>, these
are detailed in the L</"SPECIAL VARIABLES> section.

The set of values to iterate across may be a simple number, an array
or a hash, or an expression resulting in one of these. The behavior
in each case is detailed in its own section below.

=head2 Array Loops

If the set to iterate across is evaluated to be an array, then the
iterator is set to each element of the array in order, from first to
last.

=head2 Hash Loops

If the set to iterate across is evaluated to be a hash, then the
iterator is set to each key of the array in alphabetical order, from
first to last, with the special variable C<< iterator.__value__ >>
set to the corresponding value of the hash in addition to the usual
special loop variables.

=head2 Numeric Loops

If the set to iterate across is evaluated as a single number, such as:

  <: for x in 10 :>
  <: expr 10 - x :> green bottles standing on the wall.
  <: end for :>

it is taken to mean an array of values from C<0> to C<n> where C<n> is
the number given. In the example above this would be C<0> to C<10>.

If the value happens to be a floating point (or even a string), it will
be turned into a number via perl's C<int()> function.

In all other respects, a numeric loop will be have as if you had supplied
an array of the numbers directly. (See L</"Array Loops">.)

=head1 INCLUDES

It's possible with the C<< include >> statement to include the contents
of other templates at the current statment's position, this allows you
to easily share common sections of a template between several templates
rather than cut-n-paste it into each.

Basic usage is fairly simple:

  <: include transaction_row.html :>

The included template file is looked for relative to the current template's
directory, in subclasses of L<Template::Sandbox> you can override this
with the C<get_include_candidates()> method.

All includes are done at compile-time, this means that if there compile
errors in an included file, the template as a whole will fail to compile
even if the include is in a section of the template that will never be
reached during run-time. It also means you B<cannot> include a filename
based on a run-time parameter, ie the following is unlikely to be working
as intended:

  <: # Wrong!!! :>
  <: include our_files[ chosen_file ] :>

This will try to load a template with literal filename
"our_files[ chosen_file ]" and not the presumed intention of a template
whose filename is stored in the the C<our_files> array or hash with the
index stored in the C<chosen_file> variable.

=head2 Setting compile defines with C<include>

It's possible to set L</"Compile Defines"> when including a file, to do
so just set the values after the filename in the C<include> statement,
as in one of these examples:

  <: include transaction_row.html TDCLASS=green :>
  <: include transaction_row.html TDCLASSODD=green TDCLASSEVEN=blue :>
  <: include transaction_row.html TDCLASS="value with spaces" :>

Any upper-case named parameter to C<include> will set the corresponding
I<compile define> when compiling the included template, this define
value will mask any existing define of that name for the duration of the
compile of the included template. (And any templates it, in turn, includes.)

=head2 Setting scoped variables with C<include>

You can also set variables scoped locally to the included template from
the C<include> statement, you do so in much the same manner as setting
an include, except the parameter name is lower-case:

  <: include login_widget.html user=session.user :>

This would set the C<user> I<scoped variable> to be equal to the value of
the C<session.user> I<template variable> when control enters into the included
file at runtime. This variable would be local to the included file and
any files it, in turn, includes. See L</"SCOPED VARIABLES"> for more
details.

You can use any valid I<template expression> to assign to the
I<scoped variable>, but if the expression contains spaces you must
double-quote (C<"">) the expression:

  <: include image_with_border.html img="user.id . '/' . gallery.id" :>

=head1 SCOPED VARIABLES

All I<template variables> added via C<< $template->add_var() >>,
C<< $template->add_vars() >>, C<< $template->merge_var() >>, and
C<< $template->merge_vars() >> have global scope within the template
instance the method was called on, however it is also possible to create
variables that have a shorter scope than the entire template instance,
these are called I<scoped variables>.

There are three different ways of creating I<scoped variables>: the
I<iterator variable> of a C<for> loop, variables created via the
I<assign operator>, and variables set during an C<include> statement.

I<Scoped variables> behave much like Perl variables created with C<local>:
they exist for the remainder of the current context and and are visible
to all inner contexts.

New contexts are created on entering a C<for> loop (unless one is deemed
uneccessary, see L</"Template Program Optimizations">), and on entering
a file via an C<include> statement.

Note that the behaviour of the I<assign operator> differs from C<for> and
C<include> in that it only creates a I<scoped variable> in the current
context if no I<scoped variable> already exists in a visible context.

That is, C<for> and C<include> create I<scoped variables> that mask any
previous I<scoped variable> or I<template variable> of the same name,
whereas the I<assign operator> will set any previous I<scoped variable>
(but not I<template variable>) or create a new one.

This difference in behaviour allows you to produce something akin to
subroutine calls with a dirty hack by assigning a variable to a dummy
value to create it in the outer scope then setting it within an include
with a 'return value':

  In an outer template:
  <: expr returnval = 0 :>
  <: include faux_subroutine.html a=12 b=44 :>
  <: expr returnval :>

  Contents of faux_subroutine.html:
  <: expr returnval = a + b :>

  When the outer template is run, it produces:
  56

While this behaviour can be useful in some situations, it's probably
a sign that you need to create a new I<template function> to do the
heavy lifting for you.

There is currently a subtle bug with assigns to new I<template variables>
within I<context-folded> loops persisting for longer than expected, this
is detailed further in L</"KNOWN ISSUES AND BUGS">.

=head1 SPECIAL VARIABLES

=over

=item C<undef>

=item C<null>

Both C<undef> and C<null> provide access to the Perl C<undef> value,
C<null> is provided as a familiar name for Javascript developers.

=item C<cr>

Because there's, currently, no interpolation within literal strings
inside template expressions, this prevents you from using C<'\n'> to
provide a newline/carriage-return. The C<cr> special variable exists
to provide easy(ish) access to that value:

  <: expr 'Hello' . cr . 'World!' :>

This will produce template output:

  Hello
  World!

Needing to resort to use of a variable to get this functionality could
be considered a bug, or at the least a missing feature, so it may
become unneccessarily in a future release. The use of C<cr> will still
be supported beyond that point for backwards-compatibility.

=item C<var.__size__>

Provides the size of the indexed variable, as provided by the C<size()>
template function.

For arrays this is the number of elements in the array, for hashes it
is the number of keys in the hash, for strings it is the number of
characters in the string.

For numbers it has currrently undefined behaviour that is the number
of characters in the string when the number is converted to string.
This may be subject to change in future releases.

=back

The following I<special variables> are only available as indices of
the I<loop variable> of a C<for> or C<foreach> loop.

=over

=item C<iterator.__value__>

Available only when iterating across a hash, this provides access
to the value corresponding to the key the iterator is currently
set to, this can be less typing (and faster to execute) if the
hash being iterated over was the result of a long expression,
for example the following two loops are equivilent, but the second
is more convenient and also executes faster:

  <: for x in this.is.the.bottom.of[ 'a' ][ 'long' ].chain :>
  <: expr this.is.the.bottom.of[ 'a' ][ 'long' ].chain[ x ] :>
  <: end for :>

  <: for x in this.is.the.bottom.of[ 'a' ][ 'long' ].chain :>
  <: expr x.__value__ :>
  <: end for :>

=item C<iterator.__counter__>

Gives the numeric count of which iteration of the loop is currently
being run, numbered from zero:

  <: for x in y :>
  <: expr x.__counter__ :>
  <: end for :>

Will give output "0", "1", "2", "3", "4", etc.

=item C<iterator.__even__>

=item C<iterator.__odd__>

Set to true or false if this an odd or even iteration of the loop.

Commonly useful for easily doing alternating bands of background colour
in tables for legibility:

  <tr bgcolor="#<: if row.__odd__ :>ccffcc<: else :>ccccff<: endif :>">

Note that since this is derived from C<__counter__>, which starts at zero,
this means that the first iterator is C<__even__> and not C<__odd__>.

=item C<iterator.__first__>

Set to true if this is the first iteration of the loop, or false
subsequently.

=item C<iterator.__last__>

Set to true if this is the last iteration of the loop, or false otherwise.

=item C<iterator.__inner__>

Set to true if this is neither the first nor the last iteration of the
loop, otherwise false.

=item C<iterator.__prev__>

=item C<iterator.__next__>

Give you convenient access to the previous and next values that the iterator
was (or will be) set to, or undef if you are at the start or end of the loop
respectively.

Note that in none of the loop I<special variables> will be set for
the contents of C<iterator.__prev__> or C<iterator.__next__>, ie these
C<expr> statements will error:

  <: for entry in myhash :>
  <: # These will error :>
  <: expr entry.__prev__.__value__ :>
  <: expr entry.__next__.__prev__ :>
  <: end for :>

=back

=head1 COMPILE DEFINES

I<Compile defines> are a special type of variable that get replaced at
compile-time. (To be picky, they actually get replaced as the template
is read, before compilation begins.)

This means two things: 1) they're constant and cannot change during
repeated runs of the same compiled template, or within a single run;
2) they can contain anything you like, including fragments of template
statements rather that just values to use in an I<expression>.

You can set I<compile defines> at two stages, either when you call
C<< $template->set_template( $filename, $defines ) >> (or
C<set_template_string>), or as parameters to an C<include> statement.
(For more details look at L</"INCLUDES">.)

However you set them, a I<compile define> is a symbol consisting of
an entirely UPPERCASE name, that will be used for literal replacement
within the template contents being read. You may also use underscores
(C<_>) and numbers within a define name.

The template is scanned looking for constructs of the form:

  ${NAME}
  ${NAME:default}
  ${'NAME'}
  ${'NAME:default'}

And will replace them according to the rules below.

=head2 Plain Compile Defines

If the token being replaced has the form C<${NAME}>, the contents
of the define will be substituted verbatim into the source of the
template being read.

For example:

  $contents = q/Welcome to ${PAGEOWNER}'s Home Page!/;

  $template->set_template_string( $contents,
      {
          PAGEOWNER => 'Joe',
      } );
  print ${$template->run()};
  # Produces: Welcome to Joe's Home Page!

=head2 Compile Define Defaults

If the token has form C<${NAME:default}>, then if there is a
I<compile define> with name C<NAME> with a defined value, that
will be used for substitution, otherwise the value of C<default>
will be used.

For example:

  $contents = q/Welcome to ${PAGEOWNER:Fred}'s Home Page!/;

  $template->set_template_string( $contents,
      {
          PAGEOWNER => 'Joe',
      } );
  print ${$template->run()};
  # Produces: Welcome to Joe's Home Page!

  $template->set_template_string( $contents );
  print ${$template->run()};
  # Produces: Welcome to Fred's Home Page!

=head2 Quoted Compile Defines

If the token takes the form C<${'NAME'}> or C<${'NAME:default'}>
then replacement is done as above, with the addition that the replacement
is enclosed in single-quotes (') and has the contents escaped correctly
to be safe within those enclosing single-quotes.

This is mostly useful if you wish to include the contents of a I<compile
define> within an I<expression> as a string, but are unsure if the define
will contain single-quotes that would terminate your string and produce
syntax errors, and wish to avoid placing the burden of proper escaping on
whoever is setting the define's value.

For example, you wish to have an alert_header.html:

  <p class="alert">
  <: expr html_escape( ${'MOTD'} ) :>
  </p>

and in the main navigation template for your side you want to do:

  <: include alert_header.html
     MOTD="We're currently experiencing some service disruptions, please bear with us" :>

This will be replaced and produce the (safe) template source of:

  <p class="alert">
  <: expr html_escape( 'We\'re currently experiencing some service disruptions, please bear with us' ) :>
  </p>

Without the C<${'MOTD'}> quoting mechanism, the quote in "We're" would be
unescaped and terminate the string, causing a syntax error within the
template.

You could manually escape the contents of C<MOTD> when you set it within
the C<include> statement, but while this may be possible, it's
inconvenient and the sort of thing you're likely to accidentally forget
to do. It also leads to error messages at the point where the I<define>
is used rather than where the I<define> is set, which can be a pain to
track back up to in complicated template structures.

=head1 CUSTOM TEMPLATE FUNCTIONS

In order to use any functions beyond the basic ones within your template
you will need to register them as a I<custom template function>.

This can be done either with the C<template_function> constructor option
or the C<< $template->register_template_function() >> method.

To these you need to supply a name for the function, as it will be invoked
from within your templates, and a data-structure providing the function and
describing some flags on the function's behaviour.

To assist in producing the function definition you can import some helper
functions using the C<':function_sugar'> import tag on your C<use> line:

  use Template::Sandbox qw/:function_sugar/;

These imported functions, described in L</"Function Sugar">, allow you
to pass an anonymous subroutine (or function reference) and produce a
data-structure suitable for registering as a template function.

Some examples probably make this a lot clearer:

  use Template::Sandbox qw/:function_sugar/;

  #  Register 4 template functions during construction.
  $template = Template::Sandbox->new(
      template_function => [
          int => ( one_arg  sub { int( $_[ 0 ] ) } ),
          max => ( two_args sub { $_[ 0 ] > $_[ 1 ] ? $_[ 0 ] : $_[ 1 ] } ),
          min => ( two_args sub { $_[ 0 ] < $_[ 1 ] ? $_[ 0 ] : $_[ 1 ] } ),
          var => ( one_arg inconstant needs_template
                       sub { $_[ 0 ]->_var_value( $_[ 1 ] ) } ),
          ],
      );

  #  Register a template function after construction.
  $template->register_template_function(
      localtime => ( no_args inconstant sub { scalar localtime() } ),
      );

  #  Whoops, no we didn't want that function after all.
  $template->unregister_template_function( 'localtime' );

  #  Actually, we wanted it available to all templates.
  Template::Sandbox->register_template_function(
      localtime => ( no_args inconstant sub { scalar localtime() } ),
      );

Now within your templates you can do the following sorts of things:

  <: if max( pricea, priceb ) > 50 :>
  Price too high, max price (rounded down) is:
  <: expr int( max( pricea, priceb ) ) :>.
  <: else :>
  Prices all within tolerences.
  <: endif :>
  Page generated on <: expr localtime() :>.

=head2 Function Sugar

These helper functions can be exported into your namespace with:

  use Template::Sandbox qw/:function_sugar/;

=over

=item inconstant

Indicates that the function returns a value that is not constant even
if the arguments are constant, and that the function should not be
subject to I<constant-folding> optimizations at compile time. You should
also use this if the function returns a constant value for constant
input but has an important side-effect that must happen each call.

Some examples of inconstant functions in Perl would be C<time()> or
C<random()>, where the return varies for constant input; or C<flock()>
where the side-effect needs to happen at run-time.

=item needs_template

Indicates that the function would like the template instance passed as
the first argument in addition to any arguments supplied within the
template.

=item undef_ok

Indicates that the function finds it acceptable to be passed undefined
arguments and disables the warnings that would otherwise be produced by
them.

=item no_args

States that the function should be passed no arguments, attempting to
do so will produce a compile-time error.

=item one_arg

=item two_args

=item three_args

States that the function should have the relevent number of arguments,
passing a larger or smaller number produces a compile-time error.

=item any_args

States that the function does not care about how many arguments it
receives, it will accept any number of them (or none).

=item has_args

Lets you define the number of arguments manually rather than using one
of the convenience wrappers above, takes two args, the first being the
function or chained function sugar, the second being the number of arguments
the function expects, for example this gives you a function that takes
5 arguments (although it doesn't use them):

  has_args sub { 'has a lot of args but ignores them' }, 5;

Using anything other than 5 arguments to this function would then be a
compile-time error.

=item def_func

Not exported by default.

This is the function used internally by the I<function sugar> functions
listed above, it takes either an already-sugared function or a sub reference
as the first argument, the second argument is the index of the function
definition to alter, and the third is the value to set the entry to.

You shouldn't ever need to use this, but it can be exported if you find
a need for it with:

  use Template::Sandbox qw/:function_sugar def_func/;

=back

=head1 CUSTOM TEMPLATE SYNTAXES

This API is incomplete and subject to change, nevertheless the current
state-of-play is documented here in case you need to make use of it.

It's possible to add new single-statement template keywords to be
compiled into the template and run by your own custom callbacks.

You do this with either the C<template_syntax> constructor option
or the C<< $template->register_template_syntax() >> method:

  $template = Template::Sandbox->new(
      template_syntax => [
          yarr => {
              compile => sub { [] },
              run     => sub { 'Yarr!' },
              },
          ],
      );

  $template->register_template_syntax(
      lubber => {
          compile => sub { [] },
          run     => sub { 'Ye scurvy landlubber!' },
          },
      );

  $template->set_template_string( "<: yarr :> <: lubber :>\n" );
  print ${$template->run()};

  Yarr! Ye scurvy landlubber!

As can be seen, two arguments are passed, the first is the name of the
token to be added as valid template syntax, the second is a hash of options
for that syntax.

Currently the only options allowed for the syntax are C<compile> for the
I<compile callback> and C<run> for the I<run callback>.

The I<compile callback> is called as the syntax is compiled, it's passed
the template object, the token being compiled, the position data-structure
marking the current position in the template and a hashref of the named
args set in the statement being compiled.

It should return a value that will be passed as an argument to the
I<run callback> when the compiled statement is executed, or C<undef>
to indicate that the statement should be dropped entirely from the
compiled template.

The I<run callback> is called whenever the compiled statement is run,
being passed the template object, the token being run and the compiled
arguments. (Note that the position is I<not> passed to the run callback.)

It should return a string containing the content to be inserted into the
template output, or C<undef> if no output is to be produced.

Here's an example from a L<Template::Sandbox> subclass to allow
C<< <: url :> >> statements:

  sub initialize
  {
      my ( $self, $param ) = @_;

      $self->register_template_syntax(
          'url' =>
              {
                  compile => \&compile_url,
                  run     => \&run_url,
              }
              );

      $self->SUPER::initialize( $param );
  }

  sub compile_url
  {
      #  This isn't a method despite similar args.
      my ( $self, $token, $pos, $args ) = @_;

      $args = {
          map
          {
              $_ => $self->_compile_expression( $args->{ $_ } )
          }
          keys( %{$args} ) };
      $args = 0 unless scalar( keys( %{$args} ) );

      return( $args );
  }

  sub run_url
  {
      #  This isn't a method despite similar args.
      my ( $self, $token, $args ) = @_;

      $args ||= {};

      #  Craft url with given param.
      return( $app->input()->url( {
          map
          {
              $_ => $self->_eval_expression( $args->{ $_ }, 1 )
          }
          keys( %{$args} ) },
          1 ) );
  }

Currently I<custom template syntaxes> don't really let you achieve
anything you couldn't achieve with a I<custom template function>,
and you potentially miss out on fringe benefits like I<constant-folding>
optimizations. You also can't produce block-style statements like
C<if> or C<for> constructs, both of these situations may change in
future releases.

=head1 ZERO-WIDTH FOLDING

Flow control statements (such as C<if> and C<for>) and C<include>
statements are subject to I<zero-width folding>, this means that the
existence of the statement token itself should be treated as invisible
to the output of your document, even if for clarity reasons the token
has been placed on a single line by itself.

Cutting through the jargon, what this means is that these statements
won't liberally sprinkle newlines through your document if you do
the following:

  This is some text.
  <: if a :>
  Case a is true.
  <: else :>
  Case a is false.
  <: endif :>
  This is some more text.

With zero-width folding, this produces (with C<a> true):

  This is some text.
  Case a is true.
  This is some more text.

Whereas without zero-width folding, the more literal output is probably
not what you intended:

  This is some text.

  Case a is true.

  This is some more text.

This is because each clause of the C<if> statement actually has a newline
preceding and trailing it, so while the statement itself produces no output
you're left with doubled newlines - the I<zero-width folding> reduces these
to the single newline you probably intended.

It is not currently (and may never be, unless someone really needs it)
possible to disable I<zero-width folding>.

=head1 CACHING

Like most template systems L<Template::Sandbox> is heavily optimized for
speed when a template is run, sometimes at the expense of the time taken
to compile the template in the first place: currently compilation of a
template is approximately three to four times slower than running it.
(This is a very rough metric based on my practical experience for a typical
template: large or small numbers of loops at runtime will sway this figure
back and forth - they only get compiled once, but run many times.)

This strategy assumes that you'll be using some form of persistent caching
mechanism, and L<Template::Sandbox> provides an in-built caching mechanic
to make this easier for you.

Via the C<cache> constructor param or the
C<< $template->set_cache( $cache ) >> method, you can supply a cache
object of your own choosing and configuration for L<Template::Sandbox>
to use.

The only restriction on the cache object is that it must conform to
either the L<Cache::Cache> API or the extended C<set()> API of
L<Cache::CacheFactory>.

If C<< $cache->set_takes_named_param() >> exists and returns true, or
C<< $cache->isa( 'Cache::CacheFactory' ) >> returns true then the extended
(named-parameter) version of C<< $cache->set() >> will be used, this will
pass the dependencies of the template as a named parameter C<dependencies>
which is suitable for use for the 'lastmodified' expiry policy of
L<Cache::CacheFactory>.

If the extended version of C<set()> is I<not> used, then I<no dependencies
checking will be performed at all>. This may change in future versions
with L<Template::Sandbox> running its own dependencies checking to support
caches that don't perform their own.

By default L<Template::Sandbox> includes all superclasses of the template
as dependencies for the template, since if the template module changes it
may invalidate the compiled template. In a production environment this can
impose a performance hit as these relatively unchanging module files are
C<stat()>ed on each template request. To avoid this penalty you can prevent
the modules from being placed on the dependencies list by setting the
C<ignore_module_dependencies> constructor option to a true value.
If you do this, you should manually flush any cached templates when you
upgrade the template modules.

Some example code snippets for caching:

  #  Using Cache::Cache's Cache::FileCache.pm
  $cache    = Cache::FileCache->new();
  $template = Template::Sandbox->new(
      cache    => $cache,
      template => 'profile.html',
      );
  print ${$template->run()};

  $cache    = Cache::FileCache->new(
      namespace  => 'mytemplates',
      cache_root => '/var/tmp/template_cache',
      );
  $template = Template::Sandbox->new();
  $template->set_cache( $cache );
  $template->set_template( 'profile.html' );
  print ${$template->run()};

  #  Using Cache::CacheFactory
  $cache = Cache::CacheFactory->new(
      namespace => 'mytemplates',
      storage   => 'file',
      validity  => 'lastmodified',
      );
  $template = Template::Sandbox->new(
      cache    => $cache,
      template => 'profile.html',
      );
  print ${$template->run()};

  #  Using CHI
  $cache = CHI->new(
      driver  => 'Memory',
      global  => 1,
      );
  $template = Template::Sandbox->new(
      cache    => $cache,
      template => 'profile.html',
      );
  print ${$template->run()};

See L<Cache::Cache>, L<Cache::CacheFactory> and L<CHI> for further
details on configuring cache objects.

Being able to pass in your own cache object to L<Template::Sandbox>
allows you to choose a cache that truly fits your needs, and to make
use of some of the great caching modules on CPAN.

Choosing the right caching module can gain you large performance
advantage over the in-built caching methods of many other template
systems, here's some example situations with code-snippets to generate
a suitable cache for it.

=head2 In-memory cache, per process

  $cache = Cache::CacheFactory->new(
        storage       => 'fastmemory',
        validity      => 'lastmodified',
        no_deep_clone => 1,
        );

This builds you a cache that will store the compiled template in-memory
once per process, the C<'fastmemory'> storage policy provides a fast
set/get process and the C<no_deep_clone> option turns off cloning of
the data structure, this is safe because once the template has been
compiled it's treated in a read-only manner, so there's no need to
worry about polluting the cache by running it.

The C<'lastmodified'> storage policy causes the dependencies of the
template to be checked against the cached data, this imposes some
speed penaltly and can be left out, although if you're planning to
do that (and not use any of L<Cache::CacheFactory>'s other features),
you should consider using the L<Cache::FastMemory> module
directly for additional speed.

This is great to use when you're in a situation where you're using
a small number of templates repeatedly within each process, or you
have a long-running process using a large number of templates and
memory is no issue.  (We can all dream, right?)

=head2 Shared memory cache

  $cache = Cache::FastMmap->new(
      share_file => "/tmp/somewhere-or-other",
      cache_size => '100k',
      ),

Sick of multi-gajillion megabyte apache processes, but still want the
speed of a memory cache?

L<Cache::FastMmap> is for you, it'll store the compiled templates
in a file accessed via C<mmap()> for blistering speed.
You lose somewhere around 20% performance compared to using
C<Cache::FastMemory>, but if multiple processes are using the same
template you'll have fewer cache-misses and use a lot less memory.

Started from within your C<startup.pl> to ensure the memory is shared
among all server children, this makes a really nice match for a
C<mod_perl> environment.

=head2 On-disk cache

  $cache = CHI->new(
      driver   => 'File',
      root_dir => '/tmp/my-template-cache-dir',
      );

  $cache = Cache::CacheFactory->new(
      storage  => { 'file' => { cache_root => '/tmp/cachedir', }, },
      validity => 'lastmodified',
      );

If you're not so fussed about the performance of repeated template use
within a process, but want subsequent processes to not take the hit
of having to compile each time, then an on-disk cache is what you need.

This is probably what you want if you're running in a CGI environment.

L<CHI> provides a faster disk cache than L<Cache::CacheFactory>, but
doesn't hook up to the dependencies checking, both are pretty fast and
are only somewhere in the region of 25-50% of the speed of using
memory caching.

L<CHI> also requires L<Moose>, so if large dependency chains or
startup time are an issue for you, it's something to be aware of.

=head2 Multi-level caches

Both L<CHI> and L<Cache::CacheFactory> allow you to set up multi-level
caches so that you can check a memory cache first, and fetch from a
disk cache second if the memory cache fails.

That's somewhat outside the scope of this document however, so I suggest
you read the documentation of the respective modules for details.

=head1 SUBCLASSING Template::Sandbox

=head2 Useful methods to override when subclassing

These methods are likely to be of interest to you when subclassing
L<Template::Sandbox>.

=over

=item B<< $template->initialize( >> I<%param> B<)>

Called as part of the constructor, C<initialize()> is designed for
you to override, with the hash C<%param> passed as a single argument
containing the merged valid parameters passed to the constructor.

If you override this method, make sure that you call
C<< $self->SUPER::initialize( %param ) >> at some point, otherwise
L<Template::Sandbox> won't get chance to do its own initialization.

Singular param (see below) will be supplied as a single value in
C<%param>.  Multiple param will be supplied as an arrayref of
the I<exact> values that were passed to the constructor, this
means that if you pass an arrayref of values I<as> the param,
you will end up with an arrayref of arrayref(s).

=item B<< $template->get_valid_singular_constructor_param() >>

=item B<< $template->get_valid_multiple_constructor_param() >>

Override these methods to add to the list of valid parameters that
the constructor should accept and place into the C<%param> passed
to C<initialize()>. Make sure that you include the contents of
C<< $self->SUPER::get_valid_singular_constructor_param() >> or
C<< $self->SUPER::get_valid_multiple_constructor_param() >> otherwise
the standard paramaters won't be accepted as valid.

The I<singular> version lists those param that may only be supplied
once to the constructor, and I<multiple> for those that may be
supplied more than once.

=item B<< $template->get_template_candidates( >> I<$filename>, I<$dir> B<)>

=item B<< $template->get_include_candidates( >> I<$filename>, I<$dir> B<)>

These two methods are called to find the candidate filenames to
check for existence before loading a template.

They're supplied the filename as passed to the C<template> constructor
option or the C<< $template->set_template( $filename ) >> method,
and the I<current directory>.

The current directory is the current working directory for templates
and the directory of the template doing the including for includes.

The list they return will be iterated through until the first file
that actually exists is found, which will then be used as the template
file.

This would allow you to, for example, make your subclass cascade back
up a directory structure looking for a matching filename, or to
search through a list of include directories.

Note that the I<filename> parameter I<does not> have any C<template_root>
prepended, the behaviour of C<template_root> is in fact implemented
within the default version of C<< $template->get_template_candidates() >>
and you are free to support or ignore the behaviour in your implementation.

=item B<< $template->get_additional_dependencies() >>

This method is called when building a list of dependencies for the
current template for the purposes of checking if the cached version
of a compiled template is still fresh.

If for some reason your subclass contains dependencies that are not
discovered by the existing methods, you can provide your own mechanism
here to add more to the list.

An example could be if some behaviour of the compile of your template
is effected by entries your application's config file, you could return
the filename of the config file here, and whenever the config file is
updated any old cache entries will be invalidated.

=back

=head1 NOTES ON INTERNAL IMPLEMENTATION AND OTHER GORY DETAILS

This section contains a lot of technical information on how
L<Template::Sandbox> is implemented, you probably don't need
to know any of this stuff, so feel free to skip this section
entirely unless you're morbidly curious or feel it may be
relevent to your use.

=head2 Parsing and Compilation

Parsing of templates is the first step of the compile phase, it's
done by hand-crafted (and exceedingly ugly) regexps.

These regexps make heavy use of the C<(??{ ... })> subexpression
syntax to handle dealing with bracket- and quote-matching.

Sorry to older Perls who don't understand this newfangled stuff.

These regexps could run faster with some of the fancy new perl 5.10
regexp syntaxes designed for subregexps, but 5.10 is a bit I<too>
newfangled just now thanks.

These regexps don't run across your entire template at once (thankfully),
instead the template is broken down into I<hunks> by opening C<< <: >>
and each I<hunk> is then proccessed in turn.

The first stage of I<hunk> processing is to check that it fits the general
format of a known statement, broadly: <: I<known_statement> I<some_stuff> :>,
without being too fussy about what I<some_stuff> is, and dumping anything
after the closing C<< :> >> onto the hunk queue.  Note that since we're not
fussy about what's in I<some_stuff> this imposes limitations on whether we
can check we've matched "the right" closing C<< :> >> or not, see
L</"KNOWN ISSUES AND BUGS"> for more on this.

Depending on the statement, I<some_stuff> gets further parsing with
appropriate regexps and turned into an I<instruction> and
I<arguments> (and sometimes some additional flags) for the compiled
template program.

In the case of loops and branches, a stack is maintained of any opening
statements, and when the corresponding closing statements are produced
the stack is popped and each branch has its jump target updated to point
to the statement after the end of the construct.

As you may deduce from the previous paragraph, the compiled program itself
is a fairly simple linear list of instructions with jumps to implement
flow-control, it could have been implemented as an abstract syntax tree
or the like, but it wasn't. Although the structure of a compiled expression
I<is> one, just to be contrary.

If you're curious about the structure, you can make use of the
C<< $template->dumpable_template() >> method to produce a somewhat
literal dump of the compiled program with a degree of human-readability
(for I<strange> humans anyway).

=head2 Template Program Optimization

After compilation, several optimization passes are made over the
template program to eliminate common inefficiencies:

=over

=item Expression Constant Folding.

This doesn't actually happen within the optimization sweep, but instead
happens as the expression arguments are compiled, it's documented here
because this is where you'd expect to find the documentation.

Expressions have I<constant-folding> applied at two main places:

=over

=item Operator Constant Folding

If both sides of an operator are constant values then the operator is
evaluated at compile-time and the result substituted as a constant itself.

For unary operators the same occurs if the single argument is constant.

Note that, currently, constant-folding only occurs if both sides of an
operator are constant, even in the case where left-wise lazy-evaluation
(aka "short circuit") with a constant LHS would make an inconstant RHS
irrelevent.

That is:

  <: expr 42 || 0 :>

Will be folded to 

  <: expr 42 :>

but:

  <: expr 42 || a :>

will not be folded even though, when run, the right-hand side will
never be evaluated because C<42> is always true.

=item Function Constant Folding

If all arguments to a function are constant and the function I<wasn't>
constructed with the C<inconstant> flag, then the function is evaluated
at compile-time and the result substituted as a constant value.

=back

=item "Void Wrapping" of assigns.

Not really an optimization, however this is performed at the same time
as the optimization sweep: any assigns at the top level of an C<expr>
statement are flagged as being in a void context so that they don't
insert their value into the output of the document.

=item Constant-Expression Constant Folding

Any C<expr> statements that consist solely of a constant value are
converted into a literal statement of that value. This doesn't check
for I<constant-folding> within an I<expression> since that is done
during the compilation stage of expressions automatically.

=item Conditional Branch Constant Folding

Any C<if> statement branches that are the result of a constant expression
are either converted into unconditional branches or pruned entirely from
the program accordingly.

=item Context Folding

Any cases of a C<CONTEXT_PUSH> where there is no need for a new context,
such as an include of a file with no scoped variables, are removed.

While the empty C<CONTEXT_PUSH> and C<CONTEXT_POP> itself is fairly painless
it adds an extra loop iteration up the context stack to every variable
evaluation within that context, which can rapidly add up, so pruning these
is a surprisingly "big win".  This is also another good reason to use
I<defines> within an C<include> statement where possible instead of
I<scoped variables>. (See L</"Defines vs Scoped Variables"> for more
details.)

The equivilent context-folding for C<for> loops happens at run-time,
a marginal gain could be made by pushing this up to the optimization
sweep, but would result in significantly more complexity to achieve
the same behaviour.

=item Adjacent-Literal Constant Folding

Any adjacent literal values are now merged into a single literal, unless
there's a reason not to (such as the second being the target of a C<JUMP>
instruction.)

Especially after the pruning of previous optimizations, this can reduce the
number of C<LITERAL> instructions quite significantly, and fewer instructions
is always better, especially one so lightweight as C<LITERAL> where the
overhead of running the instruction is disproportional to the actual
work entailed in the instruction itself.

=item Special Loop Variable Pruning

Each loop is analyzed to see if the special loop variables are used
within that loop and if not a flag is set against that loop to indicate
it should skip creating them.

This is an all-or-nothing affair, use of any C<__inner__>, C<__counter__>,
etc special variable will cause them all to be created for that loop.

Note that this has nothing to do with access to the loop variable itself.
For example, this will optimize:

  <: for x in 5 :><: expr x :><: endfor :>

Whereas, this will not:

  <: for x in 5 :><: expr x.__inner__ :><: endfor :>

Also note that any non-constant-folded expression subscript against
the loop variable cannot be analysed at runtime, so causes the special
variables to be created just in case.
So, this will not optimize, even if z isn't set to the name of a
special variable:

  <: for x in y :><: expr x[ z ] :><: endfor :>

The gain per loop is only on the order of 20 microseconds, so really
don't stress yourself too much about reaching for this optimization
if you're doing anything much at all within the body of the loop.

=back

There are several further candidates for optimizations on the TODO list,
the most important is probably to make the C<for> loop
context-folding occur in the optimization sweep rather than at run-time.

=head2 Template Program Execution

=head2 Internal Constants

The following internal constants are used within L<Template::Sandbox>
and can be accessed via C<Template::Sandbox::CONSTANTNAME> if needed
for some reason.

General indices:

=over

=item SELF

=item OP_LHS

=item OP_RHS

=back

Compiled statement indices:

=over

=item LINE_INSTR

=item LINE_POS

=item LINE_ARG

=back

Instruction opcodes:

=over

=item LITERAL

=item DEBUG

=item EXPR

=item JUMP

=item JUMP_IF

=item FOR

=item END_FOR

=item CONTEXT_PUSH

=item CONTEXT_POP

=item LOCAL_SYNTAX

=back

Expression opcodes:

=over

=item OP_TREE

=item UNARY_OP

=item FUNC

=item METHOD

=item VAR

=item TEMPLATE

=back

Template function array indices:

=over

=item FUNC_FUNC

=item FUNC_ARG_NUM

=item FUNC_NEEDS_TEMPLATE

=item FUNC_INCONST

=item FUNC_UNDEF_OK

=back

Special loop variable array indices:

=over

=item LOOP_COUNTER

=item LOOP_EVEN

=item LOOP_ODD

=item LOOP_FIRST

=item LOOP_INNER

=item LOOP_LAST

=item LOOP_PREV

=item LOOP_NEXT

=item LOOP_VALUE

=back

For loop stack array indices:

=over

=item LOOP_STACK_COUNTER

=item LOOP_STACK_LAST

=item LOOP_STACK_SET

=item LOOP_STACK_HASH

=item LOOP_STACK_CONTEXT

=item LOOP_STACK_SPECIALS

=back

=head1 PERFORMANCE CONSIDERATIONS AND METRICS

This section aims to give you a few hints and tips on making your
templates run efficiently.

Not all of these points apply in all situations, and many are fairly
marginal unless you're running a large and complicated template, these
are merely presented as starting points and explanations that may
(or may not) prove helpful.

=head2 Defines vs Scoped Variables

Where possible you should consider using I<compile defines> instead of
I<scoped variables> when you're doing an C<include> of another template,
in fact you should consider using I<compile defines> over any kind of
variable if possible, but it's particularly relevent to includes:

=over

=item Pros of Defines over Scoped Variables

=over

=item Compile-time vs run-time

I<Compile defines> are inserted into the template as literal values
as the template is compiled, whereas variables are evaluated at
run-time each time they are used.

=item Allows context-folding of the included template

Whenever you pass I<scoped variables> to an include a new context
must be pushed onto the context stack, if no I<scoped variables>
are passed then the C<include> is a candidate for I<context-folding>
optimizations.

Since the context stack must be traversed for every variable access,
this makes access of any variables within your included template
(or anything it includes) faster.

=item Allows constant-folding of expressions using the define

Since I<compile defines> are placed in the template as constant
values it make them candidates for I<constant-folding> optimizations,
this can't happen with a variable as there's no way of telling that
it is unchanging between runs.

=back

=item Cons of Defines over Scoped Variables

=over

=item Defines contribute to the cache key, causing more cache misses

When a template is cached it needs to have a cache key that reflects
all parameters that contributed to the compiled content, that includes
the names and values of all defines.

This means that a template with any defines with differing values from
previous compiles will cause a cache-miss, meaning an expensive compile
phase and more entries overall in your cache. This may or may not be
a downside for you.

=back

=back

=head2 Method Calls

Method calls within template expressions are potentially much more
inefficient than I<template functions>, where possible you should
consider creating a I<template function> instead.

Here's a list of things to consider in the evaluation of a method
call within a template, that prevent it from being as fast:

=over

=item Evaluation of object

The object to call the method on is stored within a I<template variable>
which must be evaluated.

Since pretty much all I<template variables> originate in your perl code,
it's highly likely that a I<custom template function> could determine the
object directly from your application's data-structure eliminating the
I<template variable> access.

The same applies to any arguments to the method that originate in
I<template variables>.

=item Object is inconstant

Because the object to call the method on is within a I<template variable>,
it cannot be determined at compile-time (even if it does turn out to be a
constant value), meaning that methods cannot have I<constant-folding>
optimizations applied to them, unlike I<template functions>.

=item Every method call is actually two method calls

Each call to a method within a template actually translates to two
method calls on the object in perl: the first is the call to
C<valid_template_method( $method_name )> to determine if the method
call should be permitted.

The cost of calling this permission method may be insignificant (depending
on your implementation), but if the method to be called is also insignificant
in cost it may, proportionaly speaking, be a large overhead.

=back

=head2 Constant-folding vs Operators

Operators only have I<constant-folding> applied if both sub-expressions
are constants, even if lazy-evaluation would prevent a right-hand
expression from being evaluated.

This is detailed further in L</"KNOWN ISSUES AND BUGS">.

=head2 Metrics

Here's a dump of some raw metrics from the L<benchmark_template_engines>
script provided by L<Template::Benchmark>.

I'll state up front that I'm also the author of L<Template::Benchmark>,
and while I endeavour to make it give unbiased results, I wouldn't
want anyone thinking I was trying to pass it off as an independent
evaluation. :)

Also note that the template is a very simple template making little
use of the advanced features of many of the template systems, since
not all systems support equivilent features, this benchmark is the
result of the "lowest common denominator" set of features, if you
want to check performance of a specific set of features, I heartily
(and shamelessly self-promotingly) recommend investigating
L<Template::Benchmark>.

I make no claims for how representive these numbers are of any
particular real-world situation, and it should be taken as read
that I know how to do a better job of optimizing my own templating
system's setup compared to others - these results may well be
doing other systems an injustice.

With that disclaimer said, the results do seem reasonable and give
a broad indication of strengths and weaknesses of some systems, so
here's the data.

  Output of benchmark_template_engines --progress \
    --norecords_loop_template --novariable_if_template \
    --novariable_if_else_template
  --- Starting Benchmarks --------------------------------------------------------
  ETA: 73 benchmarks to run = 730 seconds minimum.
  progress: 100% [============================================================ ]D 0h14m58s--- Template Benchmark @Sun Mar 21 13:25:14 2010 -------------------------------
  HT         - HTML::Template (2.9)
  HTC        - HTML::Template::Compiled (0.94)
  HTE        - HTML::Template::Expr (0.07)
  HTJ        - HTML::Template::JIT (0.05)
  HTP        - HTML::Template::Pro (0.93)
  MoTe       - Mojo::Template (0.999921)
  NT         - NTS::Template (2.1)
  TAHT       - Template::Alloy (1.013) in HTML::Template mode
  TATT       - Template::Alloy (1.013) in Template::Toolkit mode
  TATT_P     - Template::Alloy (1.013) in Template::Toolkit mode (compile to
               perl)
  TATT_PS    - Template::Alloy (1.013) in Template::Toolkit mode (compile to
               perl, using process_simple())
  TATT_S     - Template::Alloy (1.013) in Template::Toolkit mode (using
               process_simple())
  TS         - Template::Sandbox (1.03) without caching
  TS_CF      - Template::Sandbox (1.03) with Cache::CacheFactory (1.10)
               caching
  TS_CHI     - Template::Sandbox (1.03) with CHI (0.34) caching
  TS_FMM     - Template::Sandbox (1.03) with Cache::FastMmap (1.34) caching
  TT         - Template::Toolkit (2.22)
  TT_X       - Template::Toolkit (2.22) with Stash::XS (no version number)
  TT_XCET    - Template::Toolkit (2.22) with Stash::XS (no version number) and
               Template::Parser::CET (0.05)
  TTiny      - Template::Tiny (0.11)
  TeMMHM     - Text::MicroMason (2.07) using Text::MicroMason::HTMLMason (no
               version number)
  TeMMTeTe   - Text::MicroMason (2.07) using Text::MicroMason::HTMLMason (no
               version number)
  TeMT       - Text::MicroTemplate (0.11)
  TeTe       - Text::Template (1.45)
  TeTeSimp   - Text::Template::Simple (0.81)
  TeTmpl     - Text::Tmpl (0.33)
  Tenj       - Tenjin (0.051)
  --- uncached_string ------------------------------------------------------------
             Rate   TTiny TeMMTeTe    HTC     TT   TT_X    HTE TT_XCET   TATT TeTeSimp    TS  TeMT  MoTe  TAHT    HT TeMMHM  TeTe TeTmpl   HTP
  TTiny    1.45/s      --     -14%   -83%   -85%   -87%   -89%    -93%   -93%     -94%  -95%  -95%  -95%  -96%  -97%   -97%  -98%  -100% -100%
  TeMMTeTe 1.69/s     17%       --   -80%   -83%   -85%   -87%    -91%   -91%     -93%  -94%  -95%  -95%  -95%  -97%   -97%  -98%  -100% -100%
  HTC      8.65/s    497%     411%     --   -11%   -25%   -35%    -56%   -56%     -66%  -71%  -72%  -72%  -74%  -82%   -83%  -87%   -99% -100%
  TT       9.72/s    571%     474%    12%     --   -16%   -27%    -51%   -51%     -62%  -68%  -69%  -69%  -71%  -80%   -81%  -86%   -98% -100%
  TT_X     11.5/s    696%     581%    33%    19%     --   -13%    -41%   -42%     -54%  -62%  -63%  -63%  -66%  -76%   -78%  -83%   -98%  -99%
  HTE      13.3/s    820%     687%    54%    37%    16%     --    -32%   -32%     -47%  -56%  -57%  -57%  -60%  -73%   -74%  -80%   -98%  -99%
  TT_XCET  19.7/s   1258%    1061%   127%   102%    70%    48%      --    -0%     -22%  -35%  -37%  -37%  -42%  -60%   -62%  -71%   -97%  -99%
  TATT     19.7/s   1263%    1065%   128%   103%    71%    48%      0%     --     -22%  -35%  -36%  -37%  -41%  -59%   -62%  -71%   -97%  -99%
  TeTeSimp 25.3/s   1647%    1393%   192%   160%   119%    90%     29%    28%       --  -17%  -18%  -19%  -25%  -48%   -51%  -63%   -96%  -99%
  TS       30.3/s   1995%    1691%   251%   212%   163%   128%     54%    54%      20%    --   -2%   -3%  -10%  -38%   -41%  -56%   -95%  -99%
  TeMT     31.0/s   2040%    1730%   258%   219%   169%   133%     58%    57%      23%    2%    --   -1%   -8%  -36%   -40%  -55%   -95%  -99%
  MoTe     31.4/s   2066%    1752%   263%   223%   172%   135%     59%    59%      24%    3%    1%    --   -7%  -36%   -39%  -54%   -95%  -98%
  TAHT     33.6/s   2222%    1886%   289%   246%   192%   152%     71%    70%      33%   11%    8%    7%    --  -31%   -35%  -51%   -95%  -98%
  HT       48.7/s   3261%    2774%   463%   401%   322%   265%    148%   147%      92%   60%   57%   55%   45%    --    -5%  -29%   -92%  -98%
  TeMMHM   51.4/s   3449%    2935%   494%   429%   346%   286%    161%   160%     103%   69%   66%   64%   53%    6%     --  -25%   -92%  -98%
  TeTe     68.2/s   4613%    3930%   689%   602%   492%   412%    247%   246%     170%  125%  120%  118%  103%   40%    33%    --   -89%  -97%
  TeTmpl    612/s  42196%   36067%  6982%  6200%  5211%  4495%   3015%  3003%    2322% 1919% 1876% 1853% 1722% 1158%  1092%  797%     --  -70%
  HTP      2072/s 143027%  122288% 23867% 21218% 17871% 15450%  10441% 10402%    8095% 6732% 6587% 6509% 6064% 4158%  3933% 2937%   238%    --
  --- uncached_disk --------------------------------------------------------------
             Rate TeMMTeTe    HTC    HTE TeTeSimp  MoTe    TS    HT    NT TeMMHM  Tenj  TeTe TeTmpl   HTP
  TeMMTeTe 1.68/s       --   -80%   -87%     -93%  -94%  -94%  -96%  -96%   -97%  -97%  -98%  -100% -100%
  HTC      8.48/s     405%     --   -35%     -66%  -69%  -72%  -82%  -82%   -84%  -87%  -87%   -99% -100%
  HTE      13.1/s     676%    54%     --     -48%  -53%  -57%  -72%  -72%   -75%  -80%  -81%   -98%  -99%
  TeTeSimp 25.2/s    1398%   197%    93%       --   -9%  -17%  -46%  -46%   -51%  -61%  -63%   -96%  -99%
  MoTe     27.7/s    1545%   226%   112%      10%    --   -9%  -40%  -40%   -47%  -57%  -59%   -95%  -99%
  TS       30.2/s    1698%   256%   132%      20%    9%    --  -35%  -35%   -42%  -53%  -55%   -95%  -99%
  HT       46.3/s    2655%   446%   255%      84%   67%   53%    --   -0%   -11%  -27%  -31%   -92%  -98%
  NT       46.4/s    2657%   447%   255%      84%   68%   53%    0%    --   -11%  -27%  -31%   -92%  -98%
  TeMMHM   51.9/s    2984%   511%   297%     106%   87%   72%   12%   12%     --  -19%  -23%   -91%  -97%
  Tenj     63.9/s    3698%   653%   389%     154%  131%  111%   38%   38%    23%    --   -5%   -89%  -97%
  TeTe     67.4/s    3910%   695%   416%     168%  144%  123%   46%   45%    30%    6%    --   -88%  -97%
  TeTmpl    570/s   33798%  6618%  4266%    2163% 1961% 1785% 1130% 1129%   999%  792%  745%     --  -72%
  HTP      2072/s  123109% 24319% 15768%    8124% 7390% 6752% 4372% 4368%  3895% 3144% 2973%   263%    --
  --- disk_cache -----------------------------------------------------------------
             Rate TATT_P TATT_PS    TT  TATT TATT_S  TeMT   HTC TT_XCET  TT_X  TAHT    HT TeTeSimp TS_CF TS_CHI Tenj  HTP
  TATT_P   25.2/s     --     -0%  -10%  -23%   -23%  -41%  -44%    -50%  -50%  -59%  -62%     -76%  -80%   -80% -91% -99%
  TATT_PS  25.3/s     0%      --   -9%  -22%   -22%  -40%  -44%    -50%  -50%  -58%  -62%     -76%  -80%   -80% -91% -99%
  TT       27.9/s    11%     10%    --  -14%   -14%  -34%  -38%    -45%  -45%  -54%  -58%     -74%  -78%   -78% -90% -99%
  TATT     32.5/s    29%     29%   17%    --    -0%  -23%  -28%    -36%  -36%  -46%  -51%     -70%  -74%   -74% -88% -98%
  TATT_S   32.6/s    29%     29%   17%    0%     --  -23%  -28%    -35%  -36%  -46%  -51%     -70%  -74%   -74% -88% -98%
  TeMT     42.5/s    69%     68%   52%   31%    30%    --   -6%    -16%  -16%  -30%  -35%     -60%  -66%   -66% -84% -98%
  HTC      45.1/s    79%     78%   62%   39%    38%    6%    --    -11%  -11%  -26%  -32%     -58%  -64%   -64% -83% -98%
  TT_XCET  50.5/s   100%    100%   81%   55%    55%   19%   12%      --   -0%  -17%  -23%     -53%  -59%   -60% -81% -98%
  TT_X     50.6/s   101%    100%   81%   55%    55%   19%   12%      0%    --  -17%  -23%     -53%  -59%   -60% -81% -98%
  TAHT     60.8/s   141%    141%  118%   87%    87%   43%   35%     20%   20%    --   -8%     -43%  -51%   -51% -77% -97%
  HT       65.9/s   161%    161%  136%  102%   102%   55%   46%     30%   30%    8%    --     -38%  -47%   -47% -75% -97%
  TeTeSimp  107/s   325%    323%  284%  229%   229%  152%  138%    112%  112%   76%   63%       --  -14%   -14% -60% -95%
  TS_CF     124/s   394%    392%  346%  282%   282%  193%  176%    147%  146%  105%   89%      16%    --    -1% -53% -94%
  TS_CHI    125/s   396%    395%  349%  285%   284%  195%  178%    148%  147%  106%   90%      17%    1%     -- -53% -94%
  Tenj      267/s   959%    956%  857%  720%   719%  528%  492%    429%  428%  339%  305%     149%  115%   113%   -- -87%
  HTP      2070/s  8111%   8087% 7323% 6261%  6255% 4772% 4493%   4001% 3994% 3304% 3043%    1833% 1564%  1554% 676%   --
  --- shared_memory_cache --------------------------------------------------------
           Rate TS_CHI TS_FMM    HTP
  TS_CHI  129/s     --    -3%   -94%
  TS_FMM  133/s     3%     --   -94%
  HTP    2073/s  1505%  1454%     --
  --- memory_cache ---------------------------------------------------------------
             Rate    HTE  TeMT  TAHT    HT   HTC TS_CHI TS_CF TeTeSimp   HTP   HTJ
  HTE      15.3/s     --  -64%  -77%  -80%  -88%   -88%  -91%     -96%  -99%  -99%
  TeMT     42.7/s   179%    --  -36%  -44%  -66%   -67%  -74%     -89%  -98%  -98%
  TAHT     67.2/s   340%   57%    --  -12%  -47%   -49%  -59%     -83%  -97%  -97%
  HT       76.0/s   397%   78%   13%    --  -40%   -42%  -54%     -81%  -96%  -97%
  HTC       128/s   734%  198%   90%   68%    --    -3%  -22%     -68%  -94%  -95%
  TS_CHI    131/s   759%  207%   95%   73%    3%     --  -20%     -67%  -94%  -95%
  TS_CF     164/s   970%  283%  143%  115%   28%    25%    --     -59%  -92%  -93%
  TeTeSimp  402/s  2529%  841%  498%  429%  215%   206%  146%       --  -81%  -83%
  HTP      2073/s 13453% 4750% 2983% 2627% 1525%  1478% 1166%     415%    --  -14%
  HTJ      2399/s 15584% 5512% 3468% 3056% 1781%  1726% 1366%     497%   16%    --
  --- instance_reuse -------------------------------------------------------------
             Rate  TATT TATT_S TATT_P TATT_PS    TT  TeTe  TT_X TT_XCET    TS Tenj TeMMHM TeMMTeTe MoTe
  TATT     34.3/s    --    -0%    -4%     -4%  -24%  -78%  -79%    -79%  -80% -88%   -98%     -98% -99%
  TATT_S   34.4/s    0%     --    -4%     -4%  -24%  -78%  -78%    -79%  -80% -88%   -98%     -98% -99%
  TATT_P   35.8/s    4%     4%     --     -0%  -20%  -77%  -78%    -78%  -79% -88%   -98%     -98% -99%
  TATT_PS  35.9/s    5%     4%     0%      --  -20%  -77%  -78%    -78%  -79% -88%   -98%     -98% -99%
  TT       45.1/s   31%    31%    26%     26%    --  -71%  -72%    -72%  -74% -84%   -98%     -98% -99%
  TeTe      156/s  356%   354%   337%    336%  247%    --   -2%     -2%   -9% -46%   -92%     -93% -95%
  TT_X      160/s  365%   364%   345%    345%  254%    2%    --     -0%   -7% -45%   -92%     -93% -95%
  TT_XCET   160/s  367%   366%   347%    347%  256%    2%    0%      --   -7% -44%   -92%     -93% -95%
  TS        172/s  400%   398%   379%    379%  281%   10%    8%      7%    -- -40%   -91%     -92% -94%
  Tenj      288/s  739%   735%   703%    702%  538%   84%   80%     79%   68%   --   -85%     -87% -91%
  TeMMHM   1937/s 5546%  5524%  5305%   5301% 4198% 1138% 1113%   1108% 1028% 573%     --     -13% -37%
  TeMMTeTe 2219/s 6366%  6342%  6090%   6085% 4822% 1318% 1290%   1284% 1192% 671%    15%       -- -28%
  MoTe     3096/s 8924%  8890%  8538%   8532% 6769% 1879% 1839%   1831% 1703% 976%    60%      40%   --

As can be seen from the results, L<Template::Sandbox> ranks
well when it comes to on-disk caching with only the
C<libtmpl>-based L<Text::Tmpl> and the compile-to-C
L<HTML::Template::Pro> running faster.

You can also see this when looking at the in-memory caching, where
the performance gap is even larger among the mostly-perl template
modules, all of whom trail far behind the more exotic compilation
methodologies of L<HTML::Template::Pro> and L<HTML::Template::JIT>.

With the instance-reuse caching (similar but not directly comparable
to in-memory caching), L<Template::Sandbox> still ranks highly, with
only the "embedded-perl" template engines of L<Text::MicroMason> and
L<Mojo::Template> performing better (much much better it must be said).
Of particular note is the performance of TT_XCET, which is
L<Template::Toolkit> running with the XS version of its stash and
parser, surpassed by the pure-perl L<Template::Sandbox>.
Since L<Template::Sandbox> and L<Template::Toolkit> are roughly
comparable as being heavyweights in terms of features, this makes
a useful comparison.

When it comes to the string-template benchmarks, you can see the impact
of being forced to compile the template each time, this is representative
of a cache-miss if you're using caching, and here L<Template::Sandbox>
shows a fairly mediocre performance, partly due to its pure-perl
implementation and partly due to the heavy optimization phase - you can
see similar costs in all the more heavily-compiled template systems.

This paints only the broadest picture and is the tip of the iceberg
when it comes to template benchmarking, if you're interested in
the numbers, I suggest looking at producing your own reports using
L<Template::Benchmark>.

=head1 PRIVATE AND SEMI-PRIVATE METHODS

You're unlikely to ever need to call these methods directly, or to
change them when subclassing L<Template::Sandbox>.

=over

=item B<< $template->find_template( >> I<$filename>, I<$current_dir> B<)>

=item B<< $template->find_include( >> I<$filename>, I<$current_dir> B<)>

These two methods find a matching template for the given filename and
dir, they basically query C<< $template->get_template_candidates() >>
or C<< $template->get_include_candidates() >> and then traverse the
list looking for a file that exists.

B<COMPAT NOTE>: I<$current_dir> will be undef in most cases when
C<find_template> is called, previous versions passed C<Cwd::cwd()> in,
however this imposed dramatic performance penalties if you didn't
need it.

=item B<< $template->cache_key( >> I<$keys> B<)>

Takes a hashref of parameters that uniquely identify the factors that
could alter the compiled template and produces a scalar value suitable
to use as a cache key.

In practice the key is a hashref of the defines (including template
filename) used in compiling the template, and the result is an MD5
hexdigest of a canonical C<nfreeze( $keys )> from L<Storable.pm>.

=item B<< $template->log_error( >> I<$message> B<)>

=item B<< $template->log_warning( >> I<$message> B<)>

Logs I<$message> with the logger object as an error or warning.

=item B<< $template->error( >> I<@message_fragments> B<)>

=item B<< $template->caller_error( >> I<@message_fragments> B<)>

Raises (and logs) an error with the message produced by concatinating
C<@message_fragments> into a single string.  C<caller_error()> reports
the error from the point of view of the calling code.

The error will have any relevent information to do with the current
template position added.

=item B<< $template->fatal_exit( >> I<$message> B<)>

=item B<< $template->caller_fatal_exit( >> I<$message> B<)>

These two do the actual C<die> or C<croak> needed by
C<error> and C<caller_error>, you can override these if you
want to prevent the C<die> or C<croak> and perform some other
behaviour.

=item B<< $template->warning( >> I<@message_fragments> B<)>

=item B<< $template->caller_warning( >> I<@message_fragments> B<)>

Raise (and log) a warning with a message composed of the message
fragments provided.  C<caller_warning()> raises the warning from
the perspective of the caller.

The warning will have any relevent information to do with the current
template position added.

=back

=head1 QUALITY ASSURANCE AND TEST METRICS

As of version 1.04 there are 1993 tests within the distribution, if the
this isn't the current version number, I've forgotton to update this section,
sorry. :)

The tests have coverage:

  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  File                           stmt   bran   cond    sub    pod   time  total
  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  blib/lib/Template/Sandbox.pm   98.7   91.9   89.2  100.0  100.0   99.8   95.7
  ...mplate/Sandbox/Library.pm  100.0  100.0   36.4  100.0  100.0    0.1   93.1
  ...andbox/NumberFunctions.pm  100.0    n/a    n/a  100.0    n/a    0.0  100.0
  ...andbox/StringFunctions.pm  100.0    n/a    n/a  100.0    n/a    0.0  100.0
  Total                          98.8   92.2   86.8  100.0  100.0  100.0   95.7
  ---------------------------- ------ ------ ------ ------ ------ ------ ------

You can generate this report within the distribution's directory by:

   perl Build.PL
   ./Build testcover

Pretty HTML reports will also be produced in the C<< cover_db/ >> subdirectory.

=head2 Why these coverage figures will never be 100%

Most uncovered statements and branches are "cannot happen" internal
sanity checks, the low conditional coverage reflects frequent use of

  function( $thing ) || $thing

constructs with always-true values vs the slower:

  function( $thing ) ? function( $thing ) : $thing

L<Devel::Cover> then thinks (correctly but irrelevently for this purpose)
that the false-false case hasn't been tested and so gives a 67% coverage
to the condition.

=head1 KNOWN ISSUES AND BUGS

=over

=item caller_error() and caller_warning() currently degraded.

L<Carp> currently is intermittantly taking fatal issue in certain
places when generating carp() or croak()s, until I've resolved this
issue these two methods behave as the error() and warning() messages
and don't report from the perspective of your calling code.

=item line numbers and char counts partially broken.

Line numbers and character counts into the original file
are still occassionally incorrect in a couple of (mostly pathological)
situations where template defines either contain fragments of a template
statement that spans the boundary of the statement, or that contain
partial defines themselves.

For example, both of these will confuse the character position count:

  #  ${EGADS} overlaps one, but not both, end of the <: expr :> statement.
  $template->set_template_string(
      "This is${EGADS}ological' :>.",
      {
          EGADS => " <: expr 'path",
      } );

  #  ${ERKLE} overlaps one, but not both, end of ${HURKLE}.
  $template->set_template_string(
      "And so${ERKLE}KLE}this.",
      {
          ERKLE  => '${HUR',
          HURKLE => " <: expr 'is' :> ",
      } );

Although in both these examples the C<expr> will be constant-folded away
and the misnumbered positions will be undetectable.
Examples that don't optimize away are more complicated and unfortunately
obscure the root problem behaviour.

Quite what line numbers result from these constructs is undefined and
unsupported, and possibly will be subject to change without notice.

This bug is not likely to be corrected soon unless it impacts people
trying to do something sane. :)

=item Quoted-':>' inside expressions still terminate the statement

Because of the implementation of the parsing of statements,
the next C<< :> >> after an opening C<< <: >> will I<always> be consided
the closing delimeter, even if it's enclosed within quotes within an
expression.

Whilst this is almost certainly a bug (in that it doesn't do what you
clearly intended it to do), it's unlikely to be resolved since it simplifies
and optimizes the parsing phase very considerably, and as a work-around
you can use either of the following:

  <: expr ':\>' :>
  <: expr ':' . '>' :>

to achieve the intended (but broken):

  <: expr ':>' :>

As a side-note, because of compile-time I<constant-folding>, the resulting
compiled template is no different than that which would have been achieved by
the intended code.

=item C<cr> special variable instead of C<\n>.

Needing to use C<cr> as a special variable instead of the expected C<\n>
interpolation in strings is pretty ugly and awkward.

=item No C<last> or C<continue> within loops.

Although it helps prevent people getting too exotic with the complexity
in their templates, instead of in the application layer where it probably
belongs, having no C<last> or C<continue> can definitely be counted as
a missing feature.

=item Can't set C<filename> scoped variable in an include.

Because the C<include> statement internally uses the C<filename> argument
name to pass the name of the included file around, this prevents you from
setting up a C<filename> variable local to the include from the include
statement, eg:

  <: include included_file.html filename=widget.selected_file :>

Will in fact try to include a file named 'widget.selected_file' when
the template is compiled.

The include statement should probabably use an internal argument name
that isn't going to clash in this manner.

=item Flow Control Constructs inside multiple files.

Building an C<if>-construct or C<for>-loop where the statements are
in different files is currently unsupported and undefined in behavior,
it I<might> do what you want, it might not. It may just die horribly.
It may not do any of those things consistently. It is certainly subject
to change in future versions, when the behaviour may become defined.

Note that it's perfectly ok to I<span> multiple files, as long as the
include statement is entirely nested within the flow control structure,
ie, this is fine and expected:

  <: for row in table :>
  <: include table_row.html :>
  <: end for :>

This however will probably cause problems:

  <: if a :>
  A is true.
  <: include subclauses.html :>
  <: else :>
  Nothing is true.
  <: endif :>

Then in subclauses.html:

  <: elsif b :>
  B is true.

Quite what it will do in this situation is undefined and subject
to a number of variables depending on the exact circumstances, what
I<is> certain is that it won't reliabily be behaving I<correctly>.

=item "Short-circuit" operators only partially constant-folded

As detailed in L</"Template Program Optimization">, operators that
"short circuit" down the left-hand side are only subject to
constant-folding optimizations if both sides of the operator are
constants, even in situations where the "short circuit" would make
the RHS irrelevent at run-time.

This is only a (probably minor) performance bug, and in no way
impacts correct behaviour.

=item Assigns within context-folded for loops persist

There's a subtly inconsistent behaviour between C<for> loops that
have been I<context-folded> and those that haven't, if there is an
assign to a new I<template variable> within the loop, in the
non-folded case, the new variable will exist only for the duration
of the loops, whereas the I<context-folded> case will cause the new
variable to exist until the end of the outer context the C<for>
loop was called from.

This is a bug, and the correct behaviour would be to not I<context-fold>
the loop if there's an assign inside, however this is difficult to test until
I<context-folding> of loops is performed during the compile-phase
optimization rather than at runtime.

=item Void-context assigns should be zero-width

Since I<void-context assigns> produce no template output, they should be
subject to I<zero-width folding>, currently however the void-context
flagging happens (long) after the I<zero-width folding>, so this doesn't
happen.

There's probably no reason why void-context flagging couldn't happen as
part of the expression compilation stage, which would be in time to also
flag it as zero-width, so this should be expected to happen in a future
release.

=item JMP_IF confusingly named

The C<JMP_IF> instruction is confusingly misnamed, since it's really
a C<JMP_UNLESS> instruction. That is it means "jump if the expression
is false" as opposed to the intuitive "jump if the expression is true".
Unless you're messing with the compiled template for some reason, this
is unlikely to effect you.

=back

=head1 SEE ALSO

L<Template::Sandbox::Library>, L<Template::Sandbox::NumberFunctions>,
L<Template::Sandbox::StringFunctions>,
L<Cache::CacheFactory>, L<Cache::Cache>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Sandbox


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Sandbox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Sandbox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Sandbox>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Sandbox>

=back

=head1 THANKS

Thanks to Paul Seamons for creating the benchmark script distributed
with L<Template::Alloy>, the benchmarks in the
L</"PERFORMANCE CONSIDERATIONS AND METRICS"> section were generated
with a modified version of this script.

=head1 AUTHORS

Original author: Sam Graham <libtemplate-sandbox-perl BLAHBLAH illusori.co.uk>

Last author:     $Author: illusori $

=head1 COPYRIGHT & LICENSE

Copyright 2005-2010 Sam Graham, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
