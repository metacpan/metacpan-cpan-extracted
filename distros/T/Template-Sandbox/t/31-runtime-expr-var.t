#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox qw/:function_sugar/;
use Test::Exception;

my @chain_one   = ( 'one',    "passthrough( one )" );
my @chain_two   = ( '.two',   "[ 'two' ]",   ".get( 'two' )",   );
my @chain_three = ( '.three', "[ 'three' ]", ".get( 'three' )", );
my @chain_four  = ( '.four',  "[ 'four' ]",  ".get( 'four' )",  );
my @chain_five  = ( '.five',  "[ 'five' ]",  ".get( 'five' )",  );

my $chain_var = bless { two =>
    bless { three =>
    bless { four =>
    bless { five =>
    'chain var value',
    }, 'Template::Sandbox::TestMethodObject'
    }, 'Template::Sandbox::TestMethodObject'
    }, 'Template::Sandbox::TestMethodObject'
    }, 'Template::Sandbox::TestMethodObject';

my $num_chain_permutations = scalar( @chain_one ) * scalar( @chain_two ) *
    scalar( @chain_three ) * scalar( @chain_four ) * scalar( @chain_five );

plan tests => ( ( 22 + ( $num_chain_permutations * 2 ) ) * 2 ) + 2;

my ( $template, $syntax );

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

foreach my $expr_type ( '', 'bare ' )
{
    my $token = $expr_type eq '' ? ' expr' : '';

#
#  1: top-level numeric var added after compile.
$syntax = "<:$token a :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->set_template_string( $syntax );
$template->add_var( a => 42 );
is( ${$template->run()}, '42',
    $expr_type . 'top-level numeric var added after compile' );

#
#  2: top-level numeric var added before compile.
$syntax = "<:$token a :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_var( a => 42 );
$template->set_template_string( $syntax );
is( ${$template->run()}, '42',
    $expr_type . 'top-level numeric var added before compile' );

#
#  3: top-level string var added after compile.
$syntax = "<:$token str :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->set_template_string( $syntax );
$template->add_var( str => 'a string' );
is( ${$template->run()}, 'a string',
    $expr_type . 'top-level string var added after compile' );

#
#  4: top-level string var added before compile.
$syntax = "<:$token str :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_var( str => 'a string' );
$template->set_template_string( $syntax );
is( ${$template->run()}, 'a string',
    $expr_type . 'top-level string var added before compile' );

#
#  5: second-level numeric var added after compile.
$syntax = "<:$token a.b :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->set_template_string( $syntax );
$template->add_var( a => { b => 42 } );
is( ${$template->run()}, '42',
    $expr_type . 'second-level numeric var added after compile' );

#
#  6: second-level numeric var added before compile.
$syntax = "<:$token a.b :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_var( a => { b => 42 } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '42',
    $expr_type . 'second-level numeric var added before compile' );

#
#  7: second-level string var added after compile.
$syntax = "<:$token str.sub :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->set_template_string( $syntax );
$template->add_var( str => { sub => 'a string' } );
is( ${$template->run()}, 'a string',
    $expr_type . 'second-level string var added after compile' );

#
#  8: second-level string var added before compile.
$syntax = "<:$token str.sub :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_var( str => { sub => 'a string' } );
$template->set_template_string( $syntax );
is( ${$template->run()}, 'a string',
    $expr_type . 'second-level string var added before compile' );

#
#  9: numeric array index 0.
$syntax = "<:$token arr[ 0 ] :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_var( arr => [ 42, 43, 44, 45 ] );
$template->set_template_string( $syntax );
is( ${$template->run()}, '42',
    $expr_type . 'numeric array index 0: arr[ 0 ]' );

#
#  10: numeric array index 2.
$syntax = "<:$token arr[ 2 ] :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_var( arr => [ 42, 43, 44, 45 ] );
$template->set_template_string( $syntax );
is( ${$template->run()}, '44',
    $expr_type . 'numeric array index 2: arr[ 2 ]' );

#
#  11: numeric array faux-index __size__.
$syntax = "<:$token arr.__size__ :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_var( arr => [ 42, 43, 44, 45 ] );
$template->set_template_string( $syntax );
is( ${$template->run()}, '4',
    $expr_type . 'numeric array faux-index __size__: arr.__size__' );

#
#  12: bracket hash index 'alpha'.
$syntax = "<:$token hash[ 'alpha' ] :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_var( hash => { 'alpha' => 'a', 'beta' => 'b' } );
$template->set_template_string( $syntax );
is( ${$template->run()}, 'a',
    $expr_type . "bracket hash index 'alpha': hash[ 'alpha' ]" );

#
#  13: variable bracket hash index.
$syntax = "<:$token hash[ greek ] :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_var( hash => { 'alpha' => 'a', 'beta' => 'b' } );
$template->add_var( greek => 'beta' );
$template->set_template_string( $syntax );
is( ${$template->run()}, 'b',
    $expr_type . "variable bracket hash index: hash[ greek ]" );

#
#  14: dotted hash index 'alpha'.
#  We've tested this already in effect, but here for completeness.
$syntax = "<:$token hash.alpha :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_var( hash => { 'alpha' => 'a', 'beta' => 'b' } );
$template->set_template_string( $syntax );
is( ${$template->run()}, 'a',
    $expr_type . "dotted hash index 'alpha': hash.alpha" );

