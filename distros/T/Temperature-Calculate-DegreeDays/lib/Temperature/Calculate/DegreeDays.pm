package Temperature::Calculate::DegreeDays;

use 5.006;
use strict;
use warnings;
use Carp qw(carp croak);
use Scalar::Util qw(looks_like_number reftype);

=head1 NAME

Temperature::Calculate::DegreeDays - Perl package to compute cooling, heating, and growing degree days

=head1 VERSION

Version 0.50

=cut

our $VERSION = '0.50';

=head1 SYNOPSIS

 use Temperature::Calculate::DegreeDays;
 
 # Default params
 my $dd_degF  = Temperature::Calculate::DegreeDays->new();
 # Try cooling and heating degree days in degC, and wheat growing degree days instead of corn!
 my $dd_degC  = Temperature::Calculate::DegreeDays->new({
    BASE     => 18,
    GBASE    => 0,
    GCEILING => 27,
    MISSING  => -9999
 });
 
 my $daily_high_temperature = 80;
 my $daily_low_temperature  = 60;
 my $cdd = $dd_degF->cooling($daily_high_temperature,$daily_low_temperature);  # Result is 5
 my $hdd = $dd_degF->heating($daily_high_temperature,$daily_low_temperature);  # Result is 0
 my $gdd = $dd_degF->growing($daily_high_temperature,$daily_low_temperature);  # Result is 20

=head1 DESCRIPTION

A degree day is a measure of sensible temperature compared to a baseline 
temperature, typically integrated over time. Degree days have numerous 
applications in agriculture, as temperatures during the growing season have a 
direct impact on crop growth progress. Degree days also support energy usage 
monitoring, as the costs to heat and cool climate controlled structures is 
directly related to outdoor temperatures. The simplest method to calculate degree 
days is to compare the daily mean temperature (the average of the daily high and low 
observed temperatures) to a baseline temperature. This is how degree days are 
L<defined by the United States National Weather Service|https://forecast.weather.gov/glossary.php?word=degree%20day>.

The Temperature::Calculate::DegreeDays package provides methods to calculate 
the following types of degree days:

=over 4

=item * Cooling degree days - zero if the baseline temperature exceeds the mean, otherwise the difference between the mean and baseline rounded to the nearest integer

=item * Heating degree days - zero if the mean temperature exceeds the baseline, otherwise the difference between the baseline and mean rounded to the nearest integer

=item * Growing degree days - same as cooling degree days, but when calculating the daily mean, temperatures exceeding a maximum "ceiling" value are set to the ceiling value

=back

This package was designed using an object-oriented framework, with a constructor 
method (new) that returns a blessed reference. The object stores the baseline 
temperature for heating and cooling degree days, a separate baseline temperature 
for growing degree days, a growing degree days ceiling temperature, and a value to 
be interpreted as missing data. The various degree days methods are designed to 
handle missing or invalid input data gracefully by returning the missing data value, 
but will fail if the caller does not supply the required number of arguments.

=head1 METHODS

=head2 new

 my $dd_degF    = Temperature::Calculate::DegreeDays->new();
 my $dd_degC    = Temperature::Calculate::DegreeDays->new({BASE => 18});
 my $dd_degC_2  = Temperature::Calculate::DegreeDays->new({
    BASE  => 18,
    GBASE => 0,
    GCEIL => 27,
    MISSING => -9999
 });

