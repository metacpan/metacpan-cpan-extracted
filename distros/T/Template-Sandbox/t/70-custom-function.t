#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox qw/:function_sugar/;
use Test::Exception;

plan tests => 73;

#  TODO:  Surely there's a Test:: module for this?
#         Test::Trap looks to clash with Test::Exception and not old perls.
sub warns_ok( &$$ )
{
    my ( $test, $like, $desc ) = @_;
    my ( $warning_contents );

    {
        $warning_contents = '';
        local $SIG{ __WARN__ } = sub { $warning_contents .= $_[ 0 ]; };
        $test->();
    }

    like( $warning_contents, $like, $desc );
}
sub doesnt_warn( &$ )
{
    my ( $test, $desc ) = @_;
    my ( $warning_contents );

    {
        $warning_contents = '';
        local $SIG{ __WARN__ } = sub { $warning_contents .= $_[ 0 ]; };
        $test->();
    }

    is( $warning_contents, '', $desc );
}
    
my ( $template, $pre_template, $post_template, $function,
     $syntax, $function2, $syntax2, $oldsyntax, $expected );

$function  = "nonexistingfunction";
$syntax    = "<: expr ${function}() :>";
$function2 = "anothernonexistingfunction";
$syntax2   = "<: expr ${function2}() :>";

#
#  1:  Test that the custom function really doesn't exist and causes a fail.
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: Unknown function: nonexistingfunction at line 1, char 1 of/,
    "verify custom function doesn't exist already";

#
#  2-4:  Function added during construction.
ok( $template = Template::Sandbox->new(
    template_function => [
        $function =>
            no_args sub { '[during-construction custom function was ere]' },
        ],
    ), 'construct with custom function as option' );
lives_ok { $template->set_template_string( $syntax ) }
    'parse with during-construction custom function';
is( ${$template->run()}, '[during-construction custom function was ere]',
    'run of during-construction custom function' );

#
#  5-7:  Multiple functions added using separate constructor param.
ok( $template = Template::Sandbox->new(
    template_function => [
        $function =>
            no_args sub { '[during-construction custom function was ere]' },
        ],
    template_function => [
        $function2 =>
            no_args sub { '[during-construction custom function2 was ere]' },
        ],
    ), 'construct with two custom functions from multiple param' );
lives_ok { $template->set_template_string( $syntax . $syntax2 ) }
    'parse with during-construction custom functions from multiple param';
is( ${$template->run()},
    '[during-construction custom function was ere]' .
    '[during-construction custom function2 was ere]',
    'run of during-construction custom functions from multiple param' );

#
#  8-10:  Multiple functions added using single constructor param.
ok( $template = Template::Sandbox->new(
    template_function => [
        $function =>
            ( no_args sub { '[during-construction custom function was ere]' } ),
        $function2 =>
            ( no_args sub { '[during-construction custom function2 was ere]' } ),
        ],
    ), 'construct with two customs function from single param' );
lives_ok { $template->set_template_string( $syntax . $syntax2 ) }
    'parse with during-construction custom functions from single param';
is( ${$template->run()},
    '[during-construction custom function was ere]' .
    '[during-construction custom function2 was ere]',
    'run of during-construction custom functions from single param' );

#
#  11-13:  Function added after construction.
$template = Template::Sandbox->new();
lives_ok { $template->register_template_function(
    $function => no_args sub { '[post-construction custom function was ere]' },
    ) } 'post-construct register of custom function';
lives_ok { $template->set_template_string( $syntax ) }
    'parse with post-construction registered custom function';
is( ${$template->run()}, '[post-construction custom function was ere]',
    'run of post-construction registered custom function' );

#
#  14-17:  Multiple functions added after construction.
$template = Template::Sandbox->new();
lives_ok { $template->register_template_function(
    $function => no_args sub { '[post-construction custom function was ere]' },
    ) } 'first post-construct register of multiple custom functions';
lives_ok { $template->register_template_function(
    $function2 => no_args sub { '[post-construction custom function2 was ere]' },
    ) } 'second post-construct register of multiple custom functions';
