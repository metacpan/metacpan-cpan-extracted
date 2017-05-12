#
# Author: Jaap Voets - Xperience Automatisering
# A van der Waals Gas Blender
# 
#
package SCUBA::Blender;

use strict;
use Carp;

our $VERSION = '0.1';

# vanderwaals constants
my %GASES;
$GASES{'AIR'}{'a'} = 1.3725; 
$GASES{'AIR'}{'b'} = 0.0372;
$GASES{'AIR'}{'weight'} = 28.84;  # gram /mole
$GASES{'O2'}{'a'} = 1.382; 
$GASES{'O2'}{'b'} = 0.0318;
$GASES{'O2'}{'weight'} = 32;  # gram /mole
$GASES{'N2'}{'a'} = 1.37; 
$GASES{'N2'}{'b'} = 0.0387;
$GASES{'N2'}{'weight'} = 28;  # gram /mole
$GASES{'HE'}{'a'} = 0.0346; 
$GASES{'HE'}{'b'} = 0.0238;
$GASES{'HE'}{'weight'} = 4;  

# Universal Gas Constant when using Bar and Liters
use constant R => 0.08314472;

sub new {
    my $class = shift;
    my $self  = {};
    bless($self, $class);
    
    # start with empty gas list
    $self->{start}->{pressure} = 0; # bar
    $self->{start}->{mix}      = { '02' => 0.21, 'N2' => 0.79, 'HE' => 0, 'AIR' => 0}; # start with air
    $self->{end}->{pressure}   = 200; # bar
    $self->{end}->{mix}        = { '02' => 0.21, 'N2' => 0.79, 'HE' => 0, 'AIR' => 0}; # end with air by default
    $self->{temperature}       = 293; # Kelvin
    $self->{volume}            = 10;  #liter
    $self->{fillorder}         = ['O2','HE','AIR'];
    
    # place holders for result of calculation
    $self->{results}           = {};

    return $self;
}

# set temperature
sub temperature {
    my $self = shift;
    my $temp = shift;
    if ($temp < 100) {
        # sounds like celsius
        $temp += 273;  # make kelvin
    }   
    $self->{temperature} = $temp;
}

sub volume {
    my $self = shift;
    my $volume = shift;
    $self->{volume} = $volume;
}

# set starting values
# first param is pressure, rest is gas list with percentages
sub start_mix {
    my $self = shift;
    my $pressure = shift;
    $self->{start}->{mix}      = $self->_gasfractions( @_ );
    $self->{start}->{pressure} = $pressure;
}

# e.g.
# mixer->end_mix(210, 'O2' => 32, 'N2' => 68);
sub end_mix {
    my $self = shift;
    my $pressure = shift;
    $self->{end}->{pressure} = $pressure;
    $self->{end}->{mix}      = $self->_gasfractions( @_ );  
}

# set the fill order of the gases
sub fill_order {
    my $self = shift;
    $self->{fillorder} = [];
    my @gases = @_;
    foreach my $gas (@gases) {
        $gas = uc($gas);
        if (exists $GASES{$gas}) {
            push @{$self->{fillorder}}, $gas;           
        } else {
            croak "Unknown gas $gas!";
        }
    }
    
}

# set fractions 
sub _gasfractions {
    my $self    = shift;
    my %gaslist = @_;
   
    # first make empty list based on %GASES
    my %fractions;
    foreach my $gas (keys %GASES) {
        $fractions{$gas} = 0;
    }
    
    my $totalfraction = 0;
    foreach my $key (keys %gaslist) {
        my $gas = uc($key);
        if (exists $GASES{$gas} ) {
            my $fraction = $gaslist{$key};
            $fraction = $fraction / 100 if ($fraction > 1);
            $fractions{$gas} = $fraction;
            $totalfraction += $fraction;
        } else {
            croak "Unknown gas $key!";
        }
    }
    # maybe they left out nitrogen, so complement the mix
    if ($totalfraction < 1.0) {
        $fractions{'N2'} = 1 - $fractions{'O2'} - $fractions{'HE'};            
    }
   
    return \%fractions;
}

# determine new A & B depending on mix of gases
# note: this depends on the MOLAR fractions, not the partial pressure fractions
sub compositeAB {
    my $self        = shift;
    my $gaslist_ref = shift;

    my $a = 0;
    my $b = 0;
    foreach my $gas1 ( keys %{ $gaslist_ref } ) {
        foreach my $gas2 ( keys %{ $gaslist_ref } ) {
            $a += sqrt( $GASES{$gas1}{a} * $GASES{$gas2}{a} ) * $gaslist_ref->{$gas1} *  $gaslist_ref->{$gas2};
            $b += sqrt( $GASES{$gas1}{b} * $GASES{$gas2}{b} ) * $gaslist_ref->{$gas1} *  $gaslist_ref->{$gas2};
        }
    }
    return ($a, $b); 
}


