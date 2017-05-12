package Spreadsheet::Engine::Function::OR;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::logical';
use List::Util 'first';

sub argument_count { -1 }

sub calculate {
  my $self = shift;
  my @ops  = map $self->next_operand, 1 .. @{ $self->foperand };
  my $type = $self->optype(propagateerror => @ops);
  die $type if $type->is_error;
  return first { $_->value } @ops;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::OR - Spreadsheet funtion OR()

=head1 SYNOPSIS

  =OR(v1,c1:c2,...)

=head1 DESCRIPTION

This returns TRUE if any paramter is true.

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


