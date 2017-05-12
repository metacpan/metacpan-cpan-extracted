package Rose::DBx::Object::Metadata::Column::EKSBlowfish;
use Rose::DB::Object::Metadata::Column;
use Rose::Object::MakeMethods::Generic;
use strict;

use Rose::DB::Object::Metadata::Column;
our @ISA = qw(Rose::DB::Object::Metadata::Column);

our $VERSION = '0.07';

__PACKAGE__->add_common_method_maker_argument_names('encrypted_suffix', 'cmp_suffix');

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
    scalar => [ __PACKAGE__->common_method_maker_argument_names ]
);

foreach my $type (__PACKAGE__->available_method_types)
{
  __PACKAGE__->method_maker_class($type => 'Rose::DBx::Object::MakeMethods::EKSBlowfish');
  __PACKAGE__->method_maker_type($type => 'eksblowfish');
}

sub type { 'eksblowfish' }

1;

=head1 NAME

Rose::DB::Object::Metadata::Column::EKSBlowfish - eksblowfish column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::EKSBlowfish;

  $col = Rose::DB::Object::Metadata::Column::EKSBlowfish->NEW(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for eksblowfish columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.  See the L<Rose::DB::Object::MakeMethods::EKSBlowfish>.

This class inherits from L<Rose::DB::Object::Metadata::Column>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::EKSBlowfish>

=back


=head1 OBJECT METHODS

=over 4

=item B<type>

Returns "eksblowfish".

=back

=head1 OBJECT METHODS

=over 4

=item B<cmp_suffix>

=item B<encrypted_suffix>

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 AUTHOR

Holger Rupprecht (holger.rupprecht@gmx.de)

=head1 COPYRIGHT

Copyright (c) 2013 by Holger Rupprecht.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
