package Rose::DB::Object::Metadata::Column::BigInt;

use strict;

use Rose::DB::Object::MakeMethods::BigNum;

use Rose::DB::Object::Metadata::Column::Integer;
our @ISA = qw(Rose::DB::Object::Metadata::Column::Integer);

our $VERSION = '0.788';

INIT_METHOD_MAKER_INFO:
{
  use Config;

  my($class, $type);

  if($Config{'use64bitint'})
  {
    $class = 'Rose::DB::Object::MakeMethods::Generic';
    $type  = 'integer';
  }
  else
  {
    $class = 'Rose::DB::Object::MakeMethods::BigNum';
    $type  = 'bigint';
  }

  __PACKAGE__->method_maker_info
  (
    get_set => 
    {
      class => $class,
      type  => $type,
    },

    get =>
    {
      class => $class,
      type  => $type,
    },

    set =>
    {
      class => $class,
      type  => $type,
    },
  );
}

sub type { 'bigint' }

sub should_inline_value
{
  my($self, $db, $value) = @_;
  no warnings 'uninitialized';
  return (($db->validate_bigint_keyword($value) && $db->should_inline_bigint_keyword($value)) ||
          ($db->keyword_function_calls && $value =~ /^\w+\(.*\)$/)) ? 1 : 0;
}

sub format_value
{
  my($self, $db, $value) = @_;
  return ref $value ? $value->bstr : $value;
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::BigInt - Big integer column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::BigInt;

  $col = Rose::DB::Object::Metadata::Column::BigInt->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for big integer (sometimes called "int8") columns in a database.  Values are stored internally and returned as L<Math::BigInt> objects.  If the L<Math::BigInt::GMP> module is installed, it will be used transparently for better performance.

This class inherits from L<Rose::DB::Object::Metadata::Column::Integer>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column::Integer> documentation for more information.

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

Returns "bigint".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
