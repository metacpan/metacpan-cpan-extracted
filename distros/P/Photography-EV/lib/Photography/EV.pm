package Photography::EV 0.07 {

  use strict;
  use warnings;
  use 5.020000;
  use experimental 'signatures';
  use base qw( Exporter );
  BEGIN {
    eval q{ 
      use POSIX qw( pow );
    };
    if($@)
    {
      *pow = sub ($x, $exponent)
      {
        my $value = 1;
        for(1..$exponent)
        {
          $value *= $x;
        }
        $value;
      }
    }
  }

  our @EXPORT_OK = qw( ev aperture shutter_speed );
  our @EXPORT = @EXPORT_OK;

# ABSTRACT: Calculate exposure value (EV)


  sub _round :prototype($)
  {
    return $_[0] ? int($_[0] + $_[0]/abs($_[0]*2)) : 0;
  }

  sub _log2 :prototype($)
  {
    return log($_[0])/log(2);
  }

  # returns the closest value in @$list to $exact
  # returns undef if @$list is empty
  sub _closest :prototype($$)
  {
    my($exact, $list) = @_;
    my $answer;
    my $diff;
    for(@$list)
    {
      my $maybe = abs($_ - $exact);
      if((!defined $answer) || $maybe < $diff)
      {
        $answer = $_;
        $diff = $maybe;
      }
    }
    $answer;
  }

  my @apertures = qw(
    1.0
    1.4
    2.8
    4.0
    5.6
    8.0
    11
    16
    22
    32
    45
    64
  );

  my @times = (
    (map { $_ * 60 } qw( 32 16 8 4 2 )),
    (                qw( 60 30 15 8 4 2 1)),
    (map { 1 / $_  } qw( 2 4 8 15 30 125 250 500 1000 2000 4000 8000 ))
  );


  sub ev ($aperture, $time)
  {
    return _round _log2 $aperture*$aperture/$time;
  }


  sub aperture ($ev, $time, $apertures = \@apertures )
  {
    return _closest sqrt pow(2, $ev)*$time, $apertures;
  }


  sub shutter_speed ($ev, $aperture, $times = \@times )
  {
    return _closest $aperture*$aperture/pow(2, $ev), $times;
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Photography::EV - Calculate exposure value (EV)

=head1 VERSION

version 0.07

=head1 SYNOPSIS

 use Photography::EV;
 my $ev = ev(5.6, 1/1000); # EV for f/5.6 at 1/1000s

=head1 DESCRIPTION

This module provides functions for calculating photographic
exposure values.  Some light meters can give readings in 
"Exposure Value" or EV.  On some cameras the exposure can 
be locked into a specific Exposure Value (EV), such that 
changing the aperture or shutter speed will adjust the 
shutter speed or aperture to maintain the same exposure.

=head1 FUNCTIONS

=head2 ev

 my $ev = ev($aperture, $time);

Takes the aperture (f-stop) and shutter speed (in seconds).
Returns the integer Exposure Value (EV).

=head2 aperture

 my $aperture = aperture($ev, $time);
 my $aperture = aperture($ev, $time, \@apertures);

Returns the correct aperture corresponding to the given EV and
shutter speed (in seconds).  By default returns the closest 
full stop aperture between 1 and 64.

If the optional third argument is given (a reference to a list of
possible aperture values), then the returned aperture will be
the closest possible from that list.  This is helpful, for example,
when you are using a lens that provides fractions of a stop.  My
Nikkor 50mm f/1.2 for example has stops at f/1.2, f/1.4, f/2, f/4
f/5.6, f/8, f/11 and f/16, so to get the correct aperture for 
1/60 at EV 9 for that lens:

 my $aperture = aperture(9, 1/60, [1.2,1.4,2,4,5.6,8,11,16]);

=head2 shutter_speed

 my $time = shutter_speed($ev, $aperture);
 my $time = shutter_speed($ev, $aperture, \@times);

Returns the correct shutter speed (in seconds) corresponding to
the given EV and aperture.  By default returns the closest
full stop between 1920s (32 minutes) and 1/8000s.

If the optional third argument is given (a reference to a list
of possible shutter speeds), then the returned shutter speed
will be the closest possible from that list.  This is helpful
for older cameras that have a different set of shutter speed
stops, or newer cameras that use half stop shutter speeds.
At least some Rolleiflex TLRs have shutter speeds of 1, 2, 5, 10,
25, 50, 100, 250, 500 instead of the modern values.  To get
the correct shutter speed for f/3.5 and EV 5:

 # map displayed shutter speed to 1/t to get time in seconds
 my $time = shutter_speed(6, 3.5, [map { 1/$_ } 1, 2, 5, 10, 25, 50, 100, 250, 500]);

=head1 CAVEATS

This module requires Perl 5.20 or better.

=head1 SEE ALSO

=over 4

=item L<http://en.wikipedia.org/wiki/Exposure_value>

=item L<Photography::DX>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
