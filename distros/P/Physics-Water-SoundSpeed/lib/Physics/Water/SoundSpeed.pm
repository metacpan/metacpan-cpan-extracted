package Physics::Water::SoundSpeed;

#use 5.010001;
use strict;
use warnings;

use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Physics::Water::SoundSpeed ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.92';

# Preloaded methods go here.

# ------------------------------------------------
# Class Data and methods
{
  my %default_hsh = (
    'ppm' => 35,
    'stdpres' => 0.101325,
    'density_pure' => 1000,
    'density_sea' => 1027
  );

  $default_hsh{'units'}  = 'SI';

  $default_hsh{'conv'}  =
  {
    'f2c' => 5/9,
    'ft2m' => 0.3048,
    'psi2kpa' => 6.89475729,
    'psi2mpa' => .00689475729,
    'm2ft' => 3.2808399
  };

  # Class methods
  sub set_defaults
  {
    my $class = shift @_;

    my %set_hsh;
    if (  ref($_[0]) eq "HASH" ) { %set_hsh = %{ $_[0] } }
    else                         { %set_hsh = @_         }

    # Merge with existing hash
    %default_hsh = ( %default_hsh, %set_hsh);

    return %default_hsh;
  }

  sub get_defaults
  {
    return %default_hsh;
  }
}

# --------------------------
sub new
{
  my $caller = shift @_;

  # In case someone wants to sub-class
  my $caller_is_obj  = ref($caller);
  my $class = $caller_is_obj || $caller;

  # Passing reference or hash
  my %arg_hsh;
  if ( ref($_[0]) eq "HASH" ) { %arg_hsh = %{ shift @_ } }
  else                        { %arg_hsh = @_ }

   # Override default hash with arguments
  my %conf_hsh = __PACKAGE__->get_defaults();

  %conf_hsh = (%conf_hsh, %arg_hsh); # overwrite defaults

  # The object data structure
  my $self = bless {
                    'units'  => $conf_hsh{'units'},
                    'conv'   => $conf_hsh{'conv'},
					'ppm' 	 => $conf_hsh{'ppm'},
					'stdpres' => $conf_hsh{'stdpres'},
					'density_pure' => $conf_hsh{'density_pure'},
					'density_sea' =>  $conf_hsh{'density_sea'},
					'err'    => ''
  }, $class;

  return $self;
}

