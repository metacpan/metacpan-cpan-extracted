#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;
use Test::Exception;

plan tests => 5;

my ( $template, $testob, $syntax );

$testob = Template::Sandbox::TestMethodObject->new();

#
#  1:  Call permitted method without args.
$syntax = "<: expr testob.permitted_method() :>";
$template = Template::Sandbox->new();
$template->add_var( testob => $testob );
$template->set_template_string( $syntax );
is( ${$template->run()},
    'You are permitted to call upon me',
    'expr permitted method without args' );

#
#  2:  Call permitted method with args.
$syntax = "<: expr testob.permitted_method_with_args( 'a', 12, 'z' ) :>";
$template = Template::Sandbox->new();
$template->add_var( testob => $testob );
$template->set_template_string( $syntax );
is( ${$template->run()},
    'oh, a valid method with args: a, 12, z',
    'expr permitted method with args' );

#
#  3:  Call forbidden method.
$syntax = "<: expr testob.forbidden_method() :>";
$template = Template::Sandbox->new();
$template->add_var( testob => $testob );
$template->set_template_string( $syntax );
throws_ok { ${$template->run()} }
    qr/runtime error: Invalid method to call from within a template: Template\::Sandbox\::TestMethodObject->forbidden_method at line 1, char 1 of/,
    'expr forbidden method';

#
#  4:  Call method on non-reference value.
$syntax = "<: expr testob.forbidden_method() :>";
$template = Template::Sandbox->new();
$template->add_var( testob => 143 );
$template->set_template_string( $syntax );
throws_ok { ${$template->run()} }
    qr/runtime error: Can't call method on non-reference value testob: 143 at line 1, char 1 of/,
    'expr error calling method on non-reference value';


#
#  5:  Call method on undefined value.
$syntax = "<: expr testob.forbidden_method() :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
{
    #  Suppress the undef testob warning, we know, that's why we're doing it.
    local $SIG{ __WARN__ } = sub { };
    throws_ok { ${$template->run()} }
qr/runtime error: Can't call method on undefined value testob at line 1, char 1 of/,
        'expr error calling method on undefined value';
}


package Template::Sandbox::TestMethodObject;

sub new
{
    my ( $this ) = @_;
    return( bless {}, $this );
}

sub valid_template_method
{
    my ( $self, $method ) = @_;

    return( 1 ) if $method eq 'permitted_method';
    return( 1 ) if $method eq 'permitted_method_with_args';
    return( 0 );
}

sub permitted_method { return( 'You are permitted to call upon me' ); }
sub forbidden_method { return( 'I are a dark forbidden method, yarr' ); }

sub permitted_method_with_args
{
    my $self = shift;

    return( 'oh, a valid method with args: ' . join( ', ', @_ ) );
}

1;
