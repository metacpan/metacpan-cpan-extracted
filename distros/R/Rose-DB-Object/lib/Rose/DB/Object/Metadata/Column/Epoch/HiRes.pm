package Rose::DB::Object::Metadata::Column::Epoch::HiRes;

use strict;

use Rose::DB::Object::MakeMethods::Date;

use Rose::DB::Object::Metadata::Column::Epoch;
our @ISA = qw(Rose::DB::Object::Metadata::Column::Epoch);

our $VERSION = '0.702';

__PACKAGE__->add_common_method_maker_argument_names('hires');

sub type { 'epoch hires' }

sub hires { 1 }

sub format_value { $_[2]->hires_epoch }

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Epoch::HiRes - Fractional seconds since the epoch column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Epoch::HiRes;

  $col = Rose::DB::Object::Metadata::Column::Epoch::HiRes->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for columns in a database that store a fractional number of seconds since the Unix epoch.  Values may contain up to six (6) digits after the decimal point.

Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column::Epoch>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column::Epoch> documentation for more information.

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

=item B<type>

Returns "epoch hires".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
