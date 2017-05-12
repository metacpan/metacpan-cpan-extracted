package Spreadsheet::Engine::Function::T;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::base';

sub argument_count { 1 }

sub result {
  my $self = shift;
  my $op   = $self->next_operand;

  return Spreadsheet::Engine::Value->new(
    type  => 't',
    value => $op->is_txt ? $op->value : ''
  );
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::T - Spreadsheet funtion T()

=head1 SYNOPSIS

  =T(value)

=head1 DESCRIPTION

If the value passed is text, then return as is. If not, then the empty
string is returned. This does *not* convert a number to text.

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


