#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;
use Test::Exception;

plan tests => 41;

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

my ( $template, $pre_template, $post_template, $token, $syntax );

$token = "nonexistingtoken";
$syntax = "<: $token :>";

#
#  1:  Test that the custom token really doesn't exist and causes a fail.
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: unrecognised token \(<: nonexistingtoken :>\) at line 1, char 1 of/,
    "verify custom syntax doesn't exist already";

#
#  2-4:  Syntax added during construction.
ok( $template = Template::Sandbox->new(
    template_syntax => [
        $token => {
            compile => sub { [] },
            run     => sub { '[during-construction custom syntax was ere]' },
            },
        ],
    ), 'construct with custom syntax as option' );
lives_ok { $template->set_template_string( $syntax ) }
    'parse with during-construction custom syntax';
is( ${$template->run()}, '[during-construction custom syntax was ere]',
    'run of during-construction custom syntax' );


#
#  5-7:  Syntax added after construction.
$template = Template::Sandbox->new();
lives_ok { $template->register_template_syntax(
    $token => {
        compile => sub { [] },
        run     => sub { '[post-construction custom syntax was ere]' },
        },
    ) } 'post-construct register of custom syntax';
lives_ok { $template->set_template_string( $syntax ) }
    'parse with post-construction registered custom syntax';
is( ${$template->run()}, '[post-construction custom syntax was ere]',
    'run of post-construction registered custom syntax' );

#
#  8-10: Check add_template_syntax synonym.
$template = Template::Sandbox->new();
lives_ok { $template->add_template_syntax(
    $token => {
        compile => sub { [] },
        run     => sub { '[post-construction custom syntax was ere]' },
        },
    ) } 'post-construct add of custom syntax (method synonym)';
lives_ok { $template->set_template_string( $syntax ) }
    'parse with post-construction added custom syntax';
is( ${$template->run()}, '[post-construction custom syntax was ere]',
    'run of post-construction added custom syntax' );

#
#  11-12:  Syntax unregister.
$template = Template::Sandbox->new(
    template_syntax => [
        $token => {
            compile => sub { [] },
            run     => sub { '[during-construction custom syntax was ere]' },
            },
        ],
    );
lives_ok { $template->unregister_template_syntax( $token ) }
    'unregister custom syntax';
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: unrecognised token \(<: nonexistingtoken :>\) at line 1, char 1 of/,
    "verify custom syntax no-longer exists";

#
#  13-14:  Syntax delete synonym.
$template = Template::Sandbox->new(
    template_syntax => [
        $token => {
            compile => sub { [] },
            run     => sub { '[during-construction custom syntax was ere]' },
            },
        ],
    );
lives_ok { $template->delete_template_syntax( $token ) }
    'delete custom syntax (method synonym)';
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: unrecognised token \(<: nonexistingtoken :>\) at line 1, char 1 of/,
    "verify custom syntax no-longer exists";

#
#  15:  Syntax args.
$template = Template::Sandbox->new(
    template_syntax => [
        $token => {
            compile => sub
                {
                    my ( $template, $token, $pos, $args ) = @_;

                    return( $args );
                },
            run     => sub
                {
                    my ( $template, $token, $args ) = @_;
                    my ( $content );

                    $content = '';

                    $content .= " name=$args->{ name }"
                        if $args and exists( $args->{ name } );

                    $content .= " id=$args->{ id }"
                        if $args and exists( $args->{ id } );

                    $content = substr( $content, 1 ) if $content;
                    return( "[$content]" );
                },
            },
        ],
    );
$syntax = "<: $token :><: $token name=fred :><: $token id=12 :><: $token name=joe id=42 :><: $token name=\"long name\" id=15 :><: $token :>";
$template->set_template_string( $syntax );
is( ${$template->run()},
    '[][name=fred][id=12][name=joe id=42][name=long name id=15][]',
    'custom syntax args' );
#  Restore test string to old one.
$syntax = "<: $token :>";

#
#  16-17:  Are constructor-added instance-syntaxes local to that instance?
$pre_template = Template::Sandbox->new();
$template = Template::Sandbox->new(
    template_syntax => [
        $token => {
            compile => sub { [] },
            run     => sub { '[during-construction custom syntax was ere]' },
            },
        ],
    );
