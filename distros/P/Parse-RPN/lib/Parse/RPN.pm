#!/usr/bin/perl
###########################################################
# RPN package with DICT
# Gnu GPL2 license
#
# Fabrice Dulaunoy <fabrice@dulaunoy.com>
###########################################################
# ChangeLog:
#
###########################################################

=head1 NAME

  Parse::RPN (2.xx) - Is a minimalist RPN parser/processor (a little like FORTH)

=head1 SYNOPSIS

  use Parse::RPN;
  $result=rpn(string ...);
  @results=rpn(string ...);
  
  $error=rpn_error();

  string... is a list of RPN operators and values separated by a coma
  in scalar mode RPN return the result of the calculation (If the stack contain more then one element, 
  you receive a warning and the top value on the stack)
  in array mode, you receive the content of the stack after evaluation

=head1 DESCRIPTION

  rpn() receive in entry a scalar of one or more elements coma separated 
  and evaluate as an RPN (Reverse Polish Notation) command.
  The function split all elements and put in the stack.
  The operator are case sensitive.
  The operator are detect as is, if they are alone in the element of the stack. 
  Extra space before or after are allowed
  (e.g "3,4,MOD" here MOD is an operator but it is not the case in "3,4,MOD 1")
  If element is not part of the predefined operator (dictionary), the element is push as a litteral.
  If you would like to put a string which is part of the dictionary, put it between quote or double-quote 
  (e.g "3,4,'MOD'" here MOD is a literal and the evaluation return MOD)
  If the string contain a coma, you need also to quote or double-quote the string. 
  (be care to close your quoted or double-quoted string)

  The evaluation follow the rule of RPN or FORTH or POSTCRIPT or pockect calcutor HP.
  Look on web for documentation about the use of RPN notation.
  
  I use this module in a application where the final user need to create and maintain 
  a configuration file with the possibility to do calculation on variables returned from application.
  
  The idea of this module is comming from Math::RPN of Owen DeLong, owen@delong.com that I used for more then a year
  before some of my customer would like more...

  rpn_error() return the last error from the evaluation (illegal division by 0, error from the PERL function execution...)
  each time that rpn() is call the rpn_error() is reinitianised.

=cut

package Parse::RPN;
use strict;
use HTTP::Date;
use Fcntl;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

use Data::Dumper;
use Carp qw(carp);

sub cc
{
    my $info = shift;
    my $line = ( caller( 0 ) )[2] || 0;
    carp "[$line] $info";
}

@ISA = qw(Exporter AutoLoader);

@EXPORT = qw(rpn rpn_error rpn_separator_out  rpn_separator_in);

$VERSION = '2.85';

my %dict;
my %pub_dict;
my %var;

my @loop;
my @begin;
my @return;

my $DEBUG;

my $separator_out = ' ';
my $separator_in  = ',';
########################
# mathematic operators
########################

=head1 MATHEMATIC operators
        
=cut

=head2 a b +

      return the result of 'a' + 'b' 
        
=cut

$dict{'+'} = sub {

    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, $a + $b;
    return \@ret, 2, 0;
};

=head2 a b -

      return the result of 'a' - 'b' 
        
=cut

$dict{'-'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, $b - $a;
    return \@ret, 2, 0;
};

=head2 a b *

      return the result of 'a' * 'b' 
        
=cut

$dict{'*'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, $b * $a;
    return \@ret, 2, 0;
};

=head2 a b /

      return the result of 'a' / 'b' 
      if b =0 return '' (to prevent exception raise)
        
=cut

$dict{'/'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    my $c;
    eval { ( $c = $b / $a ) };
    if ( $@ )
    {
        chomp $@;
        $DEBUG = $@;
        @ret   = ();
    }
    else
    {
        push @ret, $c;
    }
    return \@ret, 2, 0;
};

=head2 a b **

      return the result of 'a' ** 'b'  (exponant)
        
=cut

$dict{'**'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, $b**$a;
    return \@ret, 2, 0;
};

=head2 a 1+

      return the result of 'a' +1 
        
=cut

$dict{'1+'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, $a + 1;
    return \@ret, 1, 0;
};

=head2 a 1-

      return the result of 'a' -1 
        
=cut

$dict{'1-'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, $a - 1;
    return \@ret, 1, 0;
};

=head2 a 2-

      return the result of 'a' -2 
        
=cut

$dict{'2-'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, $a - 2;
    return \@ret, 1, 0;
};

=head2 a 2+

      return the result of 'a' +2 
        
=cut

$dict{'2+'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, $a + 2;
    return \@ret, 1, 0;
};

=head2 a b MOD

      return the result of 'a' % 'b'
        
=cut

$dict{MOD} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, $b % $a;
    return \@ret, 2, 0;
};

=head2 a ABS

      return the result of  abs 'a'
        
=cut

$dict{ABS} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, abs( $a );
    return \@ret, 1, 0;

};

=head2 a INT

      return the result of INT 'a' 
        
=cut

$dict{INT} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, int( $a );
    return \@ret, 1, 0;
};

=head2 a +-

      return the result negate value of 'a' (- 'a' )
        
=cut

$dict{'+-'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, -( $a );
    return \@ret, 1, 0;
};

=head2 a REMAIN

      return the result of 'a' - int 'a' (fractional part of 'a' ) 
        
=cut

$dict{REMAIN} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, $a - int( $a );
    return \@ret, 2, 0;
};

=head2 a SIN

      return the result of sin 'a'  ('a' in RADIAN)
        
=cut

$dict{SIN} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, sin( $a );
    return \@ret, 1, 0;
};

=head2 a COS

      return the result of cos 'a'  ('a' in RADIAN)
        
=cut

$dict{COS} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, cos( $a );
    return \@ret, 1, 0;
};

=head2 a TAN

      return the result of tan 'a'  ('a' in RADIAN)
        
=cut

$dict{TAN} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( sin( $a ) / cos( $a ) );
    return \@ret, 1, 0;
};

=head2 a CTAN

      return the result of cotan 'a'  ('a' in RADIAN)
        
=cut

$dict{CTAN} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( cos( $a ) / sin( $a ) );
    return \@ret, 1, 0;
};

=head2 a LN

      return the result of ln 'a' 
      if = 0 return '' (to prevent exception raise)
        
=cut

$dict{LN} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    my $c;
    eval { ( $c = log( $a ) ) };
    if ( $@ )
    {
        chomp $@;
        $DEBUG = $@;
        @ret   = ();
    }
    else
    {
        push @ret, $c;
    }
    return \@ret, 1, 0;
};

=head2 a EXP

      return the result of 'e' ** 'a' 
        
=cut

$dict{EXP} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, exp( $a );
    return \@ret, 1, 0;
};

=head2 PI

      return the value of PI (3.14159265358979)
        
=cut

$dict{PI} = sub {
    my @ret;
    push @ret, "3.1415926535898";
    return \@ret, 0, 0;
};

=head2 a b MIN

      return the smallest value of the 2 arguments
        
=cut

$dict{MIN} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a < $b ? $a : $b );
    return \@ret, 2, 0;
};

=head2 a b MAX

      return the greatest value of the 2 arguments
        
=cut

$dict{MAX} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a > $b ? $a : $b );
    return \@ret, 2, 0;
};

=head2 a MINX

      return the smallest value from the a elements from the stack
        
=cut

$dict{MINX} = sub {
    my $work1 = shift;
    my $nbr   = pop @{ $work1 };
    my $len   = scalar( @{ $work1 } );
    my @ret;
    my $tmp =@{ $work1 }[ $len -1]; 
    for my $i ( 1 .. $nbr )
    {
        my $b = @{ $work1 }[ $len - $i ];
        $tmp = $tmp < $b ? $tmp : $b;
    }
    push @ret, $tmp;
    return \@ret, $nbr + 1, 0;
};

=head2 a b MAXX

      return the greatest value from the a elements from the stack
        
=cut

$dict{MAXX} = sub {
    my $work1 = shift;
    my $nbr   = pop @{ $work1 };
    my $len   = scalar( @{ $work1 } );
    my @ret;
    my $tmp = 0;
    for my $i ( 1 .. $nbr )
    {
        my $b = @{ $work1 }[ $len - $i ];
        $tmp = $tmp > $b ? $tmp : $b;
    }
    push @ret, $tmp;
    return \@ret, $nbr + 1, 0;
};
=head2 a SUM
        
        sum the a elements from the top of the stack
        remove these a elements
        and return the result value on the stack

=cut

$dict{SUM} = sub {
    my $work1 = shift;
    my $nbr   = pop @{ $work1 };
    my $len   = scalar( @{ $work1 } );
    my @ret;
    my $tmp;
    for my $i ( 1 .. $nbr )
    {
        my $b = @{ $work1 }[ $len - $i ];
        $tmp += $b;
    }
    push @ret, $tmp;
    return \@ret, $nbr + 1, 0;
};

=head2 a STATS
        
        STATS the a element on top of the stack
        remove these a element
        the new variable _SUM_, _MULT_, _ARITH_MEAN_, _GEOM_MEAN_, _QUAD_MEAN_ (= _RMS_), _HARM_MEAN_, _STD_DEV_, _SAMPLE_STD_DEV_, _VARIANCE_,

=cut

$dict{STATS} = sub {
    my $work1 = shift;
    my $nbr   = pop @{ $work1 };
    my $len   = scalar( @{ $work1 } );
    my @ret;
    my $sum;
    my $mul = 1;
    my $harm;
    my $quad;
    my @elem;
    my $std_dev;

    for my $i ( 1 .. $nbr )
    {
        my $b = @{ $work1 }[ $len - $i ];
        push @elem, $b;
        $sum += $b;
        $mul *= $b;
        $harm += 1 / $b if ( $b );
        $quad += $b**2;
    }

    $var{ _ARITH_MEAN_ } = 0;
    $var{ _GEOM_MEAN_ }  = 0;
    $var{ _HARM_MEAN_ }  = 0;
    $var{ _VARIANCE_ }   = 0;
    $var{ _STD_DEV_ }    = 0;

    $var{ _SUM_ }        = $sum;
    $var{ _MULT_ }       = $mul;
    $var{ _ARITH_MEAN_ } = $sum / $nbr if ( $nbr != 0 );
    $var{ _GEOM_MEAN_ }  = $mul**( 1 / $nbr ) if ( $nbr != 0 );
    $var{ _HARM_MEAN_ }  = $nbr / $harm if ( $harm );
    $var{ _QUAD_MEAN_ }  = $var{ _RMS_ } = $quad**.5;
    foreach my $c ( @elem )
    {
        $std_dev += ( $c - $var{ _ARITH_MEAN_ } )**2;
    }
    $var{ _VARIANCE_ } = ( $std_dev / ( $nbr - 1 ) ) if ( $nbr != 1 );
    $var{ _STD_DEV_ } = ( $std_dev / $nbr )**.5 if ( $nbr != 0 );
    $var{ _SAMPLE_STD_DEV_ } = $var{ _VARIANCE_ }**.5;

    return \@ret, $nbr + 1, 0;
};

########################
# relational operators
########################

=head1 RELATIONAL operators

=cut

=head2 a b <

      return the result of 'a' < 'b'  ( BOOLEAN value ) 
        
=cut

$dict{'<'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a > $b ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b <=

      return the result of 'a' <= 'b'  ( BOOLEAN value )
        
=cut

$dict{'<='} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a >= $b ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b >

      return the result of 'a' > 'b'  ( BOOLEAN value )
        
=cut

$dict{'>'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a < $b ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b >=

      return the result of 'a' >= 'b'  ( BOOLEAN value )
        
=cut

$dict{'>='} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a <= $b ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b ==

      return the result of 'a' == 'b'  ( BOOLEAN value ) 1 if a == b else 0
        
=cut

$dict{'=='} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b == $a ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b <=>

      return the result of 'a' <=> 'b'  ( BOOLEAN value  ) -1 if a < b ,0 if a == b, 1 if a > b
        
=cut

$dict{'<=>'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b <=> $a );
    return \@ret, 2, 0;
};

=head2 a b !=

      return the result of 'a' != 'b'  ( BOOLEAN value ) 0 if a == b else 1
        
=cut

$dict{'!='} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b != $a ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b v ><

      return the 1 ( BOOLEAN value ) if v greater than a but lower than b. Otherwise return 0
      ( aka between boundaries excluded )
=cut

$dict{'><'} = sub {
    my $work1 = shift;
    my $v     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( ( $v > $a && $v < $b ) ? 1 : 0 );
    return \@ret, 3, 0;
};

=head2 a b v >=<

      return 1 ( BOOLEAN value ) if v greater or equal to a but lower or equal to b. Otherwise return 0 
      ( aka between boundaries included )
        
=cut

$dict{'>=<'} = sub {
    my $work1 = shift;
    my $v     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( ( $v >= $a && $v <= $b ) ? 1 : 0 );
    return \@ret, 3, 0;
};

=head2 a b NE<lt>

      return the result of 'a' N< 'b'  ( BOOLEAN value ) if a is ISNUM
        
=cut

$dict{'N<'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( ( $b =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ && $a > $b ) ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b NE<gt>=

      return the result of 'a' N<= 'b'  ( BOOLEAN value ) if a is ISNUM
        
=cut

$dict{'N<='} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( ( $b =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ && $a >= $b ) ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b N>

      return the result of 'a' N> 'b'  ( BOOLEAN value ) if a is ISNUM
        
=cut

$dict{'N>'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( ( $b =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ && $a < $b ) ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b N>=

      return the result of 'a' N>= 'b'  ( BOOLEAN value ) if a is ISNUM
        
=cut

$dict{'N>='} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( ( $b =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ && $a <= $b ) ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b N==

      return the result of 'a' N== 'b'  ( BOOLEAN value ) 1 if a == b and a ISNUM else 0
        
=cut

$dict{'N=='} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( ( $b =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ && $b == $a ) ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b N!=

     return the result of 'a' != 'b'  ( BOOLEAN value ) 0 if a == b and a ISNUM else 1
     
=cut

$dict{'N!='} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( ( $b =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ && $b != $a ) ? 1 : 0 );
    return \@ret, 2, 0;
};



########################
# logical operators
########################

=head1 LOGICAL operators

=cut

=head2 a b OR

      return the 1 one of the 2 argument are not equal to 0
        
=cut

$dict{OR} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a || $b );
    return \@ret, 2, 0;
};

=head2 a b AND

      return the 0 one of the 2 argument are equal to 0
        
=cut

$dict{AND} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a && $b );
    return \@ret, 2, 0;
};

=head2 a b XOR

      return the 0 if the  2 argument are equal
        
=cut

$dict{XOR} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a xor $b ) ? 1 : 0;
    return \@ret, 2, 0;
};

=head2 a b NXOR

      return the 0 if the  2 argument are equal. Any non numeric elements is seen as a 0.
        
=cut

$dict{NXOR} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    $a = $a =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ? $a : 0;
    $b = $b =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ? $b : 0;
    my @ret;
    push @ret, ( $a xor $b ) ? 1 : 0;
    return \@ret, 2, 0;
};

=head2 a NOT

      return the 0 if the argument is not eqauk to 0
      return the 1 if the argument is  eqauk to 0
        
=cut

$dict{NOT} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };

    my @ret;
    push @ret, ( not $a ) ? 1 : 0;
    return \@ret, 1, 0;
};

=head2 a TRUE

      return the 1 if the top of stack is !=0 and if stack not empty
        
=cut

$dict{TRUE} = sub {
    my $work1 = shift;
    my $a;
    my $b = 0;
    if ( scalar @{ $work1 } )
    {
        $b = 1;
        $a = pop @{ $work1 };
        $a = $a =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ? $a : 0;
        if ( $a > 0 )
        {
            $b = 1;
        }
        else
        {
            $b = 0;
        }
    }
    my @ret;
    push @ret, $b;
    return \@ret, 1, 0;
};

=head2 a FALSE

      return the 0 if the top of stack is !=0
        
=cut

$dict{FALSE} = sub {
    my $work1 = shift;
    my $a;
    my $b = 1;
    if ( scalar @{ $work1 } )
    {
        $b = 0;
        $a = pop @{ $work1 };
        $a = $a =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ? $a : 0;
        if ( $a > 0 )
        {
            $b = 0;
        }
        else
        {
            $b = 1;
        }
    }
    my @ret;
    push @ret, $b;
    return \@ret, 1, 0;
};


=head2 a b >>

      bitwise shift to the right
      shift the bits in a to the left of b level
        
=cut

$dict{'>>'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b >> $a );
    return \@ret, 2, 0;
};

=head2 a b <<

      bitwise shift to the left
      shift the bits in a to the left of b level
        
=cut

$dict{'<<'} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b << $a );
    return \@ret, 2, 0;
};


########################
# misc operators
########################

=head1 MISC operators

=cut

=head2 a VAL,RET, "operator" LOOKUP

      test with the "operator" the [a] value on each elements of VAL and if test succeed return the value from array RET with the same index
      the "operator" must be quoted to prevent evaluation
        
=cut