lives_ok { $template->set_template_string( $syntax . $syntax2 ) }
    'parse with multiple post-construction registered custom function';
is( ${$template->run()},
    '[post-construction custom function was ere]' .
    '[post-construction custom function2 was ere]',
    'run of multiple post-construction registered custom functions' );

#
#  18-20:  Check add_template_function synonym.
$template = Template::Sandbox->new();
lives_ok { $template->add_template_function(
    $function => no_args sub { '[post-construction custom function was ere]' },
    ) } 'post-construct add of custom function (method synonym)';
lives_ok { $template->set_template_string( $syntax ) }
    'parse with post-construction added custom function';
is( ${$template->run()}, '[post-construction custom function was ere]',
    'run of post-construction added custom function' );

#
#  21-22:  Function unregister.
$template = Template::Sandbox->new(
    template_function => [
        $function =>
            no_args sub { '[during-construction custom function was ere]' },
        ],
    );
lives_ok { $template->unregister_template_function( $function ) }
    'unregister custom function';
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: Unknown function: nonexistingfunction at line 1, char 1 of/,
    "verify custom function no-longer exists";

#
#  23-24:  Function delete synonym.
$template = Template::Sandbox->new(
    template_function => [
        $function =>
            no_args sub { '[during-construction custom function was ere]' },
        ],
    );
lives_ok { $template->delete_template_function( $function ) }
    'delete custom function (method synonym)';
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: Unknown function: nonexistingfunction at line 1, char 1 of/,
    "verify custom function no-longer exists";

#
#  25-26: Constant single arg to one-arg function.
$oldsyntax = $syntax;
$syntax = "<: expr ${function}( 1 ) :>";
$template = Template::Sandbox->new(
    template_function => [
        $function =>
            one_arg sub
            {
                return( '[one_arg custom function was ere with args: ' .
                    join( ',', @_ ) . ']' );
            },
        ],
    );
lives_ok { $template->set_template_string( $syntax ) }
    'parse with constant single arg to one_arg custom function';
is( ${$template->run()}, '[one_arg custom function was ere with args: 1]',
    'run of constant single arg to one_arg custom function' );
$syntax = $oldsyntax;

#
#  27-28: Variable single arg to one-arg function.
$oldsyntax = $syntax;
$syntax = "<: expr ${function}( a ) :>";
$template = Template::Sandbox->new(
    template_function => [
        $function =>
            one_arg sub
            {
                return( '[one_arg custom function was ere with args: ' .
                    join( ',', @_ ) . ']' );
            },
        ],
    );
$template->add_var( a => 45 );
lives_ok { $template->set_template_string( $syntax ) }
    'parse with variable single arg to one_arg custom function';
is( ${$template->run()}, '[one_arg custom function was ere with args: 45]',
    'run of variable single arg to one_arg custom function' );
$syntax = $oldsyntax;

#
#  29-30: Constant arg to two-arg function.
$oldsyntax = $syntax;
$syntax = "<: expr ${function}( 1, 2 ) :>";
$template = Template::Sandbox->new(
    template_function => [
        $function =>
            two_args sub
            {
                return( '[two_args custom function was ere with args: ' .
                    join( ',', @_ ) . ']' );
            },
        ],
    );
lives_ok { $template->set_template_string( $syntax ) }
    'parse with constant args to two_args custom function';
is( ${$template->run()}, '[two_args custom function was ere with args: 1,2]',
    'run of constant args to two_args custom function' );
$syntax = $oldsyntax;

#
#  31-32: Variable args to two-arg function.
$oldsyntax = $syntax;
$syntax = "<: expr ${function}( a, b ) :>";
$template = Template::Sandbox->new(
    template_function => [
        $function =>
            two_args sub
            {
                return( '[two_args custom function was ere with args: ' .
                    join( ',', @_ ) . ']' );
            },
        ],
    );
$template->add_vars( { a => 45, b => 19, } );
lives_ok { $template->set_template_string( $syntax ) }
    'parse with variable args to two_args custom function';
