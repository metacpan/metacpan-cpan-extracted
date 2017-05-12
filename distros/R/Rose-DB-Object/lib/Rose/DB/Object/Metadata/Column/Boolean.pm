package Rose::DB::Object::Metadata::Column::Boolean;

use strict;

use Rose::DB::Object::Metadata::Column::Scalar;
our @ISA = qw(Rose::DB::Object::Metadata::Column::Scalar);

our $VERSION = '0.788';

foreach my $type (__PACKAGE__->available_method_types)
{
  __PACKAGE__->method_maker_type($type => 'boolean')
}

sub type { 'boolean' }

sub parse_value  { shift; shift->parse_boolean(@_)  }
sub format_value { shift; shift->format_boolean(@_) }

sub should_inline_value
{
  my($self, $db, $value) = @_;
  no warnings 'uninitialized';
  return (($db->validate_boolean_keyword($value) && $db->should_inline_boolean_keyword($value)) ||
          ($db->keyword_function_calls && $value =~ /^\w+\(.*\)$/)) ? 1 : 0;
}

sub perl_column_definition_attributes
{
  grep { $_ ne 'length' } shift->SUPER::perl_column_definition_attributes;
}

sub method_uses_formatted_key
{
  my($self, $type) = @_;
  return 1  if($type eq 'get' || $type eq 'set' || $type eq 'get_set');
  return 0;
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Boolean - Boolean column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Boolean;

  $col = Rose::DB::Object::Metadata::Column::Boolean->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for boolean columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column::Scalar>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column::Scalar> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<boolean|Rose::DB::Object::MakeMethods::Generic/boolean>, ...

=item C<get>

L<Rose::DB::Object::MakeMethods::Generic>, L<boolean|Rose::DB::Object::MakeMethods::Generic/boolean>, ...

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<boolean|Rose::DB::Object::MakeMethods::Generic/boolean>, ...

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<parse_value DB, VALUE>

Parse VALUE and return true or false according to how the underlying database would view VALUE as the value for a boolean column.  DB is a L<Rose::DB> object that is used as part of the parsing process.  Both arguments are required.

=item B<type>

Returns "boolean".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