$dict{LOOKUP} = sub {
    my $work1 = shift;
    my $ope   = pop @{ $work1 };

    my @RET  = @{ $var{ pop @{ $work1 } } };
    my @VAL  = @{ $var{ pop @{ $work1 } } };
    my $item = pop @{ $work1 };
    my @ret;
    for my $ind ( 0 .. $#VAL )
    {
        my @tmp;
#         push @tmp, $item, $VAL[$ind], $ope;
        push @tmp, $VAL[$ind], $item, $ope;
        process( \@tmp );
        if ( $tmp[0] )
        {
            push @ret, $RET[$ind];
            last;
        }
    }
    return \@ret, 4, 0;
};

=head2 a VAL,RET, "operator" LOOKUPP

      Test with the perl "operator" the [a] value on each elements of VAL 
      and if test succeed return the value from array RET with the same index
      The "operator" must be quoted to prevent evaluation
        
=cut

$dict{LOOKUPP} = sub {
    my $work1 = shift;
    my $ope   = pop @{ $work1 };
    my @RET   = @{ $var{ pop @{ $work1 } } };
    my @VAL   = @{ $var{ pop @{ $work1 } } };
    my $item  = pop @{ $work1 };
    my @ret;
    for my $ind ( 0 .. $#VAL )
    {
        my $test  = $item . $ope . $VAL[$ind];
        my $state = eval $test;
        if ( $state )
        {
            push @ret, $RET[$ind];
            last;
        }
    }
    return \@ret, 4, 0;
};

=head2 a VAL,RET,OPE LOOKUPOP

      Loop on each item of array VAL and test the value [ a ]  with the operator from ope ARRAY 
      against the corresponding value in array VAL and return the value from array RET with the same index
        
=cut

$dict{LOOKUPOP} = sub {
    my $work1 = shift;
    my @OPE   = @{ $var{ pop @{ $work1 } } };
    my @RET   = @{ $var{ pop @{ $work1 } } };
    my @VAL   = @{ $var{ pop @{ $work1 } } };
    my $item  = pop @{ $work1 };
    my @ret;
    for my $ind ( 0 .. $#VAL )
    {
        my @tmp;
#         push @tmp, $item, $VAL[$ind], $OPE[$ind];
        push @tmp, $VAL[$ind], $item, $OPE[$ind];
        process( \@tmp );
        if ( $tmp[0] )
        {
            push @ret, $RET[$ind];
            last;
        }
    }
    return \@ret, 4, 0;
};

=head2 a VAL,RET,OPE LOOKUPOPP

      Loop on each item of array VAL and test the value [ a ]  with the perl operator from ope ARRAY 
      against the corresponding value in array VAL and return the value from array RET with the same index
        
=cut

$dict{LOOKUPOPP} = sub {
    my $work1 = shift;
    my @OPE   = @{ $var{ pop @{ $work1 } } };
    my @RET   = @{ $var{ pop @{ $work1 } } };
    my @VAL   = @{ $var{ pop @{ $work1 } } };
    my $item  = pop @{ $work1 };
    my @ret;
    for my $ind ( 0 .. $#VAL )
    {
        my $test  = $item . $OPE[$ind] . $VAL[$ind];
        my $state = eval $test;
        if ( $state )
        {
            push @ret, $RET[$ind];
            last;
        }
    }
    return \@ret, 4, 0;
};

=head2 TICK

      return the current time in ticks
        
=cut

$dict{TICK} = sub {
    my @ret;
    push @ret, ( time() );
    return \@ret, 0, 0;
};

=head2 a LTIME

      return the localtime coresponding to the ticks value 'a'
      the format is 'sec' 'min' 'hour' 'day_in_the_month' 'month' 'year' 'day_in_week' 'day_year' 'dayloight_saving'
      'year' is the elapsed year since 1900
      'month' start to 0
      The format is the same as localtime() in perl
        
=cut

$dict{LTIME} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( localtime( $a ) );
    return \@ret, 1, 0;
};

=head2 a GTIME

      return the gmtime coresponding to the ticks value 'a'
      the format is 'sec' 'min' 'hour' 'day_in_the_month' 'month' 'year' 'day_in_week' 'day_year' 'dayloight_saving'
      'year' is the elapsed year since 1900
      'month' start to 0
      The format is the same as gmtime() in perl
        
=cut

$dict{GTIME} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( gmtime( $a ) );
    return \@ret, 1, 0;
};

=head2 a HLTIME

      return the localtime coresponding to the ticks value 'a' in a human readable format
        
=cut

$dict{HLTIME} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, scalar( localtime( $a ) );
    return \@ret, 1, 0;
};

=head2 a HGTIME

      return the gmtime coresponding to the ticks value 'a' in a human readable format
        
=cut

$dict{HGTIME} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, scalar( gmtime( $a ) );
    return \@ret, 1, 0;
};

=head2 a HTTPTIME

      return the ticks coresponding to the time value in a format accepted by HTTP::Date
        
=cut

$dict{HTTPTIME} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, str2time( $a );
    return \@ret, 1, 0;
};

=head2 RAND

      return a random value in the range [0,1[
        
=cut

$dict{RAND} = sub {
    my @ret;
    push @ret, rand();
    return \@ret, 0, 0;
};

=head2 a LRAND

      return a random value in the range [0,'a'[
        
=cut

$dict{LRAND} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, rand( $a );
    return \@ret, 1, 0;
};

=head2 a SPACE

      return the number 'a' formated with space each 3 digits
        
=cut

$dict{SPACE} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $text  = reverse $a;
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1 /g;
    $text = reverse $text;
    my @ret;
    push @ret, $text;
    return \@ret, 1, 0;
};

=head2 a DOT

      return the number 'a' formated with . (dot) each 3 digits
        
=cut

$dict{DOT} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $text  = reverse $a;
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1./g;
    $text = reverse $text;
    my @ret;
    push @ret, $text;
    return \@ret, 1, 0;
};

=head2 a NORM

      return the number 'a' normalize by slice of 1000 with extra power value "K", "M", "G", "T", "P" (or nothing if lower than 1000)
        
=cut

$dict{NORM} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $exp;
    $a = $a ? $a : 0;
    my @EXP = ( " ", "K", "M", "G", "T", "P" );
    while ( $a > 1000 )
    {
        $a = $a / 1000;
        $exp++;
    }
    $a = sprintf "%.2f", $a;
    my $ret = "$a $EXP[$exp]";
    my @ret;
    push @ret, "'" . $ret . "'";
    return \@ret, 1, 0;
};

=head2 a NORM2

      return the number 'a' normalize by slice of 1024 with extra power value "K", "M", "G", "T", "P" (or nothing if lower than 1024)
        
=cut

$dict{NORM2} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $exp;
    $a = $a ? $a : 0;
    my @EXP = ( " ", "K", "M", "G", "T", "P" );
    while ( $a > 1024 )
    {
        $a = $a / 1024;
        $exp++;
    }
    $a = sprintf "%.2f", $a;
    my $ret = "$a $EXP[$exp]";
    my @ret;
    push @ret, "'" . $ret . "'";
    return \@ret, 1, 0;
};

=head2 a UNORM

      reverse function of NORM
      return the number from a 'a' with a sufix "K", "M", "G", "T", "P" (or nothing if lower than 1000)
      and calculate the real value base 1000 ( e.g  7k = 7000)
        
=cut

$dict{UNORM} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    $a = $a ? $a : 0;
    $a =~ /(\d+(\.{0,1}\d*)\s*)(\D)/;
    my $num  = $1;
    my $suff = lc( $3 );
    my %EXP  = (
        "k" => 1,
        "m" => 2,
        "g" => 3,
        "t" => 4,
        "p" => 5
    );
    my $mult = 0;

    if ( exists( $EXP{ $suff } ) )
    {
        $mult = $EXP{ $suff };
    }
    my $ret = $num * ( 1000**$mult );
    my @ret;
    push @ret, "'" . $ret . "'";
    return \@ret, 1, 0;
};

=head2 a UNORM2

      reverse function of NORM2
      return the number from a 'a' with a sufix "K", "M", "G", "T", "P" (or nothing if lower than 1024)
      and calculate the real value base 1024 ( e.g  7k = 7168)
        
=cut

$dict{UNORM2} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    $a = $a ? $a : 0;
    $a =~ /(\d+(\.{0,1}\d*)\s*)(\D)/;
    my $num  = $1;
    my $suff = lc( $3 );
    my %EXP  = (
        "k" => 1,
        "m" => 2,
        "g" => 3,
        "t" => 4,
        "p" => 5
    );
    my $mult = 0;

    if ( exists( $EXP{ $suff } ) )
    {
        $mult = $EXP{ $suff };
    }
    my $ret = $num * ( 1024**$mult );
    my @ret;
    push @ret, "'" . $ret . "'";
    return \@ret, 1, 0;
};

=head2 a OCT

      return the decimal value for the HEX, BINARY or OCTAL value 'a'
      OCTAL is like  '0nn' where n is in the range of 0-7
      BINARY is like '0bnnn...'   where n is in the range of 0-1
      HEX is like '0xnnn' where n is in the range of 0-9A-F
      if no specific format convert as an hexadecimal by default
        
=cut

$dict{OCT} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    if ( $a !~ /^0(x|b|([0-7][0-7]))/ )
    {
        $a = "0x" . $a;
    }
    push @ret, oct( $a );
    return \@ret, 1, 0;
};

=head2 a OCTSTR2HEX

      return a HEX string from a OCTETSTRING.
      useful when receiving an SNMP ASN.1 OCTETSTRING like mac address
        
=cut

$dict{OCTSTR2HEX} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, unpack( "H*", pack( "a*", $a ) );
    return \@ret, 1, 0;
};

=head2 a HEX2OCTSTR

      return a OCTETSTRING string from a HEX
      useful when you need to check if an SNMP ASN.1 OCTETSTRING if matching the hex value provided
        
=cut

$dict{HEX2OCTSTR} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, unpack( "a*", pack( "H*", $a ) );
    return \@ret, 1, 0;
};

=head2 a DDEC2STR

      return a string from a dotted DEC string
      useful when you need to manipulate an SNMP extension with 'exec' 
        
=cut

$dict{DDEC2STR} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, join "", map { sprintf( "%c", $_ ) } ( split /\./, $a );
    return \@ret, 1, 0;
};

=head2 a STR2DDEC

      return a dotted DEC string to a string
      useful when you need to manipulate an SNMP extension with 'exec' 
        
=cut

$dict{STR2DDEC} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, join '.', map { unpack( "c", $_ ) } ( split //, $a );
    return \@ret, 1, 0;
};


########################
# structurated string operators
########################

=head1 Structurated string (SLxxx) operators

=cut

=head2 string a b SLSLICE

      return the STRUCTURATED list slice  from 'a' to 'b' extracted from STRUCTURATED list.
      string are the STRUCTURATED list
      the STRUCTURATED LIST use this format:
      each entries are separated by ' # ' and inside each entry , the KEY and the VAL are separated by ' | '
      'keys1 | val1 # key2 | val2 # Keys3 | val3 # Keys4 | val4 #'
      example:
      'keys1 | val1 # key2 | val2 # Keys3 | val3 # Keys4 | val4 #,1,2,SLSLICE'
      return:
      # key2 | val2 # Keys3 | val3 #

=cut

