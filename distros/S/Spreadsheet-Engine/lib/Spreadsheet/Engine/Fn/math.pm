package Spreadsheet::Engine::Fn::math;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::base';

use constant PI => atan2(1, 1) * 4;
use constant JULIAN_OFFSET => 2_415_019;

sub signature        { 'n' }
sub _result_type_key { 'oneargnumeric' }

sub result_type {
  my $self = shift;
  return $self->optype($self->_result_type_key => $self->_ops);
}

sub result {
  my $self = shift;
  my $type = $self->result_type;
  die $type unless $type->is_num;

  return Spreadsheet::Engine::Value->new(
    type  => $type->type,
    value => $self->calculate(map $_->value, $self->_ops),
  );
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Fn::math - base class for math functions

=head1 SYNOPSIS

  use base 'Spreadsheet::Engine::Fn::math';

  sub calculate { ... }

=head1 DESCRIPTION

This provides a base class for spreadsheet functions that perform
mathematical functions on a single argument (ABS(), SIN(), SQRT() etc).

Subclasses should provide 'calculate' function that will be called with 
the argument provided.

=head1 INSTANCE METHODS

=head2 calculate

Subclasses should provide this as the workhorse. It should either return
the result, or die with an error message (that will be trapped and
turned into a e#NUM! error).

=head2 arg_check

Before calulate is called, an arg_check subref, if provided, will be
called to check that the argument passed to the function is acceptable.
This is an interim step towards proper argument validation. Be careful
about relying on it.

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


