package Rose::DB::Object::Metadata::Column::Interval;

use strict;

use Rose::Object::MakeMethods::Generic;
use Rose::DB::Object::MakeMethods::Time;

use Rose::DB::Object::Metadata::Column;
our @ISA = qw(Rose::DB::Object::Metadata::Column);

our $VERSION = '0.788';

__PACKAGE__->add_common_method_maker_argument_names('default', 'scale', 'end_of_month_mode');

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
  scalar => [ scale => { default => 0 } ],
  scalar => [ __PACKAGE__->common_method_maker_argument_names ]
);

foreach my $type (__PACKAGE__->available_method_types)
{
  __PACKAGE__->method_maker_class($type => 'Rose::DB::Object::MakeMethods::Time');
  __PACKAGE__->method_maker_type($type => 'interval');
}

sub type { 'interval' }

sub should_inline_value
{
  my($self, $db, $value) = @_;
  no warnings 'uninitialized';
  return (($db->validate_interval_keyword($value) && $db->should_inline_interval_keyword($value)) ||
          ($db->keyword_function_calls && $value =~ /^\w+\(.*\)$/)) ? 1 : 0;
}

sub method_should_set
{
  my($self, $type, $args) = @_;

  return 1  if($type eq 'set' || $type eq 'get_set');
  return 0  if($type eq 'get');

  return $self->SUPER::method_should_set($type, $args);
}

sub parse_value  { shift; shift->parse_interval(@_)  }
sub format_value { shift; shift->format_interval(@_) }

sub method_uses_formatted_key
{
  my($self, $type) = @_;
  return 1  if($type eq 'get' || $type eq 'set' || $type eq 'get_set');
  return 0;
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Interval - Interval column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Interval;

  $col = Rose::DB::Object::Metadata::Column::Interval->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for interval columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<date|Rose::DB::Object::MakeMethods::Time/interval>, ...

=item C<get>

L<Rose::DB::Object::MakeMethods::Time>, L<date|Rose::DB::Object::MakeMethods::Time/interval>, ...

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Time>, L<date|Rose::DB::Object::MakeMethods::Time/interval>, ...

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<end_of_month_mode MODE>

This mode determines how math is done on duration objects.  If defined, the C<end_of_month> setting for each L<DateTime::Duration> object created by this column will have its mode set to MODE.  Otherwise, the C<end_of_month> parameter will not be passed to the L<DateTime::Duration> constructor.

Valid modes are C<wrap>, C<limit>, and C<preserve>.  See the documentation for L<DateTime::Duration> for a full explanation.

=item B<parse_value DB, VALUE>

Convert VALUE to the equivalent L<DateTime::Duration> object.  VALUE maybe returned unmodified if it is a valid interval keyword or otherwise has special meaning to the underlying database.  DB is a L<Rose::DB> object that is used as part of the parsing process.  Both arguments are required.

=item B<scale [INT]>

Get or set the integer number of places past the decimal point preserved for fractional seconds.  Defaults to 0.

Returns "interval".

=item B<type>

Returns "interval".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
