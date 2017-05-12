package MouseX::SingletonMethod;
use strict;
use warnings;
use 5.008001;

use Mouse ();
use Mouse::Exporter;
use Mouse::Util::MetaRole;

our $VERSION = '0.05';

Mouse::Exporter->setup_import_methods( also => 'Mouse' );

sub init_meta {
    shift;
    my %options = @_;

    my $meta = Mouse->init_meta(%options);

    Mouse::Util::MetaRole::apply_base_class_roles(
        for_class => $options{for_class},
        roles     => ['MouseX::SingletonMethod::Role'],
    );
    
    return $meta;
}

1;
__END__

=head1 NAME

MouseX::SingletonMethod - Mouse with Singleton Method facility


=head1 SYNOPSIS

  package Foo;
  use MouseX::SingletonMethod;
  no MouseX::Singleton;
  
  package main;
  my $foo1 = Foo->new;
  my $foo2 = Foo->new;
  
  $foo1->add_singleton_method( foo => sub { 'foo' } );
  
  say $foo1->foo; # => 'foo'
  say $foo2->foo; # ERROR: Can't locate object method "foo" ...

or

  package Bar;
  use Mouse;
  with 'MouseX::SingletonMethod::Role';

  no Mouse;

=head1 DESCRIPTION

This module can create singleton methods with Mouse.

=head1 METHODS

=head2 become_singleton

Make the object a singleton

=head2 add_singleton_method

Adds a singleton method to this object:

  $foo->add_singleton_method( foo => sub { 'foo' } );

=head2 add_singleton_methods

Same as above except allows multiple method declaration:

  $bar->add_singleton_methods(
      bar1 => sub { 'bar1' },
      bar2 => sub { 'bar2' },
  );

=head1 SEE ALSO

L<Mouse>
L<MooseX::SingletonMethod>

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
