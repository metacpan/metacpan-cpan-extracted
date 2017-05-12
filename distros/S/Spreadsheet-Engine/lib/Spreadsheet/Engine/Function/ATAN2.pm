package Spreadsheet::Engine::Function::ATAN2;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::math2';

sub calculate {
  my ($self, $x, $y) = @_;
  die Spreadsheet::Engine::Error->div0 if $x == 0 && $y == 0;
  return atan2($y, $x);
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::ATAN2 - Spreadsheet funtion ATAN2()

=head1 SYNOPSIS

  =ATAN2(x, y)

=head1 DESCRIPTION

This returns the ar tangent of the x and y coordinates.

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


