package Spreadsheet::Engine::Function::NPER;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::investment';

sub result_type { Spreadsheet::Engine::Value->new(type => 'n') }

sub calculate {
  my ($self, $rate, $payment, $pv, $fv, $type) = @_;
  $fv ||= 0;
  $type = $type ? 1 : 0;

  die Spreadsheet::Engine::Value->num if $rate == 0 && $payment == 0;
  return ($pv + $fv) / (-$payment) if $rate == 0;

  my $part1 = $payment * (1 + $rate * $type) / $rate;
  my $part2 = $pv + $part1;
  die Spreadsheet::Engine::Value->num if $part2 == 0 || $rate <= -1;

  my $part3 = ($part1 - $fv) / $part2;
  die Spreadsheet::Engine::Value->num if $part3 <= 0;

  my $part4 = log($part3);
  my $part5 = log(1 + $rate);    # rate > -1
  return $part4 / $part5;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::NPER - Spreadsheet funtion NPER()

=head1 SYNOPSIS

  =NPER(rate, payment, pv, [fv, [paytype]])

=head1 DESCRIPTION

This calculates the number of payment periods for an investment

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


