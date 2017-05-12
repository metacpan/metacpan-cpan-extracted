#!perl -T

use strict;
use warnings;

use Test::More;

use Log::Any;

use Template::Sandbox;
use Test::Exception;

plan tests => 13;

my ( $template, $message );


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
    
#
#  1:  post-init error instance method
$message = 'test post-init error instance method';
$template = Template::Sandbox->new();
throws_ok { $template->error( $message ); }
    qr/Template post-initialization error: $message at .*Template.*Sandbox\.pm line/,
    'post-init error instance method';

#
#  2:  post-compile error instance method
$message = 'test post-compile error instance method';
$template->set_template_string( '' );
throws_ok { $template->error( $message ); }
    qr/Template error: $message at .*Template.*Sandbox\.pm line/,
    'post-compile error instance method';

#
#  3:  post-run error instance method
$message = 'test post-run error instance method';
$template->run();
throws_ok { $template->error( $message ); }
    qr/Template error: $message at .*Template.*Sandbox\.pm line/,
    'post-run error instance method';

#
#  4:  error class method
$message = 'test error class method';
throws_ok { Template::Sandbox->error( $message ); }
    qr/Template error: $message at .*Template.*Sandbox\.pm line/,
    'error class method';

#
#  5:  post-init warning instance method
$message = 'test post-init warning instance method';
$template = Template::Sandbox->new();
warns_ok { $template->warning( $message ); }
    qr/Template post-initialization error: $message at .*Template.*Sandbox\.pm line/,
    'post-init warning instance method';

#
#  6:  post-compile warning instance method
$message = 'test post-compile warning instance method';
$template->set_template_string( '' );
warns_ok { $template->warning( $message ); }
    qr/Template error: $message at .*Template.*Sandbox\.pm line/,
    'post-compile warning instance method';

#
#  7:  post-run warning instance method
$message = 'test post-run warning instance method';
$template->run();
warns_ok { $template->warning( $message ); }
    qr/Template error: $message at .*Template.*Sandbox\.pm line/,
    'post-run warning instance method';

#
#  8:  warning class method
$message = 'test warning class method';
warns_ok { Template::Sandbox->warning( $message ); }
    qr/Template error: $message at .*Template.*Sandbox\.pm line/,
    'warning class method';

#
#  9:  caller_error instance method.
$message = 'test post-init error instance method';
$template = Template::Sandbox->new();
throws_ok { $template->caller_error( $message ); }
    qr/Template post-initialization error: $message at .*Template.*Sandbox\.pm line/,
    'caller_error instance method';

#
#  10:  caller_warning instance method
$message = 'test post-init warning instance method';
$template = Template::Sandbox->new();
warns_ok { $template->caller_warning( $message ); }
    qr/Template post-initialization error: $message at .*11-diagnostics\.t line/,
    'caller_warning instance method';

#
#  11: test logger option.
lives_ok
    {
        $template = Template::Sandbox->new(
            logger => Log::Any->get_logger(),
        );
    } 'logger construct option';

#
#  12: error with undef logger option.
$message = 'test post-init error instance method';
$template = Template::Sandbox->new(
    logger => undef,
    );
throws_ok { $template->error( $message ); }
    qr/Template post-initialization error: $message at .*Template.*Sandbox\.pm line/,
    'post-init error instance method with undef logger';

#
#  13: warning with undef logger option.
$message = 'test post-init warning instance method';
$template = Template::Sandbox->new(
    logger => undef,
    );
warns_ok { $template->warning( $message ); }
    qr/Template post-initialization error: $message at .*Template.*Sandbox\.pm line/,
    'post-init warning instance method with undef logger';