$post_template = Template::Sandbox->new();
throws_ok { $pre_template->set_template_string( $syntax ) }
    qr/compile error: unrecognised token \(<: nonexistingtoken :>\) at line 1, char 1 of/,
    "construct-option instance-syntax doesn't exist in existing instances";
throws_ok { $post_template->set_template_string( $syntax ) }
    qr/compile error: unrecognised token \(<: nonexistingtoken :>\) at line 1, char 1 of/,
    "construct-option instance-syntax doesn't exist in new instances";

#
#  18-19:  Are post-construct instance-syntaxes local to that instance?
$pre_template = Template::Sandbox->new();
$template = Template::Sandbox->new();
$template->register_template_syntax(
    $token => {
        compile => sub { [] },
        run     => sub { '[post-construction custom syntax was ere]' },
        },
    );
$post_template = Template::Sandbox->new();
throws_ok { $pre_template->set_template_string( $syntax ) }
    qr/compile error: unrecognised token \(<: nonexistingtoken :>\) at line 1, char 1 of/,
    "post-construct instance-syntax doesn't exist in existing instances";
throws_ok { $post_template->set_template_string( $syntax ) }
    qr/compile error: unrecognised token \(<: nonexistingtoken :>\) at line 1, char 1 of/,
    "post-construct instance-syntax doesn't exist in new instances";

#
#  20-26:  Class syntax addition.
$pre_template = Template::Sandbox->new();
lives_ok { Template::Sandbox->register_template_syntax(
    $token => {
        compile => sub { [] },
        run     => sub { '[class-method custom syntax was ere]' },
        },
    ) } 'class-method register of custom syntax';
$post_template = Template::Sandbox->new();
lives_ok { $pre_template->set_template_string( $syntax ) }
    'existing template parse with class-method registered custom syntax';
is( ${$pre_template->run()}, '[class-method custom syntax was ere]',
    'existing template run of class-method registered custom syntax' );
lives_ok { $post_template->set_template_string( $syntax ) }
    'new template parse with class-method registered custom syntax';
is( ${$post_template->run()}, '[class-method custom syntax was ere]',
    'new template run of class-method registered custom syntax' );
lives_ok { Template::Sandbox->unregister_template_syntax( $token ) }
    'class-method unregister of custom syntax';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: unrecognised token \(<: nonexistingtoken :>\) at line 1, char 1 of/,
    'verify class-method custom syntax was removed';

#
#  27-28:  warnings on remove of non-existing syntax
$template = Template::Sandbox->new();
{
    local $^W = 1;
    warns_ok { $template->unregister_template_syntax( $token ) }
        qr/Template post-initialization error: Template syntax '$token' does not exist, cannot be removed. at .*60-custom-syntax\.t line/,
        'warn on unregister of non-existing syntax';
}
{
    local $^W = 0;
    doesnt_warn { $template->unregister_template_syntax( $token ) }
        'warning suppression on unregister of non-existing syntax';
}

#
#  29-30:  warnings on add of existing syntax
$template = Template::Sandbox->new();
$template->register_template_syntax(
    $token => {
        compile => sub { [] },
        run     => sub { '[instance-method custom syntax was ere]' },
        },
    );
{
    local $^W = 1;
    warns_ok
        {
            $template->register_template_syntax(
                $token => {
                    compile => sub { [] },
                    run     =>
                        sub { '[instance-method custom syntax was ere]' },
                    },
                );
        }
        qr/Template post-initialization error: Template syntax '$token' exists, overwriting. at .*60-custom-syntax\.t line/,
        'warn on register of existing syntax';
}
{
    local $^W = 0;
    doesnt_warn
        {
            $template->register_template_syntax(
                $token => {
                    compile => sub { [] },
                    run     =>
                        sub { '[instance-method custom syntax was ere]' },
                    },
                );
        }
        'warning suppression on register of existing syntax';
}

#
#  31: Does local instance-function mask class-function?
Template::Sandbox->register_template_syntax(
    $token => {
        compile => sub { [] },
        run     => sub { '[class-method custom syntax was ere]' },
        },
    );
