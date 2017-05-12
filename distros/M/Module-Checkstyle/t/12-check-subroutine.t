#!perl
use Test::More tests => 17;

use strict;
use PPI;
use Module::Checkstyle::Config;

BEGIN { use_ok('Module::Checkstyle::Check::Subroutine'); } # 1

# max-length
{
    my $checker = Module::Checkstyle::Check::Subroutine->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Subroutine]
max-length = 3
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
sub my_sub_fail {
    # This should
    # make the
    # subroutine
    # just a bit
    # too long
}

sub my_sub_pass {
    # This should pass
}
END_OF_CODE

    # Normally index_locations is called by Module::Checkstyle
    # when it loads a document but since we're loading
    # documents directlly here we have to do it manually
    $doc->index_locations();

    my $tokens = $doc->find('PPI::Statement::Sub');
    is(scalar @$tokens, 2); # 2
    my $token = shift @$tokens;

    my @problems = $checker->handle_subroutine($token);
    is(scalar @problems, 1); # 3

    $token = shift @$tokens;
    @problems = $checker->handle_subroutine($token);
    is(scalar @problems, 0); # 4
}

# naming
{
    my $checker = Module::Checkstyle::Check::Subroutine->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Subroutine]
matches-name = /^_?(?:[a-z]+)(_[a-z]+)*$/
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
sub c_style_subs {
}
sub javaStyleSubs {
}
sub _is_private {
}
END_OF_CODE

    $doc->index_locations();

    my $tokens = $doc->find('PPI::Statement::Sub');
    is(scalar @$tokens, 3); # 5

    my $token = shift @$tokens;
    my @problems = $checker->handle_subroutine($token);
    is(scalar @problems, 0); # 6

    $token = shift @$tokens;
    @problems = $checker->handle_subroutine($token);
    is(scalar @problems, 1); # 7

    $token = shift @$tokens;
    @problems = $checker->handle_subroutine($token);
    is(scalar @problems, 0); # 8
}

# no-fully-qualified-name
{
    my $checker = Module::Checkstyle::Check::Subroutine->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Subroutine]
no-fully-qualified-names = true
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
sub Temp::temp_function {
}
sub Old'style {
}
sub should_pass {
}
END_OF_CODE

    $doc->index_locations();

    my $tokens = $doc->find('PPI::Statement::Sub');
    is(scalar @$tokens, 3); # 9

    my $token = shift @$tokens;
    my @problems = $checker->handle_subroutine($token);
    is(scalar @problems, 1); # 10

    $token = shift @$tokens;
    @problems = $checker->handle_subroutine($token);
    is(scalar @problems, 1); # 11

    $token = shift @$tokens;
    @problems = $checker->handle_subroutine($token);
    is(scalar @problems, 0); # 12
}

{
    my $checker = Module::Checkstyle::Check::Subroutine->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Subroutine]
no-calling-with-ampersand = true
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
&foo;
&foo(10);
foo(10);
&foo (20);
&foo 10 20;
END_OF_CODE

    $doc->index_locations();

    my $tokens = $doc->find('PPI::Token::Symbol');
    is (scalar @$tokens, 4); # 13

    my $token = shift @$tokens;
    my @problems = $checker->handle_symbol($token);
    is (scalar @problems, 0); # 14

    $token = shift @$tokens;
    @problems = $checker->handle_symbol($token);
    is (scalar @problems, 1); # 15

    $token = shift @$tokens;
    @problems = $checker->handle_symbol($token);
    is (scalar @problems, 1); # 16

    $token = shift @$tokens;
    @problems = $checker->handle_symbol($token);
    is (scalar @problems, 0), # 17
       
}
   
