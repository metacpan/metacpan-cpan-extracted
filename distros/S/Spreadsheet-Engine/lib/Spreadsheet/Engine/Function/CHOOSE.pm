package Spreadsheet::Engine::Function::CHOOSE;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::base';

sub argument_count { -2 }

sub result {
  my $self   = shift;
  my $index  = $self->next_operand_as_number;
  my $cindex = $index->is_num ? int $index->value : 1;

  my $count = 0;
  while (my $op = $self->top_of_stack) {
    return $op if ($cindex == ++$count);
  }
  return Spreadsheet::Engine::Error->val;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::CHOOSE - Spreadsheet funtion CHOOSE()

=head1 SYNOPSIS

  =CHOOSE(index,value1,value2,...)

=head1 DESCRIPTION

Pick a value from a list by index.

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


