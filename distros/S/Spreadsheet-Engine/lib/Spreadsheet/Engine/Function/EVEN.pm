package Spreadsheet::Engine::Function::EVEN;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::math';

sub calculate {
  my ($self, $value) = @_;
  my $result = $value < 0 ? -$value : $value;
  my $extra = $result - int($result);
  if ($extra) {
    $result = int($result + 1) + (($result + 1) % 2);
  } else {    # integer
    $result = $result + ($result % 2);
  }
  $result = -$result if $value < 0;
  return $result;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::EVEN - Spreadsheet funtion EVEN()

=head1 SYNOPSIS

  =EVEN(value)

=head1 DESCRIPTION

This rounds the value to the nearest even integer, away from zero.

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


