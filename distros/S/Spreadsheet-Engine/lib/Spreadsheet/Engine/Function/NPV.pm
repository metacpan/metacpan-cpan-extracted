package Spreadsheet::Engine::Function::NPV;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::base';

sub argument_count { -2 }

sub result {
  my $self = shift;

  my $rate = $self->next_operand_as_number;
  die $rate if $rate->is_error;

  my $type   = Spreadsheet::Engine::Value->new(type => 'n', value => '0');
  my $sum    = 0;
  my $factor = 1;

  while (@{ $self->foperand }) {
    my $op = $self->next_operand;
    die Spreadsheet::Engine::Error->new(type => $op->type, value => $sum)
      if $op->is_error && !$type->is_error;

    if ($op->is_num) {
      $factor *= (1 + $rate->value) or die Spreadsheet::Engine::Error->div0;
      $sum += $op->value / $factor;
      $type = $self->optype(plus => $op, $type);
    }
  }

  return Spreadsheet::Engine::Value->new(
    type => $type->is_num ? 'n$' : $type->type,
    value => $sum
  );
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::NPV - Spreadsheet funtion NPV()

=head1 SYNOPSIS

  =NPV(rate,v1,v2,c1:c2,...)

=head1 DESCRIPTION

This calculates the net present value of a series of periodic cash
flows.

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


