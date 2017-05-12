package Spreadsheet::Engine::Function::DDB;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::depreciation';
use List::Util 'min';

sub argument_count { -4 => 5 }
sub signature { 'n', 'n', '>=1', 'n', 'n' }

sub calculate {
  my ($self, $cost, $salvage, $lifetime, $period, $method) = @_;
  $method ||= 2;

  my $depreciation = 0;    # calculated for each period
  my $accumulated  = 0;    # accumulated by adding each period's

  # calculate for each period based on net from previous
  for my $i (1 .. min($period, $lifetime)) {
    $depreciation = ($cost - $accumulated) * ($method / $lifetime);
    {                      # don't go lower than salvage value
      my $bottom = $cost - $salvage - $accumulated;
      $depreciation = $bottom if $bottom < $depreciation;
    }
    $accumulated += $depreciation;
  }
  return $depreciation;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::DDB - Spreadsheet funtion DDB()

=head1 SYNOPSIS

  =DDB(cost, salvage, lifetime, period, [lifetime])

=head1 DESCRIPTION

This calculates depreciation by declining balance.

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