$dict{SLSLICE} = sub {
    my $work1 = shift;
    
    my $to  = pop @{ $work1 };
    my $from  = pop @{ $work1 };
    my $string = pop @{ $work1 };
    ( $from, $to ) = ( $to, $from ) if ( $from > $to );
    my @ret;
    
    $string =~ s/^#\s*//;
    my @tmp =  ( split /\s?\#\s?/, $string )[$from..$to];
    my $res = '# ' . join ( ' # ' , @tmp ).' #' if ( scalar @tmp );
    push @ret, $res;
    return \@ret, 3, 0;
};

=head2 string a SLITEM

      return the STRUCTURATED item at position 'a' from a STRUCTURATED list.
      string are the STRUCTURATED list
      the STRUCTURATED LIST use this format:
      each entries are separated by ' # ' and inside each entry , the KEY and the VAL are separated by ' | '
      'keys1 | val1 # key2 | val2 # Keys3 | val3 #'
      example:
      'keys1 | val1 # key2 | val2 # Keys3 | val3 #,1,SLITEM'
      return:
      # key2 | val2 #

=cut

$dict{SLITEM} = sub {
    my $work1 = shift;

    my $item  = pop @{ $work1 };
    my $string = pop @{ $work1 };

    my @ret;
    $string =~ s/^#\s*//;
    my $res =  ( split /\s?\#\s?/, $string )[$item];
    $res = '# ' . $res .' #' if ( $res );
    push @ret, $res;
    return \@ret, 2, 0;
};

=head2 string a SLGREP

      return a STRUCTURATED list from a STRUCTURATED list where the STRUCTURATED LIST match the REGEX a.
      string are the STRUCTURATED list
      the STRUCTURATED LIST use this format:
      each entries are separated by ' # ' and inside each entry , the KEY and the VAL are separated by ' | '
      'keys1 | val1 # key2 | val2 # Keys3 | val3 #'
      example:
      'keys1 | val1 # key2 | val2 # Keys3 | val3 #,Keys,SLGREP'
      return:
      #  Keys3 | val3 #

=cut

$dict{SLGREP} = sub {
    my $work1 = shift;

    my $regex  = pop @{ $work1 };
    my $string = pop @{ $work1 };

    my @ret;
    my $res;
    $string =~ s/^#\s*//;
    foreach my $i ( split /\s?\#\s?/, $string )
    {
        next unless ( $i );
        if ( $i =~ /$regex/ )
        {
            $res .= $i . ' # ';
        }
    }
    $res = '# ' . $res if ( $res );
    $res =~ s/\s+$//;
    push @ret, $res;
    return \@ret, 2, 0;
};

=head2 string a SLGREPI

      return a STRUCTURATED list from a STRUCTURATED list where the STRUCTURATED LIST match the REGEX a (case insensitive).
      string are the STRUCTURATED list
      the STRUCTURATED LIST use this format:
      each entries are separated by ' # ' and inside each entry , the KEY and the VAL are separated by ' | '
      'keys1 | val1 # key2 | val2 # Keys3 | val3 #'
      example:
      'keys1 | val1 # key2 | val2 # Keys3 | val3 #,Keys,SLGREPI'
      return:
      #  keys1 | val1 # Keys3 | val3 #

=cut

$dict{SLGREPI} = sub {
    my $work1 = shift;

    my $regex  = pop @{ $work1 };
    my $string = pop @{ $work1 };

    my @ret;
    my $res;
    $string =~ s/^#\s*//;
    foreach my $i ( split /\s?\#\s?/, $string )
    {
        next unless ( $i );
        if ( $i =~ /$regex/i )
        {
            $res .= $i . ' # ';
        }
    }
    $res = '# ' . $res if ( $res );
    $res =~ s/\s+$//;
    push @ret, $res;
    return \@ret, 2, 0;
};

=head2 string a SLSEARCHALL

      return all KEYS from a STRUCTURATED LIST where the STRUCTURATED LIST val match the REGEX a.
      string are the STRUCTURATED list
      the STRUCTURATED LIST use this format:
      each entries are separated by ' # ' and inside each entry , the KEY and the VAL are separated by ' | '
     
      example:
      '# 1.3.6.1.2.1.25.3.3.1.2.779 | 5 # 1.3.6.1.2.1.25.3.3.1.2.780 | 25 # 1.3.6.1.2.1.25.3.3.1.2.781 | 6 # 1.3.6.1.2.1.25.3.3.1.2.782 | 2 #,2,SLSEARCHALL'
      return:
      1.3.6.1.2.1.25.3.3.1.2.780  1.3.6.1.2.1.25.3.3.1.2.782

=cut

$dict{SLSEARCHALL} = sub {
    my $work1 = shift;

    my $regex  = pop @{ $work1 };
    my $string = pop @{ $work1 };

    my @ret;
    $string =~ s/^#\s*//;
    foreach my $i ( split /\s?\#\s?/, $string )
    {
        next unless ( $i );
        my ( $key, $val ) = split /\s\|\s/, $i;
        if ( $val =~ /$regex/ )
        {
            push @ret, $key;
        }
    }
    return \@ret, 2, 0;
};

=head2 string a SLSEARCHALLI

      return all KEYS from a STRUCTURATED LIST where the STRUCTURATED LIST val match the REGEX a (case insensitive).
      string are the STRUCTURATED list
      the STRUCTURATED LIST use this format:
      each entries are separated by ' # ' and inside each entry , the KEY and the VAL are separated by ' | '
      '# key1 | val1 # key2 | val2 # key12 | VAL12 #,val1,SLSEARCHALLI'
      example:
      '# key1 | val1 # key2 | val2 # key12 | VAL12 #,val1,SLSEARCHALLI'
      return:
      key1  key12

=cut

$dict{SLSEARCHALLI} = sub {
    my $work1 = shift;

    my $regex  = pop @{ $work1 };
    my $string = pop @{ $work1 };

    my @ret;
    $string =~ s/^#\s*//;
    foreach my $i ( split /\s?\#\s?/, $string )
    {
        next unless ( $i );
        my ( $key, $val ) = split /\s\|\s/, $i;
        if ( $val =~ /$regex/i )
        {
            push @ret, $key;
        }
    }
    return \@ret, 2, 0;
};

=head2 string a SLSEARCHALLKEYS

      return all VALUES from a STRUCTURATED LIST where the STRUCTURATED LIST keys match the REGEX a
      string are the STRUCTURATED list
      the STRUCTURATED LIST use this format:
      each entries are separated by ' # ' and inside each entry , the KEY and the VAL are separated by ' | '
      '# 1.3.6.1.2.1.25.3.3.1.2.779 | 1 # 1.3.6.1.2.1.25.3.3.1.2.780 | 5 # 1.3.6.1.2.1.25.3.3.1.2.781 | 6 # 1.3.6.1.2.1.25.3.3.1.2.782 | 2 #' 
      example:
      '# 1.3.6.1.2.1.25.3.3.1.2.779 | 1 # 1.3.6.1.2.1.25.3.3.1.2.780 | 5 # 1.3.6.1.2.1.25.3.3.1.2.781 | 6 # 1.3.6.1.2.1.25.3.3.1.2.782 | 2 #,1.3.6.1.2.1.25.3.3.1.2.,SLSEARCHALLKEYS'
      return:
      1 5 6 2

=cut

$dict{SLSEARCHALLKEYS} = sub {
    my $work1 = shift;

    my $regex  = pop @{ $work1 };
    my $string = pop @{ $work1 };

    my @ret;
    $string =~ s/^#\s*//;
    foreach my $i ( split /\s?\#\s?/, $string )
    {
        next unless ( $i );
        my $match = $1;
        my ( $key, $val ) = split /\s\|\s/, $i;
        if ( $key =~ /$regex/ )
        {
            push @ret, $val;
        }
    }
    return \@ret, 2, 0;
};

=head2 string a SLSEARCHALLKEYSI

      return all VALUES from a STRUCTURATED LIST where the STRUCTURATED LIST key match the REGEX a.
      string are the STRUCTURATED list.
      the STRUCTURATED LIST use this format:
      each entries are separated by ' # ' and inside each entry , the KEY and the VAL are separated by ' | '
      '# tata is not happy | and what? # tata is happy | and??  # toto is not happy | oops # toto is happy | yeah #'
      example:
      '# tata is not happy | and what? # tata is happy | and??  # toto is not happy | oops # toto is happy | yeah #,toto,SLSEARCHALLKEYSI'
      return:
      oops yeah

=cut

$dict{SLSEARCHALLKEYSI} = sub {
    my $work1 = shift;

    my $regex  = pop @{ $work1 };
    my $string = pop @{ $work1 };

    my @ret;
    $string =~ s/^#\s*//;
    foreach my $i ( split /\s?\#\s?/, $string )
    {
        next unless ( $i );
        my $match = $1;
        my ( $key, $val ) = split /\s\|\s/, $i;
        if ( $key =~ /$regex/i )
        {
            push @ret, $val;
        }
    }
    return \@ret, 2, 0;
};

=head2 string a OIDSEARCHALLVAL

      return all OID leaf from a snmpwalk macthing the REGEX a 
      string are the OID walk list
      the OID walk result use this format:
      each snmpwalk entries are separated by ' # ' and inside each entry , the OID and the VAL are separated by ' | ' 
      '# .1.3.6.1.2.1.25.4.2.1.2.4704 | "TASKMGR.EXE" # .1.3.6.1.2.1.25.4.2.1.2.2692 | "winvnc4.exe" # .1.3.6.1.2.1.25.4.2.1.2.3128 | "CSRSS.EXE" #
      example:
      '# .1.3.6.1.2.1.25.4.2.1.2.488 | "termsrv.exe" # .1.3.6.1.2.1.25.4.2.1.2.688 | "Apache.exe" # .1.3.6.1.2.1.25.4.2.1.2.5384 | "aimsserver.exe" # .1.3.6.1.2.1.25.4.2.1.2.2392 | "Apache.exe" # .1.3.6.1.2.1.25.4.2.1.2.2600 | "cpqnimgt.exe" #,Apache\.exe,OIDSEARCHALLVAL'
      return:
      688 2392
        
=cut

$dict{OIDSEARCHALLVAL} = sub {
    my $work1 = shift;

    my $regex  = pop @{ $work1 };
    my $string = pop @{ $work1 };

    my @ret;
    $string =~ s/^#\s*//;
    foreach my $i ( split /\s?\#\s?/, $string )
    {
        next unless ( $i );
        if ( $i =~ /$regex/ )
        {
            my $match = $1;
            my ( $oid, undef ) = split /\s\|\s/, $i;
            $oid =~ /\.(\d+)$/;
            push @ret, $1;
        }
    }
    return \@ret, 2, 0;
};

=head2 string a OIDSEARCHALLVALI

      return all OID leaf from a snmpwalk macthing the REGEX a ( case insensitive ) 
      string are the OID walk list
      the OID walk result use this format:
      each snmpwalk entries are separated by ' # ' and inside each entry , the OID and the VAL are separated by ' | ' 
      '# .1.3.6.1.2.1.25.4.2.1.2.4704 | "TASKMGR.EXE" # .1.3.6.1.2.1.25.4.2.1.2.2692 | "winvnc4.exe" # .1.3.6.1.2.1.25.4.2.1.2.3128 | "CSRSS.EXE" #
      example:
      '# .1.3.6.1.2.1.25.4.2.1.2.488 | "termsrv.exe" # .1.3.6.1.2.1.25.4.2.1.2.688 | "Apache.exe" # .1.3.6.1.2.1.25.4.2.1.2.5384 | "aimsserver.exe" # .1.3.6.1.2.1.25.4.2.1.2.2392 | "Apache.exe" # .1.3.6.1.2.1.25.4.2.1.2.2600 | "cpqnimgt.exe" #,Apache\.exe,OIDSEARCHALLVALI'
      return:
      688 2392
        
=cut

$dict{OIDSEARCHALLVALI} = sub {
    my $work1 = shift;

    my $regex  = pop @{ $work1 };
    my $string = pop @{ $work1 };

    my @ret;
    $string =~ s/^#\s*//;
    foreach my $i ( split /\s?\#\s?/, $string )
    {
        next unless ( $i );
        if ( $i =~ /$regex/i )
        {
            my $match = $1;
            my ( $oid, undef ) = split /\s\|\s/, $i;
            $oid =~ /\.(\d+)$/;
            push @ret, $1;
        }
    }
    return \@ret, 2, 0;
};

=head2 string x x x a OIDSEARCHLEAF

      return all VAL leaf from a snmpwalk when the OID leaf match each REGEX 
      a is the number of leaf to pick from the stack 
      x are all the leaf
      string are the OID walk list
      the OID walk result use this format:
      each snmpwalk entries are separated by ' # ' and inside each entry , the OID and the VAL are separated by ' | ' 
      '# .1.3.6.1.2.1.25.4.2.1.2.4704 | "TASKMGR.EXE" # .1.3.6.1.2.1.25.4.2.1.2.2692 | "winvnc4.exe" # .1.3.6.1.2.1.25.4.2.1.2.3128 | "CSRSS.EXE" # 
      example: 
      '# .1.3.6.1.2.1.25.4.2.1.7.384 | running # .1.3.6.1.2.1.25.4.2.1.7.688 | running # .1.3.6.1.2.1.25.4.2.1.7.2384 | invalid #,688,2384,2,OIDSEARCHLEAF'
      return:
      running invalid
 
=cut

$dict{OIDSEARCHLEAF} = sub {
    my $work1 = shift;

    my $nbr = pop @{ $work1 };
    my @all = splice @{ $work1 }, 1, $nbr;

    my $string = pop @{ $work1 };
    my @ret;
    $string =~ s/^#\s*//;
    foreach my $i ( split /\s?\#\s?/, $string )
    {
        next unless ( $i );
        foreach my $regex ( @all )
        {
            if ( $i =~ /\.$regex\s?\|\s/ )
            {
                my ( undef, $val ) = split /\s\|\s/, $i;
                push @ret, $val;
            }
        }
    }
    return \@ret, 3 + $nbr, 0;
};

=head2 string x x x a OIDSEARCHLEAFI

      return all VAL leaf from a snmpwalk when the OID leaf match each REGEX 
      a ( case insensitive ) is the number of leaf to pick from the stack 
      x are all the leaf
      string are the OID walk list
      the OID walk result use this format:
      each snmpwalk entries are separated by ' # ' and inside each entriy , the OID and the VAL are separated by ' | ' 
      '# .1.3.6.1.2.1.25.4.2.1.2.4704 | "TASKMGR.EXE" # .1.3.6.1.2.1.25.4.2.1.2.2692 | "winvnc4.exe" # .1.3.6.1.2.1.25.4.2.1.2.3128 | "CSRSS.EXE" #' 
      example: 
      '# .1.3.6.1.2.1.25.4.2.1.7.384 | running # .1.3.6.1.2.1.25.4.2.1.7.688 | running # .1.3.6.1.2.1.25.4.2.1.7.2384 | invalid #,688,2384,2,OIDSEARCHLEAFI'
      return:
      running invalid
 
=cut

$dict{OIDSEARCHLEAFI} = sub {
    my $work1 = shift;

    my $nbr = pop @{ $work1 };
    my @all = splice @{ $work1 }, 1, $nbr;

    my $string = pop @{ $work1 };
    my @ret;
    $string =~ s/^#\s*//;
    foreach my $i ( split /\s?\#\s?/, $string )
    {
        next unless ( $i );
        foreach my $regex ( @all )
        {
            if ( $i =~ /\.$regex\s?\|\s/ )
            {
                my ( undef, $val ) = split /\s+\|\s+/, $i;
                push @ret, $val;
            }
        }
    }
    return \@ret, 3 + $nbr, 0;
};

########################
# string operators
########################

=head1 STRING operators

=cut

=head2 a b EQ

      return the result of 'a' EQ 'b'  ( BOOLEAN value )
        
=cut

$dict{EQ} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b eq $a ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b NE

      return the result of 'a' NE 'b'  ( BOOLEAN value )
        
=cut

$dict{NE} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b ne $a ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b LT

      return the result of 'a' LT 'b'  ( BOOLEAN value )
        
=cut

$dict{LT} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b lt $a ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b GT

      return the result of 'a' GT 'b'  ( BOOLEAN value )
        
=cut

$dict{GT} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b gt $a ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b LE

      return the result of 'a' LE 'b'  ( BOOLEAN value )
        
=cut

$dict{LE} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b le $a ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b GE

      return the result of 'a' GE 'b'  ( BOOLEAN value )
        
=cut

$dict{GE} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b ge $a ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b CMP
        WORDS,LEN                                                              = 1584'
#   at t/09DICT.t line 58.
# Looks like you failed 1 test of 31.

      return the result of 'a' CMP 'b'  ( BOOLEAN value )
        
=cut

$dict{CMP} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b cmp $a );
    return \@ret, 2, 0;
};

=head2 a LEN

      return the length of 'a' 
        
=cut

$dict{LEN} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( length $a );
    return \@ret, 1, 0;
};

=head2 a CHOMP

      remove any terminaison line charecter ( CR CR/LF) from 'a' 
        
=cut

$dict{CHOMP} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    chomp $a;
    push @ret, $a ;
    return \@ret, 1, 0;
};

=head2 a b CAT

      return the concatenation 'a' and 'b' 
        
=cut

$dict{CAT} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( "'" . $b . $a . "'" );
    return \@ret, 2, 0;
};

=head2 a b ... n  x CATN

      return the concatenation of the 'x' element from the stack 
        
=cut

$dict{CATN} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
   
    my $ret;
    my @ret;
    for ( 1 .. $a )
    {
    $ret .= pop @{ $work1 };
    }
    push @ret, $ret;
    return \@ret, 1 +$a, 0;
};

=head2 a b CATALL

      return the concatenation all element on the stack 
        
=cut

$dict{CATALL} = sub {
    my $work1 = shift;
    my $dep   = scalar @{ $work1 };
    my $ret;
    for ( 1 .. $dep )
    {
        $ret .= shift @{ $work1 };
    }
    my @ret;
    push @ret, $ret;
    return \@ret, 1 + $dep, 0;
};


=head2 a b x JOIN

      return the concatenation 'a', 'x' and 'b' 
        
=cut

$dict{JOIN} = sub {
    my $work1 = shift;
    my $x     = pop @{ $work1 };
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };  
    my @ret;
    push @ret, ( "'" . $b .$x. $a . "'" );
    return \@ret, 3, 0;
};

=head2 a b ... n  x y JOINN

      return the concatenation of the 'y' element from the stack with 'x' as separator
        
=cut

$dict{JOINN} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $x     = pop @{ $work1 };
    my $ret;
    for ( 1 .. $a-1 )
    {
        $ret .= (pop @{ $work1 }) . $x;
    }
    $ret .= pop @{ $work1 };
    my @ret = ( $ret );
    return \@ret, 2 +$a, 0;
};

=head2 a b x JOINALL

      return the concatenation all element on the stack with 'x' as separator
        
=cut

$dict{JOINALL} = sub {
    my $work1 = shift;
    my $x     = pop @{ $work1 };
    my $dep   = scalar @{ $work1 };
    my $ret;
    for ( 1 .. $dep-1 )
    {
        $ret .= (shift @{ $work1 }) .$x;
    }
    $ret .= pop @{ $work1 };
    my @ret =( $ret );  
    return \@ret, 1 + $dep, 0;
};

=head2 a b REP

      return the result of 'a' x 'b'  duplicate 'a' by the number of 'x' 
        
=cut

$dict{REP} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b x $a );
    return \@ret, 2, 0;
};

=head2 a REV

      return the reverse of 'a'
        
=cut

$dict{REV} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = reverse $a;
    my @ret;
    push @ret, ( $b );
    return \@ret, 1, 0;
};

=head2 a b c SUBSTR

      return the substring of 'c' starting at 'b' with the length of 'a'
        
=cut

$dict{SUBSTR} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $c     = pop @{ $work1 };
    my @ret;
    push @ret, ( substr( $c, $b, $a ) );
    return \@ret, 3, 0;
};

=head2 a UC

      return 'a' in uppercase
        
=cut

$dict{UC} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( uc $a );
    return \@ret, 1, 0;
};

=head2 a LC

      return 'a' in lowercase
        
=cut

$dict{LC} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( lc $a );
    return \@ret, 1, 0;
};

=head2 a UCFIRST

      return 'a' with the first letter in uppercase
        
=cut

$dict{UCFIRST} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( ucfirst $a );
    return \@ret, 1, 0;
};

=head2 a LCFIRST

      return 'a' with the first letter in lowercase
        
=cut

$dict{LCFIRST} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( lcfirst $a );
    return \@ret, 1, 0;
};

=head2 a R1 R2 K V SPLIT2

      split a with the REGEX R1
      each result are splitted with the REGEX R2
      the result are stored in the variable k and v
      
      # .1.3.6.1.2.1.25.3.3.1.2.768 | 48 # .1.3.6.1.2.1.25.3.3.1.2.769 | 38 # .1.3.6.1.2.1.25.3.3.1.2.771 | 42 # .1.3.6.1.2.1.25.3.3.1.2.770 | 58 #,\s?#\s?,\s\|\s,a,b,SPLIT2
      return a with .1.3.6.1.2.1.25.3.3.1.2.768,.1.3.6.1.2.1.25.3.3.1.2.769,.1.3.6.1.2.1.25.3.3.1.2.771,.1.3.6.1.2.1.25.3.3.1.2.770
      and b with 48,38,42,58
 
      !!! becare, if you need to use : as a regex, you need to backslash to prevent overlap with new dictionary entry
      SPLIT return the matched value WITHOUT the empty string of the beginning
        
=cut

$dict{SPLIT2} = sub {
    my $work1 = shift;
    my $v2    = pop @{ $work1 };
    my $v1    = pop @{ $work1 };
    my $r2    = pop @{ $work1 };
    my $r1    = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @T1;
    my @T2;

    foreach my $i ( split /$r1/, $b )
    {
        next unless ( $i );
        my ( $k, $v ) = split /$r2/, $i, 2;
        if ( $k )
        {
            push @T1, $k;
            push @T2, $v;
        }
    }
    $var{ $v1 } = \@T1;
    $var{ $v2 } = \@T2;
    my @ret;
    return \@ret, 5, 0;
};

=head2 a b SPLIT

      return all splitted item of 'a' by the separator 'b' 
      'b' is a REGEX 
      !!! becare, if you need to use : as a regex, you need to backslash to prevent overlap with new dictionary entry
      !!! if the split match on the beginning of string,
      SPLIT return the matched value WITHOUT the empty string of the beginning
        
=cut

$dict{SPLIT} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @r     = grep /[^(^$)]/, split /$a/, $b;
    my @ret;
    push @ret, @r;
    return \@ret, 2, 0;
};

=head2 a b SPLITI

      return all splitted item of 'a' by the separator 'b' 
      'b' is a REGEX case insensitive
      !!! becare, if you need to use : as a regex, you need to backslash to prevent overlap with new dictionary entry
      !!! if the split match on the beginning of string,
      SPLIT return the matched value WITHOUT the empty string of the beginning
      
=cut

$dict{SPLITI} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @r     = grep /[^(^$)]/, split /$a/i, $b;
    my @ret;
    push @ret, @r;
    return \@ret, 2, 0;
};

=head2 a b PAT

      return one or more occurance of 'b' in 'a' 
      'b' is a REGEX
      !!! becare, if you need to use : as a regex, you need to backslash to prevent overlap with new dictionary entry
        
=cut

$dict{PAT} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @r     = ( $b =~ m/\Q$a\E/g );
    my @ret;
    push @ret, @r;
    return \@ret, 2, 0;
};

=head2 a b PATI

      return one or more occurance of 'b' in 'a' 
      'b' is a REGEX case insensitive
      !!! becare, if you need to use : as a regex, you need to backslash to prevent overlap with new dictionary entry
        
=cut

$dict{PATI} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @r     = ( $b =~ m/$a/ig );
    my @ret;
    push @ret, @r;
    return \@ret, 2, 0;
};

=head2 a b TPAT

      test if the pattern 'b' is in 'a' 
      'b' is a REGEX
      !!! becare, if you need to use : as a regex, you need to backslash to prevent overlap with new dictionary entry
        
=cut

$dict{TPAT} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $r     = ( $b =~ m/$a/g );
    my @ret;
    push @ret, ( $r ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b TPATI

      test if the pattern 'b' is in 'a' 
      'b' is a REGEX
      !!! becare, if you need to use : as a regex, you need to backslash to prevent overlap with new dictionary entry
        
=cut

$dict{TPATI} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $r     = ( $b =~ m/$a/ig );
    my @ret;
    push @ret, ( $r ? 1 : 0 );
    return \@ret, 2, 0;
};

=head2 a b c SPAT

      substitute the pattern 'b' by the pattern 'a'  in 'c'
      'b' and 'c' are a REGEX
      !!! becare, if you need to use : as a regex, you need to backslash to prevent overlap with new dictionary entry
        
=cut

