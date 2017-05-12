package Spreadsheet::Engine::Fn::counter;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::base';

sub argument_count { -1 }

sub result {
  my $self = shift;

  return unless defined(my $foperand = $self->foperand);

  my $match = $self->calculate;
  my $count = 0;

  while (@{$foperand}) {
    $count++ if $match->($self->next_operand);
  }

  return Spreadsheet::Engine::Value->new(type => 'n', value => $count);
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Fn::counter - base class for counting functions

=head1 SYNOPSIS

  use base 'Spreadsheet::Engine::Fn::counter';

  sub calculate { 
    return sub { 
      my $type = shift;
      return is_match($type)
    };
  }

=head1 DESCRIPTION

This provides a base class for spreadsheet functions that count the
number of values in a list that match a certain type (COUNT, COUNTA,
COUNTBLANK, etc). 

=head1 METHODS 

=head2 argument_count

By default all such functions take one or more argument.

=head2 result_type

This is always a number.

=head1 TO SUBCLASS

=head2 calculate

Returns a subref that is given each type in turn and returns a
true/false value for whether or not it should be counted in the
total.

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


