package Rose::DB::Object::Metadata::Column::Date;

use strict;

use Rose::DateTime::Util();

use Rose::Object::MakeMethods::Generic;
use Rose::DB::Object::MakeMethods::Date;

use Rose::DB::Object::Metadata::Column;
our @ISA = qw(Rose::DB::Object::Metadata::Column);

our $VERSION = '0.788';

__PACKAGE__->add_common_method_maker_argument_names('default', 'time_zone', 'type');

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
  scalar => [ __PACKAGE__->common_method_maker_argument_names ]
);

foreach my $type (__PACKAGE__->available_method_types)
{
  __PACKAGE__->method_maker_class($type => 'Rose::DB::Object::MakeMethods::Date');
  __PACKAGE__->method_maker_type($type => 'date');
}

sub type { 'date' }

sub should_inline_value
{
  my($self, $db, $value) = @_;
  no warnings 'uninitialized';
  return (($db->validate_date_keyword($value) && $db->should_inline_date_keyword($value)) ||
          ($db->keyword_function_calls && $value =~ /^\w+\(.*\)$/)) ? 1 : 0;
}

sub method_should_set
{
  my($self, $type, $args) = @_;

  return 1  if($type eq 'set');
  return 0  if($type eq 'get');

  if($type eq 'get_set')
  {
    # Set with 1 arg, but two args is a form of get.
    # Three or more args is undefined...
    return @$args == 2 ? 1 : 0;
  }

  return $self->SUPER::method_should_set($type, $args);
}

sub parse_value
{
  my($self, $db) = (shift, shift);

  $self->parse_error(undef);

  my $dt = $db->parse_date(@_);

  if($dt)
  {
    $dt->set_time_zone($self->time_zone || $db->server_time_zone)
      if(UNIVERSAL::isa($dt, 'DateTime'));
  }
  else
  {
    $dt = Rose::DateTime::Util::parse_date($_[0], $self->time_zone || $db->server_time_zone);

    if(my $error = Rose::DateTime::Util->error)
    {
      $self->parse_error("Could not parse value '$_[0]' for column $self: $error")
        if(defined $_[0]);
    }
  }

  return $dt;
}

sub format_value { shift; shift->format_date(@_) }

sub method_uses_formatted_key
{
  my($self, $type) = @_;
  return 1  if($type eq 'get' || $type eq 'set' || $type eq 'get_set');
  return 0;
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Date - Date column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Date;

  $col = Rose::DB::Object::Metadata::Column::Date->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for date columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Date>, L<date|Rose::DB::Object::MakeMethods::Date/date>, C<interface =E<gt> 'get_set', ...>

=item C<get>

L<Rose::DB::Object::MakeMethods::Date>, L<date|Rose::DB::Object::MakeMethods::Date/date>, C<interface =E<gt> 'get', ...>

=item C<set>

L<Rose::DB::Object::MakeMethods::Date>, L<date|Rose::DB::Object::MakeMethods::Date/date>, C<interface =E<gt> 'set', ...>

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<parse_value DB, VALUE>

Convert VALUE to the equivalent L<DateTime> object.  VALUE maybe returned unmodified if it is a valid date keyword or otherwise has special meaning to the underlying database.  DB is a L<Rose::DB> object that is used as part of the parsing process.  Both arguments are required.

=item B<time_zone [TZ]>

Get or set the time zone of the dates stored in this column.  TZ should be a time zone name that is understood by L<DateTime::TimeZone>.

=item B<type>

Returns "date".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
