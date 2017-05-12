package MoopsX::ListObjects;
{
  $MoopsX::ListObjects::VERSION = '0.003001';
}
use strict; use warnings FATAL => 'all';

use parent 'Moops';
use List::Objects::WithUtils ();
use List::Objects::Types ();
use Type::Registry ();

sub import {
  my ($class, %params) = @_;
  push @{ $params{imports} },
    'List::Objects::Types'     => [ -all ],
    'List::Objects::WithUtils' => [ qw/
      array immarray array_of immarray_of
      hash hash_of immhash immhash_of
    / ],
  ;

  my $pkg = caller;
  Type::Registry->for_class($pkg)->add_types('List::Objects::Types');

  for my $tname (List::Objects::Types->type_names) {
    my $reg = Type::Registry->for_class($pkg);
    $reg->add_type( List::Objects::Types->get_type($tname) )
      unless $reg->simple_lookup($tname)
  }

  @_ = ( $class, %params );
  goto \&Moops::import
}

1;

=pod

=for Pod::Coverage import

=head1 NAME

MoopsX::ListObjects - Use Moops with List::Objects::WithUtils

=head1 SYNOPSIS

  package My::App;
  use MoopsX::ListObjects;

  class Foo {
    has mylist => ( 
      default => sub { array }, 
      isa     => ArrayObj
    );

    has mydata => ( 
      default => sub { +{} },
      isa     => HashObj,
      coerce  => 1
    );

    method add_items (@items) {
      $self->mylist->push(@items)
    }

    method find_matches (Str $string) {
      $self->mylist->grep(sub { $_ eq $string })
    }
  }

  my $foo = Foo->new;

  $foo->add_items(qw/ foo bar baz /);

  my $matches = $foo->find_matches( 'foo' );

=head1 DESCRIPTION

Extends Toby Inkster's L<Moops> sugary class building syntax with
L<List::Objects::WithUtils> objects.

Importing L<MoopsX::ListObjects> is the same as importing L<Moops>, but with
all of the objects available from L<List::Objects::WithUtils>, as well as the
types and coercions from L<List::Objects::Types>.

=head1 SEE ALSO

L<Moops>

L<List::Objects::WithUtils>

L<List::Objects::Types>

L<List::Objects::WithUtils::Role::Array>

L<List::Objects::WithUtils::Role::Hash>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