Constructs a Temperature::Calculate::DegreeDays object (L<blessed reference|https://perldoc.perl.org/perlobj>) 
and returns it to the calling program. The default object data can be changed by 
passing a L<hashref|https://perldoc.perl.org/perlref> argument with some or all 
of the following parameters:

 $params = {
    BASE     => [baseline temperature for cooling and heating degree days],
    GBASE    => [baseline temperature for growing degree days],
    GCEILING => [ceiling/heat threshold temperature for growing degree days]
    MISSING  => [missing value]
 }

If supplied, these parameters must have defined and numeric values or the constructor will 
L<croak|https://perldoc.perl.org/Carp>. If not supplied, the default values are C<BASE = 65>, 
C<GBASE = 50> and C<GCEILING = 86>, which is how the US National Weather Service defines cooling, 
heating, and corn (maize) growing degree days in degrees Fahrenheit. The default missing value 
is C<MISSING = NaN>.

=cut

sub new {
    my $class         = shift;
    my $self          = {};
    # Set defaults
    $self->{BASE}     = 65;
    $self->{GBASE}    = 50;
    $self->{GCEILING} = 86;
    my $inf           = exp(~0 >> 1);
    my $nan           = $inf / $inf;
    $self->{MISSING}  = $nan;

    if(@_) {
        my $arg = shift;
        # Assume the caller did something wrong and croak if the arg is not a hash ref
        unless(reftype($arg) eq 'HASH') { croak "Argument must be a hash reference"; }

        # Check for each allowed key in the hash ref, croak if the value is undef or non-numeric

        foreach my $param (qw(BASE GBASE GCEILING MISSING)) {

            if(exists($arg->{$param})) {
                croak "Invalid $param param" unless(defined($arg->{$param}) and looks_like_number($arg->{$param}));
                $self->{$param} = $arg->{$param};
            }

        }

    }

    bless($self,$class);
    return $self;
}

=head2 cooling

 my $maxT = 88;
 my $minT = 60;
 my $mean = ($maxT + $minT) / 2;
 my $cdd  = $dd->cooling($maxT,$minT); # Order of the args does not matter
 $cdd     = $dd->cooling($mean);       # Same result

Given one temperature argument taken to be the daily mean temperature, or two 
arguments taken to be the daily maximum and minimum temperatures, returns the 
cooling degree days accumulated to the nearest integer. If the argument value(s) 
are undefined, non-numeric, NaN, or equal to the missing value, the missing value 
is returned. The method will croak if no argument is supplied.

=cut

sub cooling {
    my $self = shift;
    my $tmean;

    # In case the caller stupidly set the base param to missing or NaN...
    return $self->{MISSING} if($self->{BASE} == $self->{MISSING} or not defined($self->{BASE} <=> 0));

    if(not @_)     {
        croak "No argument supplied";
    }
    if(@_ == 1)    {
        $tmean   = shift;
        if(not defined($tmean) or not looks_like_number($tmean) or $tmean == $self->{MISSING} or not defined($tmean <=> 0)) { return $self->{MISSING}; }
    }
    elsif(@_ >= 2) {
        my $tmax = shift;
        my $tmin = shift;
        if(not defined($tmax) or not looks_like_number($tmax) or $tmax == $self->{MISSING} or not defined($tmax <=> 0))     { return $self->{MISSING}; }
        if(not defined($tmin) or not looks_like_number($tmin) or $tmin == $self->{MISSING} or not defined($tmin <=> 0))     { return $self->{MISSING}; }
        $tmean   = ($tmax + $tmin) / 2;
    }

    return $tmean > $self->{BASE} ? int($tmean - $self->{BASE} + 0.5) : 0;
}

=head2 heating

 my $maxT = 50;
 my $minT = 35;
 my $mean = ($maxT + $minT) / 2;
 my $hdd  = $dd->heating($maxT,$minT); # Order of the args does not matter
 $hdd     = $dd->heating($mean);       # Same result

Given one temperature argument taken to be the daily mean temperature, or two
arguments taken to be the daily maximum and minimum temperatures, returns the
heating degree days accumulated to the nearest integer. If the argument value(s)
are undefined, non-numeric, NaN, or equal to the missing value, the missing value 
is returned. The method will croak if no argument is supplied.

=cut

sub heating {
    my $self = shift;
    my $tmean;

    # In case the caller stupidly set the BASE param to missing or NaN...
    return $self->{MISSING} if($self->{BASE} == $self->{MISSING} or not defined($self->{BASE} <=> 0));

    if(not @_)     {
        croak "No argument supplied";
    }
    if(@_ == 1)    {
        $tmean   = shift;
        if(not defined($tmean) or not looks_like_number($tmean) or $tmean == $self->{MISSING} or not defined($tmean <=> 0)) { return $self->{MISSING}; }
    }
    elsif(@_ >= 2) {
        my $tmax = shift;
        my $tmin = shift;
        if(not defined($tmax) or not looks_like_number($tmax) or $tmax == $self->{MISSING} or not defined($tmax <=> 0))     { return $self->{MISSING}; }
        if(not defined($tmin) or not looks_like_number($tmin) or $tmin == $self->{MISSING} or not defined($tmin <=> 0))     { return $self->{MISSING}; }
        $tmean   = ($tmax + $tmin) / 2;
    }

    print return $tmean < $self->{BASE} ? int($self->{BASE} - $tmean + 0.5) : 0;
}

=head2 growing

 my $maxT = 90;
 my $minT = 70;
 my $gdd  = $dd->growing($maxT,$minT); # Order of args does not matter

Given two arguments taken to be the daily maximum and minimum temperatures, returns 
the growing degree days accumulated to the nearest integer. If the argument values
are undefined, non-numeric, NaN, or equal to the missing value, the missing value is
returned. If fewer than two arguments are supplied, the method will croak.

=cut

sub growing {
    my $self = shift;

    # In case the caller stupidly set the GBASE or GCEILING params to missing or NaN...
    return $self->{MISSING} if($self->{GBASE} == $self->{MISSING} or $self->{GCEILING} == $self->{MISSING} or not defined($self->{GBASE} <=> 0) or not defined($self->{GCEILING} <=> 0));

    if(not @_ or @_ < 2) {
        croak "Two arguments were not supplied";
    }

    my $tmax = shift;
    my $tmin = shift;
    if(not defined($tmax) or not looks_like_number($tmax) or $tmax == $self->{MISSING} or not defined($tmax <=> 0)) { return $self->{MISSING}; }
    if(not defined($tmin) or not looks_like_number($tmin) or $tmin == $self->{MISSING} or not defined($tmin <=> 0)) { return $self->{MISSING}; }
    if($tmax > $self->{GCEILING}) { $tmax = $self->{GCEILING}; }
    if($tmin > $self->{GCEILING}) { $tmin = $self->{GCEILING}; }
    my $tmean   = ($tmax + $tmin) / 2;
    return $tmean > $self->{GBASE} ? int($tmean - $self->{GBASE} + 0.5) : 0;
}

=head1 INSTALLATION

The best way to install this module is with a CPAN client, which will resolve and 
install the dependencies:

 cpan Temperature::Calculate::DegreeDays
 cpanm Temperature::Calculate::DegreeDays

You can also install the module directly from the distribution directory after 
downloading it and extracting the files, which will also install the dependencies:

 cpan .
 cpanm .

If you want to install the module manually do the following in the distribution 
directory:

 perl Makefile.PL
 make
 make test
 make install

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

 perldoc Temperature::Calculate::DegreeDays

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Temperature-Calculate-DegreeDays>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Temperature-Calculate-DegreeDays>

=item * Search CPAN

L<https://metacpan.org/release/Temperature-Calculate-DegreeDays>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-temperature-calculate-degreedays at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Temperature-Calculate-DegreeDays>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Adam Allgood

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Adam Allgood.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1; # End of Temperature::Calculate::DegreeDays
