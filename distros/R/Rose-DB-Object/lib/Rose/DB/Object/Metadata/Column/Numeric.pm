package Rose::DB::Object::Metadata::Column::Numeric;

use strict;

use Rose::Object::MakeMethods::Generic;

use Rose::DB::Object::Metadata::Column::Scalar;
our @ISA = qw(Rose::DB::Object::Metadata::Column::Scalar);

our $VERSION = '0.812';

__PACKAGE__->delete_common_method_maker_argument_names('length');

__PACKAGE__->add_common_method_maker_argument_names
(
  qw(precision scale)
);

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
  scalar => [ __PACKAGE__->common_method_maker_argument_names ]
);

sub type { 'numeric' }

sub should_inline_value
{
  my($self, $db, $value) = @_;
  no warnings 'uninitialized';
  return (($db->validate_numeric_keyword($value) && $db->should_inline_numeric_keyword($value)) ||
          ($db->keyword_function_calls && $value =~ /^\w+\(.*\)$/)) ? 1 : 0;
}

sub init_with_dbi_column_info
{
  my($self, $col_info) = @_;

  $self->precision(defined $col_info->{'NUMERIC_PRECISION'} ? 
    $col_info->{'NUMERIC_PRECISION'} : $col_info->{'COLUMN_SIZE'});

  $self->scale(defined $col_info->{'NUMERIC_SCALE'} ? 
    $col_info->{'NUMERIC_SCALE'} : $col_info->{'DECIMAL_DIGITS'});

  # Prevent COLUMN_SIZE from setting bogus length in superclass
  delete $col_info->{'COLUMN_SIZE'};

  $self->SUPER::init_with_dbi_column_info($col_info);

  return;
}

sub perl_column_definition_attributes
{
  grep { $_ ne 'length' } shift->SUPER::perl_column_definition_attributes;
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Numeric - Numeric column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Numeric;

  $col = Rose::DB::Object::Metadata::Column::Numeric->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for numeric columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column::Scalar>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column::Scalar> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>, C<interface =E<gt> 'get_set', ...>

=item C<get>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>, C<interface =E<gt> 'get', ...>

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>, C<interface =E<gt> 'set', ...>

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<precision [INT]>

Get or set the precision of the numeric value.  The precision is the total count of significant digits in the whole number. That is, the number of digits to both sides of the decimal point. For example, the number 23.5141 has a precision of 6.

=item B<scale [INT]>

Get or set the scale of the numeric value.  The scale is the count of decimal digits in the fractional part, to the right of the decimal point.  For example, the number 23.5141 has a scale of 4.  Integers can be considered to have a scale of zero.

=item B<type>

Returns "numeric".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
