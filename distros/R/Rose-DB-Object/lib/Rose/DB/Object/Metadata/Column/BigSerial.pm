package Rose::DB::Object::Metadata::Column::BigSerial;

use strict;

use Rose::DB::Object::Metadata::Column::BigInt;
use Rose::DB::Object::Metadata::Column::Serial;
our @ISA = qw(Rose::DB::Object::Metadata::Column::BigInt 
              Rose::DB::Object::Metadata::Column::Serial);

our $VERSION = '0.711';

sub type { 'bigserial' }

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::BigSerial - Big serial column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::BigSerial;

  $col = Rose::DB::Object::Metadata::Column::BigSerial->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for big serial (sometimes called "serial8") columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column::BigInt>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column::BigInt> documentation for more information.

=head1 METHOD MAP

If perl is compiled to use 64-bit integers, then the method map is:

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/integer>, C<interface =E<gt> 'get_set', ...>

=item C<get>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/integer>, C<interface =E<gt> 'get', ...>

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/integer>, C<interface =E<gt> 'set', ...>

=back

Otherwise, the method map is:

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::BigNum/bigint>, C<interface =E<gt> 'get_set', ...>

=item C<get>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::BigNum/bigint>, C<interface =E<gt> 'get', ...>

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::BigNum/bigint>, C<interface =E<gt> 'set', ...>

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<type>

Returns "bigserial".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
