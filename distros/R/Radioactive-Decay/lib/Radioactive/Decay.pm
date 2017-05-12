package Radioactive::Decay;

=head1 NAME

Radioactive::Decay - allow scalar values to decay over time

=head1 SYNOPSIS

  use Radioactive::Decay;

  my $halflife = 10;
  tie my $var, $Radioactive::Decay, $halflife;

  $var = 40;
  sleep 10;
  print $var;  # 20
  sleep 10;
  print $var;  # 10

=head1 DESCRIPTION

This allows you to tie a scalar variable so that it will decay over
time. 

For example, if you set a half-life of 30 seconds, then a variable which
is set to 100 now will be 25 in a minute's time.

We're sure there are all manner of useful applications for this, and
hopefully someone will let us know what they are.

=head1 AUTHOR

Tony Bowden and Marty Pauley

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Radioactive-Decay@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2000-2005 Tony Bowden, Marty Pauley

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License; either version
  2 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

$VERSION = "1.00";
use strict;

sub TIESCALAR { bless [0,log(2)/$_[1], time], $_[0]; }
sub STORE     { $_[0]->[0] = $_[1] }
sub FETCH     { $_[0]->[0] * exp(-$_[0]->[1] * (time - $_[0]->[2])) }
sub DESTROY   {}

return q/
  make me laugh make me cry enrage me don't try to disengage me
/;

