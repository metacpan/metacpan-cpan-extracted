package Spreadsheet::Engine::Function::AVERAGE;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::series';

sub calculate {
  return sub {
    my ($op,    $accum) = @_;
    my ($count, $sum)   = @{$accum};
    $count++ if $op->is_num;
    $sum += $op->value;    # Will be zero if type is not a number
    return [ $count, $sum ];
  };
}

sub accumulator { [ 0, 0 ] }

sub result_from {
  my ($self,  $accum) = @_;
  my ($count, $sum)   = @{$accum};
  die Spreadsheet::Engine::Error->div0 unless $count;
  return $sum / $count;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::AVERAGE - Spreadsheet funtion AVERAGE()

=head1 SYNOPSIS

  =AVERAGE(list_of_numbers)

=head1 DESCRIPTION

This returns the numeric mean of the values

=head1 HISTORY

This is a Modified Version of code extracted from SocialCalc::Functions
in SocialCalc 1.1.0

=head1 COPYRIGHT

Portions (c) Copyright 2005, 2006, 2007 Software Garden, Inc.
All Rights Reserved.

Portions (c) Copyright 2007 Socialtext, Inc.
All Rights Reserved.

Portions (c) Copyright 2007, 2008 Tony Bowden

=head1 LICENCE

The contents of this file are subject to the Artistic License 2.0;
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
  http://www.perlfoundation.org/artistic_license_2_0


