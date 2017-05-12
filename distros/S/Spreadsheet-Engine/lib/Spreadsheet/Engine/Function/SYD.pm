package Spreadsheet::Engine::Function::SYD;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::depreciation';

sub signature { 'n', 'n', '>=1', '>=0' }

sub calculate {
  my ($self, $cost, $salvage, $lifetime, $period) = @_;
  return ($cost - $salvage) * ($lifetime - $period + 1) /
    ((($lifetime + 1) * $lifetime) / 2);
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::SYD - Spreadsheet funtion SYD()

=head1 SYNOPSIS

  =SYD(cost, salvage, lifetime, period)

=head1 DESCRIPTION

This calculates depreciation using the Sum of Year's Digits method.

See: http://en.wikipedia.org/wiki/Depreciation

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


