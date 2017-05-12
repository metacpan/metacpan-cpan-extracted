package Spreadsheet::Engine::Function::TRUNC;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::math2';

sub calculate {
  my ($self, $num, $digits) = @_;
  if ($digits >= 0) {
    my $decimalscale = 10**int $digits;
    my $scaledvalue  = int($num * $decimalscale);
    return $scaledvalue / $decimalscale;
  }

  # $digits < 0
  my $decimalscale = 10**int -$digits;
  my $scaledvalue  = int($num / $decimalscale);
  return $scaledvalue * $decimalscale;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::TRUNC - Spreadsheet funtion TRUNC()

=head1 SYNOPSIS

  =TRUNC(value, digits)

=head1 DESCRIPTION

This truncates the value to the specified number of digits.

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


