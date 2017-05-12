package Spreadsheet::Engine::Function::IRR;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::base';
use Spreadsheet::Engine::Sheet qw/operand_value_and_type/;
use Spreadsheet::Engine::Fn::Approximator 'iterate';

sub argument_count { -1 => 2 }
sub signature { 'r', 'n' }

sub result {
  my $self = shift;
  my ($r_op, $g_op) = $self->_ops;
  die Spreadsheet::Engine::Sheet->val
    if $g_op
    and not $g_op->is_num
    and not $g_op->is_blank;

  my @cashflows;
  my @rangeoperand = ($r_op->value);

  while (@rangeoperand) {
    my $value1 =
      operand_value_and_type($self->sheetdata, \@rangeoperand,
      $self->errortext, \my $tostype);
    die Spreadsheet::Engine::Sheet->val if substr($tostype, 0, 1) eq 'e';
    push @cashflows, $value1 if substr($tostype, 0, 1) eq 'n';
  }

  my $rate = iterate(
    initial_guess => $g_op ? $g_op->value : 0.01,
    function => sub {
      my $rate   = shift;
      my $sum    = 0;
      my $factor = 1;
      for my $cf (@cashflows) {
        $factor *= (1 + $rate) or die Spreadsheet::Engine::Error->div0;
        $sum += $cf / $factor;
      }
      return $sum;
    },
  );
  die Spreadsheet::Engine::Error->num unless defined $rate;
  return Spreadsheet::Engine::Value->new(type => 'n%', value => $rate);

}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::IRR - Spreadsheet funtion IRR()

=head1 SYNOPSIS

  =IRR(c1:c2, [guess])

=head1 DESCRIPTION

Calculate the internal rate of return of a series of cashflows.

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