$dict{SPAT} = sub {
    my $work1   = shift;
    my $a       = pop @{ $work1 };
    my $b       = pop @{ $work1 };
    my $c       = pop @{ $work1 } || '';
    my $to_eval = qq{\$c =~ s#$b#$a#};
    eval( $to_eval );
    my @ret;
    push @ret, $c;
    return \@ret, 3, 0;
};

=head2 a b c SPATG

      substitute the pattern 'b' by the pattern 'a'  in 'c' as many time as possible (g flag in REGEX)
      'b' and 'c' are a REGEX
      !!! becare, if you need to use : as a regex, you need to backslash to prevent overlap with new dictionary entry
        
=cut

$dict{SPATG} = sub {
    my $work1   = shift;
    my $a       = pop @{ $work1 };
    my $b       = pop @{ $work1 };
    my $c       = pop @{ $work1 };
    my $to_eval = qq{\$c =~ s#$b#$a#g};
    eval( $to_eval );
    my @ret;
    push @ret, $c;
    return \@ret, 3, 0;
};

=head2 a b c SPATI

      substitute the pattern 'b' by the pattern 'a'  in 'c'case insensitive (i flag in REGEX)
      'b' and 'c' are a REGEX
      !!! becare, if you need to use : as a regex, you need to backslash to prevent overlap with new dictionary entry
        
=cut

$dict{SPATI} = sub {
    my $work1   = shift;
    my $a       = pop @{ $work1 };
    my $b       = pop @{ $work1 };
    my $c       = pop @{ $work1 };
    my $to_eval = qq{\$c =~ s#$b#$a#i};
    eval( $to_eval );
    my @ret;
    push @ret, $c;
    return \@ret, 3, 0;
};

=head2 a b c SPATGI

      substitute the pattern 'b' by the pattern 'a'  in 'c' as many time as possible (g flag in REGEX)
      and case insensitive (1 flag in REGEX)
      'b' and 'c' are a REGEX
      !!! becare, if you need to use : as a regex, you need to backslash to prevent overlap with new dictionary entry
        
=cut

$dict{SPATGI} = sub {
    my $work1   = shift;
    my $a       = pop @{ $work1 };
    my $b       = pop @{ $work1 };
    my $c       = pop @{ $work1 };
    my $to_eval = qq{\$c =~ s#$b#$a#ig};
    eval( $to_eval );
    my @ret;
    push @ret, $c;
    return \@ret, 3, 0;
};

=head2 a ... z PRINTF

     use the format 'z' to print the value(s) on the stack
     7,3,/,10,3,/,%d %f,PRINTF -> 2 3.333333
     see printf in perl
        
=cut

$dict{PRINTF} = sub {

    my $work1  = shift;
    my $format = pop @{ $work1 };
    my @r      = ( $format =~ m/(%[^ ])/g );
    my @var;
    for ( 0 .. $#r )
    {
        unshift @var, pop @{ $work1 };
    }
    my @ret;
    push @ret, sprintf $format, @var;
    return \@ret, 2 + $#r, 0;
};

=head2 a b PACK

      pack the value 'a' with the format 'b'

      2004,06,08,a4 a2 a2,PACK 
      result: 20040608

      see pack in perl
        
=cut

$dict{PACK} = sub {
    my $work1  = shift;
    my $format = " " . ( pop( @{ $work1 } ) ) . " ";
    my @r      = ( $format =~ m/([a-zA-Z]\d*\s*)/g );
    my @var;
    for ( 0 .. $#r )
    {
        unshift @var, pop @{ $work1 };
    }
    my @ret;
    push @ret,, pack( $format, @var );
    return \@ret, 2 + $#r, 0;
};

=head2 a b UNPACK

      unpack the value 'a' with the format 'b'

      20040608,a4 a2 a2,UNPACK
      result: 2004,06,08

      see unpack in perl
        
=cut

$dict{UNPACK} = sub {
    my $work1  = shift;
    my $format = pop @{ $work1 };
    my $var    = pop @{ $work1 };
    my @ret;
    push @ret, unpack( $format, $var );
    return \@ret, 2, 0;
};

=head2 a b ISNUM

      test if top of the stack is a number
      return 1 if if it is a NUMBER otherwise return 0
        
=cut

$dict{ISNUM} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ? 1 : 0 );
    return \@ret, 0, 0;
};

=head2 a b ISNUMD

      test if top of the stack is a number
      delete the top element on the statck and return 1 if it is a NUMBER otherwise return 0 
        
=cut

$dict{ISNUMD} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ? 1 : 0 );
    return \@ret, 1, 0;
};

=head2 a b ISINT

      test if top of the stack is a integer (natural number)
      return 1 if if it is a INTEGER otherwise return 0
        
=cut

$dict{ISINT} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a =~ /^\d+$/ ? 1 : 0 );
    return \@ret, 0, 0;
};

=head2 a b ISINTD

      test if top of the stack is a integer (natural number)
      delete the top element on the statck and return 1 if it is a INTEGER otherwise return 0 
        
=cut

$dict{ISINTD} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a =~ /^\d+$/ ? 1 : 0 );
    return \@ret, 1, 0;
};

=head2 a b ISHEX

      test if top of the stack is a hexadecimal value (starting with 0x or 0X or # )
      return 1 if if it is a HEXADECIMAL otherwise return 0
        
=cut

$dict{ISHEX} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a =~ /^(#|0x|0X)(\p{IsXDigit})+$/ ? 1 : 0 );
    return \@ret, 0, 0;
};

=head2 a b ISHEXD

      test if top of the stack is a hexadecimal value (starting with 0x or 0X or # )
      delete the top element on the statck and return 1 if it is a HEXADECIMAL otherwise return 0 
        
=cut

$dict{ISHEXD} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a =~ /^(#|0x|0X)(\p{IsXDigit})+$/ ? 1 : 0 );
    return \@ret, 1, 0;
};

########################
# stack operators
########################

=head1 STACK operators

=cut

=head2  a b SWAP

        return 'b' 'a'

=cut

$dict{SWAP} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, $a, $b;
    return \@ret, 2, 0;
};

=head2  a b OVER

        return 'a' 'b' 'a'

=cut

$dict{OVER} = sub {
    my $work1 = shift;
    my @ret;
    push @ret, @{ $work1 }[-2];
    return \@ret, 0, 0;
};

=head2  a DUP

        return 'a' 'a'

=cut

$dict{DUP} = sub {
    my $work1 = shift;
    my @ret;
    push @ret, @{ $work1 }[-1];
    return \@ret, 0, 0;
};

=head2  a b DDUP

        return 'a' 'b' 'a' 'b'

=cut

$dict{DDUP} = sub {
    my $work1 = shift;
    my @ret;
    push @ret, @{ $work1 }[-2], @{ $work1 }[-1];
    return \@ret, 0, 0;
};

=head2  a b c ROT

        return 'b' 'c' 'a'

=cut

$dict{ROT} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $c     = pop @{ $work1 };
    my @ret;
    push @ret, $b, $a, $c;
    return \@ret, 3, 0;
};

=head2  a b c RROT

        return 'c' 'a' 'b'

=cut

$dict{RROT} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $c     = pop @{ $work1 };
    my @ret;
    push @ret, $a, $c, $b;
    return \@ret, 3, 0;
};

=head2  DEPTH

        return the number of elements on the stack

=cut

$dict{DEPTH} = sub {
    my $work1 = shift;
    my $ret   = scalar @{ $work1 };
    my @ret;
    push @ret, $ret;
    return \@ret, 0, 0;
};

=head2  a b POP

        remove the last element on the stack

=cut

$dict{POP} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    return \@ret, 1, 0;
};

=head2  a ... z POPN

        remove the 'z' last element(s) from the stack

=cut

$dict{POPN} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    for ( 1 .. $a )
    {
        pop @{ $work1 };
    }
    my @ret;
    return \@ret, 1 + $a, 0;
};

=head2  a b c d e n ROLL

        rotate the stack on 'n' element
        a,b,c,d,e,f,4,ROLL -> a b d e f c
        if n = 3 <=> ROT
        if  -2 < n < 2 nothing is done
        if n < -1 ROLL in reverse order
        a,b,c,d,e,f,-4,ROLL -> a b f e d c
        To reveerse a stack content use this:
        a,b,c,d,e,f,DEPTH,+-,ROLL => f e d c b a

=cut

$dict{ROLL} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };

    my @tmp;
    my $b;
    if ( $a > 1 )
    {
        @tmp = splice @{ $work1 }, -( $a - 1 );
        $b = pop @{ $work1 };
    }
    if ( $a < -1 )
    {
        @tmp = reverse( splice @{ $work1 }, ( $a ) );
        $a *= -1;
    }
    my @ret;
    if ( $a < 2 && $a > -2 )
    {
        return \@ret, 1, 0;
    }
    if ( defined $b )
    {
        push @ret, @tmp, $b;
    }
    else
    {
        push @ret, @tmp;
    }
    return \@ret, 1 + $a, 0;
};

=head2 a PICK
        
        copy element from depth 'a' to the stack

=cut

$dict{PICK} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    if ( $a <= scalar @{ $work1 } )
    {
        push @ret, @{ $work1 }[ -( $a ) ];
    }

    return \@ret, 1, 0;
};

=head2 a GET
        
        get (remove) element from depth 'a'
        and put on top of stack 

=cut

$dict{GET} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    my $b;
    if ( $a <= ( scalar @{ $work1 } ) && ( $a > 1 ) )
    {
        my $line = join " | ", @{ $work1 };
        my @tmp = splice @{ $work1 }, -( $a - 1 );
        $line = join " | ", @tmp;
        $b = pop @{ $work1 };
        push @ret, @tmp, $b;
        return \@ret, 1 + $a, 0;
    }
    else
    {
        return \@ret, 1, 0;
    }

};

=head2 a b PUT
        
        put element 'a' at the level 'b' of the stack
        if 'b' greater than the stack put at first place
        if 'b' < 0 start to the reverse order of the stack

=cut

$dict{PUT} = sub {
    my $work1 = shift;
    my $len   = scalar @{ $work1 };
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @tmp;
    my @ret = @{ $work1 };
    if ( $a >= ( scalar( @{ $work1 } ) ) )
    {
        $a = scalar( @{ $work1 } );
    }
    if ( $a )
    {
        @tmp = splice @ret, -( $a - 1 );
    }
    push( @ret, $b, @tmp );
    return \@ret, $len, 0;
};

=head2 a b DEL
        
        delete 'b' element on the stack from level 'a'
        'a' and 'b' is get in absolute value 

=cut

$dict{DEL} = sub {
    my $work1   = shift;
    my $len     = scalar( @{ $work1 } );
    my $start   = abs pop @{ $work1 };
    my $length1 = abs pop @{ $work1 };
    my $length  = ( $length1 + $start + 2 > $len ? $len - $start - 2 : $length1 );
    my @temp;
    @temp = splice @{ $work1 }, $len - 2 - $start - $length, $length;
    my @ret;
    push( @ret, @{ $work1 } );
    return \@ret, $len, 0;
};

=head2 a FIND
        
        get the level of stack containing the exact value 'a'
        if no match, return 0   

=cut

$dict{FIND} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };

    my $nbr = scalar( @{ $work1 } );
    my $ret = 0;
    for ( 1 .. $nbr )
    {
        my $b = @{ $work1 }[ $nbr - $_ ];
        if ( $a =~ /^(\d+|\d+\.\d*|\.\d*)$/ )
        {
            if ( $b == $a )
            {
                $ret = $_;
                last;
            }
        }
        else
        {
            if ( $b eq $a )
            {
                $ret = $_;
                last;
            }
        }
    }
    my @ret;
    push( @ret, $ret );
    return \@ret, 1, 0;
};

=head2 a FINDK
        
        keep the level of stack containing the exact value 'a'
        f no match, return an empty stack
        ( shortcut for a,FIND,KEEP )
        
=cut

$dict{FINDK} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };

    my $nbr = scalar( @{ $work1 } );
    my $ret;
    for ( 1 .. $nbr )
    {
        my $b = @{ $work1 }[ $nbr - $_ ];
        if ( $a =~ /^(\d+|\d+\.\d*|\.\d*)$/ )
        {
            if ( $b == $a )
            {
                $ret = $a;
                last;
            }
        }
        else
        {
            if ( $b eq $a )
            {
                $ret = $a;
                last;
            }
        }
    }
    my @ret;
    push( @ret, $ret );
    return \@ret, $nbr + 1, 0;
};

=head2 a SEARCH
        
        get the first level of stack containing the REGEX 'a'

=cut

$dict{SEARCH} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $ret   = 1;
    my $nbr   = scalar( @{ $work1 } );
    my @ret;
    for ( my $i = $nbr ; $i ; $i-- )
    {
        my $b = @{ $work1 }[ $nbr - $i ];
        if ( $b =~ /$a/ )
        {
            $ret = $i;
            push( @ret, $ret );
            return \@ret, 1, 0;
        }
    }
    push( @ret, 0 );
    return \@ret, 1, 0;
};

=head2 a SEARCHI
        
        get the first level of stack containing the REGEX 'a' (cas insensitive)

=cut

$dict{SEARCHI} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $ret   = 1;
    my $nbr   = scalar( @{ $work1 } );
    my @ret;
    for ( my $i = $nbr ; $i ; $i-- )
    {
        my $b = @{ $work1 }[ $nbr - $i ];
        if ( $b =~ /$a/i )
        {
            $ret = $i;
            push( @ret, $ret );
            return \@ret, 1, 0;
        }
    }
    push( @ret, 0 );
    return \@ret, 1, 0;
};

=head2 a SEARCHIA

        get all level of stack containing the REGEX 'a' (cas insensitive)
        empty the stack and return all the index of item matching

=cut

$dict{SEARCHIA} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $ret;
    my $nbr = scalar( @{ $work1 } );
    my @ret;
    for ( my $i = $nbr ; $i ; $i-- )
    {
        my $b = @{ $work1 }[ $nbr - $i ];
        if ( $b =~ /$a/i )
        {
            $ret++;
            push @ret, $i;
        }
    }
    return \@ret, 1 + $nbr, 0;
};

=head2 a SEARCHA

        get all level of stack containing the REGEX 'a' (cas sensitive)
        empty the stack and return all the index of item matching

        toto,toti,titi,tata,tota,tito,tutot,truc,tot,SEARCHA
        result: 8 7 4 2

=cut

$dict{SEARCHA} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $ret;
    my $nbr = scalar( @{ $work1 } );
    my @ret;
    for ( my $i = $nbr ; $i ; $i-- )
    {
        my $b = @{ $work1 }[ $nbr - $i ];
        if ( $b =~ /$a/ )
        {
            $ret++;
            push @ret, $i;
        }
    }
    return \@ret, 1 + $nbr, 0;
};

=head2 a SEARCHK
        
        keep all level of stack containing the REGEX 'a' (cas sensitive)

        toto,toti,titi,tata,tota,tito,tutot,truc,tot,SEARCHK
        result: toto toti tota tutot

=cut

$dict{SEARCHK} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $ret   = 1;
    my $nbr   = scalar( @{ $work1 } );
    my @ret;
    for ( my $i = $nbr ; $i ; $i-- )
    {
        my $b = @{ $work1 }[ $nbr - $i ];
        if ( $b =~ /$a/ )
        {
            $ret = $i;
            push @ret, $b;
        }
    }
    return \@ret, $nbr + 1, 0;
};

=head2 a SEARCHIK
        
        keep all level of stack containing the REGEX 'a' (cas insensitive)

=cut

$dict{SEARCHIK} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $ret   = 1;
    my $nbr   = scalar( @{ $work1 } );
    my @ret;
    for ( my $i = $nbr ; $i ; $i-- )
    {
        my $b = @{ $work1 }[ $nbr - $i ];
        if ( $b =~ /$a/i )
        {
            $ret = $i;
            push @ret, $b;
        }
    }
    return \@ret, $nbr + 1, 0;
};

=head2 a KEEP
        
        delete all element on the stack except the level 'a'
        if 'a' is deeper then stack, keep the stack untouched
        
=cut

$dict{KEEP} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    if ( $a <= 0 )
    {
        return \@ret, 1 + ( scalar @{ $work1 } );
    }
    if ( $a < ( ( scalar @{ $work1 } ) + 1 ) )
    {
        push @ret, @{ $work1 }[ -( $a ) ];
        return \@ret, 1 + ( scalar @{ $work1 } ), 0;
    }
    else
    {
        return \@ret, 1, 0;
    }
};

=head2 a KEEPV
                
        delete all element on the stack except the levels with indice in the var A

        1,5,2,3,A,!!,a,b,c,d,e,f,g,i,A,KEEPV
        result: i d g
                
=cut

$dict{KEEPV} = sub {
    my $work1 = shift;
    my $name  = pop @{ $work1 };
    my @ret;

    if ( exists $var{ $name } )
    {
        if ( ref $var{ $name } eq 'ARRAY' )
        {
            foreach my $ind ( @{ $var{ $name } } )
            {
                push @ret, @{ $work1 }[ -$ind ] if ( defined @{ $work1 }[ -$ind ] );
            }
        }
        else
        {
            push @ret, @{ $work1 }[ -$var{ $name } ] if ( defined @{ $work1 }[ -$var{ $name } ] );
        }
    }
    return \@ret, scalar( @{ $work1 } ) + 1, 0;
};

=head2 a KEEPVV
        
        keep element from array B with indice from ARRAY A  

        1,5,2,3,A,!!,a,b,c,d,e,f,g,i,8,B,!!,B,A,KEEPVV
        result: i d g
        
=cut

$dict{KEEPVV} = sub {
    my $work1 = shift;
    my $name1 = pop @{ $work1 };
    my $name2 = pop @{ $work1 };
    my @ret;
    my @tmp;

    if ( exists $var{ $name1 } && exists $var{ $name2 } )
    {
        if ( ref $var{ $name2 } eq 'ARRAY' )
        {
            @tmp = @{ $var{ $name2 } };
        }
        else
        {
            @tmp = $var{ $name2 };
        }
        if ( ref $var{ $name1 } eq 'ARRAY' )
        {
            foreach my $ind ( @{ $var{ $name1 } } )
            {
                push @ret, $tmp[ -$ind ] if ( defined $tmp[ -$ind ] );
            }
        }
        else
        {
            push @ret, $tmp[ -$var{ $name1 } ] if ( defined $tmp[ -$var{ $name1 } ] );
        }
    }
    return \@ret, 2, 0;
};

=head2 b a KEEPN
        
        keep 'b' element on the stack from level 'a'
        and delete all other element
        'a' and 'b' is get in absolute value 

        a,b,c,d,e,f,g,h,4,3,KEEPN
        result: c d e f

=cut

$dict{KEEPN} = sub {
    my $work1   = shift;
    my $len     = scalar( @{ $work1 } );
    my $start   = abs pop @{ $work1 };
    my $length1 = abs pop @{ $work1 };
    my $length  = ( $length1 + $start + 2 > $len ? $len - $start - 1 : $length1 );
    my @ret     = splice @{ $work1 }, $len - 1 - $start - $length, $length;
    return \@ret, $len, 0;
};

=head2 b a KEEPR
        
        delete all elements on the stack except the level 'a' and keep all element deeper than 'b'
        if 'a' is deeper then stack, keep the stack untouched

        a,b,c,d,e,f,g,h,6,3,KEEPR
        result: a b f

