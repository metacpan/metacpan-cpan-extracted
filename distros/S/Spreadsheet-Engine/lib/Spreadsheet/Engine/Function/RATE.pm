package Spreadsheet::Engine::Function::RATE;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::investment';

use Spreadsheet::Engine::Fn::Approximator 'iterate';

sub argument_count { -3 => 6 }
sub signature { 'n', 'n', 'n', 'n', 'n', 'n' }
sub result_type { Spreadsheet::Engine::Value->new(type => 'n%') }

sub calculate {
  my ($self, $n, $payment, $pv, $fv, $paytype, $guess) = @_;
  $fv ||= 0;
  $paytype = $paytype ? 1 : 0;

  my $rate = iterate(
    max_iterations => 100,
    initial_guess  => $guess || 0.1,
    function       => sub {
      my $rate = shift;
      return $fv + $pv * (1 + $rate)**$n + $payment * (1 + $rate * $paytype) *
        ((1 + $rate)**$n - 1) / $rate;
    },
  );
  die Spreadsheet::Engine::Error->num unless defined $rate;
  return $rate;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::RATE - Spreadsheet funtion RATE()

=head1 SYNOPSIS

  =RATE(n, payment, pv, [fv, [paytype, [guess]]])

=head1 DESCRIPTION

This calculates the interest rate per period of an investment.

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


