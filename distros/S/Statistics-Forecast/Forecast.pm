package Statistics::Forecast;

require 5.005_62;
use strict;
use warnings;

our $VERSION = '0.3';

=head1 NAME

Statistics::Forecast - calculates a future value

=head1 DESCRIPTION

This is a dummy Oriented Object module that calculates a future value by using existing values. The new value is calculated by using linear regression.

=head1 SYNOPSIS

   use Statistics::Forecast;

Create forecast object

   my $FCAST = Statistics::Forecast->new("My Forecast Name");

Add data

   $FCAST->{DataX} = \@Array_X;
   $FCAST->{DataY} = \@Array_Y;
   $FCAST->{NextX} = $NextX;

Calculate the result

   $FCAST->calc;

Get the result

   my $Result_Forecast = $FCAST->{ForecastY);

=head1 INTERNALS

The equation for Forecast is:

   a+bx, where 'x' is the predicted value and
       _    _
   a = y + bx

   b = sum((x+x)(y-y))/sum(x-x)**2

=head1 METHODS

=over

=item F<new>

Receives a forecast name, only to remember
and returns the blessed data structure as
a Statistics::Forecast object.

 my $FCAST = Statistics::Forecast->new("My Forecast");

=cut

################################################################

sub new {
        my $classname= shift(@_);
        my $ForecastName = shift(@_) || "with no name";
        my $DataX = shift(@_) || undef;
        my $DataY = shift(@_) || undef;
        my $NextX = shift(@_) || undef;
        my $self = {
                ForecastName => $ForecastName,
                DataX => $DataX,
                DataY => $DataY,
                NextX => $NextX,

                # Initialializing Acumulative variables
                SumX => 0,
                SumY => 0,
                SumXY => 0,
                SumXX => 0
        };

        bless $self;
        return $self;

}

=item F<calc>

Calculate and return the forecast value.

 $FCAST->calc;

=cut

################################################################

sub calc {
        my $self = shift;

        # Verify if the inputed values are correct.
        if (!$self->{DataY}) { die "Cannot run without Y values" };

        # if no X values were input, populate with 1, 2 ...
        if ($#{$self->{DataX}} eq -1) {
           for (my $X=1; $X <= $#{$self->{DataY}}+1; $X++) {
              $self->{DataX}[$X-1] = $X;
           }
        }

        if (join("", @{$self->{DataX}}) =~ /[^0-9\-]/) { die "You tried to input an illegal value to 'X'." };
        if (join("", @{$self->{DataY}}) =~ /[^0-9\-]/) { die "You tried to input an illegal value to 'Y'." };
        if ($self->{NextX} =~ /[^0-9\-]/) { die "You tried to input an illegal value to predict." };

        if ($#{$self->{DataY}} != $#{$self->{DataX}}) { die "Cannot run with different number of 'X' values." };
        if (!$self->{NextX}) { die "Cannot run with no data point which you want to predict a value." };


        # Calculate the Sum of Y, X, X*Y and X**2 values.
        for (my $X=0; $X <= $#{$self->{DataX}}; $X++) {
           $self->{SumY} += $self->{DataY}[$X];
           $self->{SumX} += $self->{DataX}[$X];
           $self->{SumXY} += ($self->{DataX}[$X] * $self->{DataY}[$X]);
           $self->{SumXX} += ($self->{DataX}[$X]**2);
        }

        $self->{N} = $#{$self->{DataX}}+1;              # Number of Elements
        $self->{AvgX} = $self->{SumX} / $self->{N};     # X Average
        $self->{AvgY} = $self->{SumY} / $self->{N};     # Y Average

        my $B1 = ($self->{N} * $self->{SumXY} - $self->{SumX} * $self->{SumY});
        my $B2 = ($self->{N} * $self->{SumXX} - $self->{SumX}**2 );
        my $B = $B1 / $B2;
        my $A = $self->{AvgY} - $B*$self->{AvgX};

        $self->{ForecastY} = $A + $B*$self->{NextX}; # The forecast
}

################################################################

=item F<dump>

Prints data for debuging propose.

 $FCAST->dump;

=item F<SumX>

Returns the sum of X values.

 my $SumOfX = $FCAST->{SumX};

=item F<SumY>

Returns the sum of Y values.

 my $SumOfY = $FCAST->{SumY};

=item F<SumXX>

Returns the sum of X**2 values.

 my $SumOfXX = $FCAST->{SumXX};

=item F<SumXY>

Returns the sum of X * Y values.

 my $SumOfXY = $FCAST->{SumXY};

=item F<AvgX>

Returns the average of X values.

 my $AvgX = $FCAST->{AvgX};

=item F<AvgY>

Returns the average of Y values.

 my $AvgY = $FCAST->{AvgY};

=item F<N>

Return the number of X values.

 my $N = $FCAST->{N};

=back

=cut

################################################################

sub dump {

        my $self = shift;
        print "\n\n";
        print "###########################################\n";
        print "      This is a Forecast dump              \n";
        print "###########################################\n";
        print "\n";
        if ($self->{N}) {
           print ".  Forecast Name   : ", $self->{ForecastName}, "\n";
           print ".  Number of elements: ", $self->{N}, "\n";
           print ".  --------------------------------------- \n";
           print ".  X Values\n\t", join(";  ", @{$self->{DataX}}), "\n";
           print ".  Sum of X values   : ", $self->{SumX}, "\n";
           print ".  --------------------------------------- \n";
           print ".  Y Values\n\t", join(";  ", @{$self->{DataY}}), "\n";
           print ".  Sum of Y values   : ", $self->{SumY}, "\n";
           print ".  --------------------------------------- \n";
           print ".  Sum of X*Y values : ", $self->{SumXY}, "\n";
           print ".  Sum of X**2 values: ", $self->{SumXX}, "\n";
           print ".  --------------------------------------- \n";
           print ".  Predict inputed   : ", $self->{NextX}, "\n";
           print ".  Forecast value    : ", $self->{ForecastY}, "\n";
           print ".  --------------------------------------- \n";
           print ".  Thanks for using Statistics::Forecast\n";
           print ".     contact: alexjfalcao\@hotmail.com\n\n";
        } else {
           print "Error: You have to use method <calc> \n";
           print "       before dump the values.\n";
           print "       Exiting with error code 255.\n";
           print "\n";
		   exit (255);
        }
}

=head1 EXAMPLE

   use Statistics::Forecast;

   my @Y = (1,3,7,12);
   my @X = (1,2,3,4);

   my $FCAST = Statistics::Forecast->new("My Forecast");

   $FCAST->{DataX} = \@X;
   $FCAST->{DataY} = \@Y;
   $FCAST->{NextX} = 8;
   $FCAST->calc;

   print "The Forecast ", $FCAST->{ForecastName};
   print " has the forecast value: ", $FCAST->{ForecastY}, "\n";

=head1 AUTHOR

This module was developed by Alex Falcao (alexjfalcao@hotmail.com)

=head1 STATUS OF THE MODULE

This is the first version and calculates forecast value.

=head1 VERSION

0.3

=head1 COPYRIGHT

This module is released for free public use under a GPL license.

=cut

1;
