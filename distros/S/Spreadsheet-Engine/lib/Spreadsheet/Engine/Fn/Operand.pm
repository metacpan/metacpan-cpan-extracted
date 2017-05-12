package Spreadsheet::Engine::Fn::Operand;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Value';

1;

__END__

=head1 NAME

Spreadsheet::Engine::Fn::Operand - An operand passed to a function

=head1 SYNOPSIS

  my $op = Spreadsheet::Engine::Fn::operand->new(
    type => 'n',
    value => 10,
  );

  my $type = $op->type;
  my $value = $op->value;

=head1 DESCRIPTION

This represents an operand passed to a function. It is currently merely
a thin wrapper around a L<Spreadsheet::Engine::Value>.

=head1 HISTORY

This code was created for Spreadsheet::Engine 0.11

=head1 COPYRIGHT

Copyright (c) 2007, 2008 Tony Bowden

=head1 LICENCE

The contents of this file are subject to the Artistic License 2.0;
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
  http://www.perlfoundation.org/artistic_license_2_0

=cut

