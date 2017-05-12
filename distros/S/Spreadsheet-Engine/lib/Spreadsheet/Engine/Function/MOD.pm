package Spreadsheet::Engine::Function::MOD;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::math2';

sub calculate {
  my ($self, $x, $y) = @_;
  die Spreadsheet::Engine::Error->div0 if $y == 0;
  my $quotient = $x / $y;
  if ($quotient >= 0) {
    $quotient = int($quotient);
  } else {
    $quotient = int($quotient) - 1;
  }
  return $x - ($quotient * $y);
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::MOD - Spreadsheet funtion MOD()

=head1 SYNOPSIS

  =MOD(a, b)

=head1 DESCRIPTION

This returns the remainder when a is divided by b

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


