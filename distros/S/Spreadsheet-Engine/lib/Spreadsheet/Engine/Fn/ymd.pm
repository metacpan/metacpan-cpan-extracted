package Spreadsheet::Engine::Fn::ymd;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::math';

use Spreadsheet::Engine::Sheet qw/convert_date_julian_to_gregorian/;

sub signature { 'n' }

sub calculate {
  my ($self, $value) = @_;
  return $self->_calculate(
    convert_date_julian_to_gregorian(int($value + $self->JULIAN_OFFSET)));
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Fn::ymd - base class for DMY functions

=head1 SYNOPSIS

  use base 'Spreadsheet::Engine::Fn::ymd';

  sub calculate { ... }

=head1 DESCRIPTION

This provides a base class for spreadsheet functions that operate on a
single date pre-split into year, month, and day.

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


