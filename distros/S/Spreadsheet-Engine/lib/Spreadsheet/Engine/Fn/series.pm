package Spreadsheet::Engine::Fn::series;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::base';

sub argument_count { -1 }

sub result {
  my $self        = shift;
  my $type        = '';
  my $calculator  = $self->calculate;
  my $accumulator = $self->accumulator;

  my $foperand = $self->foperand;
  while (@{$foperand}) {
    my $op = $self->next_operand;
    if ($op->is_num) {
      $accumulator = $calculator->($op, $accumulator);
      $type = $self->optype(plus => $op, $type || $op)->type;
    } elsif ($op->is_error && substr($type, 0, 1) ne 'e') {
      $type = $op->type;
    }
  }
  my $result = $self->result_from($accumulator) || 0;

  return Spreadsheet::Engine::Value->new(
    type => $type || 'n',
    value => $result
  );
}

sub accumulator { undef }

sub result_from {
  my ($self, $accumulator) = @_;
  return $accumulator;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Fn::series - base class for series functions

=head1 SYNOPSIS

  use base 'Spreadsheet::Engine::Fn::series';

  sub calculate { 
    return sub { 
      my ($value, $accumulator) = @_;
      # ... do stuff
      return $accumulator;
    };
  }

=head1 DESCRIPTION

This provides a base class for spreadsheet functions that reduce a list
of values to a single number, such as SUM(), MIN(), MAX() etc.

=head1 METHODS 

=head2 argument_count

By default all such functions take one or more argument.

=head2 result_type

This usualy depends on the types of the arguments passed. See the
typelookup table in L<Spreadsheet::Engine::Sheet> for more details.

=head1 TO SUBCLASS

=head2 calculate

Returns a subref that is given each value in turn along with the
accumulator, and returns the new value for the accumulator. 

=head2 accumulator

This should provide the initial accumulator value. The default is to
set it to undef. 

=head2 result_from($accumulator)

Calculate the result based on the accumulator. The default is that the
result is whatever value is in the accumulator. Functions such as
AVERAGE() that need to perform extra calculations at the end can
override this.

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


