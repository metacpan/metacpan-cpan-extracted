package Spreadsheet::Engine::Function::EXACT;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::logical';

sub argument_count { 2 }

sub calculate {
  my $self = shift;

  # Sort values by type so we only need to compare in one direction
  my ($X, $Y) =
    sort { $a->type cmp $b->type } ($self->next_operand, $self->next_operand);

  die $X if $X->is_error;
  die $Y if $Y->is_error;

  if ($X->is_blank) {
    return 1                 if $Y->is_blank;
    return !length $Y->value if $Y->is_txt;
  }

  if ($X->is_num) {
    return $X->value == $Y->value if $Y->is_num;
    return $X->value . '' eq $Y->value if $Y->is_txt;
  }

  if ($X->is_txt) {
    return $X->value eq $Y->value if $Y->is_txt;
  }

  return 0;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::EXACT - Spreadsheet funtion EXACT()

=head1 SYNOPSIS

  =EXACT(value1, value2)

=head1 DESCRIPTION

Are both valus the same, using case-sensitive text comparison.

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


