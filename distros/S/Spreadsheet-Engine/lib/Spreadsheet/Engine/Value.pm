package Spreadsheet::Engine::Value;

=head1 NAME

Spreadsheet::Engine::Value - A value/type combination

=head1 SYNOPSIS

  my $op = Spreadsheet::Engine::Value->new(
    type => 'n',
    value => 10,
  );

  my $type = $op->type;
  my $value = $op->value;

  if ($op->is_txt) { ... }
  if ($op->is_num) { ... }
  if ($op->is_number) { ... }
  if ($op->is_blank) { ... }
  if ($op->is_logical) { ... }
  if ($op->is_error) { ... }
  if ($op->is_na) { ... }

=head1 DESCRIPTION

In a spreadsheet, values also have an accompanying type. This class
represents such a value/type combination.

=cut

use strict;
use warnings;

=head1 CONSTRUCTOR

=head2 new

Instantiate with a type and value.

=head1 INSTANCE VARIABLES

=head2 type / value

The value and type.

=cut

use Class::Struct;
struct type => '$', value => '$';

=head1 METHODS

=head2 is_txt

Does this have a textual type (of any subtype)?

=cut

sub is_txt {
  my $self = shift;
  substr($self->type, 0, 1) eq 't';
}

=head2 is_num

Does this have a numberic type (of any subtype)?

=cut

sub is_num {
  my $self = shift;
  substr($self->type, 0, 1) eq 'n';
}

=head2 is_number

Is this a number (type 'n', no subtype)?

=cut

sub is_number {
  my $self = shift;
  $self->type eq 'n';
}

=head2 is_blank

Is this blank?

=cut

sub is_blank {
  my $self = shift;
  $self->type eq 'b';
}

=head2 is_logical

Is this a logical value (true/false)?

=cut

sub is_logical {
  my $self = shift;
  $self->type eq 'nl';
}

=head2 is_error

Is this an error?

=cut

sub is_error {
  my $self = shift;
  substr($self->type, 0, 1) eq 'e';
}

=head2 is_na

Is this N/A?

=cut

sub is_na {
  my $self = shift;
  $self->type eq 'e#N/A';
}

1;

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

