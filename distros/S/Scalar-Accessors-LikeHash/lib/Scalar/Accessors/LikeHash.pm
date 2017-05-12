package Scalar::Accessors::LikeHash;

use 5.008;
use strict;
use warnings;

use Carp qw(croak);
use Role::Tiny;
use Scalar::Util qw(blessed);

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

requires qw( _to_hash _from_hash );

sub new
{
	my $class = blessed($_[0]) ? ref(shift) : shift;
	
	croak "Class $class does not implement a constructor"
		unless $class->does(__PACKAGE__);
	
	return bless(ref $_ ? \${$_} : \$_, $class)
		for (@_, $class->_empty_structure);
}

sub _empty_structure
{
	my $class = shift;
	$class->can('_from_hash')->(\(my $r), {});
	return $r;
}

sub fetch
{
	my $invocant = shift;
	my $ref      = (not ref $invocant) ? shift : $invocant;
	$invocant    = __PACKAGE__ if ref $invocant && ! blessed $invocant;
	
	$invocant->can('_to_hash')->($ref)->{ $_[0] };
}

sub store
{
	my $invocant = shift;
	my $ref      = (not ref $invocant) ? shift : $invocant;
	$invocant    = __PACKAGE__ if ref $invocant && ! blessed $invocant;
	
	my $hash = $invocant->can('_to_hash')->($ref);
	$hash->{ $_[0] } = $_[1];
	$invocant->can('_from_hash')->($ref, $hash);
	return;
}

sub exists
{
	my $invocant = shift;
	my $ref      = (not ref $invocant) ? shift : $invocant;
	$invocant    = __PACKAGE__ if ref $invocant && ! blessed $invocant;
	
	exists $invocant->can('_to_hash')->($ref)->{ $_[0] };
}

sub values
{
	my $invocant = shift;
	my $ref      = (not ref $invocant) ? shift : $invocant;
	$invocant    = __PACKAGE__ if ref $invocant && ! blessed $invocant;
	
	my $hash = $invocant->can('_to_hash')->($ref);
	map { $hash->{$_} } sort keys %$hash;
}

sub keys
{
	my $invocant = shift;
	my $ref      = (not ref $invocant) ? shift : $invocant;
	$invocant    = __PACKAGE__ if ref $invocant && ! blessed $invocant;
	
	my $hash = $invocant->can('_to_hash')->($ref);
	sort keys %$hash;
}

sub delete
{
	my $invocant = shift;
	my $ref      = (not ref $invocant) ? shift : $invocant;
	$invocant    = __PACKAGE__ if ref $invocant && ! blessed $invocant;
	
	my $hash = $invocant->can('_to_hash')->($ref);
	my $r    = CORE::delete($hash->{ $_[0] });
	$invocant->can('_from_hash')->($ref, $hash);
	return $r;
}

sub clear
{
	my $invocant = shift;
	my $ref      = (not ref $invocant) ? shift : $invocant;
	$invocant    = __PACKAGE__ if ref $invocant && ! blessed $invocant;
	
	$$ref = $invocant->_empty_structure;
}

1;

__END__

=head1 NAME

Scalar::Accessors::LikeHash - access a JSON/Sereal/etc scalar string in a hash-like manner

=head1 SYNOPSIS

   {
      package Acme::Storable::Accessors;
      
      use Storable qw/ freeze thaw /;
      
      use Role::Tiny::With;
      with 'Scalar::Accessors::LikeHash';
      
      sub _to_hash {
         my ($ref) = @_;
         thaw($$ref);
      }
      
      sub _from_hash {
         my ($ref, $hash) = @_;
         $$ref = freeze($hash);
      }
   }
   
   my $string = File::Slurp::slurp("some-data.storable");
   my $object = Acme::Storable::Accessors->new(\$string);
   
   $object->store(some_key => 42) unless $object->exists('some_key');
   $object->fetch('some_key');
   $object->delete('some_key');

=head1 DESCRIPTION

The idea of this is to treat a reference to a string as if it were a hash.
You can store key-values pairs; fetch values using keys; delete keys; etc.
This is slow and quite silly.

This module is a role. Concrete implementations of the role need to provide
C<< _from_hash >> and C<< _to_hash >> methods to serialize and deserialize
a hashref to/from a scalarref.

This role provides the following methods:

=over

=item C<< new(\$scalar) >>

Yes, this role provides a constructor. Consumers can overide it.

=item C<< fetch($key) >>

=item C<< store($key, $value) >>

=item C<< exists($key) >>

=item C<< delete($key) >>

=item C<< clear() >>

Delete for each key.

=item C<< keys() >>

=item C<< values() >>

=back

These can be called as methods on a blessed scalar reference:

	my $string = "{}";
	bless \$string, "Scalar::Accessors::LikeHash::JSON";
	$string->store(foo => 42);

Or as class methods passing the scalar reference as an extra first argument:

	my $string = "{}";
	Scalar::Accessors::LikeHash::JSON->store(\$string, foo => 42);

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Scalar-Accessors-LikeHash>.

=head1 SEE ALSO

For a more usable interface, see L<Tie::Hash::SerializedString>.

For concrete implementations, see L<Scalar::Accessors::LikeHash::JSON>
and L<Scalar::Accessors::LikeHash::Sereal>.

For an insane usage of this concept, see L<Acme::MooseX::JSON>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

