package Spreadsheet::Engine::Function::N;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::base';

sub argument_count { 1 }

sub result {
  my $self = shift;
  my $op   = $self->next_operand;

  return Spreadsheet::Engine::Value->new(
    type  => 'n',
    value => $op->is_num ? $op->value : 0
  );
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::N - Spreadsheet funtion N()

=head1 SYNOPSIS

  =N(value)

=head1 DESCRIPTION

If the value is numberic, return it, else return zero.

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


