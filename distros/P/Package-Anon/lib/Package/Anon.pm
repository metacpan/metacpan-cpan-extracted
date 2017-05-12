use strict;
use warnings;

package Package::Anon;
BEGIN {
  $Package::Anon::AUTHORITY = 'cpan:FLORA';
}
{
  $Package::Anon::VERSION = '0.05';
}
# ABSTRACT: Anonymous packages

use XSLoader;

XSLoader::load(
    'Package::Anon',
    $Package::Anon::{VERSION} ? ${ $Package::Anon::{VERSION} } : (),
);

use Scalar::Util ();


sub add_method {
    my ($self, $name, $code) = @_;
    my $gv = $self->install_glob($name);
    *$gv = $code;
    return;
}


sub install_glob {
    my ($self, $name) = @_;
    my $gv = $self->create_glob($name);
    $self->{$name} = *$gv;
    return $gv;
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Package::Anon - Anonymous packages

=head1 SYNOPSIS

  my $stash = Package::Anon->new;
  $stash->add_method(get_answer => sub { 42 });

  my $obj = $stash->bless({});

  $obj->get_answer; # 42

=head1 DESCRIPTION

This module allows for anonymous packages that are independent of the main
namespace and only available through an object instance, not by name.

  # Declare an anonymous package using new()
  my $stash = Package::Anon->new;

  # Add behavior to the package
  $stash->add_method('get_answer', sub{ return 42; });

  # Create an instance of the anonymous package
  my $instance = $stash->bless({});

  # Call the method
  $instance->get_answer(); # returns 42

In C<< $my_object->do_stuff() >> Perl uses a the name of the class C<$my_object>
is blessed into to resolve the function C<do_stuff()>.

Packages created using Package::Anon exist outside of the C<main::> namespace
and cannot be referenced by name. These packages are defined within stashes that
are only accessible through a reference rather than using a name.

Previous attempts to allow for anonymous packages in Perl use workarounds that
still ultimately result in references by named packages. Because Package::Anon
allows method dispatching without a name lookup, packages are truly anonymous.

=head1 METHODS

=head2 new ($name?)

  my $stash = Package::Anon->new;

  my $stash = Package::Anon->new('Foo');

Create a new anonymous package. The optional C<$name> argument sets the stash's
name. This name only serves as an aid for debugging. The stash is not reachable
from the global symbol table by the given name.

C<$name> defaults to C<__ANON__>.

=head2 bless ($reference)

  my $instance = $stash->bless({});

Bless a C<$reference> into the anonymous package.

=head2 add_method ($name, $code)

  $stash->add_method(foo => sub { return 42; });

Register a new method in the anonymous package. C<add_method()> is provided as a
convenience method for adding code symbols to slots in the anonymous stash. For
additional symbol table manipulation, see L</SYMBOL TABLE MANIPULATION>.

=head2 blessed ($obj)

  my $stash = Package::Anon->blessed($obj);

Returns a Package::Anon instance for the package the given C<$obj> is blessed
into, or undef if C<$obj> isn't an object.

=head2 install_glob ($name)

  my $gv = $stash->install_glob('foo');

Create a glob with the given C<$name> and install it under that C<$name> within
the C<$stash>. The returned glob can be used to install symbols into the
C<$stash>. See L</SYMBOL TABLE MANIPULATION> for examples.

=head1 EXPERIMENTAL METHODS

These methods interact with the symbol table in ways that could cause unexpected
results in your programs. Please use them with caution.

=head2 create_glob ($name)

  my $gv = $stash->create_glob('foo');

Creates a new glob with the name C<$name>, pointing to C<$stash> as its
stash. The created glob is not installed into the C<$stash>.

This method implements functionality similar to L<Symbol::gensym|Symbol>, but
allows you to specify the name of the glob.

=head1 SYMBOL TABLE MANIPULATION

This module is intended to create anonymous packages with behavior, not data
members. Support for data members has been documented because the Glob API
supports the addition of data types besides coderefs. Please use this module
with caution when creating data members in your anonymous packages.

  add_method('get_answer', sub {return 42});

is the same as:

  my $gv = install_glob('get_answer');
  *$gv = sub { return 42 };

For other data types:

  *$gv = \$foo # scalar
  *$gv = \@foo # array
  *$gv = \%foo # hash

Currently, C<Package::Anon> instances are blessed stash references, so the
following is possible:

  $stash->{$symbol_name} = *$gv;

However, the exact details of how to get a hold of the actual stash reference
might change in the future.

=head1 AUTHORS

=over 4

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Augustina Blair <auggy@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
