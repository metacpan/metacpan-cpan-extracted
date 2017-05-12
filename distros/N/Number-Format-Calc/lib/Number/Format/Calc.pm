package Number::Format::Calc;

use strict;
use warnings;

use Number::Format;

our $VERSION = 0.1;

my %defaults =
(
    -thousands_sep => ",",
    -decimal_point => ".",
);

sub import
{
    shift;
    my %def = @_;
    $defaults{$_} = $def{$_} for keys %def;
}

use overload

    '""'   =>  sub { $_[0]->{formatter}->format_number( $_[0]->{number} ) },

    #arithmetic operations
    '+'    =>  sub { _operate  ("+",  @_); },
    '-'    =>  sub { _operate  ("-",  @_); },
    '*'    =>  sub { _operate  ("*",  @_); },
    '/'    =>  sub { _operate  ("/",  @_); },
    '%'    =>  sub { _operate  ("%",  @_); },
    '**'   =>  sub { _operate  ("**", @_); },

    #arithmetic operations with assign
    '+='   =>  sub { _operatew ("+",  @_); },
    '-='   =>  sub { _operatew ("-",  @_); },
    '*='   =>  sub { _operatew ("*",  @_); },
    '/='   =>  sub { _operatew ("/",  @_); },
    '%='   =>  sub { _operatew ("%",  @_); },
    '**='  =>  sub { _operatew ("**", @_); },

    #arithmetic functions
    'abs'  =>  sub { _function ("abs", @_);},
    'sqrt' =>  sub { _function ("sqrt",@_);},
    'cos'  =>  sub { _function ("cos", @_);},
    'sin'  =>  sub { _function ("sin", @_);},
    'exp'  =>  sub { _function ("exp", @_);},
    'log'  =>  sub { _function ("log", @_);},

    #mutations
    '++'   =>  sub { _mutate   ("++", @_); },
    '--'   =>  sub { _mutate   ("--", @_); },

    #numeric comparisons
    '<'    =>  sub { _compare  ("<",  @_); },
    '<='   =>  sub { _compare  ("<=", @_); },
    '>'    =>  sub { _compare  (">",  @_); },
    '>='   =>  sub { _compare  (">=", @_); },
    '=='   =>  sub { _compare  ("==", @_); },
    '!='   =>  sub { _compare  ("!=", @_); },

    #numeric sorting
    '<=>'  =>  sub { _numsort  (@_);       },

    #fallback
    fallback => 1;

#/use overload

sub new
{
    my $class = shift;
    my $number = shift;
    my %args = @_;

    my %realargs = ();


    for ( keys %args )
    {
        my $value = $args{$_};

        $_ = lc($_); s/^(?!-)/-/;

        $realargs{$_} = $value;
    }

    for ( keys %defaults )
    {
        my $value = $defaults{$_};

        $_ = lc($_);
        s/^(?!-)/-/;

        $realargs{$_} = $value unless exists $realargs{$_};
    }

    my $self = bless {}, 'Number::Format::Calc';

    $self->{formatter} = new Number::Format (%realargs);
    $self->{number}    = $self->{formatter}->unformat_number( $number );

    return $self;
}

sub _operate
{
    my $op = shift;

    my $op1 = ref( $_[0] ) ? $_[0]->{number} : $_[0];
    my $op2 = ref( $_[1] ) ? $_[1]->{number} : $_[1];

    my $number = { %{$_[0]} };

    if    ( $op eq "+"  ) { $number->{number} = $op1 +  $op2; }
    elsif ( $op eq "-"  ) { $number->{number} = $op1 -  $op2; }
    elsif ( $op eq "*"  ) { $number->{number} = $op1 *  $op2; }
    elsif ( $op eq "/"  ) { $number->{number} = $op1 /  $op2; }
    elsif ( $op eq "%"  ) { $number->{number} = $op1 %  $op2; }
    elsif ( $op eq "**" ) { $number->{number} = $op1 ** $op2; }

    return bless $number, 'Number::Format::Calc';
}

sub _operatew
{
    my $op = shift;

    my $op1 = ref( $_[0] ) ? $_[0]->{number} : $_[0];
    my $op2 = ref( $_[1] ) ? $_[1]->{number} : $_[1];

    if    ( $op eq "+"  ) { $_[0]->{number} = $op1 +  $op2; }
    elsif ( $op eq "-"  ) { $_[0]->{number} = $op1 -  $op2; }
    elsif ( $op eq "*"  ) { $_[0]->{number} = $op1 *  $op2; }
    elsif ( $op eq "/"  ) { $_[0]->{number} = $op1 /  $op2; }
    elsif ( $op eq "%"  ) { $_[0]->{number} = $op1 %  $op2; }
    elsif ( $op eq "**" ) { $_[0]->{number} = $op1 ** $op2; }

    return $_[0];
}