is( ${$template->run()}, '[two_args custom function was ere with args: 45,19]',
    'run of variable args to two_args custom function' );
$syntax = $oldsyntax;

#
#  33-34: Constant arg to three-arg function.
$oldsyntax = $syntax;
$syntax = "<: expr ${function}( 1, 2, 5 ) :>";
$template = Template::Sandbox->new(
    template_function => [
        $function =>
            three_args sub
            {
                return( '[three_args custom function was ere with args: ' .
                    join( ',', @_ ) . ']' );
            },
        ],
    );
lives_ok { $template->set_template_string( $syntax ) }
    'parse with constant args to three_args custom function';
is( ${$template->run()},
    '[three_args custom function was ere with args: 1,2,5]',
    'run of constant args to three_args custom function' );
$syntax = $oldsyntax;

#
#  35-36: Variable args to three-arg function.
$oldsyntax = $syntax;
$syntax = "<: expr ${function}( a, b, c ) :>";
$template = Template::Sandbox->new(
    template_function => [
        $function =>
            three_args sub
            {
                return( '[three_args custom function was ere with args: ' .
                    join( ',', @_ ) . ']' );
            },
        ],
    );
$template->add_vars( { a => 45, b => 19, c => 25, } );
lives_ok { $template->set_template_string( $syntax ) }
    'parse with variable args to three_args custom function';
is( ${$template->run()},
    '[three_args custom function was ere with args: 45,19,25]',
    'run of variable args to three_args custom function' );
$syntax = $oldsyntax;

#
#  37: No args to one-arg function.
$oldsyntax = $syntax;
$syntax = "<: expr ${function}() :>";
$template = Template::Sandbox->new(
    template_function => [
        $function =>
            one_arg sub
            {
                return( '[one_arg custom function was ere with args: ' .
                    join( ',', @_ ) . ']' );
            },
        ],
    );
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: too few args to nonexistingfunction\(\), expected 1 and got 0 in nonexistingfunction\(\) at line 1, char 1 of/,
    'error on missing args to single-arg function';
$syntax = $oldsyntax;

#
#  38: Two args to one-arg function.
$oldsyntax = $syntax;
$syntax = "<: expr ${function}( 1, 2 ) :>";
$template = Template::Sandbox->new(
    template_function => [
        $function =>
            one_arg sub
            {
                return( '[one_arg custom function was ere with args: ' .
                    join( ',', @_ ) . ']' );
            },
        ],
    );
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: too many args to nonexistingfunction\(\), expected 1 and got 2 in nonexistingfunction\( 1, 2 \) at line 1, char 1 of/,
    'error on two args to single-arg function';
$syntax = $oldsyntax;

#
#  39-40: construct-option function instance locality testing
$pre_template = Template::Sandbox->new();
$template = Template::Sandbox->new(
    template_function => [
        $function =>
            no_args sub { '[during-construction custom function was ere]' },
        ],
    );
$post_template = Template::Sandbox->new();
throws_ok { $pre_template->set_template_string( $syntax ) }
    qr/compile error: Unknown function: nonexistingfunction at line 1, char 1 of/,
    "construct-option instance-function doesn't exist in existing instances";
throws_ok { $post_template->set_template_string( $syntax ) }
    qr/compile error: Unknown function: nonexistingfunction at line 1, char 1 of/,
    "construct-option instance-function doesn't exist in new instances";

#
#  41-42: post-construct function instance locality testing
$pre_template = Template::Sandbox->new();
$template = Template::Sandbox->new();
$template->register_template_function(
    $function => no_args sub { '[post-construction custom function was ere]' },
    );
$post_template = Template::Sandbox->new();
throws_ok { $pre_template->set_template_string( $syntax ) }
    qr/compile error: Unknown function: nonexistingfunction at line 1, char 1 of/,
    "post-construct instance-function doesn't exist in existing instances";
throws_ok { $post_template->set_template_string( $syntax ) }
    qr/compile error: Unknown function: nonexistingfunction at line 1, char 1 of/,
    "post-construct instance-function doesn't exist in new instances";

