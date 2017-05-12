#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;
use Test::Exception;

#  SYNTAXES TO TEST:
#    var .
#    expr .
#    #
#    debug x on
#  Combinations of:
#    { if .     } {               } {      } { endif      }
#    { unless . } { elsif .       } { else } { end if     }
#                 { elseif .      }          { endunless  }
#                 { else if .     }          { end unless }
#                 { elsunless .   }          { end        }
#                 { elseunless .  }
#                 { else unless . }
#  Combinations of:
#    { for . in .     } { endfor      }
#    { foreach . in . } { end for     }
#                       { endforeach  }
#                       { end foreach }
#                       { end         }
#  TODO:
#    include .

my ( @basic_syntaxes );
my ( @if_one, @if_two, @if_three, @if_four );
my ( @for_one, @for_two );
my ( $num_basic_tests, $num_if_tests, $num_for_tests );

@basic_syntaxes = (
    'var x',
    'expr x',
    '# comment contents',
    'debug x on',
    );
@if_one   = ( 'if x', 'unless x' );
@if_two   = ( '',
              'elsif y', 'elseif y', 'else if y',
              'elsunless y', 'elseunless y', 'else unless y',
            );
@if_three = ( '', 'else', 'elsif z', );
@if_four  = ( 'endif', 'end if', 'endunless', 'end unless', 'end', );
@for_one  = ( 'for x in y', 'foreach x in y', );
@for_two  = ( 'endfor', 'end for', 'endforeach', 'end foreach', 'end', );

$num_basic_tests = scalar( @basic_syntaxes );
$num_if_tests    = scalar( @if_one ) * scalar( @if_two ) *
                   scalar( @if_three ) * scalar( @if_four );
$num_for_tests   = scalar( @for_one ) * scalar( @for_two );

plan tests => $num_basic_tests + $num_if_tests + $num_for_tests;

my ( $template );

foreach my $basic_syntax ( @basic_syntaxes )
{
    my ( $syntax );

    $syntax = "<: $basic_syntax :>";
    $template = Template::Sandbox->new();
    lives_ok { $template->set_template_string( $syntax ) } $syntax;
}

foreach my $syntax_one ( @if_one )
{
    foreach my $syntax_two ( @if_two )
    {
        foreach my $syntax_three ( @if_three )
        {
            foreach my $syntax_four ( @if_four )
            {
                my ( $syntax );

                $syntax  = "<: $syntax_one :>a";
                $syntax .= "<: $syntax_two :>b"   if $syntax_two;
                $syntax .= "<: $syntax_three :>c" if $syntax_three;
                $syntax .= "<: $syntax_four :>";

                $template = Template::Sandbox->new();
                lives_ok { $template->set_template_string( $syntax ) } $syntax;
            }
        }
    }
}

foreach my $syntax_one ( @for_one )
{
    foreach my $syntax_two ( @for_two )
    {
        my ( $syntax );

        $syntax  = "<: $syntax_one :>a<: $syntax_two :>";

        $template = Template::Sandbox->new();
        lives_ok { $template->set_template_string( $syntax ) } $syntax;
    }
}