sub _mutate
{
    my $op = shift;

    if    ( $op eq "++" ) { ++ $_[0]->{number} }
    elsif ( $op eq "--" ) { -- $_[0]->{number} }
}

sub _compare
{
    my $op = shift;

    my $op1 = ref( $_[0] ) ? $_[0]->{number} : $_[0];
    my $op2 = ref( $_[1] ) ? $_[1]->{number} : $_[1];

    if    ( $op eq "<"  ) { return $op1 <  $op2; }
    elsif ( $op eq ">"  ) { return $op1 >  $op2; }
    elsif ( $op eq "<=" ) { return $op1 <= $op2; }
    elsif ( $op eq ">=" ) { return $op1 >= $op2; }
    elsif ( $op eq "==" ) { return $op1 == $op2; }
    elsif ( $op eq "!=" ) { return $op1 != $op2; }
}

sub _numsort
{
    my $op1 = ref( $_[0] ) ? $_[0]->{number} : $_[0];
    my $op2 = ref( $_[1] ) ? $_[1]->{number} : $_[1];

    return $op1 <=> $op2;
}

sub _function
{
    my $op = shift;

    my $op1 = ref( $_[0] ) ? $_[0]->{number} : $_[0];

    my $number = { %{$_[0]} };

    if    ( $op eq "sqrt" ) { $number->{number} = sqrt($op1); }
    elsif ( $op eq "abs"  ) { $number->{number} = abs($op1);  }
    elsif ( $op eq "cos"  ) { $number->{number} = cos($op1);  }
    elsif ( $op eq "sin"  ) { $number->{number} = sin($op1);  }
    elsif ( $op eq "exp"  ) { $number->{number} = exp($op1);  }
    elsif ( $op eq "log"  ) { $number->{number} = log($op1);  }

    return bless $number, 'Number::Format::Calc';
}

sub number
{
    return $_[0]->{number};
}

use Data::Dumper;
sub fmod
{
    my $op1 = ref( $_[0] ) ? $_[0]->{number} : $_[0];
    my $op2 = ref( $_[1] ) ? $_[1]->{number} : $_[1];

    my $number = { %{$_[0]} };

    $number->{number} = $op1-(int($op1/$op2)*$op2);

    return bless $number, 'Number::Format::Calc';
}

1;


=head1 NAME

Number::Format::Calc

=head1 SYNOPSIS

 use Number::Format::Calc (%args);
 $n = new Number::Format::Calc ('1.234,5', %args );

=head1 DESCRIPTION

This module makes calculations with formatted numbers transparent.

All arithmetric operators and and some arithmetric functions (I<sqrt, abs, cos, sin, exp, log>) are overloaded.

=head1 METHODS

=head2 new ($self, $number, %args)

The constructor awaits the formatted number-string as the first argument,
and a hash with the same formatting-options as in Number::Format.

The same arguments can be passed via the C<use Number::Format::Calc (%args);>-statement and will then serve as defaults
for all instances of Number::Format::Calc-objects.

=head2 number ($self)

This method returns the number without formats.

=head2 fmod ($self, $foo)

This method returns the result of a floating-point modulo operation from $self->number modulo $foo.

=head1 Examples

 use Number::Format::Calc;

 my $n = new Number::Format::Calc ( '1.111,5'  , -thousands_sep=>".", -decimal_point=>",", decimal_digits=>1 );
 my $m = new Number::Format::Calc ( '2.222,35' , -thousands_sep=>".", -decimal_point=>",", decimal_digits=>2 );

 #add 10 to the object
 print $n + 10, "\n"; #1.121,5;

 #When two objects are involved, the settings of the left object win:
 print $n + $m, "\n"; #3.333,9;
 print $m + $n, "\n"; #3.333,85;

 #modulo operation
 print $n % 9, "\n"; #4

 #floating-point modulo operation
 print $n->fmod(9), "\n"; #4.5

 #Get plain number
 print $n->number; #1111.5

More examples can be found in the test-files (*.t) that come with this module.

 ########################################################################

 #using defaults
 use Number::Format::Calc ( -thousands_sep=>".", -decimal_point=>",", -decimal_digits=>2, -decimal_fill => 1 );

 my $n = new Number::Format::Calc ('1.111,5');
 print $n; #1.111,50


=head1 PREREQUISITIES

 Number::Format
 Test::Simple

=head1 BUGS

None that I know of. If you find one, or a missing test-case, let me know.

=head1 AUTHOR

 Markus Holzer
 CPAN ID: HOLLIHO
 HOLLIHO@gmx.de
 http://holli.perlmonk.org

You can also reach me via the chatterbox at L<http://www.perlmonks.org>

=head1 COPYRIGHT

This program is free software licensed under the...

    The General Public License (GPL)
    Version 2, June 1991

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

############################################# main pod documentation end ##
