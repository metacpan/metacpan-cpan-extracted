package Spreadsheet::Engine::Function::DATE;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::math';

use Spreadsheet::Engine::Sheet qw/convert_date_gregorian_to_julian/;

sub argument_count   { 3 }
sub signature        { 'n', 'n', 'n' }
sub result_type { Spreadsheet::Engine::Value->new(type => 'nd') }

sub calculate {
  my ($self, $y, $m, $d) = @_;
  return convert_date_gregorian_to_julian(int($y), int($m), int($d)) -
    $self->JULIAN_OFFSET;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::DATE - Spreadsheet funtion DATE()

=head1 SYNOPSIS

  =DATE(Y,M,D)

=head1 DESCRIPTION

This converts a Year, Month, Day list into a date.

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