=cut

$dict{KEEPR} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @tmp   = splice @{ $work1 }, scalar( @{ $work1 } ) - $b;

    my @ret;
    if ( $a <= 0 )
    {
        return \@ret, 1 + ( scalar @tmp );
    }
    if ( $a < ( ( scalar @tmp ) + 1 ) )
    {
        push @ret, @tmp[ -( $a ) ];
        return \@ret, 2 + ( scalar @tmp ), 0;
    }
    else
    {
        return \@ret, 2, 0;
    }
};

=head2 c b a KEEPRN
        
        keep 'b' element on the stack from level 'a' and keep all element deeper than 'c'
        if 'a' is deeper then stack, keep the stack untouched

        a,b,c,d,e,f,g,h,i,j,7,3,2,KEEPRN
        result: a b c g h i

=cut

$dict{KEEPRN} = sub {
    my $work1 = shift;

    my $start = abs pop @{ $work1 };
    my @ret;
    unless ( $start )
    {
        return \@ret, +3, 0;
    }
    my $length1 = abs pop @{ $work1 };
    my $deepth  = abs pop @{ $work1 };
    my @tmp     = splice @{ $work1 }, scalar( @{ $work1 } ) - $deepth;
    my $len     = scalar( @tmp );
    my @t       = reverse @tmp;
    @ret = reverse splice @t, $start - 1, $length1;
    return \@ret, $len + 3, 0;
};

=head2 a b PRESERVE
        
        keep  element on the stack from level 'a'
        to level 'b'
        and delete all other element
        'a' and 'b' is get in absolute value 
        if 'a' > 'b'  keep the reverse of selection (boustrophedon)

=cut

$dict{PRESERVE} = sub {
    my $work1 = shift;
    my $len   = scalar( @{ $work1 } );
    my $start = ( abs pop @{ $work1 } );
    my $end   = ( abs pop @{ $work1 } );
    my $len1  = scalar( @{ $work1 } );
    my @temp;
    if ( $start <= $end )
    {
        @temp = @{ $work1 }[ ( $len1 - $end ) .. ( $len1 - $start ) ];
    }
    else
    {
        push @temp, @{ $work1 }[ ( $start - 1 ) .. ( $#$work1 ) ];
        push @temp, @{ $work1 }[ 0 .. ( $end - 1 ) ];
    }
    return \@temp, $len, 0;
};

=head2 a b COPY
        
        copy  element on the stack from level 'a'
        to level 'b'
        'a' and 'b' is get in absolute value 
        if 'a' > 'b'  keep the reverse of selection (boustrophedon)

=cut

$dict{COPY} = sub {
    my $work1 = shift;
    my $len   = scalar( @{ $work1 } );
    my $start = ( abs pop @{ $work1 } );
    my $end   = ( abs pop @{ $work1 } );
    my $len1  = scalar( @{ $work1 } );
    my @temp;
    if ( $start <= $end )
    {
        @temp = @{ $work1 }[ ( $len1 - $end ) .. ( $len1 - $start ) ];
    }
    else
    {
        push @temp, @{ $work1 }[ ( $len1 - $end ) .. ( $#$work1 ) ];
        push @temp, @{ $work1 }[ ( 0 ) .. ( $len1 - $start ) ];
    }
    return \@temp, 2, 0;
};

########################
# DICT operator
########################

=head1 DICTIONARY and VARS operators

=cut

=head2 WORDS

        return as one stack element the list of WORD in DICT separated by a |
        
=cut

$dict{WORDS} = sub {
    my @tmp = join " | ", sort keys( %dict );
    my @ret;
    push @ret, @tmp;
    return \@ret, 0, 0;
};

=head2 VARS

        return as one stack element the list of VARS  separated by a |
        
=cut

$dict{VARS} = sub {
    my @tmp = join " | ", sort keys( %var );
    my @ret;
    push @ret, @tmp;
    return \@ret, 0, 0;
};

=head2 v SIZE

        return the size of the variable on the stack
        
=cut

$dict{SIZE} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $ret   = 0;
    if ( exists $var{ $a } )
    {
        if ( ( ref( $var{ $a } ) eq 'ARRAY' ) )
        {
            $ret = scalar( @{ $var{ $a } } );
        }
        else
        {
            $ret = 1;
        }
    }
    my @ret;
    push @ret, $ret;
    return \@ret, 1, 0;
};

=head2 v POPV

        remove return the first item of the variable on the stack
        
=cut

$dict{POPV} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $ret   = 0;
    if ( exists $var{ $a } )
    {
        if ( ( ref( $var{ $a } ) eq 'ARRAY' ) )
        {
            $ret = pop( @{ $var{ $a } } );
        }
        else
        {
            $ret = $var{ $a };
            $var{ $a } = '';
        }
    }
    my @ret;
    push @ret, $ret;
    return \@ret, 1, 0;
};

=head2 v SHIFTV

        remove return the latest item of the variable on the stack
        
=cut

$dict{SHIFTV} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $ret   = 0;
    if ( exists $var{ $a } )
    {
        if ( ( ref( $var{ $a } ) eq 'ARRAY' ) )
        {
            $ret = shift( @{ $var{ $a } } );
        }
        else
        {
            $ret = $var{ $a };
            $var{ $a } = '';
        }
    }
    my @ret;
    push @ret, $ret;
    return \@ret, 1, 0;
};

=head2 v a IND

       return the element of the variable at the indice a  ( ARRAY emulation )
        
=cut

$dict{IND} = sub {
    my $work1 = shift;
    my $ind   = pop @{ $work1 };
    my $name  = pop @{ $work1 };
    my $ret   = 0;

    if ( exists $var{ $name } )
    {
        if ( ( ref( $var{ $name } ) eq 'ARRAY' ) )
        {
            my $size = scalar @{ $var{ $name } };
            $ret = $var{ $name }->[ $size - $ind ];
        }
        else
        {
            $ret = $var{ $name };
        }
    }
    my @ret;
    push @ret, $ret;
    return \@ret, 2, 0;
};

=head2 v INC

        incremente (+ 1) the value of the variable on the statck
        
=cut

$dict{INC} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    if ( ( !ref( $var{ $a } ) ) && $var{ $a } =~ /\d+/ )
    {
        ( $var{ $a } )++;
    }
    my @ret;
    return \@ret, 1, 0;
};

=head2 v DEC

        decremente (- 1) the value of the variable on the statck
        
=cut

$dict{DEC} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    if ( ( !ref( $var{ $a } ) ) && $var{ $a } =~ /\d+/ )
    {
        ( $var{ $a } )--;
    }
    my @ret;
    return \@ret, 1, 0;
};

=head2 VARIABLE xxx

       declare the variable 'xxx' (reserve memory)
        
=cut

$dict{VARIABLE} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    if ( $a )
    {
        $var{ $a } = '';
        return \@ret, 1, 0;
    }
    return \@ret, 0, 0;
};

=head2 v UNSET 

       delete the variable v 
        
=cut

$dict{UNSET} = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 }; 
    my @ret;
    delete $var{$a} if exists  $var{$a};
    return \@ret, 1, 0;
};

=head2 xx var !

        set and delete from the stack the value xx to the variable 'var'
        
=cut

$dict{'!'} = sub {
    my $work1 = shift;
    my $name  = pop @{ $work1 };
    my $val   = pop @{ $work1 };
    $var{ $name } = $val;
    my @ret;
    return \@ret, 2, 0;
};

=head2 xx var !A

        append to the variable and delete from the stack the value xx to the variable 'var'
        
=cut

$dict{'!A'} = sub {
    my $work1 = shift;
    my $name  = pop @{ $work1 };
    my $val   = pop @{ $work1 };
    my @ret;
    my @TMP;
    if ( exists $var{ $name } )
    {
        if ( ref $var{ $name } eq 'ARRAY' )
        {
            unshift @TMP, $val, @{ $var{ $name } };
        }
        else
        {
            unshift @TMP, $val, $var{ $name };
        }
        $var{ $name } = \@TMP;
    }
    else
    {
        $var{ $name } = $val;
    }
    return \@ret, 2, 0;
};

=head2 x1 x2 x3 ... n var !!
        
        put and delete from the stack 'n' element(s) from the stack in the variable 'var'
        'n' is in absolute value 

=cut

