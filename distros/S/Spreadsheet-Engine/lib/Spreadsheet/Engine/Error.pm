package Spreadsheet::Engine::Error;

use strict;
use warnings;

use Spreadsheet::Engine::Value;

sub _new {
  my ($self, $type, $val) = @_;
  Spreadsheet::Engine::Value->new(type => $type, value => $val || 0);
}

sub div0 { shift->_new('e#DIV/0!', @_) }
sub na   { shift->_new('e#N/A',    @_) }
sub name { shift->_new('e#NAME?',  @_) }
sub null { shift->_new('e#NULL!',  @_) }
sub num  { shift->_new('e#NUM!',   @_) }
sub ref  { shift->_new('e#REF!',   @_) }
sub val  { shift->_new('e#VALUE!', @_) }

1;
__END__

=head1 NAME

Spreadsheet::Engine::Error - Standard errors

=head1 SYNOPSIS

  die Spreadsheet::Engine::Value->div0;
  die Spreadsheet::Engine::Value->na;
  die Spreadsheet::Engine::Value->name;
  die Spreadsheet::Engine::Value->null;
  die Spreadsheet::Engine::Value->num;
  die Spreadsheet::Engine::Value->ref;
  die Spreadsheet::Engine::Value->val;

=head1 DESCRIPTION

This is a convenience to create various types of spreadsheet errors.

=head1 ERRORS

=head2 div0

#DIV/0: Division by zero.

=head2 name

#NAME?: Name not found

=head2 na

#N/A: Not available

=head2 null

#NULL!: No cells in intersection

=head2 num

#NUM!: Failure to meet domain constraints.

=head2 ref

#REF!: Reference is to an invalid cell

=head2 val

#VALUE!: Parameter is of wrong type

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