# do the calculation
sub calc {
    my $self = shift;
    
    # determine starting moles of each gas and the corresponding composite a and b values
    my ($a_start, $b_start) = $self->compositeAB( $self->{start}->{mix} );    
    # and the initial molar amounts of each gas (hashref)
    my $start_moles = _molesInMix( $self->{start}->{mix}, $self->{start}->{pressure}, $self->{temperature}, $self->{volume}, $a_start, $b_start);
    _adjustforAir($start_moles);
    
    # same for the end mix
    my ($a_end, $b_end) = $self->compositeAB( $self->{end}->{mix} );    
    my $end_moles = _molesInMix( $self->{end}->{mix}, $self->{end}->{pressure}, $self->{temperature}, $self->{volume}, $a_end, $b_end);
    _adjustforAir($end_moles);

    # we now know how much to add for each gas
    my %add_moles;
    foreach my $gas (keys %GASES) {
        $add_moles{$gas} = $end_moles->{$gas} - $start_moles->{$gas};
    }

    # so let's see how we fill the tank in bars instead of moles
    my $mix = $start_moles;
    
    # it's determined by the fillorder
    my $previous_pressure = $self->{start}->{pressure};
    foreach my $gas ( $self->_order_all() ) {
    
        if ($add_moles{$gas} != 0 ) {
            $mix->{$gas} += $add_moles{$gas};
    
            $self->{results}->{$gas}->{mole_add}   = $add_moles{$gas};
            $self->{results}->{$gas}->{mole_total} = $mix->{$gas};
            $self->{results}->{$gas}->{weight}     = $mix->{$gas} * $GASES{$gas}{weight}; # in grams

            # get the new fractions of this fresh mix
            my ($gas_fractions, $moles) = _recalc_fractions($mix);
            
            # then calculate the new a and b
            my ($a, $b) = $self->compositeAB( $gas_fractions );
        
            # and get the pressure to fill to with these params
            # (P + a*n^2/V^2)*(V - n*b) = n*R*T
            # so P = (n*R*T) / (V - n*b)  - a*n^2/V^2
            my $P = ($moles * R * $self->{temperature}) / ( $self->{volume} - $moles * $b) - $a * _sqr($moles / $self->{volume});
            
            $self->{results}->{$gas}->{end_pressure} = $P;
            $self->{results}->{$gas}->{pressure}     = $P - $previous_pressure;
            
            $previous_pressure = $P;
        }
    }
}

# make a human friendly string of the mix
sub mix_to_string {
    my $self    = shift;
    my $mix_ref = shift;

    my $string = '';
    $string .= int($mix_ref->{'O2'} * 100) . "% O2";
    if ($mix_ref->{'HE'} > 0 ) {
        $string .= ', ' . int($mix_ref->{'HE'} * 100) . "% He";
    }
    
    return $string;
}

# get all gases, but preserve the fill order
sub _order_all {
    my $self = shift;
    my @order = @{ $self->{fillorder} };
    foreach my $gas ( keys %GASES ) {
        if ( ! grep ( { /$gas/ } @order)  ) {
             push  @order, $gas;
        }
    }
    return @order;                                    
}

# make a nice report of the results
sub report {
    my $self = shift;
    my $report = '';

    my $desired_mix = $self->mix_to_string( $self->{end}->{mix} );
    my $start_mix   = $self->mix_to_string( $self->{start}->{mix} );
    $report .= 'To fill a tank of ' . $self->{volume} . " liters with $desired_mix to a pressure of " . $self->{end}->{pressure} . " bar\n";
    $report .= "starting with $start_mix at a pressure of " . $self->{start}->{pressure} . " bar\n\n";

    my $total_weight = 0;
    foreach my $gas ( $self->_order_all() ) {
         if (exists $self->{results}->{$gas} ) {
             $report .= "add $gas to " . int($self->{results}->{$gas}->{end_pressure}) . " bar"; 
             $report .= " (adding " . int($self->{results}->{$gas}->{pressure}) . " bars)\n";
             $total_weight += $self->{results}->{$gas}->{weight};           
        }
    }

    $report .= "\ntotal weight of mix is " . int($total_weight) . " grams\n";
    return $report;
}

# get a mix of moles
# and return the same mix as fractions
sub _recalc_fractions {
    my $mix = shift;
    my $frac = {};
    my $total_moles = 0;

    foreach my $gas ( %{ $mix } ) {
        $total_moles += $mix->{$gas};
    }
    
    if ($total_moles > 0) {
        foreach my $gas ( %{ $mix } ) {
            $frac->{$gas} = $mix->{$gas} / $total_moles; 
        }
    }
    return ($frac, $total_moles);
}