$template = Template::Sandbox->new();
$template->register_template_syntax(
    $token => {
        compile => sub { [] },
        run     => sub { '[instance-method custom syntax was ere]' },
        },
    );
$template->set_template_string( $syntax );
is( ${$template->run()}, '[instance-method custom syntax was ere]',
    'instance registration masks class registration' );
Template::Sandbox->unregister_template_syntax( $token );

#
#  32:  undef args from compile skips instruction.
$template = Template::Sandbox->new();
$template->register_template_syntax(
    $token => {
        compile => sub { undef },
        run     => sub { '[undef args custom syntax never appens]' },
        },
    );
$template->set_template_string( $syntax );
is( ${$template->run()}, '',
    'undef args custom syntax compile eliminates instruction from program' );

#
#  33:  undef return from run skips content.
$template = Template::Sandbox->new();
$template->register_template_syntax(
    $token => {
        compile => sub { {} },
        run     => sub { undef },
        },
    );
$template->set_template_string( $syntax );
is( ${$template->run()}, '',
    'undef custom syntax run provides no content' );

#
#  34-37: bad syntax definition args to constructor.
throws_ok
    {
        $template = Template::Sandbox->new(
            template_syntax => [
                $token => 'expecting a hashref? tough luck.',
                ],
            );
    }
    qr/Template initialization error: Bad template syntax '$token' to register_template_syntax\(\), expected hash ref, got: 'expecting a hashref\? tough luck\.' at .*Template.*Sandbox\.pm line/,
    'error on bad definition (string) for construct-option custom syntax';
throws_ok
    {
        $template = Template::Sandbox->new(
            template_syntax => [
                $token => [ 'expecting a hashref? tough luck.' ],
                ],
            );
    }
    qr/Template initialization error: Bad template syntax '$token' to register_template_syntax\(\), expected hash ref, got: ARRAY at .*Template.*Sandbox\.pm line/,
    'error on bad definition (arrayref) for construct-option custom syntax';
throws_ok
    {
        $template = Template::Sandbox->new(
            template_syntax => [
                $token => {
                    run     =>
                        sub { '[during-construction custom syntax was ere]' },
                },
                ],
            );
    }
    qr/Template initialization error: Missing compile callback for syntax nonexistingtoken at .*Template.*Sandbox\.pm line/,
    'error on missing compile callback for construct-option custom syntax';
throws_ok
    {
        $template = Template::Sandbox->new(
            template_syntax => [
                $token => {
                    compile => sub { [] },
                },
                ],
            );
    }
    qr/Template initialization error: Missing run callback for syntax nonexistingtoken at .*Template.*Sandbox\.pm line/,
    'error on missing run callback for construct-option custom syntax';

#
#  38-41: bad syntax definition args to constructor.
$template->new();
throws_ok
    {
        $template->register_template_syntax(
            $token => 'expecting a hashref? tough luck.',
            );
    }
    qr/Template error: Bad template syntax '$token' to register_template_syntax\(\), expected hash ref, got: 'expecting a hashref\? tough luck\.' at .*Template.*Sandbox\.pm line/,
    'error on bad definition (string) for post-construct custom syntax';
throws_ok
    {
        $template->register_template_syntax(
            $token => [ 'expecting a hashref? tough luck.' ],
            );
    }
    qr/Template error: Bad template syntax '$token' to register_template_syntax\(\), expected hash ref, got: ARRAY at .*Template.*Sandbox\.pm line/,
    'error on bad definition (arrayref) for post-construct custom syntax';
throws_ok
    {
        $template->register_template_syntax(
            $token => {
                run     =>
                    sub { '[post-construction custom syntax was ere]' },
                },
            );
    }
    qr/Template error: Missing compile callback for syntax nonexistingtoken at .*Template.*Sandbox\.pm line/,
    'error on missing compile callback for post-construct custom syntax';
throws_ok
    {
        $template->register_template_syntax(
            $token => {
                compile => sub { [] },
                },
            );
    }
    qr/Template error: Missing run callback for syntax nonexistingtoken at .*Template.*Sandbox\.pm line/,
    'error on missing run callback for post-construct custom syntax';


#  TODO: multiple custom syntaxes as single constructor param
#  TODO: multiple custom syntaxes as multiple constructor param