#
#  15: dotted hash faux-index '__size__'.
#  We've tested this already in effect, but here for completeness.
$syntax = "<:$token hash.__size__ :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_var( hash => { 'alpha' => 'a', 'beta' => 'b' } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '2',
    $expr_type . "dotted hash faux-index '__size__': hash.__size__" );

#
#  16: mix it all together
$syntax = "<:$token str.sub :> <:$token numbers[ 3 ] :> <:$token a :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_vars(
    {
        str     => { sub => 'a string' },
        a       => 'U',
        numbers => [ 1, 2, 3, 4, 5 ],
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, 'a string 4 U',
    $expr_type . "mix it all together: $syntax" );

#
#  17: warn on undef value
$syntax = "<:$token a :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->set_template_string( $syntax );
warns_ok { $template->run() }
    qr/Template runtime error: undefined template value 'a' at line 1, char 1 of/,
    $expr_type . 'warn on undef value of template var';

#
#  18: undef value for subscript of parent.
$syntax = "<:$token a[ b ] :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_vars( {
    a => { 'existing' => 1, },
    b => 'non-existing',
    } );
$template->set_template_string( $syntax );
warns_ok { $template->run() }
    qr/Template runtime error: undefined template value 'a\[ b \]' at line 1, char 1 of/,
    $expr_type . 'warn on undef value of template var hash value';

#
#  19: error on subscript of non-reference parent.
$syntax = "<:$token a[ b ] :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_vars( {
    a => 'not a hash, idiot',
    b => 'index index index',
    } );
$template->set_template_string( $syntax );
throws_ok { $template->run() }
    qr/Template runtime error: Can't get key 'index index index' \(from 'b'\) of non-reference parent in 'a\[ b \]' at line 1, char 1 of/,
    $expr_type . 'error on subscript of non-reference parent';

#
#  20: error on subscript of undef parent.
$syntax = "<:$token a[ b ] :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_vars( {
    b => 'index index index',
    } );
$template->set_template_string( $syntax );
throws_ok { $template->run() }
    qr/Template runtime error: Can't get key 'index index index' \(from 'b'\) of undefined parent in 'a\[ b \]' at line 1, char 1 of/,
    $expr_type . 'error on subscript of undef parent';

#
#  21: error on undef subscript of parent.
$syntax = "<:$token a[ b ] :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_vars( {
    a => { 'existing' => 1, },
    } );
$template->set_template_string( $syntax );
{
    #  We want to hide the warning that 'b' is undef because it's
    #  intentional as the test...
    local $SIG{ __WARN__ } = sub {};
    throws_ok { $template->run() }
        qr/Template runtime error: Undefined index 'b' in 'a\[ b \]' at line 1, char 1 of/,
        $expr_type . 'error on undef subscript of parent';
}

#
#  22: error on string index of array ref.
$syntax = "<:$token a[ b ] :>";
$template = $expr_type eq '' ? Template::Sandbox->new() : Template::Sandbox->new( allow_bare_expr => 1 );
$template->add_vars( {
    a => [ 'not a hash, idiot' ],
    b => 'index index index',
    } );
$template->set_template_string( $syntax );
throws_ok { $template->run() }
    qr/Template runtime error: Can't index array-reference with string 'index index index' \(from 'b'\) in 'a\[ b \]' at line 1, char 1 of/,
    $expr_type . 'error on string index of array ref';

#
#  Permutations of indexing.
foreach my $one ( @chain_one )
{
    foreach my $two ( @chain_two )
    {
        foreach my $three ( @chain_three )
        {
            foreach my $four ( @chain_four )
            {
                SKIP: foreach my $five ( @chain_five )
                {
                    $syntax = "<:$token $one$two$three$four$five :>";
#print "#testing $syntax\n";
                    $template = $expr_type eq '' ?
                        Template::Sandbox->new() :
                        Template::Sandbox->new( allow_bare_expr => 1 );
                    $template->register_template_function(
                        'passthrough' =>
                            ( one_arg sub { $_[ 0 ] } ),
                        );
                    $template->add_var( one => $chain_var );
                    lives_ok { $template->set_template_string( $syntax ) }
                        "permutations: $syntax compile";
                    skip 'Skipping run - compile failed', 1 if $@;
#use Data::Dumper;
#print Data::Dumper::Dumper( $template ) if $syntax =~ /get/;
                    is( ${$template->run()}, 'chain var value',
                        "permutations: $syntax run" );
                }
            }
        }
    }
}
}


#
#  +1: clear_vars() before compile removes var
$syntax = "<: expr a :>";
$template = Template::Sandbox->new();
$template->add_var( a => 42 );
$template->clear_vars();
$template->set_template_string( $syntax );
warns_ok { $template->run() }
    qr/Template runtime error: undefined template value 'a' at line 1, char 1 of/,
    'clear_vars() before compile remove var';

#
#  +2: clear_vars() after compile removes var
$syntax = "<: expr a :>";
$template = Template::Sandbox->new();
$template->add_var( a => 42 );
$template->set_template_string( $syntax );
$template->clear_vars();
warns_ok { $template->run() }
    qr/Template runtime error: undefined template value 'a' at line 1, char 1 of/,
    'clear_vars() after compile remove var';

package Template::Sandbox::TestMethodObject;

sub valid_template_method
{
    my ( $self, $method ) = @_;

    return( 1 );
}

sub get
{
    my ( $self, $index ) = @_;

    return( $self->{ $index } );
}

1;
