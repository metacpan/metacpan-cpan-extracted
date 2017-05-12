package Rose::DB::Object::Metadata::Column::Epoch;

use strict;

use Rose::DB::Object::MakeMethods::Date;

use Rose::DB::Object::Metadata::Column::Date;
our @ISA = qw(Rose::DB::Object::Metadata::Column::Date);

our $VERSION = '0.788';

foreach my $type (__PACKAGE__->available_method_types)
{
  __PACKAGE__->method_maker_class($type => 'Rose::DB::Object::MakeMethods::Date');
  __PACKAGE__->method_maker_type($type => 'epoch');
}

sub type { 'epoch' }

sub should_inline_value { 0 }

sub format_value { $_[2]->epoch }

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Epoch - Seconds since the epoch column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Epoch;

  $col = Rose::DB::Object::Metadata::Column::Epoch->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for columns in a database that store an integer number of seconds since the Unix epoch.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column::Date>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column::Date> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Date>, L<epoch|Rose::DB::Object::MakeMethods::Date/epoch>, ...

=item C<get>

L<Rose::DB::Object::MakeMethods::Date>, L<epoch|Rose::DB::Object::MakeMethods::Date/epoch>, ...

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Date>, L<epoch|Rose::DB::Object::MakeMethods::Date/epoch>, ...

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<parse_value DB, VALUE>

Convert VALUE to the equivalent L<DateTime> object.  VALUE maybe returned unmodified if it has special meaning to the underlying database.  DB is a L<Rose::DB> object that is used as part of the parsing process.  Both arguments are required.

=item B<type>

Returns "epoch".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
