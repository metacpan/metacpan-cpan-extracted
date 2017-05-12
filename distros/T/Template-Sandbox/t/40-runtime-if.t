#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;

my @first_tokens  = qw/if unless/;
my @second_tokens = qw/if unless none/;
my @third_tokens  = qw/else none/;

my $num_tests = 5 + ( 2 *
    ( scalar( @first_tokens ) * 2 ) *
    ( scalar( @second_tokens ) * 2 ) *
    ( scalar( @third_tokens ) ) );

plan tests => $num_tests;

my ( $template, $syntax );

my @branches = ( 'one', 'two', 'three' );

#  Yick, yick, and double yick.
#  Yes this produces some dupes, but better some dupes and to be exhaustive
#  than try to make it even more complex to avoid the dupes.
foreach my $first ( @first_tokens )
{
    foreach my $first_val ( 0, 1 )
    {
        my ( $first_true, $first_clause );

        $first_true = $first_val;
        $first_true = !$first_true if $first eq 'unless';

        $first_clause = "<: $first $first_val :>$branches[ 0 ]";

foreach my $second ( @second_tokens )
{
    foreach my $second_val ( 0, 1 )
    {
        my ( $second_true, $second_clause );

        if( $second eq 'none' )
        {
            $second_true   = 0;
            $second_clause = '';
        }
        else
        {
            $second_true = $second_val;
            $second_true = !$second_true if $second eq 'unless';
            $second_clause = "<: els$second $second_val :>$branches[ 1 ]";
        }

foreach my $third ( @third_tokens )
{
    my ( $third_true, $third_clause, $result );

    if( $third eq 'none' )
    {
        $third_true   = 0;
        $third_clause = '';
    }
    else
    {
        $third_true = 1;
        $third_clause = "<: else :>$branches[ 2 ]";
    }

    $syntax = "$first_clause$second_clause$third_clause<: endif :>";
    $result = '';
    $result = $branches[ 2 ] if $third_true;
    $result = $branches[ 1 ] if $second_true;
    $result = $branches[ 0 ] if $first_true;

    $template = Template::Sandbox->new();
    $template->set_template_string( $syntax );
    is( ${$template->run()}, $result, $syntax . " = '$result'" );
}
}
}
}
}


#  I truly loathe cut-n-paste code, but sometimes it's the easiest way...
foreach my $first ( @first_tokens )
{
    foreach my $first_val ( 0, 1 )
    {
        my ( $first_true, $first_clause );

        $first_true = $first_val;
        $first_true = !$first_true if $first eq 'unless';

        $first_clause = "<: $first a :>$branches[ 0 ]";

foreach my $second ( @second_tokens )
{
    foreach my $second_val ( 0, 1 )
    {
        my ( $second_true, $second_clause );

        if( $second eq 'none' )
        {
            $second_true   = 0;
            $second_clause = '';
        }
        else
        {
            $second_true = $second_val;
            $second_true = !$second_true if $second eq 'unless';
            $second_clause = "<: els$second b :>$branches[ 1 ]";
        }

foreach my $third ( @third_tokens )
{
    my ( $third_true, $third_clause, $result );

    if( $third eq 'none' )
    {
        $third_true   = 0;
        $third_clause = '';
    }
    else
    {
        $third_true = 1;
        $third_clause = "<: else :>$branches[ 2 ]";
    }

    $syntax = "$first_clause$second_clause$third_clause<: endif :>";
    $result = '';
    $result = $branches[ 2 ] if $third_true;
    $result = $branches[ 1 ] if $second_true;
    $result = $branches[ 0 ] if $first_true;

    $template = Template::Sandbox->new();
    $template->set_template_string( $syntax );
    $template->add_vars(
        {
            a => $first_val,
            b => $second_val,
        } );
    is( ${$template->run()}, $result, $syntax . " ( a => $first_val, b => $second_val ) = '$result'" );
}
}
}
}
}

#
#
#  Nested if statements.
#


#  Syntax used by the next 4 tests.
$syntax = "{<: if a :>A[<: if a.a :>A=1<: else :>A=0<: endif :>]<: else :>B[<: if b :>1<: else :>0<: endif :>]<: endif :>}";

#
#  +1: Nested if-else statement on both branches, path 11.
$template = Template::Sandbox->new();
$template->add_vars(
    {
        a => { a => 1 },
        b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '{A[A=1]}', 'nested variable if, path 11' );

#
#  +2: Nested if-else statement on both branches, path 10.
$template = Template::Sandbox->new();
$template->add_vars(
    {
        a => { a => 0 },
        b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '{A[A=0]}', 'nested variable if, path 10' );

#
#  +3: Nested if-else statement on both branches, path 01.
$template = Template::Sandbox->new();
$template->add_vars(
    {
        a => 0,
        b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '{B[1]}', 'nested variable if, path 01' );

#
#  +4: Nested if-else statement on both branches, path 00.
$template = Template::Sandbox->new();
$template->add_vars(
    {
        a => 0,
        b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '{B[0]}', 'nested variable if, path 00' );


#
#  +5:  Nested constant if test.
$syntax = "<: if 0 :>A<: else :>B<: endif :>";
$syntax = "<: if 1 :>A($syntax)<: else :>B($syntax)<: endif :>";
$syntax = "<: if 0 :>A[$syntax]<: else :>B[$syntax]<: endif :>";
$syntax = "{$syntax}";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '{B[A(B)]}', 'nested constant if' );