#
#  43-49: class-method testing
$pre_template = Template::Sandbox->new();
lives_ok { Template::Sandbox->register_template_function(
    $function => no_args sub { '[class-method custom function was ere]' },
    ) }
    'class-method register of custom function';
$post_template = Template::Sandbox->new();
lives_ok { $pre_template->set_template_string( $syntax ) }
    'existing template parse with class-method registered custom function';
is( ${$pre_template->run()}, '[class-method custom function was ere]',
    'existing template run of class-method custom function' );
lives_ok { $post_template->set_template_string( $syntax ) }
    'new template parse with class-method registered custom function';
is( ${$post_template->run()}, '[class-method custom function was ere]',
    'new template run of class-method custom function' );
lives_ok { Template::Sandbox->unregister_template_function( $function ) }
    'class-method unregister of custom function';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: Unknown function: nonexistingfunction at line 1, char 1 of/,
    'verify class-method custom function was removed';

#
#  50-52:  needs_template testing
#  TODO:  check it's _our_ template
ok( $template = Template::Sandbox->new(
    template_function => [
        $function =>
            needs_template no_args sub
            {
                '[needs_template function got a: ' . ref( $_[ 0 ] ) . ']'
            },
        ],
    ), 'construct with needs_template custom function as option' );
lives_ok { $template->set_template_string( $syntax ) }
    'parse with needs_template custom function';
is( ${$template->run()}, '[needs_template function got a: Template::Sandbox]',
    'run of needs_template custom function' );

#
#  53:  non-constant needs_template function.
$oldsyntax = $syntax;
$syntax = "<: expr ${function}( a ) :>";
$template = Template::Sandbox->new(
    template_function => [
        $function =>
            needs_template one_arg sub
            {
                '[needs_template function got: ' . ref( $_[ 0 ] ) .
                    ', ' . $_[ 1 ] . ']'
            },
        ],
    );
$template->set_template_string( $syntax );
$template->add_var( a => 12 );
is( ${$template->run()}, '[needs_template function got: Template::Sandbox, 12]',
    'run of non-constant-folded needs_template custom function' );
$syntax = $oldsyntax;

#
#  54-55:  warnings on remove of non-existing function
$template = Template::Sandbox->new();
{
    local $^W = 1;
    warns_ok { $template->unregister_template_function( $function ) }
        qr/Template post-initialization error: Template function 'nonexistingfunction' does not exist, cannot be removed. at .*70-custom-function\.t line/,
        'warn on unregister of non-existing function';
}
{
    local $^W = 0;
    doesnt_warn { $template->unregister_template_function( $function ) }
        'warning suppression on unregister of non-existing function';
}

#
#  56-57:  warnings on add of existing function
$template = Template::Sandbox->new();
$template->register_template_function(
    $function => no_args sub { '[post-construction custom function was ere]' },
    );
{
    local $^W = 1;
    warns_ok
        {
            $template->register_template_function(
                $function => no_args
                    sub { '[post-construction custom function was ere]' },
                );
        }
        qr/Template post-initialization error: Template function 'nonexistingfunction' exists, overwriting. at .*70-custom-function\.t line/,
        'warn on register of existing function';
}
{
    local $^W = 0;
    doesnt_warn
        {
            $template->register_template_function(
                $function => no_args
                    sub { '[post-construction custom function was ere]' },
                );
        }
        'warning suppression on register of existing function';
}

#
#  58: Does local instance-function mask class-function?
Template::Sandbox->register_template_function(
    $function => no_args sub { '[class-method custom function was ere]' },
    );
$template = Template::Sandbox->new();
$template->register_template_function(
    $function => no_args sub { '[instance-method custom function was ere]' },
    );
$template->set_template_string( $syntax );
is( ${$template->run()}, '[instance-method custom function was ere]',
    'instance registration masks class registration' );
Template::Sandbox->unregister_template_function( $function );

#
#  59: undef args produce warning
$oldsyntax = $syntax;
$syntax = "<: expr $function( a ) :>";
$template = Template::Sandbox->new();
$template->register_template_function(
    $function => one_arg sub { '[nobody expects the undef inquisition]' },
    );
