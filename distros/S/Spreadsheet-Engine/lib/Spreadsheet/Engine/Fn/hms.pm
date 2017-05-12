package Spreadsheet::Engine::Fn::hms;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::math';

sub signature { 'n' }

sub calculate {
  my ($self, $value) = @_;

  my $fraction = $value - int($value);    # fraction of a day
  $fraction *= 24;

  my $H = int($fraction);
  $fraction -= int($fraction);
  $fraction *= 60;

  my $M = int($fraction);
  $fraction -= int($fraction);
  $fraction *= 60;

  my $S = int($fraction + ($value >= 0 ? 0.5 : -0.5));
  return $self->_calculate($H, $M, $S);
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Fn::hms - base class for HMS functions

=head1 SYNOPSIS

  use base 'Spreadsheet::Engine::Fn::hms';

  sub calculate { ... }

=head1 DESCRIPTION

This provides a base class for spreadsheet functions that operate on a
given time pre-split into hours, minutes, and seconds.

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


