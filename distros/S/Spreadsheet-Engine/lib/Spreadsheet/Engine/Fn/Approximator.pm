package Spreadsheet::Engine::Fn::Approximator;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw/iterate/;

sub iterate {
  my %arg = @_;

  my $guess   = $arg{initial_guess}  || 0.01;
  my $maxloop = $arg{max_iterations} || 20;
  my $epsilon = $arg{epsilon}        || 0.0000001;

  my $value    = $guess;
  my $oldvalue = 0;
  my $delta    = 1;
  my $olddelta;
  my $factor;
  my $tries = 0;

  while (abs($delta) > $epsilon && ($value != $oldvalue)) {
    $delta = $arg{function}->($value);

    if (defined $olddelta) {
      my $m = ($delta - $olddelta) / ($value - $oldvalue);    # get slope
      $oldvalue = $value;
      $value    = $value - $delta / ($m || 0.01);    # look for zero crossing
      $olddelta = $delta;
    } else {    # first time - no old values
      $oldvalue = $value;
      $value    = 1.1 * $value;
      $olddelta = $delta;
    }

    # error if we don't converge quickly enough
    return if (++$tries >= $maxloop);
  }

  return $value;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Fn::Approximator - Solve using Newton's method

=head1 SYNOPSIS

  my $answer = iterate(
    initial_guess => 0.3,
    maximum_iterations => 50,
    epsilon => 0.0001,
    function => sub { 
      my $value = shift;
      return calculate_next_guess($value);
    }
  );

=head1 DESCRIPTION

This iterates towards an approximate result using the Newtown-Raphson
method.

=head1 EXPORTS

=head2 iterate

This must be passed a 'function' to calculate the next guess given the
previous one. It should also be passed an initial guess.

It may also be given a maximum number of iterations and/or an epsilon for how
close an answer is accepable.

=head1 HISTORY

This is a Modified Version of code extracted from SocialCalc::Functions
in SocialCalc 1.1.0

=head1 COPYRIGHT

Portions (c) Copyright 2005, 2006, 2007 Software Garden, Inc.
All Rights Reserved.

Portions (c) Copyright 2007 Socialtext, Inc.
All Rights Reserved.

Portions (c) Copyright 2008 Tony Bowden

=head1 LICENCE

The contents of this file are subject to the Artistic License 2.0;
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
  http://www.perlfoundation.org/artistic_license_2_0