# solve the vanderwaals equation for n 
# (P + a*n^2/V^2)*(V - n*b) = n*R*T
# for a mix with a composite a and b
# this will give the TOTAL number of moles of the gas
#
# we will be using a newton iteration
sub _molesInMix {
    my ($mix_ref, $P, $T, $V, $a, $b) = @_;

    my $n = 1;
    my $success = 0;

    my $max_iteration = 100;
    my $epsilon       = 0.0001;
    # function to solve
    for (my $i = 1; $i < $max_iteration; $i++) {
        my $function_val = ( $P + $a * _sqr($n / $V)) * ( $V - $n*$b) - $n * R * $T;
        # dF/dn = -b*P + 2a*n/V - 3ab * n^2/V^2 -RT 
        my $funcderiv_val   = -1 * $P * $b + 2 * $a * $n/$V -3 * $a * $b * _sqr($n/$V) - R * $T;
        # calculate new n
        $n = $n - $function_val/$funcderiv_val;
        if ( abs( $function_val ) < $epsilon ) {
            # we are close enough to the root
            $success = 1;
            last;
        }
    }   
    if ($success) {
        my $moles_mix = {};
        foreach my $gas (keys %{ $mix_ref } ) {
            $moles_mix->{$gas} = $mix_ref->{$gas} * $n;
        }
        return $moles_mix;
    } else {
        croak "Couldn't solve";
    }
    
}

# we do not fill with pure nitrogen
# but with air
# so correct both the nitrogen and oxygen parts
sub _adjustforAir {
    my $mix_ref = shift;
    # the nitrogen comes from the air, so we know how much air we need
    $mix_ref->{'AIR'} = $mix_ref->{'N2'} / 0.79;
    $mix_ref->{'O2'}  = $mix_ref->{'O2'} - 0.21 * $mix_ref->{'AIR'};
    # now clear the pure nitrogen part
    $mix_ref->{'N2'} = 0;
}

# square a number
sub _sqr {
    my $n = shift;
    return ($n * $n);
}

1;
__END__

=head1 NAME

SCUBA::Blender - Module for calculating gas pressures for blending Nitrox or Trimix 

=head1 SYNOPSIS

use SCUBA::Blender;

my $blender = new SCUBA::Blender()

# start with 20 bar of air

$blender->start_mix( 20, 'O2' => 21);

# calculate for 230 bar of Nitrox 32%

$blender->end_mix( 230, 'O2' => 32);

$blender->calc();

print $blender->report();

=head1 EXPORT

None by default.

=head1 DESCRIPTION

This package uses the van der Waals equation to calculate the needed pressures for blending Nitrox and Trimix for (technical) scuba diving.

You set the starting pressure and mix (leftover gases from previous dive) and specify the desired mix and pressure. The program will then calculate how much of each gas you have to add. With the ideal gas law you are usually not too much off when blending Nitrox to 200 bar.
But with Helium and higher pressures, van der Waals is much preciser.

At the moment the SCUBA::Blender package is metric only.

=head2 METHODS

=over 4

=item new()

Constructor, creates a new blender object.

E.g. my $blender = new SCUBA::Blender;

=item volume( $volume )

Set the volume of the tank used to blend in. Defaults to 10 liters.

E.g. $blender->volume(24);

=item temperature( $temperature ) 

Set the temperature of the gas mix. Defaults to 20 degrees celsius (293 Kelvin)

E.g $blender->temperature( 10 );

=item start_mix( $pressure, $gas1 => $percentage1, $gas2 => $percentage2 , ...)

Set the mix to start with (that is the stuff left in your tank from a previous dive), 
pressure should be given in bar. Valid gases are O2 (oxygen), He (helium) , N2 (nitrogen). You can omit the N2 and He.
When N2 is missing , it will be calculated based upon the other percentages. Missing Helium will result in a Nitrox blend instead of a trimix one.

Examples:

25 bar of air left:  
 $blender->start_mix( 25, 'O2' => 21 );

40 bar of nitrox 33%: 
 $blender->start_mix( 40, 'O2' => 33 );

70 bar of trimix 16/50:  
 $blender->start_mix( 70, 'O2' => 16, 'He' => 50);

=item end_mix( $pressure, $gas1 => $percentage1, ...)

Same as with start_mix().

E.g. I want 235 bar of trimix 13/60

 $blender->start_mix( 235, 'O2' => 13, 'He' => 60);
 
=item calc()

Perform the actual calculation

E.g. $blender->calc();

=item report()

Return the results of the calculation.

E.g. print $blender->report();

=back

=head1 AUTHOR

Jaap Voets, E<lt>narked@xperience-automatisering.nlE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jaap Voets

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