$dict{'!!'} = sub {

    my $work1     = shift;
    my $len       = scalar( @{ $work1 } );
    my $name      = pop @{ $work1 };
    my $len_to_rm = ( abs pop @{ $work1 } );
    my @temp;
    my $from = ( 1 + ( $#$work1 ) - $len_to_rm );
    $from = $from < 0 ? 0 : $from;
    my @TMP = @{ $work1 }[ $from .. ( $#$work1 ) ];
    $var{ $name } = \@TMP;
    return \@temp, $len_to_rm + 2, 0;
};

=head2 x1 x2 x3 ... n var !!A
        
        append and delete 'n' element(s) from the stack in the variable 'var'
        'n' is in absolute value 

=cut

$dict{'!!A'} = sub {

    my $work1     = shift;
    my $len       = scalar( @{ $work1 } );
    my $name      = pop @{ $work1 };
    my $len_to_rm = ( abs pop @{ $work1 } );
    my @temp;
    my $from = ( 1 + ( $#$work1 ) - $len_to_rm );
    $from = $from < 0 ? 0 : $from;
    my @TMP = @{ $work1 }[ $from .. ( $#$work1 ) ];
    if ( exists $var{ $name } )
    {

        if ( ref $var{ $name } eq 'ARRAY' )
        {
            unshift @TMP, @{ $var{ $name } };
        }
        else
        {
            unshift @TMP, $var{ $name };
        }
        $var{ $name } = \@TMP;
    }
    else
    {
        $var{ $name } = \@TMP;
    }
    return \@temp, $len_to_rm + 2, 0;
};

=head2 x1 x2 x3 ... n var !!C
        
        copy 'n' element(s) from the stack in the variable 'var'
        'n' is in absolute value 

=cut

$dict{'!!C'} = sub {

    my $work1     = shift;
    my $len       = scalar( @{ $work1 } );
    my $name      = pop @{ $work1 };
    my $len_to_rm = ( abs pop @{ $work1 } );
    my @temp;
    my $from = ( 1 + ( $#$work1 ) - $len_to_rm );
    $from = $from < 0 ? 0 : $from;
    my @TMP = @{ $work1 }[ $from .. ( $#$work1 ) ];
    $var{ $name } = \@TMP;
    return \@temp, 2, 0;
};

=head2 x1 x2 x3 ... n var !!CA
        
        append  'n' element(s) from the stack in the variable 'var'
        'n' is in absolute value 

=cut

$dict{'!!CA'} = sub {

    my $work1     = shift;
    my $len       = scalar( @{ $work1 } );
    my $name      = pop @{ $work1 };
    my $len_to_rm = ( abs pop @{ $work1 } );
    my @temp;
    my $from = ( 1 + ( $#$work1 ) - $len_to_rm );
    $from = $from < 0 ? 0 : $from;
    my @TMP = @{ $work1 }[ $from .. ( $#$work1 ) ];
    if ( exists $var{ $name } )
    {

        if ( ref $var{ $name } eq 'ARRAY' )
        {
            unshift @TMP, @{ $var{ $name } };
        }
        else
        {
            unshift @TMP, $var{ $name };
        }
        $var{ $name } = \@TMP;
    }
    else
    {
        $var{ $name } = \@TMP;
    }
    return \@temp, 2, 0;
};

=head2 x1 x2 x3 ... b a var !!!
        
        put and delete ' element(s) from the stack in the variable 'var'
        starting at element  'a' to element 'b'
        'a' and 'b' in absolute value 
        if 'a' > 'b'  keep the reverse of selection (boustrophedon)

=cut

$dict{'!!!'} = sub {
    my $work1 = shift;
    my $len   = scalar( @{ $work1 } );
    my $name  = pop @{ $work1 };
    my $start = ( abs pop @{ $work1 } );
    my $end   = ( abs pop @{ $work1 } );
    my $len1  = scalar( @{ $work1 } );
    my @temp;
    my @TMP;

    if ( $start <= $end )
    {
        @TMP = @{ $work1 }[ ( $len1 - $end ) .. ( $len1 - $start ) ];
        push @temp, @{ $work1 }[ 0 .. ( $len1 - $end - 1 ) ];
        push @temp, @{ $work1 }[ ( $len1 - $start + 1 ) .. ( $#$work1 ) ];
    }
    else
    {
        push @TMP, @{ $work1 }[ ( $len1 - $end ) .. ( $#$work1 ) ];
        push @TMP, @{ $work1 }[ ( 0 ) .. ( $len1 - $start ) ];
        @temp = @{ $work1 }[ ( $len1 - $start + 1 ) .. ( $len1 - $end - 1 ) ];
    }
    $var{ $name } = \@TMP;
    return \@temp, $len, 0;
};

=head2 x1 x2 x3 ... b a var !!!A
        
        append and delete ' element(s) from the stack in the variable 'var'
        starting at element  'a' to element 'b'
        'a' and 'b' in absolute value 
        if 'a' > 'b'  keep the reverse of selection (boustrophedon)

=cut

$dict{'!!!A'} = sub {
    my $work1 = shift;
    my $len   = scalar( @{ $work1 } );
    my $name  = pop @{ $work1 };
    my $start = ( abs pop @{ $work1 } );
    my $end   = ( abs pop @{ $work1 } );
    my $len1  = scalar( @{ $work1 } );
    my @temp;
    my @TMP;

    if ( $start <= $end )
    {
        @TMP = @{ $work1 }[ ( $len1 - $end ) .. ( $len1 - $start ) ];
        push @temp, @{ $work1 }[ 0 .. ( $len1 - $end - 1 ) ];
        push @temp, @{ $work1 }[ ( $len1 - $start + 1 ) .. ( $#$work1 ) ];
    }
    else
    {
        push @TMP, @{ $work1 }[ ( $len1 - $end ) .. ( $#$work1 ) ];
        push @TMP, @{ $work1 }[ ( 0 ) .. ( $len1 - $start ) ];
        @temp = @{ $work1 }[ ( $len1 - $start + 1 ) .. ( $len1 - $end - 1 ) ];
    }
    if ( exists $var{ $name } )
    {
        if ( ref $var{ $name } eq 'ARRAY' )
        {
            unshift @TMP, @{ $var{ $name } };
        }
        else
        {
            unshift @TMP, $var{ $name };
        }
        $var{ $name } = \@TMP;
    }
    else
    {
        $var{ $name } = \@TMP;
    }
    return \@temp, $len, 0;
};

=head2 x1 x2 x3 ... b a var !!!C
        
        copy element(s) on the stack in the variable 'var'
        starting at element  'a' to element 'b' 
        'a' and 'b' in absolute value 
        if 'a' > 'b'  keep the reverse of selection (boustrophedon)

=cut

$dict{'!!!C'} = sub {

    my $work1     = shift;
    my $len       = scalar( @{ $work1 } );
    my $name      = pop @{ $work1 };
    my $start     = ( abs pop @{ $work1 } );
    my $end       = ( abs pop @{ $work1 } );
    my $len1      = scalar( @{ $work1 } );
    my $len_to_rm = abs( $start - $end );
    my @temp;
    my @TMP;

    if ( $start <= $end )
    {
        @TMP = @{ $work1 }[ ( $len1 - $end ) .. ( $len1 - $start ) ];
    }
    else
    {
        push @TMP, @{ $work1 }[ ( $len1 - $end ) .. ( $#$work1 ) ];
        push @TMP, @{ $work1 }[ ( 0 ) .. ( $len1 - $start ) ];
    }
    $var{ $name } = \@TMP;
    return \@temp, 3, 0;
};

=head2 x1 x2 x3 ... b a var !!!CA
        
        append element(s) on the stack in the variable 'var'
        starting at element  'a' to element 'b' 
        'a' and 'b' in absolute value 
        if 'a' > 'b'  keep the reverse of selection (boustrophedon)

=cut

$dict{'!!!CA'} = sub {

    my $work1     = shift;
    my $len       = scalar( @{ $work1 } );
    my $name      = pop @{ $work1 };
    my $start     = ( abs pop @{ $work1 } );
    my $end       = ( abs pop @{ $work1 } );
    my $len1      = scalar( @{ $work1 } );
    my $len_to_rm = abs( $start - $end );
    my @temp;
    my @TMP;

    if ( $start <= $end )
    {
        @TMP = @{ $work1 }[ ( $len1 - $end ) .. ( $len1 - $start ) ];
    }
    else
    {
        push @TMP, @{ $work1 }[ ( $len1 - $end ) .. ( $#$work1 ) ];
        push @TMP, @{ $work1 }[ ( 0 ) .. ( $len1 - $start ) ];
    }
    if ( exists $var{ $name } )
    {
        if ( ref $var{ $name } eq 'ARRAY' )
        {
            unshift @TMP, @{ $var{ $name } };
        }
        else
        {
            unshift @TMP, $var{ $name };
        }
        $var{ $name } = \@TMP;
    }
    else
    {
        $var{ $name } = \@TMP;
    }
    return \@temp, 3, 0;
};


=head2  var @

        return the value of the variable 'var'
        
=cut

$dict{'@'} = sub {
    my $work1 = shift;
    my $name  = pop @{ $work1 };
    my @ret;
    if ( ref( $var{ $name } ) =~ /ARRAY/i )
    {
        push @ret, @{ $var{ $name } };
    }
    else
    {
        push @ret, $var{ $name };
    }
    return \@ret, 1, 0;
};

=head2 : xxx  name1 ;

        create a new entry in the dictionary whith name name1 and store the progam xxx
        
=cut

$dict{';'} = sub {
    my $work1   = shift;
    my $return1 = shift;
    my $len     = scalar( @{ $work1 } );
    my $b_ref   = pop @{ $return1 };
    my $a_ref   = pop @{ $return1 };
    my @pre     = @{ $work1 };
    my @BLOCK   = splice @pre, $a_ref, $b_ref - $a_ref;
    my @ret;
    pop @pre;
    my $name = pop @BLOCK;
    unless ( exists  $dict{ $name } )
    {
    $pub_dict{ $name } = 1;
    $dict{ $name } = sub {
        my $ret;
        @ret = @BLOCK;
        return \@ret, 0, 0;
    };
    return \@ret, $#BLOCK + 2, 2;
    }
    return \@ret, $#BLOCK + 2, 0;
};

=head2 name1 FORGOT

        delete/erase a create word (name1 )
        
=cut

$dict{FORGOT} = sub {
    my $work1 = shift;
    my $name  = pop @{ $work1 };
    my @ret;
    if ( exists $pub_dict{$name} )
    {
    delete $pub_dict{$name} ;
    delete $dict{$name} ;
    }
     return \@ret, 1, 0;
     };

=head2 : xxx yyy name1 PERL

        execute the PERL code
        with parameter(s) xxx yyy
        !!! be care if the perl code need to use a coma (,) 
        you need to enclose the line inside double quote
        if you need double quote in code use qq{ ... }
        
=cut

$dict{PERL} = sub {
    my $work1   = shift;
    my $return1 = shift;

    my $b_ref      = pop @{ $return1 };
    my $a_ref      = pop @{ $return1 } // 0;
    my @in         = @{ $work1 };
    my @pre        = splice @in, 0, $a_ref;
    my @tmp        = ( @pre, @in );
    my $len_before = scalar( @tmp );
    my $len_after = scalar( @tmp );
    my $delta     = $len_before - $len_after;
    my @BLOCK     = splice( @tmp, -$delta, $len_before - $delta );
    my $name      = join ";", @BLOCK;

    my $not_stdout;
    open($not_stdout,'>', \my $buf ); 
    select($not_stdout);
    eval $name;
    if ( $@ )
    {
        chomp $@;
        $DEBUG = $@;
    }
    select(STDOUT);
    close $not_stdout;
    my @ret = @pre;
    push @ret,  $buf;
    return \@ret, scalar @BLOCK + $delta, 2;
};

=head2 : xxx name1 PERLFUNC

        execute the PERL function name1 with the parameter xxx
        the default name space is "main::"
        It is possible tu use a specific name space
        the parameter are "stringified"
        e.g. ':,5,filename,save,PERLFUNC'
        call the function save("filename", 5);
        
=cut

$dict{PERLFUNC} = sub {
    my $work1   = shift;
    my $return1 = shift;

    my $b_ref = pop @{ $return1 };
    my $a_ref = pop @{ $return1 };
    my @pre   = @{ $work1 };
    my @BLOCK = splice @pre, $a_ref, $b_ref - $a_ref;
    my @tmp   = ( @pre, @BLOCK );
    pop @tmp;
    my $name       = pop @BLOCK;
    my $len_before = scalar( @BLOCK );
    process( \@BLOCK );
    foreach my $item ( @BLOCK )
    {
        if ( $item =~ /^(\d+|^\$\w+)$/ )
        {
            next;
        }
        $item =~ s/^(.*)$/"$1"/;
    }
    my $len_after = scalar( @BLOCK );
    my $delta     = $len_before - $len_after;
    my $arg       = join ',', reverse @BLOCK;
    my $todo;
    if ( $name !~ /::[^:]*$/ )
    {
        $todo = "main::" . $name . '(' . $arg . ');';
    }
    else
    {
        my $before = $`;
        eval "require  $before";
        $todo = $name . '(' . $arg . ');';
    }
    my @ret = eval( $todo );
    if ( $@ )
    {
        chomp $@;
        $DEBUG = $@;
        @ret   = ();
    }
    return \@ret, scalar( @BLOCK ) + $delta + 1, 2;
};

=head2  name1 PERLFUNC0

        execute the PERL function name1 with no parameters 
        the default name space is "main::"
        It is possible tu use a specific name space
        the parameter are "stringified"
        !!! because this function don't know the namescape of the caller 
        !!! the parameter for the function must be scalar 
        !!! and not a perl variable or a ref to a perl compenent 
        !!! see PERLVAR
        e.g. 'Test2,PERLFUNC0'
        call the function Test2();
        
=cut

$dict{PERLFUNC0} = sub {
    my $work1   = shift;
    my $name    = pop @{ $work1 };

    my $todo;
    my $ref_var = peek_my( 3 );

    if ( $name !~ /::[^:]*$/ )
    {
        $todo = "main::" . $name . ';';
    }
    else
    {
        my $before = $`;
        eval "require  $before";
        $todo = $name . ';';
    }

    my @ret = eval( $todo );
    if ( $@ )
    {
        chomp $@;
        $DEBUG = $@;
        @ret   = ();
    }
    return \@ret, 1 , 0;
};

=head2  xxx nbr name1 PERLFUNCX

        execute the PERL function name1 with nbr parameters from the stack xxx
        the default name space is "main::"
        It is possible tu use a specific name space
        the parameter are "stringified"
        !!! because this function don't know the namescape of the caller 
        !!! the parameter for the function must be scalar 
        !!! and not a perl variable or a ref to a perl compenent 
        !!! see PERLVAR
        e.g. 'file,name,2,substit,PERLFUNCX'
        call the function substit("name", "file");
        
=cut

$dict{PERLFUNCX} = sub {
    my $work1   = shift;
    my $name    = pop @{ $work1 };
    my $nbr_arg = pop @{ $work1 };
    my $arg = '';
    my $todo;
    my $ref_var = peek_my( 3 );
    for ( 1 .. $nbr_arg )
    {
        my $new = pop @{ $work1 };
        if ( $new =~ /^[\\$%@]/ )
        {
            $arg = $arg . ',' . $new;
        }
        else
        {
            $arg = $arg . ',"' . $new . '"';
        }
    }
    if ( $arg )
    {
        $arg =~ s/^,//;
    }
    if ( $name !~ /::[^:]*$/ )
    {
        $todo = "main::" . $name . '(' . $arg . ');';
    }
    else
    {
        my $before = $`;
        eval "require  $before";
        $todo = $name . '(' . $arg . ');';
    }

    my @ret = eval( $todo );
    if ( $@ )
    {
        chomp $@;
        $DEBUG = $@;
        @ret   = ();
    }
    return \@ret, $nbr_arg + 2, 0;
};

=head2  xxx name1 PERLFUNC1

        execute the PERL function name1 with the only one parameter xxx
        the default name space is "main::"
        It is possible tu use a specific name space
        the parameter are "stringified"
        e.g. 'file,name,CAT,substit,PERLFUNC1'
        call the function substit("filename");
        
=cut

$dict{PERLFUNC1} = sub {
    my $work1 = shift;
    my $name  = pop @{ $work1 };
    my $arg   = pop @{ $work1 };
    my $todo;
    if ( $name !~ /::[^:]*$/ )
    {
        $todo = "main::" . $name . '("' . $arg . '");';
    }
    else
    {
        my $before = $`;
        eval "require  $before";
        $todo = $name . '("' . $arg . '");';
    }
    my @ret = eval( $todo );
    if ( $@ )
    {
        chomp $@;
        $DEBUG = $@;
        @ret   = ();
    }
    return \@ret, 2, 0;

};

=head2  xxx nbr name1 PERLVAR

        Return the perl variable.
        If the var returned is an array, return each element of the array on the stack
        If the var returned is a hash , return a STRUCTURATED LIST
        the default name space is "main::"
        It is possible tu use a specific name space
        the parameter are "stringified"
        e.g.1 '{$data},PERLVAR'
        call the value of $data;
        e.g.2 '{%S}->{extra},PERLVAR'
        call the value of $S->{extra};
        
=cut

$dict{PERLVAR} = sub {
    my $work1 = shift;
    my $name  = pop @{ $work1 };
    my $name1 = pop @{ $work1 };
    $name =~ /^\{([^}]*)\}/;
    my $base_name = $1;
    my @ret;
    use PadWalker qw(peek_my);
    my $level = 0 ;
    my $ref_var;
    while ( ! exists  $ref_var->{$base_name} )
    {
        eval { $ref_var= peek_my( $level++ ) };
        if ( $@ )
        { 
            return \@ret, 1, 0;
        }
    }

    my @all     = split /->/, $name;
    my $res     = __deref__( $ref_var, \@all );
    my ($tmp ,undef )= __to_sl__($res,0);
    $tmp =~ s/#\s+$/\#/;
    $tmp =~ s/^\s+#/\#/;
    push @ret, $tmp;
    
    return \@ret, 1, 0;

};

sub __to_sl__
{
    my $ref = shift;
    my $dep = shift;

    my $res;
    if ( ref $ref eq 'HASH' )
    {
        $dep++;
        $res .= '#' x $dep . ' ';
        foreach my $key ( keys %$ref )
        {
            $res .= $key . ' ' . '|' x $dep . ' ';
            my ( $r, $dep ) = __to_sl__( $ref->{ $key }, $dep );
            $res .= $r . ' ' . '#' x $dep . ' ';
        }
    }
    elsif ( ref $ref eq 'ARRAY' )
    { 
        $dep++;
        foreach my $val ( @$ref )
        {
            my ( $r, $dep ) = __to_sl__( $val, $dep );
            $res .= ' ' . '#' x $dep . ' ' . $r;
        }
        $res .= ' ' . '#' x $dep . ' ';
    }
    else
    {
        $res = $ref;
    }
   
    $res =~ s/\s+##\s+##/ ## #/g;
    return $res, $dep;
}

sub __deref__
{
    my $var_ref   = shift;
    my $array_ref = shift;
    my $ret;
    my $ref = shift @{ $array_ref }; 
      if ( ref $var_ref eq 'REF' )
    {
        $var_ref = $$var_ref;
    }
    if ( $ref =~ s/\{|\}//g )
    {
      if (  ref $var_ref->{ $ref } eq 'SCALAR') 
      {
          $ret = ${$var_ref->{ $ref }};
      } else {
          $ret = $var_ref->{ $ref };
      }
    }
    elsif ( $ref =~ s/\[|\]//g )
    {
        $ret = $var_ref->[$ref];
    }
    if ( ref $ret eq 'REF' )
    {  
        $ret = $$ret;
    }
    if ( scalar @{ $array_ref } )
    {
        $ret = __deref__( $ret, $array_ref );
    }
    
    return $ret;
}

=head2 a >R

        put 'a' on the return stack
        
=cut

$dict{'>R'} = sub {
    my @ret;
    my $work1 = shift;
    my $val   = pop @{ $work1 };
    push @ret, $val;
    return \@ret, 1, -1;
};

=head2 R>

       remove first element from the return stack and copy on the normal stack
        
=cut

$dict{'R>'} = sub {
    my @ret;
    my $work1   = shift;
    my $return1 = shift;
    my $val;
    if ( scalar @{ $return1 } )
    {

        push @ret, pop @{ $return1 };
    }
    return \@ret, 0, 1;
};

=head2 RL

       return the depth of the return stack
        
=cut

$dict{RL} = sub {
    my @ret;
    my $work1   = shift;
    my $return1 = shift;
    push @ret, scalar @{ $return1 };
    return \@ret, 0, 0;
};

=head2 R@

       copy return stack on normal stack
        
=cut

$dict{'R@'} = sub {
    my @ret;
    my $work1   = shift;
    my $return1 = shift;
    push @ret, @{ $return1 };
    return \@ret, 0, 0;
};

########################
# FILE operator
########################

=head1 FILE operators ( basic IO )

=cut

=head2 file, mode , FH, OPEN

       OPEN a file and keep the filehandle in the variable X
       mode could be all combination of : 
       'r' ( read  ), 
       'w' ( write ), 
       'c' ( create ),
       't' ( truncate ), 
       'a'( append = seek to end )
=cut

$dict{OPEN} = sub {
    my @ret;
    my $work1  = shift;
    my $fh_var = pop @{ $work1 };
    my $mode   = pop @{ $work1 };
    my $file   = pop @{ $work1 };
    my $fh;

    my $type = O_RDONLY;
    $type |= O_RDONLY if ( $mode =~ /r/ );
    $type |= O_RDWR   if ( $mode =~ /w/ );
    $type |= O_CREAT  if ( $mode =~ /c/ );
    $type |= O_TRUNC  if ( $mode =~ /t/ );

    sysopen $fh, $file, $type;
    seek $fh, 0, 2 if ( $mode =~ /a/ );
    $var{ $fh_var } = $fh;
    return \@ret, 3, 0;
};

=head2 file, UNLINK

       UNLINK ( delete ) a file 
      
=cut

$dict{UNLINK} = sub {
    my @ret;
    my $work1  = shift;
    my $file   = pop @{ $work1 };

    
    push @ret , unlink($file);
    return \@ret, 1, 0;
};
=head2  FH, STAT

       STAT the file using the handle stored in the var FH ( FH could also be a file path )
       return the same content as perl stat. Keep in mind that the indice 0 from the perl array is the 1 fisrt stack level.
       To get the size of a file:
       /tmp/rpn,STAT,13,8,KEEPR
        
=cut

$dict{STAT} = sub {
    my $work1  = shift;
    my $fh_var = pop @{ $work1 };
    my $fh     = $var{ $fh_var };
    $fh = $fh_var if ( ref( $fh ) ne 'GLOB' );
    my @ret = reverse stat( $fh );
    return \@ret, 2, 0;
};

=head2  OFFSET, WHENCE, FH, SEEK

       SEEK of OFFSET in the file using the handle stored in the var FH 
       if WHENCE = 0 seek from the beginning of the file
       if WHENCE = 1 seek from the current position 
       if WHENCE = 2 seek from the end of the file ( offset must be < 0 )
       ( see perldoc -f seek )
        
=cut

$dict{SEEK} = sub {
    my @ret;
    my $work1  = shift;
    my $fh_var = pop @{ $work1 };
    my $whence = pop @{ $work1 };
    my $offset = pop @{ $work1 };
    my $fh     = $var{ $fh_var };
    sysseek $fh, $offset, $whence;
    return \@ret, 3, 0;
};

=head2   FH, TELL

       TELL return the position in the file using the handle stored in the var FH 
        
=cut

$dict{TELL} = sub {
    my @ret;
    my $work1  = shift;
    my $fh_var = pop @{ $work1 };
    my $fh     = $var{ $fh_var };
    my $tmp    = sysseek($fh, 0, 1);
    push @ret, $tmp;
    return \@ret, 1, 0;
};

=head2  FH, CLOSE

       CLOSE the file handle stored in the var FH 
        
=cut

$dict{CLOSE} = sub {
    my @ret;
    my $work1  = shift;
    my $fh_var = pop @{ $work1 };
    close $var{ $fh_var };
    delete $var{ $fh_var };
    return \@ret, 1, 0;
};

=head2 N, FH, GETC

       read and put on top of the stack N character from the filedscriptor stored in the variable FH
       to do a file slurp:
       /tmp/rpn,r,fh,OPEN,sh,STAT,13,6,KEEPR,fh,GETC,fh,CLOSE
        
=cut

$dict{GETC} = sub {
    my @ret;
    my $work1  = shift;
    my $fh_var = pop @{ $work1 };
    my $nbr    = pop @{ $work1 };
    my $buf;
    my $fh = $var{ $fh_var };
    sysread $fh, $buf, $nbr;
    push @ret, $buf;
    return \@ret, 2, 0;
};

=head2 N, FH, GETCS

       read and put on the stack N character from the filedscriptor stored in the variable FH
       each character is pushed on the stack ( and then the stack is evalueted )
        
=cut

$dict{GETCS} = sub {
    my @ret;
    my $work1  = shift;
    my $fh_var = pop @{ $work1 };
    my $nbr    = pop @{ $work1 };
    my $fh = $var{ $fh_var };
    for ( 1 .. $nbr )
    {
        my $buf = getc( $var{ $fh_var } );
        #sysread $fh, $buf, 1;
        push @ret, $buf;
    }
    return \@ret, 2, 0;
};

=head2 N, FH, WRITE

        put and delete N element from the stack to the filedscriptor stored in the variable FH
        
=cut

$dict{WRITE} = sub {
    my @ret;
    my $work1  = shift;
    my $fh_var = pop @{ $work1 };
    my $nbr    = pop @{ $work1 };
    my $buf;
   
    for ( 1 .. $nbr )
    {
        $buf .= pop @{ $work1 };
    }
    my $fh = $var{ $fh_var };
    syswrite $fh, $buf;
    return \@ret, 2 + $nbr, 0;
};

=head2 N, FH, WRITELINE

        put and delete N element from the stack as a new line for each element to the filedscriptor stored in the variable FH
        to flush buffer, use 0,0,FH,SEEK
        
=cut

$dict{WRITELINE} = sub {
    my @ret;
    my $work1  = shift;
    my $fh_var = pop @{ $work1 };
    my $nbr    = pop @{ $work1 };
    my $buf; 
     my $from = ( 1 + ( $#$work1 ) - $nbr );
    $from = $from < 0 ? 0 : $from;
    my @TMP = @{ $work1 }[ $from .. ( $#$work1 ) ];
    foreach my $tmp ( @TMP )
    {   
        $buf .= "$tmp\n";
    }
    my $fh = $var{ $fh_var };
    syswrite $fh, $buf, length $buf;
    return \@ret, 2 + $nbr, 0;
};

=head2 FH, READLINE

       read and put on the stack a line from the filedscriptor stored in the variable FH
        
=cut

$dict{READLINE} = sub {

    my $work1  = shift;
    my $fh_var = pop @{ $work1 };
    my $fh     = $var{ $fh_var };
    my $buf;
    my $tmp = '';
    while ( $tmp !~ /((\n\r)|\n|\r)/ )
    {
        last if ( !sysread $fh, $tmp, 1 );
        $buf .= $tmp;
    }
    my @ret;
    push @ret, $buf;
    return \@ret, 1, 0;
};

########################
# loop operators
########################

=head1 LOOP and DECISION operators

=cut

=head2 a IF xxx THEN

        test the element on top of stack 
                if == 1 execute 'xxx' block
                
        The loop is executed always one time

=cut

$dict{THEN} = sub {
    my @ret;
    my $work1   = shift;
    my $return1 = shift;
    my $b_ref   = pop @{ $return1 };
    my $a_ref   = pop @{ $return1 };
    my @pre     = @{ $work1 };
    my @BEGIN   = splice @pre, $a_ref + 1, $b_ref - $a_ref - 1;
    my $len     = scalar @BEGIN;
    my $r       = scalar @{ $work1 };
    my $i       = $r - $len - 2;
    my $res     = $pre[$i];
#    my $res     = pop @pre;
    pop @pre;

    my $len_d = 2 + $len;

    if ( $res )
    {
        my @TMP = @pre;
        pop @TMP;
        push @TMP, @BEGIN;
        process( \@TMP );
        $len_d = scalar( @pre ) + $len + 1;
        @ret   = @TMP;
    }

    return \@ret, $len_d, 2;
};

=head2 a IF zzz ELSE xxx THEN

        test the element on top of stack 
                if == 1 execute 'xxx' block
                if != 1 execute 'zzz' block 
                
        The loop is executed always one time

=cut

$dict{THENELSE} = sub {
    my @ret;
    my $work1   = shift;
    my $return1 = shift;
    my $c_ref   = pop @{ $return1 };
    my $b_ref   = pop @{ $return1 };
    my $a_ref   = pop @{ $return1 };
    my @pre     = @{ $work1 };

    my @BEGIN = splice @pre, 0, $a_ref - 1;
    @pre = @{ $work1 };
    my @THEN = splice @pre, $c_ref + 1, $b_ref - 1;
    my @ELSE = splice @pre, scalar( @BEGIN ) + 2;
    pop @ELSE;

    my $VAR = $pre[-2];

    my $len_d = scalar( @pre ) + scalar( @BEGIN ) + scalar( @THEN ) + 3;
    if ( $VAR )
    {
        my @TMP = @BEGIN;
        push @TMP, $VAR;
        push @TMP, 'IF';
        push @TMP, @THEN;
        push @TMP, 'THEN';
        process( \@TMP );
        @ret   = @TMP;
        $len_d = scalar( @THEN ) + scalar( @BEGIN ) + scalar( @ELSE ) + 5;

        if ( scalar( @pre ) == 2 )
        {
            $len_d++;
        }
    }
    else
    {
        my @TMP = @BEGIN;
        push @TMP, @ELSE;
        process( \@TMP );
        @ret   = @TMP;
        $len_d = scalar( @pre ) + scalar( @BEGIN ) + scalar( @ELSE ) + scalar( @THEN ) + 2;
    }
    return \@ret, $len_d, 3;
};

=head2 BEGIN xxx WHILE zzz REPEAT

        execute 'xxx' block
        test the element on top of stack 
                if == 0 execute 'zzz' block and branch again at 'BEGIN'
                if != 0 end the loop
                
        The loop is executed always one time


=cut

$dict{REPEAT} = sub {
    my @ret;
    my $work1   = shift;
    my $return1 = shift;
    my $c_ref   = pop @{ $return1 };
    my $b_ref   = pop @{ $return1 };
    my $a_ref   = pop @{ $return1 };
    my @pre     = @{ $work1 };
    my @BEGIN   = splice @pre, $a_ref, $b_ref - $a_ref;
    my @HEAD    = splice @pre, 0, $a_ref;
    my $len     = scalar( @BEGIN );
    @pre = @{ $work1 };
    my @WHILE = splice @pre, $b_ref + 1, $c_ref - $b_ref;
    my @WHILE2 = @WHILE;
    @pre = @{ $work1 };
    my @TMP  = @HEAD;
    my $head = $HEAD[-1];
    push @TMP, @BEGIN;
    process( \@TMP );
    my $res = pop @TMP;
    $len += scalar( @WHILE );

    if ( !$res )
    {
        push @TMP, @WHILE;
        process( \@TMP );
        push @ret, @TMP;
        @BEGIN = splice @pre, $a_ref, $b_ref - $a_ref;
        push @ret, 'BEGIN', @BEGIN, 'WHILE', @WHILE2, 'REPEAT';
        return \@ret, scalar( @TMP ) + $len + 1, 3;
    }
    my @BEGIN1 = @BEGIN;
    process( \@BEGIN1 );
    $res = pop @BEGIN1;
    push @ret, @BEGIN1;
    return \@ret, scalar( @WHILE2 ) + scalar( @BEGIN ) + 1, 3;
};

=head2  end start DO,block,LOOP

        process 'block' with iterator from value 'start' until 'end' value,with increment of 1;
        The iterator variable is the second value on the stack (start argument)
        
=cut

$dict{LOOP} = sub {
    my $work1   = shift;
    my $return1 = shift;
    my $len     = scalar( @{ $work1 } );
    my $b_ref   = pop @{ $return1 };
    my $a_ref   = pop @{ $return1 };
    my @pre     = @{ $work1 };
    my @BLOCK   = splice @pre, $a_ref + 1, $b_ref - $a_ref;
    my @pre1    = @{ $work1 };
    my @HEAD    = splice @pre1, 0, $a_ref;
    pop @pre;
    my $start   = pop @pre;
    my $end   = pop @pre;
    my $ind = $start;
    my @ret;

    if ( $ind <= $end )
    {
        $var{ _T_ }= $ind;
        $ind++;
        my @TMP = @pre;
        push @TMP, @BLOCK;
        process( \@TMP );
        @pre = @TMP;
        push @pre, $end, $ind, "DO", @BLOCK, "LOOP";
    }
    return \@pre, $len + 1, 0;
};

=head2  end start increment DO,block,+LOOP

        process 'block' with iterator from value 'start' untill 'end' value,with increment of 'increment' 
        This allow rational or negative value
        The iterator variable is the second value on the stack (start argument)
        
=cut

$dict{'+LOOP'} = sub {
    my $work1   = shift;
    my $return1 = shift;
    my $len     = scalar( @{ $work1 } );
    my $b_ref   = pop @{ $return1 };
    my $a_ref   = pop @{ $return1 };
    my @pre     = @{ $work1 };
    my @BLOCK   = splice @pre, $a_ref + 1, $b_ref - $a_ref;
    my @pre1    = @{ $work1 };
    my @HEAD    = splice @pre1, 0, $a_ref;
    pop @pre;
    my $inc = pop @pre;
    my $start      = pop @pre;
    my $end        = pop @pre;
    
    my @TMP1       = @pre;
    my $subs_start = scalar( @TMP1 ) - 1;
    push @TMP1, @BLOCK;
    my $ind = $start;
    my @ret;
    if ( $inc < 0 )
    {
        if ( $ind >= $end )
        {  
            $var{ _T_ }= $ind;
            $ind += $inc;
            @pre = @TMP1;
            push @pre, $end, $ind,$inc, "DO", @BLOCK, "+LOOP";
        }
    }
    elsif ( $inc > 0 )
    {
        if ( $ind <= $end )
        {
            $var{ _T_ }= $ind;
            $ind += $inc;
            @pre = @TMP1;
            push @pre, $end, $ind,$inc, "DO", @BLOCK, "+LOOP";
        }
    }
    else
    {
        my @pre = ();
    }
    return \@pre, $len + 1, 2;
};

#####################################
# main code
#####################################
sub parse
{
    my $remainder = shift;
    $remainder =~ s/^$separator_in//;
    my $before;
    my $is_string = 0;
    $remainder =~ s/^\s+//;
    if ( $remainder =~ /^('|")(.*)/ )
    {
        $is_string = 1;
        $remainder = $2;
        if ( $remainder =~ /^([^\"']*)('|")(.*)/ )
        {
            $before    = $1;
            $remainder = $3;
        }
    }
    else
    {
        ( $before, $remainder ) = split /$separator_in/, $remainder, 2;
    }
    return ( $before, $remainder, $is_string );
}

sub rpn($)
{
    my $item = shift;
    $DEBUG = '';
    my @stack;
    while ( length $item )
    {
        my $elem;
        my $is_string;
        ( $elem, $item, $is_string ) = parse( $item );
        if ( $is_string )
        {
            push @stack, "'" . $elem . "'";
        }
        else
        {
            push @stack, $elem;
        }
    }
    process( \@stack );
    my $ret = join $separator_out, @stack;
    return $ret;
}

sub process
{
    my $stack = shift;
    my $is_block;
    my $is_begin;
    my $is_while;
    my $is_do;
    my $is_if=0;
    my $is_else;
    my $else;
    my @work;

    while ( @{ $stack } )
    {
        my $op        = shift @{ $stack };
        my $is_string = 0;
        my $tmp_op    = $op;
        $tmp_op =~ s/^\s+//g;
        $tmp_op =~ s/\s+$//g;
        if ( exists( $dict{ $tmp_op } ) || exists( $var{ $tmp_op } ) )
        {
            $op =~ s/^\s+//g;
            $op =~ s/\s+$//g;
        }
        if ( ( $op =~ /^VARIABLE$/g ) )
        {
            push @work, shift @{ $stack };
        }
        if ( $op =~ /^'(.*)'$/ )
        {
            $is_string = 1;
            unless ( $is_do )
            {
                $op =~ s/^'(.*)'$/$1/g;
            }
        }
        if ( $op =~ /^;$/g )
        {
            $is_block = 0;
            push @return, ( scalar( @work ) );
        }
        if ( $op =~ /^PERL$/g )
        {
            $is_block = 0;
            push @return, ( scalar( @work ) );
        }
        if ( $op =~ /^PERLFUNC$/g )
        {
            $is_block = 0;
            push @return, ( scalar( @work ) );
        }
        if ( $op =~ /^:$/g )
        {
            $is_block = 1;
            push @return, ( scalar( @work ) );
            next;
        }
        if ( !$is_block )
        {
            if ( $op =~ /^BEGIN$/g )
            {
                $is_begin = 1;
                push @return, ( scalar( @work ) );
                next;
            }
            if ( ( $op =~ /^WHILE$/g ) )
            {
                $is_begin = 0;
                $is_do    = 1;
                push @return, ( scalar( @work ) );
            }
            if ( $is_do && ( $op =~ /^REPEAT$/g ) )
            {
                $is_do = 0;
                push @return, ( scalar( @work ) - 1 );
            }
            if ( $op =~ /^DO$/g )
            {
                $is_do = 1;
                push @return, ( scalar( @work ) );
            }
            if ( ( $op =~ /^LOOP|\+LOOP$/g ) )
            {
                $is_do = 0;
                push @return, scalar( @work );
            }

            if ( $op =~ /^IF$/g )
            {
                $is_do = 1;
                if ( $is_if == 0 )
                {
                    push @return, ( scalar( @work ) );
                }
                $is_if++;
            }
            if ( $op =~ /^ELSE$/g )
            {
                if ( $is_if == 1 )
                {
                    $is_else++;
                    $else = ( scalar( @work ) );
                }
            }
            if ( $op =~ /^THEN$/g )
            {
                $is_if--;
                if ( $is_if == 0 )
                {
                    push @return, ( scalar( @work ) );
                    $is_do = 0;

                    if ( $is_else )
                    {
                        $op = "THENELSE";
                        push @return, $else;
                    }
                }
            }

        }
        if ( !$is_string )
        {
            if ( $is_do || $is_begin || $is_block )
            {
                push @work, $op;
            }
            else
            {
                if ( defined( $dict{ $op } ) )
                {
                    my @work_stack   = @work;
                    my @return_stack = @return;
                    my ( $ret, $remove_stack, $remove_return ) = $dict{ $op }( \@work_stack, \@return_stack );
                    if ( $remove_return >= 0 )
                    {
                        for ( 1 .. $remove_return )
                        {
                            pop @return;
                        }
                    }
                    else
                    {
                        my $to_ret = pop @{ $ret };
                        push @return, $to_ret;
                    }
                    for ( 1 .. $remove_stack )
                    {
                        pop @work;
                    }
                    unshift @{ $stack }, @work, @{ $ret };
                    undef @work;
                }
                else
                {
                    push @work, $op;
                }
            }
        }
        else
        {
            push @work, $op;
        }
    }
    unshift @{ $stack }, @work;
}

=head1 Useful functions for the module (not related to the RPN language)

=cut

=head2  rpn_error()

        function which return the debug info from the calculation (like a division by 0)
        
=cut

sub rpn_error
{
    return $DEBUG;
}

=head2  rpn_separator_out( 'sep' )

        function to set a specific separator for the returned stack (default = space)
        This is useful when the result of rpn() is use inside another rpn() call 
        
=cut

sub rpn_separator_out
{ 
    my $sep = shift;
    $separator_out = $sep if ( $sep ) ;
    return $separator_out;
}

=head2  rpn_separator_in( 'sep' )

        function to set a specific separator for the input data (default = ')
        
        
=cut

sub rpn_separator_in
{
    my $sep = shift;
    $separator_in = $sep if ( $sep );
    return $separator_in ;
}

1;

__END__

=head1 OPERATORS

     The operators get value from the stack and push the result on top
     In the following explanation, the stack is represented as a pair of brackets ()
     and each elements by a pair of square barcket []
     The left part is the state before evalutation 
     and the right part is the state of the stack after evaluation 

        Arithmetic operators
        ---------------------
            +                   ([a][b])                ([a+b])
            -                   ([a][b])                ([a-b])
            *                   ([a][b])                ([a*b])
            /                   ([a][b])                ([a/b])         Becare if division by null return a blank value
            **                  ([a][b])                ([a**b])
            1+                  ([a])                   ([a+1])
            1-                  ([a])                   ([a-1])
            2+                  ([a])                   ([a+2])
            2-                  ([a])                   ([a-2])    
            MOD                 ([a][b])                ([a%b])
            ABS                 ([a])                   ([ABS a])
            INT                 ([a])                   ([INT a])
            +-                  ([a])                   ([-a])
            REMAIN              ([a])                   ([a- INT a])
            
        Rationnal operators
        -------------------  
            SIN                 ([a])                   ([SIN a])       Unit in radian
            COS                 ([a])                   ([COS a])       Unit in radian
            TAN                 ([a])                   ([TAN a])       Unit in radian
            CTAN                ([a])                   ([CTAN a])      Unit in radian
            LN                  ([a])                   ([LOG a])
            EXP                 ([a])                   ([EXP a])
            PI                                          ([3.14159265358979])    
            
        Relational operator
        ----------------
            <                   ([a][b])                ([1]) if [a]<[b] else ([0])
            <=                  ([a][b])                ([1]) if [a]<=[b] else ([0])
            >                   ([a][b])                ([1]) if [a]>[b] else ([0])
            >=                  ([a][b])                ([1]) if [a]>=[b] else ([0])    
            ==                  ([a][b])                ([1]) if [a]==[b] else ([0])
            <=>                 ([a][b])                ([-1]) if [a]>[b],([1]) if [a]<[b], ([0])if [a]==[b]
            !=                  ([a][b])                ([0]) if [a]==[b] else ([1])
            TRUE                ([a])                   Return 1 if [a]>0 and exist
            FALSE               ([a])                   Return 0 if [a]>0
            
        Logical operator
        ----------------
        
            OR                  ([a][b])                ([1]) if [a] or [b] >0
            AND                 ([a][b])                ([1]) if [a] and [b] >0
            XOR                 ([a][b])                ([1]) if [a] and [b] are >0 or ==0
            NOT                 ([a])                   Return 0 if [a]>0, Return 1 if[a]==0, 
        
        Other operator
        ----------------
        
            >>                  ([a][b])                shift to the right the bits from [a] of [b] rank
            <<                  ([a][b])                shift to the left the bits from [a] of [b] rank
            MIN                 ([a][b])                ([a]) if  [a]<[b] else ([b]) 
            MAX                 ([a][b])                ([a]) if  [a]>[b] else ([b]) 
            LOOKUP              ([a] V R [ope] )        test [ a ] on all value of array V with the operator [ope] 
                                                        if succeed, return the value from array R at the succesfull indice
            LOOKUPP             ([a] V R [ope] )        test [ a ] on all value of array V with the perl operator [ope] 
                                                        if succeed, return the value from array R at the succesfull indice
            LOOKUPOP            ([a] V R O] )           test [ a ] on all value of array V with the operator from the array OPE with the same indice
            LOOKUPOPP           ([a] V R O] )           test [ a ] on all value of array V with the perl operator from the array OPE with the same indice
                                                        if succeed, return the value from array R at the succesfull indice
            TICK                ()                      ([time]) time in ticks
            LTIME               ([a])                   ([min][hour][day_in_the_month][month][year][day_in_week][day_year][daylight_saving]
                                                        localtime of [a] like PERL
            GTIME               ([a])                   ([min][hour][day_in_the_month][month][year][day_in_week][day_year][daylight_saving]
                                                        ([a]) gmtime of [a] like PERL
            HLTIME              ([a])                   ([a]) localtime human readeable
            HGTIME              ([a])                   gmtime human readeable          
            RAND                ()                      ([rand]) a random numder between 0 and 1
            LRAND               ([a])                   ([rand]) a random numder between 0 and [a]
            SPACE               ([a])                   Return [a] with space between each 3 digits
            DOT                 ([a])                   Return [a] with dot (.) between each 3 digits
            NORM                ([a])                   Return [a] normalized by 1000 (K,M,G = 1000 * unit)
            NORM2               ([a])                   Return [a] normalized by 1000 (K,M,G = 1024 * unit)
            OCT                 (|a|)                   Return the DECIMAL value from HEX,OCTAL or BINARY value |a| (see oct from perl)
            OCTSTR2HEX          (|a|)                   Return a HEX string from a OCTETSTRING
            HEX2OCTSTR          (|a|)                   Return a OCTETSTRING string from a HEX
            DDEC2STR            (|a|)                   Return a string from a dotted DEC string
            STR2DDEC            (|a|)                   Return a dotted DEC string to a string

        String operators
        ----------------
            EQ                  ([a][b])                ([1]) if [a] eq [b] else ([0])
            NE                  ([a][b])                ([1]) if [a] ne [b] else ([0])
            LT                  ([a][b])                ([1]) if [a] lt [b] else ([0])
            GT                  ([a][b])                ([1]) if [a] gt [b] else ([0])
            LE                  ([a][b])                ([1]) if [a] le [b] else ([0])
            GE                  ([a][b])                ([1]) if [a] ge [b] else ([0])
            CMP                 ([a][b])                ([-1]) if [a] gt [b],([1]) if [a] lt [b], ([0])if [a] eq [b]
            LEN                 ([a])                   ([LENGTH a])
            CAT                 ([a][b])                ([ab])  String concatenation
            CATALL              ([a][b]...[z])          ([ab...z]) String concatenation of all elements on the stack
            REP                 ([a][b])                ([a x b]) repeat [b] time the motif [a]
            REV                 ([a])                   ([REVERSE a])
            SUBSTR              ([a][b][c])             ([SUBSTR [a], [b], [c]) get substring of [a] starting from [b] untill [c]
            UC                  ([a])                   ([UC a])
            LC                  ([a])                   ([LC a])
            UCFIRST             ([a])                   ([UCFIRST a])
            LCFIRST             ([a])                   ([LCFIRST a])
            PAT                 ([a][b])                ([r1]...) use the pattern [b] on the string [a] and return result 
                                                        if more then one result like $1, $2 ... return all the results 
            PATI                ([a][b])                ([r1]...) use the pattern CASE INSENSITIVE [b] on the string [a] and return result 
                                                        if more then one result like $1, $2 ... return all the results
            TPAT                ([a][b])                ([r]) use the pattern [b] on the string [a] and return 1 if pattern macth 
                                                        otherwise return 0
            TPATI               ([a][b])                ([r]) use the pattern CASE INSENSITIVE [b] on the string [a] and return 1 if pattern macth 
                                                        otherwise return 0
            SPLIT               ([a][b])                split ([a]) using the pattern ([b]) and return all elements on stack
            SPLITI                                      split ([a]) using the pattern CASE INSENSITIVE  ([b])) and return all elements on stack
            SPLIT2              ([a][R1][R2][K][V])     split ([a]) using the pattern ([R1]), each result are splitted using the pattern ([R2])
                                                        the result are stored in the variables [K] and [V]
            SPAT                ([a][b][c])             Do a pattern subsititution following this rule I<[c] =~s/[a]/[b]/>
            SPATG               ([a][b][c])             Do a pattern subsititution following this rule I<[c] =~s/[a]/[b]/g>
            SPATI               ([a][b][c])             Do a pattern subsititution following this rule I<[c] =~s/[a]/[b]/i> 
                                                        (case insensitive)
            SPATGI              ([a][b][c])             Do a pattern subsititution following this rule I<[c] =~s/[a]/[b]/gi> 
                                                        (case insensitive)
            PRINTF              ([a][b]...[x])          use the format present in [a] to print the value [b] to [x] 
                                                        the format is the same as (s)printf 
            PACK                ([a][b]...[x])          Do an unpack on variable [b] to [x] using format [b] 
            UNPACK              ([a][b])                Do an unpack on variable [b] using format [a]
            
            ISNUM               ([a])                   Test if a is a NUMBER return 1 if success ( [a] [1|0] )
                                                        Keep the value on the stack
            ISNUMD              ([a])                   Test if a is a NUMBER return 1 if success ( [1|0] )
                                                        Remove the value from the stack
            ISINT               ([a])                   Test if a is a INTEGER (natural number )
                                                        Return 1 if success ( [a] [1|0] )
                                                        Keep the value on the stack
            ISINTD              ([a])                   Test if a is a INTEGER (natural number )
                                                        Return 1 if success ( [1|0] )
                                                        Remove the value from the stack                                 
            ISHEX               ([a])                   Test if a is a HEXADECIMAL (hex starting with 0x or 0X or # )
                                                        Return 1 if success ( [a] [1|0] )
                                                        Keep the value on the stack
            ISHEXD              ([a])                   Test if a is a HEXADECIMAL (hex starting with 0x or 0X or # )
                                                        Return 1 if success ( [1|0] )
                                                        Remove the value from the stack                                 
                                                        
 
         Stack operators
         ---------------
                
            SWAP                ([a][b])                ([b][a])
            OVER                ([a][b])                ([a][b][a])
            DUP                 ([a])                   ([a][a])
            DDUP                ([a][b])                ([a][b][a][b])
            ROT                 ([a][b][c])             ([b][c][a])
            RROT                ([a][b][c])             ([c][a][b])
            DEPTH               ([r1]...)               ([re1]...[nbr]) Return the number of elements in the statck
            POP                 ([a][b])                ([a])
            POPN                ([a][b][c]...[x])       ([l]...[x]) remove [b] element from the stack (starting at [c])
            SWAP2               ([a][b][c])             ([a][c][b])
            ROLL                ([a][b][c][d][e][n])    ([a][c][d][e][b]) rotate the [n] element of the stack (here [n]=4)
                                                        if  [n] =3 it is equivalent to ROT
            PICK                ([a][b][c][d][e][n])    ([a][b][c][d][e][b]) copy element from depth [n] on top 
            GET                 ([a][b][c][d][e][n])    ([a][b][c][d][e][b]) get element from depth [n] and put on top 
            PUT                 ([a][b][c][d][v][n])    ([a][v][b][c][d]) put element [v] at level [n] (here [n]=3)
            DEL                 ([a][b])                delete [b] element on the stack from level [a]
                                                        [a] and [b] is get in absolute value        
            KEEPN               ([a][b])                keep [b] element(s) on the stack from level [a] 
                                                        (and delete all other elements)
                                                        [a] and [b] is get in absolute value        
            KEEPR
            KEEPRN
            PRESERVE            ([a][b])                keep element(s) on the stack from level [a] to level [b]
                                                        (and delete all other elements)
                                                        [a] and [b] is get in absolute value
            COPY                ([a][b])                copy element(s) on the stack from level [a] to level [b]
                                                        [a] and [b] is get in absolute value                                    
            FIND                ([a])                   get the level of stack containing [a]
            SEARCH              ([a])                   get the level of stack containing the REGEX [a]
            SEARCHI             ([a])                   get the level of stack containing the REGEX [a] ( case insensitive )
            SEARCHK             ([a])                   keep only level of stack matching the REGEX [a]
            SEARCHIK            ([a])                   keep only level of stack matching the REGEX [a] ( case insensitive )
            KEEP                ([a][b][c][d][e][n])    remove all elements of the stack except the element at deepth |n|
            
         Dictionary operators
         --------------------    
          
            WORDS               ()                              ([a])return as one stack element the list of WORD in DICT separated by a |      
            VARS                ()                              ([a])return as one stack element the list of VARIABLE in VAR separated by a |                           
            INC                 ([a])                           () increment (+1) the value of variable [a]
            DEC                 ([a])                           () decrement (-1) the value of variable [a]
            VARIABLE            ([a])                           () create a entry in VAR for the variable [a]
            !                   ([a][b])                        store the value [a] in the variable [b]
            !A
            !!                  ([a][b][c]...[n] [var])         put and delete 'n' element(s) from the stack in the variable 'var'
                                                                'n' is in absolute value        
            !!A
            !!C                 ([a][b][c]...[n] [var])         copy 'n' element(s) from the stack in the variable 'var'
                                                                'n' is in absolute value        
            !!CA
            !!!                 ([a][b][c]...[n1] [n2] [var])   put and delete element(s) from the stack in the variable 'var'
                                                                starting at element  'a' to element 'b'
                                                                'a' and 'b' in absolute value 
                                                                if 'a' > 'b'  keep the reverse of selection (boustrophedon)
            !!!A
            !!!C                        ([a][b][c]...[n] [var]) copy 'element(s) from the stack in the variable 'var'
                                                                starting at element  'a' to element 'b'
                                                                'a' and 'b' in absolute value 
                                                                if 'a' > 'b'  keep the reverse of selection (boustrophedon)                                                             
            !!!CA
            @                   ([a])                           ([a]) return the value of the variable [a]
            : xxx yyy ;                                         create a new word (sub) into the dictionary with the xxx "code" and name yyy
            : xxx yyy PERLFUNC                                  execute the PERL function yyy with parameter(s) yyy 
                                                                the default name space is "main::"
                                                                It is possible tu use a specific name space
            : xxx yyy PERL                                      execute the PERL code xxx ; yyy                                 

         File oprator
         -------------
         
           OPEN
           STAT
           SEEK
           TELL
           CLOSE
           GETC
           GETCS
           READLINE
           WRITE
           WRITELINE
           
         Return Stack operators
         ----------------------
         
           >R                   ([a])                   put ^a$ on the return stack
           R>                   ()                      remove first element from the return stack and copy on the normal
           RL                   ()                      return the depth of the return stack
           R@                   ()                      copy return stack ion normal stack

        LOOP and DECISION operators
        ---------------------------
        
         [a] IF [..xxx] THEN                            Test the element on top of stack
                                                          if ==0, execute 'xxx' block
                                                        The loop is executed always one time
         
         [a] IF [...zzz...] ELSE [..xxx...] THEN        Test the element on top of stack
                                                          if ==0, execute 'xxx' block
                                                          if != 0 execute 'zzz' block
                                                        The loop is executed always one time

         BEGIN xxx WHILE zzz REPEAT                     Execute 'xxx' block
                                                        Test the element on top of stack
                                                          if ==0 execute 'zzz' block and branch again to BEGIN
                                                          if != 0 end the loop
                                                        The loop is executed always one time

        [a] [b] DO [...xxx...] LOOP     ([a][b])        process block [...xxx...] with iterator from value [b] untill [a] value,
                                                        with increment of 1;
                                                        The iterator variable is '_I_' (read only and scoop only the DO ... LOOP block)
        
        [a] [b] DO [...xxx...] [c] +LOOP        ([a][b])        process block [...xxx...] with iterator from value [b] untill [a] value,
                                                        with increment of [c];
                                                        The iterator variable is '_I_' (read only and scoop only the DO ... LOOP block)


=head1 EXAMPLES

        use Parse::RPN;
        
        $test ="3,5,+";
        $ret = rpn($test);  # $ret = 8
        
        $test = "Hello World,len,3,+";
        $ret = rpn($test);  # $ret = 14
        
        $test = "'Hello,World',len,3,+";
        $ret = rpn($test);  # $ret = 14
        
        $test = "'Hello,World,len,3,+";
        ---------^-----------^-
        $ret = rpn($test);  # $ret = 8 with a warning because the stack is not empty ([Hello] [8])
                            # be care to close your quoted string 
        
        $test = "'Hello world','or',PAT,'or',EQ,IF,'string contain or',ELSE,'No or in string',THEN"
        $ret = rpn($test);  # $ret = "Contain a coma"
        
        $test = "'Hello world','or',TPAT,IF,'string contain or',ELSE,'No or in string',THEN";
        $ret = rpn($test);  # $ret = "string contain or"
        
        
        $test = "3,10,/,5,+,82,*,%b,PRINTF";
        $ret = rpn($test);  # $ret = "110110010"
        
        $test = "3,10,/,5,+,82,*,%016b,PRINTF";
        $ret = rpn($test);  # $ret = "0000000110110010"
        
        $test = "55,N,pack,B32,unpack,^0+(?=\d), ,spat,'+',ds";
        $ret = rpn($test);  # $ret = 110111
        
        $test = "7,3,/,10,3,/,%d %f,PRINTF";
        @ret = rpn($test); # @ret = 2 3.333333
        
        $test = "VARIABLE,a,0,a,!,##,b,BEGIN,bbbb,a,INC,a,@,4,>,WHILE,####,a,@,****,REPEAT";
        @ret =rpn($test); # @ret = ## b bbbb #### 1 **** bbbb #### 2 **** bbbb #### 3 **** bbbb
        or
        $test = "0,a,!,##,b,BEGIN,bbbb,a,INC,a,@,4,>,WHILE,####,a,@,****,REPEAT"; # the VARIABLE declaration is optionel
        @ret =rpn($test); # @ret = ## b bbbb #### 1 **** bbbb #### 2 **** bbbb #### 3 **** bbbb #### 4 **** bbbb
        
        $test = "VARIABLE,a,0,a,!,z,0,5,-1,DO,a,INC,6,1,2,DO,A,_I_,+LOOP,#,+LOOP,##,a,@";
        @ret =rpn($test); # @ret = z A 3 A 5 A 7 # A 3 A 5 A 7 # A 3 A 5 A 7 # A 3 A 5 A 7 # A 3 A 5 A 7 # A 3 A 5 A 7 # ## 6
        
        $test = 'a,b,c,d,e,f,g,h,i,5,2,V1,!!!,uuu,V1,SIZE'
        $ret  =rpn($test); # $ret = a b c d i uuu 4
        
        $test = "1,2,3,4,5,6,7,8,9,3,KEEP";
        $ret =rpn($test); # $ret = 7
        
        $test = "1,2,3,4,5,6,7,8,9,30,KEEP";
        $ret =rpn($test); # $ret = 1,2,3,4,5,6,7,8,9
        
        $test = "h,g,f,e,d,c,b,a,4,3,DEL";
        $ret =rpn($test); # $ret = h,c,b,a
        
        $test = 'test for a split,\s,SPLIT,DEPTH';
        $ret =rpn($test); # $ret = test,for,a,split,4
        
        $test = '# .1.3.6.1.2.1.25.3.3.1.2.768 | 48 # .1.3.6.1.2.1.25.3.3.1.2.769 | 38 # .1.3.6.1.2.1.25.3.3.1.2.771 | 42 # .1.3.6.1.2.1.25.3.3.1.2.770 | 58 #,\s?#\s?,\s\|\s,a,b,SPLIT2
        $ret = rpn($test)
        $ret = rpn(a,@); # $ret = .1.3.6.1.2.1.25.3.3.1.2.768,.1.3.6.1.2.1.25.3.3.1.2.769,.1.3.6.1.2.1.25.3.3.1.2.771,.1.3.6.1.2.1.25.3.3.1.2.770
        $ret = rpn(b,@); # $ret = 48,38,42,58
                
        $test = "h,g,f,e,d,c,b,a,4,3,KEEPN"";
        ret =rpn($test); # @ret = g,f,e,d
        
        sub Test {
           my $a  = shift;
           my $b = shift;
           my $c = $a/$b;
           print "a=$a\tb=$b\ttotal=$c\n";
           return $c;
        }
        $test = ":,5,6,Test,PERLFUNC";
        @ret =rpn($test); # call the function "Test" from the main package (the caller) with parameter 5,6 and return result (in @ret)
        
        $test = ":,05,11,01,0,0,0,Time::Local::timelocal,PERLFUNC";
        @ret =rpn($test); # @ret = 1133391600
        
        $test = "1,2,3,+,:, my $b=7, "open LOG , qq{ >/tmp/log }",print LOG time,PERL";
        @ret =rpn($test); # @ret = 1,5
        and the file /tmp/log contain a line with the tick time.
        
        $test = "11,55,*,5,2,401,+,:,my $b=,SWAP,CAT, "open LOG , qq{ >/tmp/log }",print LOG $b.qq{ \n },PERL"
        @ret =rpn($test); # @ret =1 2 3 1 (the latest 1 is the succes result return)
        and the file /tmp/log contain a line with 403 + a cariage return
        
        $test = 'mb,tb,gb,mb,kb,4,V,!!,12,9,6,3,4,R,!!,V,R,"TPATI",LOOKUP'
        @ret =rpn($test); # @ret = 6

        $test = '5,1,2,3,4,5,5,V,!!," "," ",ok," ",nok,5,R,!!,V,R,"<=",LOOKUPP'
        @ret =rpn($test); # @ret = nok

        $test = '3,1,2,3,4,5,5,V,!!,a,b,ok,d,nok,5,R,!!,"<","<","<","<","<",5,O,!!,V,R,O,LOOKUPOPP'
        @ret =rpn($test); # @ret = d
          
        $test =   1,2,3,4,2,5,2,10,7,DEPTH,1,DO,MAX,LOOP'
        @ret =rpn($test); # @ret = 10        ( = search the MAX in the stack )
        
        $test =     'toto,tata,tota,tato,titi,tito,toti,tot,SEARCHA,DEPTH,r,!!,res1,res2,res3,res4,res5,res6,res7,res8,r,SIZE,DUP,s,!,1,DO,r,POPV,PICK,st,!A,LOOP,DEPTH,POPN,st,@'
        @ret =rpn($test); # @ret = res2 res4 res8

        The small tool 'RPN.pl' provide an easy interface to test quickly an RPN.
        This include two test functions named 'save' and 'restore'
        Try RPN.pl to get a minimal help. 
        Take a look to the minimalistic code, and put RPN.pl in your path.
        
        Sample of use:
        RPN.pl -r '1,2,3,:,123,100,+,7,*,test,save,PERLFUNC'
        save in file '/tmp/test' the value '1561' (whithout CR/LF) and return 1 2 3 1
                

=head1 AUTHOR

        Fabrice Dulaunoy <fabrice@dulaunoy.com> 
        It is a full rewrite from the version 1.xx to allow DICTIONNARY use
        and STRUCTURE control
        Thanks to the module Math::RPN from  Owen DeLong, <owen@delong.com> 
        for the idea of using RPN in a config file

=head1 SEE ALSO

        Math-RPN from  Owen DeLong, <owen@delong.com> 

=head1 TODO

        Error processing, stack underflow...

=head1 CREDITS
        
        Thank's to Stefan Moser <sm@open.ch> for the idea 
        to call a perl function from the rpn() and also for pin-pointing an error in stack return. 
        
=head1 LICENSE

        Under the GNU GPL2

        This program is free software; you can redistribute it and/or modify it 
        under the terms of the GNU General Public 
        License as published by the Free Software Foundation; either version 2 
        of the License, or (at your option) any later version.

        This program is distributed in the hope that it will be useful, 
        but WITHOUT ANY WARRANTY;  without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
        See the GNU General Public License for more details.

        You should have received a copy of the GNU General Public License 
        along with this program; if not, write to the 
        Free Software Foundation, Inc., 59 Temple Place, 
        Suite 330, Boston, MA 02111-1307 USA

        Parse::RPN   Copyright (C) 2004 2005 2006 2007 2008 2009 2010 DULAUNOY Fabrice  
        Parse::RPN comes with ABSOLUTELY NO WARRANTY; 
        for details See: L<http://www.gnu.org/licenses/gpl.html> 
        This is free software, and you are welcome to redistribute 
        it under certain conditions;
   
   
=cut
