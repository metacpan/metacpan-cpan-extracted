package Rose::DB::Object::Metadata::Column::Bitfield;

use strict;

use Rose::Object::MakeMethods::Generic;
use Rose::DB::Object::MakeMethods::Generic;

use Rose::DB::Object::Metadata::Column;
our @ISA = qw(Rose::DB::Object::Metadata::Column);

our $VERSION = '0.788';

__PACKAGE__->add_common_method_maker_argument_names
(
  qw(default bits)
);

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
  scalar => [ __PACKAGE__->common_method_maker_argument_names ]
);

sub type { 'bitfield' }

foreach my $type (__PACKAGE__->available_method_types)
{
  __PACKAGE__->method_maker_type($type => 'bitfield')
}

# sub dbi_data_type { DBI::SQL_INTEGER() }

sub parse_value
{
  my $self  = shift;
  my $db    = shift;
  my $value = shift;
  my $bits  = shift || $self->bits;

  return $db->parse_bitfield($value, $bits);
}

sub format_value
{
  my $self  = shift;
  my $db    = shift;
  my $value = shift;
  my $bits  = shift || $self->bits;

  return $db->format_bitfield($value, $bits);
}

sub init_with_dbi_column_info
{
  my($self, $col_info) = @_;

  $self->SUPER::init_with_dbi_column_info($col_info);

  $self->bits($col_info->{'COLUMN_SIZE'});

  return;
}

sub should_inline_value
{
  my($self, $db, $value) = @_;
  no warnings 'uninitialized';
  return (($db->validate_bitfield_keyword($value) && $db->should_inline_bitfield_value($value)) ||
          ($db->keyword_function_calls && $value =~ /^\w+\(.*\)$/)) ? 1 : 0;
}

sub method_uses_formatted_key
{
  my($self, $type) = @_;
  return 1  if($type eq 'get' || $type eq 'set' || $type eq 'get_set');
  return 0;
}

sub select_sql
{
  my($self, $db, $table) = @_;

  if($db)
  {
    if(defined $table)
    {
      return $db->select_bitfield_column_sql($self->{'name'}, $table);
    }
    else
    {
      return $self->{'select_sql'}{$db->{'driver'}} ||= $db->select_bitfield_column_sql($self->{'name'});
    }
  }
  else
  {
    return $self->{'name'};
  }
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Bitfield - Bitfield column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Bitfield;

  $col = Rose::DB::Object::Metadata::Column::Bitfield->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for bitfield columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for parsing, formatting, and creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column> documentation for more information.

B<Important note:> if you are using MySQL 5.0.3 or later, you I<must> L<allow inline column values|Rose::DB::Object::Metadata/allow_inline_column_values> in any L<Rose::DB::Object>-derived class that has one or more bitfield columns.  (That is, columns that use the C<BIT> data type.)  This requirement may be relaxed in the future.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<bitfield|Rose::DB::Object::MakeMethods::Generic/bitfield>, ...

=item C<get>

L<Rose::DB::Object::MakeMethods::Generic>, L<bitfield|Rose::DB::Object::MakeMethods::Generic/bitfield>, ...

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<bitfield|Rose::DB::Object::MakeMethods::Generic/bitfield>, ...

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<bits [INT]>

Get or set the number of bits in the column.

=item B<parse_value DB, VALUE>

Convert VALUE to the equivalent C<Bit::Vector> object.  The return value of the column object's C<bits()> method is used to determine the length of the bitfield in bits.  DB is a L<Rose::DB> object that is used as part of the parsing process.  Both arguments are required.

=item B<type>

Returns "bitfield".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
