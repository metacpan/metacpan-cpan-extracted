package Spreadsheet::Engine::Function::ROUND;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::math';

sub argument_count { -1 => 2 }
sub signature { 'n', 'n' }
sub _result_type_key { 'oneargnumeric' }

sub calculate {
  my ($self, $value, $precision) = @_;
  my $rounding = ($value >= 0 ? 0.5 : -0.5);
  my $decimalscale = 10**int($precision || 0);
  my $scaledvalue = int($value * $decimalscale + $rounding);
  return $scaledvalue / $decimalscale;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::ROUND - Spreadsheet funtion ROUND()

=head1 SYNOPSIS

  =ROUND(value, [precision])

=head1 DESCRIPTION

This rounds the value to the nearest power of 10 specified by precision.

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