sub sound_speed
{
  my $self = shift;
  my $arg1 = shift;
  my $arg2 = shift;

  if ( ( ref $arg1 eq 'ARRAY' ) && ( ref $arg2 eq 'ARRAY' ) )
  {
    # Input temp and pres arrays
    my @ss;
    for ( my $i = 0; $i <=  $#$arg1; $i++ )
    {
      push @ss, sound_speed_tp($self, $arg1->[$i],$arg2->[$i],);
    }
    return \@ss;
  }
  elsif ( ( ref $arg1 eq 'ARRAY' ) && ( not ref $arg2 ) && ( $arg2 =~ /\d+/ ) )
  {
    # Input temp array and constant pres
    my @ss;
    for ( my $i = 0; $i <= $#$arg1; $i++ )
    {
      push @ss, sound_speed_tp($self, $arg1->[$i],$arg2);
    }
    return \@ss;
  }
  elsif ( ( not ref $arg1 ) && ( $arg1 =~ /\d+/ ) && ( ref $arg2 eq 'ARRAY' )  )
  {
    # Input temp array and constant pres
    my @ss;
    for ( my $i = 0; $i <= $#$arg2; $i++ )
    {
      push @ss, sound_speed_tp($self, $arg1, $arg2->[$i]);
    }
    return \@ss;
  }
  elsif ( ref $arg1 eq 'ARRAY' )
  {
    # Input temp array only
    my @ss;
    foreach my $temp ( @$arg1 )
    {
      push @ss, sound_speed_t($self, $temp);
    }

    return \@ss;
  }
  elsif ( ( not ref $arg1 ) && ( $arg1 =~ /\d+/ ) && ( not ref $arg2 ) && ( $arg2 =~ /\d+/ )  )
  {
    # Input temp and pres scalars
    my $ss = sound_speed_tp($self, $arg1, $arg2);
    return $ss;
  }
  elsif ( $arg1 )
  {
    # Input temp scalar only
    my $ss = sound_speed_t($self, $arg1);
    return $ss;
  }

  $self->{'err'} = "Input not recognized";
  return '';
}

# Sound Speed as function of T
# Marczak Equation: W. Marczak (1997), Water as a standard in the measurements of speed of sound in liquids J. Acoust. Soc. Am. 102(5) pp 2776-2779.
sub sound_speed_t
{
  my $self = shift;
  my $temp = shift;

  if ( $self->{units} eq 'US' )
  {
    $temp = $self->{conv}->{f2c} * ( $temp - 32 );
  }

  my $ss =  (1402.385)
          + (5.038813 * $temp)
          - (5.799136 * 10**-2 * $temp**2)
          + (3.287156 * 10**-4 * $temp**3)
          - (1.398845 * 10**-6 * $temp**4)
          + (2.787860 * 10**-9 * $temp**5);

  if ( $self->{units} eq 'US' )
  {
    $ss = $ss * $self->{conv}->{'m2ft'};
  }

  return $ss;
}

# Sound Speed as function of T
# Belogol'skii, Sekoyan, Samorukova, Stefanov and Levtsov (1999), Pressure dependence of the sound velocity in distilled water, Measurement Techniques, Vol 42, No 4, pp 406-413.
sub sound_speed_tp
{
  my $self = shift;
  my $temp = shift;
  my $pres = shift;

  if ( $self->{units} eq 'US' )
  {
    $temp = $self->{conv}->{f2c} * ( $temp - 32 );
    $pres = $self->{conv}->{psi2mpa} * $pres;
  }

  my @a;
	$a[0][0] = 1402.38744;
	$a[1][0] = 5.03836171;
	$a[2][0] = -5.81172916 * 10**-2;
	$a[3][0] = 3.34638117 * 10**-4;
	$a[4][0] = -1.48259672 * 10**-6;
	$a[5][0] = 3.16585020 * 10**-9;
	$a[0][1] = 1.49043589;
	$a[1][1] = 1.077850609 * 10**-2;
	$a[2][1] = -2.232794656 * 10**-4;
	$a[3][1] = 2.718246452 * 10**-6;
	$a[0][2] = 4.31532833 * 10**-3;
	$a[1][2] = -2.938590293 * 10**-4;
	$a[2][2] = 6.822485943 * 10**-6;
	$a[3][2] = -6.674551162 * 10**-8;
	$a[0][3] = -1.852993525 * 10**-5;
	$a[1][3] = 1.481844713 * 10**-6;
	$a[2][3] = -3.940994021 * 10**-8;
	$a[3][3] = 3.939902307 * 10**-10;

  my $c0 = $a[0][0] + $a[1][0]*$temp + $a[2][0]*$temp**2 + $a[3][0]*$temp**3 + $a[4][0]*$temp**4 + $a[5][0]*$temp**5;

  my @M;
	$M[1] =   $a[0][1] + $a[1][1]*$temp + $a[2][1]*$temp**2 + $a[3][1]*$temp**3;
	$M[2] =   $a[0][2] + $a[1][2]*$temp + $a[2][2]*$temp**2 + $a[3][2]*$temp**3;
	$M[3] =   $a[0][3] + $a[1][3]*$temp + $a[2][3]*$temp**2 + $a[3][3]*$temp**3;
	my $ss = $c0 + $M[1] * ($pres - $self->{stdpres}) + $M[2] * ($pres - $self->{stdpres})**2 + $M[3] * ($pres - $self->{stdpres})**3;

  if ( $self->{units} eq 'US' )
  {
    $ss = $ss * $self->{conv}->{'m2ft'};
  }

  return $ss;

}

# - - - - - - - -
sub sound_speed_sea_tps
{
  my $self = shift;
  my $tm = shift;
  my $pr = shift;
  my $sl = shift || $self->{ppm};

  if ( $self->{units} eq 'US' )
  {
    $tm = $self->{conv}->{f2c} * ( $tm - 32 );
    $pr = $self->{conv}->{psi2mpa} * $pr;
  }

  $pr = $pr * 10; # Eqn is in bars

  print "====> $pr\n";

	my $C00=1402.388;
	my $C01=5.03830;
	my $C02=-5.81090*10**-2;
	my $C03=3.3432*10**-4;
	my $C04=-1.47797*10**-6;
	my $C05=3.1419*10**-9;
	my $C10=0.153563;
	my $C11=6.8999*10**-4;
	my $C12=-8.1829*10**-6;
	my $C13=1.3632*10**-7;
	my $C14=-6.1260*10**-10;
	my $C20=3.1260*10**-5;
	my $C21=-1.7111*10**-6;
	my $C22=2.5986*10**-8;
	my $C23=-2.5353*10**-10;
	my $C24=1.0415*10**-12;
	my $C30=-9.7729*10**-9;
	my $C31=3.8513*10**-10;
	my $C32=-2.3654*10**-12;
	my $A00=1.389;
	my $A01=-1.262*10**-2;
	my $A02=7.166*10**-5;
	my $A03=2.008*10**-6;
	my $A04=-3.21*10**-8;
	my $A10=9.4742*10**-5;
	my $A11=-1.2583*10**-5;
	my $A12=-6.4928*10**-8;
	my $A13=1.0515*10**-8;
	my $A14=-2.0142*10**-10;
	my $A20=-3.9064*10**-7;
	my $A21=9.1061*10**-9;
	my $A22=-1.6009*10**-10;
	my $A23=7.994*10**-12;
	my $A30=1.100*10**-10;
	my $A31=6.651*10**-12;
	my $A32=-3.391*10**-13;
	my $B00=-1.922*10**-2;
	my $B01=-4.42*10**-5;
	my $B10=7.3637*10**-5;
	my $B11=1.7950*10**-7;
	my $D00=1.727*10**-3;
	my $D10=-7.9836*10**-6;

	my $Cw = ($C00 + $C01*$tm + $C02*$tm**2 + $C03*$tm**3 + $C04*$tm**4 + $C05*$tm**5) +
	                   ($C10 + $C11*$tm + $C12*$tm**2 + $C13*$tm**3 + $C14*$tm**4)*$pr +
	                   ($C20 +$C21*$tm +$C22*$tm**2 + $C23*$tm**3 + $C24*$tm**4)*$pr**2 +
					   ($C30 + $C31*$tm + $C32*$tm**2)*$pr**3;

	my $A = ($A00 + $A01*$tm + $A02*$tm**2 +$A03*$tm**3 +$A04*$tm**4 ) +
					($A10 + $A11*$tm + $A12*$tm**2 +$A13*$tm**3 + $A14*$tm**4)*$pr +
					($A20 +$A21*$tm +$A22*$tm**2 +$A23*$tm**3)*$pr**2 +
					($A30 + $A31*$tm + $A32*$tm**2)*$pr**3;
	my $B = $B00 + $B01*$tm + ($B10 + $B11*$tm)*$pr;
	my $D = $D00+($D10*$pr);

	my $C = $Cw + $A*$sl + $B*$sl**(3/2) + $D*($sl**2);

    return $C;

}


# -------
sub d2p_fresh
{
  my $self = shift;
  my $depth = shift;

  return d2p($self,$depth,$self->{'density_pure'});
}

# -------
sub d2p_sea
{
  my $self = shift;
  my $depth = shift;

  return d2p($self,$depth,$self->{'density_sea'});
}

# Depth to pressure
sub d2p
{
  my $self = shift;
  my $depth = shift;
  my $density = shift || $self->{'density_pure'};

  if ( ref $depth eq 'ARRAY' )
  {
    my @pres;
    foreach my $d (@$depth)
    {
      if ( $self->{units} eq 'US' ) { $d = $self->{conv}->{ft2m} * $d }
      push @pres, ( $density * 9.807 * $d  / 1000000 + $self->{stdpres});
    }

    return \@pres;
  }

  if ( $depth =~ /\d+/)
  {
    if ( $self->{units} eq 'US' ) { $depth = $self->{conv}->{ft2m} * $depth }
    my $pres = $density * 9.807 * $depth / 1000000 + $self->{stdpres};

    return $pres;
  }

  $self->{'err'} = "Input Not Recognized\n";
  return '';

}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Physics::Water::SoundSpeed - Perl module to calculate the speed of sound in pure water and sea water
as a function of temperature (and pressure)

=head1 SYNOPSIS

    use Physics::Water::SoundSpeed;
    
    $Sound = new Physics::Water::SoundSpeed();

Simplist usage as a function of temperature

    $ss = $Sound->soundspeed(21);
    print "The speed of sound in pure water is $ss meters/sec at 21 degrees\n";

Or as a function of temperature and pressure

    $ss = $Sound->soundspeed(21,7);  # Input in degrees C / MPa
    print "The speed of sound in pure water is $ss meters/sec at 21 C and 7 MPa\n";

Both sound speed functions accept references to arrays and returns a reference to an array.
Obviously arrays need to be the same size and the same size array (as a ref) is returned.

    @t_lst = ( 50,70 );
    $ss = $Sound->soundspeed( \@t_lst );
    print "The speed of sound at $t_lst->[0] C is $ss->[0] and at $t_lst->[1] is $ss->[1]\n";

    @p_lst = ( 0.1, 1);
    $ss = $Sound->soundspeed( \@t_lst, \@p_lst ); # Returns a ref to array with sound speed for each pair of t and p

However you can enter a scalar (single value) for either the temperature or pressure
and an array ref for the other input - good for isothermal or isobaric calcs. Such as

    $ss = $Sound->soundspeed( 10, \@p_lst ); # Isothermal calcs with temperature at 10 C

    $ss = $Sound->soundspeed( \@p_lst, 0.1 ); # Isobaric calcs with pressure 0.1 MPa

Also there is function to calculate the speed of sound in sea water as a function
of temperature, pressure and salinity. The inputs to this function must all be scalars.
The equation by Chen and Millero is used.

    $ss = $obj->sound_speed_sea_tps( 5, 1, 35);
    print "Speed Sound in Sea Water at 5 C, 1 MPa, 35 ppm -> $ss\n";

Simple hydrostatic pressure from depth functions are available for fresh and sea water. These
functions take either a scalar or a reference to array 

    @dp = (0,50,100,150,200,250,300,350,400,450,500,600,700,800,900,1000); # In Meters
    $pr = $obj->d2p_fresh( \@dp ); # Returned is a ref to array with pressure in MPa for each depth

    $pr = $obj->d2p_sea( \@dp ); # Returned is a ref to array with pressure in MPa for each depth

    $pr = $obj->d2p_sea( 50 );   # Returned is scalar for the given pressure 
    
    
SI Units (Meters, Seconds, MPa) are default however you can switch to us US Customary units when creating
the object. US Customary units used are ft, sec, psi. Here is how to use the above functions in US Customary.

    $Sound = new Physics::Water::SoundSpeed( 'units'=>'US' );  # Switch back using 'SI'

    $ss = $Sound->soundspeed_t(72);
    print "The speed of sound in pure water is $ss ft/sec at 72 degrees F\n";
   
Finally the defaults used in these calculation are

* Salinity for Sea Water 'ppm' => 35 ppm

* Standard Pressure 'stdpres' => 0.101325 MPa

* Density of pure water   'density_pure' => 1000 kg/m**3

* Density of sea water   'density_sea' => 1027 kg/m**3

These can be overwritten on object creation such as

    $Sound = new Physics::Water::SoundSpeed( 'ppm' => 35,'stdpres' => 0.101,'density_pure' => 1000,'density_sea' => 1027 );


=head1 DESCRIPTION


This module Physics::Water::SoundSpeed calculates the speed of sound in pure water for a given temperature
and pressure and Sea water for a given temperature, pressure and salinity. Defaults units are SI Meters, Seconds, MPa

=head2 EXPORT

None by default.

=head1 SEE ALSO

B<Pure Water>

The calculations are based on those found in a technical report
"Speed of Sound in Pure Water" by the National Physical Laboratory

http://resource.npl.co.uk/acoustics/techguides/soundpurewater/

More specifically for speed of sound as a fuction of temperature the Marczak equation is used.

I<W. Marczak (1997), Water as a standard in the measurements of speed of sound in liquids J. Acoust. Soc. Am. 102(5) pp 2776-2779.>

For speed of sound as a function of temperature and pressure an equation developed by Belogol'skii, Sekoyan et al
is used.

B<Sea Water>

V.A. Belogol'skii, S.S. Sekoyan, L.M. Samorukova, S.R. Stefanov and V.I. Levtsov (1999), Pressure dependence of the sound velocity in distilled water, Measurement Techniques, Vol 42, No 4, pp 406-413.

For Sea Water Calculation see

http://resource.npl.co.uk/acoustics/techguides/soundseawater/content.html

Specifically the UNESCO equation by Chen and Millero is used for Sea Water calculations with salinity defaulted to 35 ppm.

I<C-T. Chen and F.J. Millero, Speed of sound in seawater at high pressures (1977) J. Acoust. Soc. Am. 62(5) pp 1129-1135>

Sound Speed in water along isotherms and isobars plotted as a test using this module are available at   

http://perlworks.com/cpan/Physics-Water-SoundSpeed/misc/Sound-Speed-in-Water.html


=head1 AUTHOR

troxel@REMOVEME perlworks.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steven Troxel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