$template->set_template_string( $syntax );
warns_ok { $template->run(); }
    qr/Template runtime error: undefined template value 'a' at line 1, char 1 of/,
    'warn on undef function args';
$syntax = $oldsyntax;

#
#  60: undef_ok prevents undef args warning
$oldsyntax = $syntax;
$syntax = "<: expr $function( a ) :>";
$template = Template::Sandbox->new();
$template->register_template_function(
    $function => undef_ok one_arg
        sub { "[what's a little undef among friends?]" },
    );
$template->set_template_string( $syntax );
doesnt_warn { $template->run(); }
    'undef_ok function sugar suppresses undef warning';
$syntax = $oldsyntax;

#
#  61: hashref function definition args to constructor.
throws_ok
    {
        $template = Template::Sandbox->new(
            template_function => [
                $function =>
                    { 'you were expecting' => 'an arrayref or coderef?' },
                ],
            );
    }
    qr/Template initialization error: Bad template function '$function' to register_template_function\(\), expected sub ref or 'function_sugar'ed sub ref, got: HASH at .*Template.*Sandbox\.pm line/,
    'error on hashref definition in construct-option function';

#
#  62: bad function definition args to constructor.
throws_ok
    {
        $template = Template::Sandbox->new(
            template_function => [
                $function =>
                    'you were expecting an arrayref or coderef?',
                ],
            );
    }
    qr/Template initialization error: Bad template function '$function' to register_template_function\(\), expected sub ref or 'function_sugar'ed sub ref, got: 'you were expecting an arrayref or coderef\?' at .*Template.*Sandbox\.pm line/,
    'error on scalar definition in construct-option function';

#
#  63: hashref function definition args to register method.
$template = Template::Sandbox->new();
throws_ok
    {
        $template->register_template_function(
            $function => { 'you were expecting' => 'an arrayref or coderef?' },
            );
    }
    qr/Template post-initialization error: Bad template function '$function' to register_template_function\(\), expected sub ref or 'function_sugar'ed sub ref, got: HASH at .*Template.*Sandbox\.pm line/,
    'error on hashref definition in post-construct function';

#
#  64: hashref function definition args to register method.
$template = Template::Sandbox->new();
throws_ok
    {
        $template->register_template_function(
            $function => 'you were expecting an arrayref or coderef?',
            );
    }
    qr/Template post-initialization error: Bad template function '$function' to register_template_function\(\), expected sub ref or 'function_sugar'ed sub ref, got: 'you were expecting an arrayref or coderef\?' at .*Template.*Sandbox\.pm line/,
    'error on scalar definition in post-construct function';

#
#  65: raw sub register autoapplies function sugar.
$oldsyntax = $syntax;
$syntax = "<: expr ${function}( 1, 2 ) :>";
$template = Template::Sandbox->new(
    template_function => [
        $function =>
            sub
            {
                return( '[raw-sub custom function was ere with args: ' .
                    join( ',', @_ ) . ']' );
            },
        ],
    );
$template->set_template_string( $syntax );
is( ${$template->run()}, '[raw-sub custom function was ere with args: 1,2]',
    'raw-sub custom function auto-applies function sugar' );
$syntax = $oldsyntax;

#
#  66: error on run of instance function removed after compile
$oldsyntax = $syntax;
$syntax = "<: expr ${function}( a ) :>";
$template = Template::Sandbox->new();
$template->register_template_function(
    $function => one_arg sub { '[instance-method custom function was ere]' },
    );
$template->add_var( a => 1 );
$template->set_template_string( $syntax );
$template->unregister_template_function( $function );
throws_ok { $template->run() }
    qr{Template runtime error: Unknown function: nonexistingfunction at line 1, char 1 of},
    'error on run of instance function removed after compile';
$syntax = $oldsyntax;

#
#  67: error on run of class function removed after compile
$oldsyntax = $syntax;
$syntax = "<: expr ${function}( a ) :>";
Template::Sandbox->register_template_function(
    $function => one_arg sub { '[class-method custom function was ere]' },
    );
