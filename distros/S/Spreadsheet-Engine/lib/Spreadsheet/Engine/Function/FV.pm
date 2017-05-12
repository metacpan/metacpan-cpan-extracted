package Spreadsheet::Engine::Function::FV;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::investment';

sub result_type { Spreadsheet::Engine::Value->new(type => 'n$') }

sub calculate {
  my ($self, $r, $n, $pmt, $pv, $type) = @_;
  $pv ||= 0;
  $type = $type ? 1 : 0;

  return -$pv - ($pmt * $n) if $r == 0;    # simple calculation if no interest
  return -(
    $pv * (1 + $r)**$n + $pmt * (1 + $r * $type) * ((1 + $r)**$n - 1) / $r);
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::FV - Spreadsheet funtion FV()

=head1 SYNOPSIS

  =FV(rate, n, payment, [pv, [paytype]])

=head1 DESCRIPTION

This calculates the future value of an investment.

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


