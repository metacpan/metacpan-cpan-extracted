package Spreadsheet::Engine::Function::PV;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::investment';

sub calculate {
  my ($self, $rate, $n, $payment, $fv, $type) = @_;
  $fv ||= 0;
  $type = $type ? 1 : 0;

  die Spreadsheet::Engine::Error->div0 if $rate == -1;
  return -$fv - ($payment * $n) if $rate == 0;
  return (
    -$fv - $payment * (1 + $rate * $type) * ((1 + $rate)**$n - 1) / $rate) /
    ((1 + $rate)**$n);
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::PV - Spreadsheet funtion PV()

=head1 SYNOPSIS

  =PV(rate, n, payment, [vv, [paytype]])

=head1 DESCRIPTION

This calculates the present value of an investment.

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