$template = Template::Sandbox->new();
$template->add_var( a => 1 );
$template->set_template_string( $syntax );
Template::Sandbox->unregister_template_function( $function );
throws_ok { $template->run() }
    qr{Template runtime error: Unknown function: nonexistingfunction at line 1, char 1 of},
    'error on run of class function removed after compile';
$syntax = $oldsyntax;

#
#  68-69: copy_global_functions tests.
$oldsyntax = $syntax;
$syntax = "<: expr ${function}( a ) :>";
Template::Sandbox->register_template_function(
    $function => one_arg sub { '[class-method custom function was ere]' },
    );
$template = Template::Sandbox->new(
    copy_global_functions => 1,
    );
$template->add_var( a => 1 );
Template::Sandbox->unregister_template_function( $function );
lives_ok { $template->set_template_string( $syntax ); }
    'copy_global_functions instance compiles after class function deleted';
lives_and { is ${$template->run()}, '[class-method custom function was ere]' }
    'copy_global_functions instance runs after class function deleted';
$syntax = $oldsyntax;

#
#  70:  return ref to scalar (const func)
$template = Template::Sandbox->new();
$template->register_template_function(
    $function => no_args sub
        {
            my $ret = '[return-by-reference custom function was ere]';
            return( \$ret );
        },
    );
$template->set_template_string( $syntax );
is( ${$template->run()}, '[return-by-reference custom function was ere]',
    'constant custom function returning scalar-reference' );

#
#  71:  return ref to scalar (inconst func)
$oldsyntax = $syntax;
$syntax = "<: expr ${function}( a ) :>";
$template = Template::Sandbox->new();
$template->add_var( a => 50 );
$template->register_template_function(
    $function => one_arg sub
        {
            my $ret = '[return-by-reference custom function was ere]';
            return( \$ret );
        },
    );
$template->set_template_string( $syntax );
is( ${$template->run()}, '[return-by-reference custom function was ere]',
    'non-constant custom function returning scalar-reference' );
$syntax = $oldsyntax;

#
#  72: apparantly-constant function optimization.
$oldsyntax = $syntax;
$syntax = "<: for x in 3 :>\nOn loop <: expr x :> function returns: <: expr ${function}() :>\n<: end for :>\n";
$template = Template::Sandbox->new();
{
    my ( $callcount );

    $callcount = 0;

    $template->register_template_function(
        $function => no_args sub
            {
                $callcount++;
                "[I've been called $callcount times]";
            },
        );
}
$template->set_template_string( $syntax );
$expected = <<END_OF_EXPECTED;
On loop 0 function returns: [I've been called 1 times]
On loop 1 function returns: [I've been called 1 times]
On loop 2 function returns: [I've been called 1 times]
On loop 3 function returns: [I've been called 1 times]
END_OF_EXPECTED
is( ${$template->run()}, $expected,
    'apparantly-constant function optimization' );
$syntax = $oldsyntax;

#
#  73: inconstant function-sugar on apparantly-constant function
$oldsyntax = $syntax;
$syntax = "<: for x in 3 :>\nOn loop <: expr x :> function returns: <: expr ${function}() :>\n<: end for :>\n";
$template = Template::Sandbox->new();
{
    my ( $callcount );

    $callcount = 0;

    $template->register_template_function(
        $function => no_args inconstant sub
            {
                $callcount++;
                "[I've been called $callcount times]";
            },
        );
}
$template->set_template_string( $syntax );
$expected = <<END_OF_EXPECTED;
On loop 0 function returns: [I've been called 1 times]
On loop 1 function returns: [I've been called 2 times]
On loop 2 function returns: [I've been called 3 times]
On loop 3 function returns: [I've been called 4 times]
END_OF_EXPECTED
is( ${$template->run()}, $expected,
    'inconstant function-sugar on apparantly-constant function' );
$syntax = $oldsyntax;

#  TODO: call non-existing function when different local function added
#  TODO: call non-existing function when different class function added
