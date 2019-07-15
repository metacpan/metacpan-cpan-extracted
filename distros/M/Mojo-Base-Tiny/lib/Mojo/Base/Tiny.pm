package Mojo::Base::Tiny;
## no critic (ProhibitNoStrict, ProhibitStringyEval)

use strict;
use warnings;
use utf8;
use feature ':5.10';
use mro;

# No imports because we get subclassed, a lot!
use Carp         ();
use Scalar::Util ();
use Sub::Util    ();

# Only Perl 5.14+ requires it on demand
use IO::Handle ();

our $VERSION = '0.03';

# Role support requires Role::Tiny 2.000001+
use constant ROLES =>
  !!(eval { require Role::Tiny; Role::Tiny->VERSION('2.000001'); 1 });

# Protect subclasses using AUTOLOAD
sub DESTROY { }

sub attr {
  my ($self, $attrs, $value, %kv) = @_;
  return unless (my $class = ref $self || $self) && $attrs;

  Carp::croak 'Default has to be a code reference or constant value'
    if ref $value && ref $value ne 'CODE';
  Carp::croak 'Unsupported attribute option' if grep { $_ ne 'weak' } keys %kv;

  # Weaken
  if ($kv{weak}) {
    state %weak_names;
    unless ($weak_names{$class}) {
      my $names = $weak_names{$class} = [];
      my $sub   = sub {
        my $self = shift->next::method(@_);
        ref $self->{$_} and Scalar::Util::weaken $self->{$_} for @$names;
        return $self;
      };
      _monkey_patch(my $base = $class . '::_Base', 'new', $sub);
      no strict 'refs';
      unshift @{"${class}::ISA"}, $base;
    }
    push @{$weak_names{$class}}, ref $attrs eq 'ARRAY' ? @$attrs : $attrs;
  }

  for my $attr (@{ref $attrs eq 'ARRAY' ? $attrs : [$attrs]}) {
    Carp::croak qq{Attribute "$attr" invalid} unless $attr =~ /^[a-zA-Z_]\w*$/;

    # Very performance-sensitive code with lots of micro-optimizations
    my $sub;
    if ($kv{weak}) {
      if (ref $value) {
        $sub = sub {
          return exists $_[0]{$attr}
            ? $_[0]{$attr}
            : (
            ref($_[0]{$attr} = $value->($_[0]))
              && Scalar::Util::weaken($_[0]{$attr}),
            $_[0]{$attr}
            ) if @_ == 1;
          ref($_[0]{$attr} = $_[1]) and Scalar::Util::weaken($_[0]{$attr});
          $_[0];
        };
      }
      else {
        $sub = sub {
          return $_[0]{$attr} if @_ == 1;
          ref($_[0]{$attr} = $_[1]) and Scalar::Util::weaken($_[0]{$attr});
          $_[0];
        };
      }
    }
    elsif (ref $value) {
      $sub = sub {
        return
          exists $_[0]{$attr} ? $_[0]{$attr} : ($_[0]{$attr} = $value->($_[0]))
          if @_ == 1;
        $_[0]{$attr} = $_[1];
        $_[0];
      };
    }
    elsif (defined $value) {
      $sub = sub {
        return exists $_[0]{$attr} ? $_[0]{$attr} : ($_[0]{$attr} = $value)
          if @_ == 1;
        $_[0]{$attr} = $_[1];
        $_[0];
      };
    }
    else {
      $sub
        = sub { return $_[0]{$attr} if @_ == 1; $_[0]{$attr} = $_[1]; $_[0] };
    }
    _monkey_patch($class, $attr, $sub);
  }
}

sub import {
  my ($class, $caller) = (shift, caller);
  return unless my @flags = @_;

  # Mojo modules are strict!
  $_->import for qw(strict warnings utf8);
  feature->import(':5.10');

  while (my $flag = shift @flags) {

    # Base
    if ($flag eq '-base') { push @flags, $class }

    # Role
    elsif ($flag eq '-role') {
      Carp::croak 'Role::Tiny 2.000001+ is required for roles' unless ROLES;
      _monkey_patch($caller, 'has', sub { attr($caller, @_) });
      eval "package $caller; use Role::Tiny; 1" or die $@;
    }

    # Signatures (Perl 5.20+)
    elsif ($flag eq '-signatures') {
      Carp::croak 'Subroutine signatures require Perl 5.20+' if $] < 5.020;
      require experimental;
      experimental->import('signatures');
    }

    # Module
    elsif ($flag !~ /^-/) {
      no strict 'refs';
      require(_class_to_path($flag)) unless $flag->can('new');
      push @{"${caller}::ISA"}, $flag;
      _monkey_patch($caller, 'has', sub { attr($caller, @_) });
    }

    elsif ($flag ne '-strict') { Carp::croak "Unsupported flag: $flag" }
  }
}

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub tap {
  my ($self, $cb) = (shift, shift);
  $_->$cb(@_) for $self;
  return $self;
}

sub with_roles {
  Carp::croak 'Role::Tiny 2.000001+ is required for roles' unless ROLES;
  my ($self, @roles) = @_;

  return Role::Tiny->create_class_with_roles($self,
    map { /^\+(.+)$/ ? "${self}::Role::$1" : $_ } @roles)
    unless my $class = Scalar::Util::blessed $self;

  return Role::Tiny->apply_roles_to_object($self,
    map { /^\+(.+)$/ ? "${class}::Role::$1" : $_ } @roles);
}

# internal functions

sub _class_to_path { join '.', join('/', split(/::|'/, shift)), 'pm' }

sub _monkey_patch {
  my ($class, %patch) = @_;
  no strict 'refs';
  no warnings 'redefine';
  *{"${class}::$_"} = Sub::Util::set_subname("${class}::$_", $patch{$_}) for keys %patch;
}

1;

=encoding utf8

=head1 NAME

Mojo::Base::Tiny - Minimal base class for !Mojo projects

=head1 SYNOPSIS

  package Cat;
  use Mojo::Base::Tiny -base;

  has name => 'Nyan';
  has ['age', 'weight'] => 4;

  package Tiger;
  use Mojo::Base::Tiny 'Cat';

  has friend  => sub { Cat->new };
  has stripes => 42;

  package main;
  use Mojo::Base::Tiny -strict;

  my $mew = Cat->new(name => 'Longcat');
  say $mew->age;
  say $mew->age(3)->weight(5)->age;

  my $rawr = Tiger->new(stripes => 38, weight => 250);
  say $rawr->tap(sub { $_->friend->name('Tacgnol') })->weight;

=head1 DESCRIPTION

L<Mojo::Base::Tiny> is a simple base class for Perl projects with fluent
interfaces.

It is nothing else than L<Mojo::Base> in a single file without dependencies
outside the core modules (or to be correct, on Perl 5.20 and older you need
L<Sub::Util> 1.41). You can copy it directly to your project in all the
"I can't (or don't want to) install L<Mojolicious>" cases.

  # Automatically enables "strict", "warnings", "utf8" and Perl 5.10 features
  use Mojo::Base::Tiny -strict;
  use Mojo::Base::Tiny -base;
  use Mojo::Base::Tiny 'SomeBaseClass';
  use Mojo::Base::Tiny -role;

All four forms save a lot of typing. Note that role support depends on
L<Role::Tiny> (2.000001+).

  # use Mojo::Base::Tiny -strict;
  use strict;
  use warnings;
  use utf8;
  use feature ':5.10';
  use mro;
  use IO::Handle ();

  # use Mojo::Base::Tiny -base;
  use strict;
  use warnings;
  use utf8;
  use feature ':5.10';
  use mro;
  use IO::Handle ();
  push @ISA, 'Mojo::Base::Tiny';
  sub has { Mojo::Base::Tiny::attr(__PACKAGE__, @_) }

  # use Mojo::Base::Tiny 'SomeBaseClass';
  use strict;
  use warnings;
  use utf8;
  use feature ':5.10';
  use mro;
  use IO::Handle ();
  require SomeBaseClass;
  push @ISA, 'SomeBaseClass';
  sub has { Mojo::Base::Tiny::attr(__PACKAGE__, @_) }

  # use Mojo::Base::Tiny -role;
  use strict;
  use warnings;
  use utf8;
  use feature ':5.10';
  use mro;
  use IO::Handle ();
  use Role::Tiny;
  sub has { Mojo::Base::Tiny::attr(__PACKAGE__, @_) }

On Perl 5.20+ you can also use the C<-signatures> flag with all four forms and
enable support for L<subroutine signatures|perlsub/"Signatures">.

  # Also enable signatures
  use Mojo::Base::Tiny -strict, -signatures;
  use Mojo::Base::Tiny -base, -signatures;
  use Mojo::Base::Tiny 'SomeBaseClass', -signatures;
  use Mojo::Base::Tiny -role, -signatures;

This will also disable experimental warnings on versions of Perl where this
feature was still experimental.

=head1 FLUENT INTERFACES

Fluent interfaces are a way to design object-oriented APIs around method
chaining to create domain-specific languages, with the goal of making the
readablity of the source code close to written prose.

  package Duck;
  use Mojo::Base::Tiny -base;

  has 'name';

  sub quack {
    my $self = shift;
    my $name = $self->name;
    say "$name: Quack!"
  }

L<Mojo::Base::Tiny> will help you with this by having all attribute accessors created
with L</"has"> (or L</"attr">) return their invocant (C<$self>) whenever they
are used to assign a new attribute value.

  Duck->new->name('Donald')->quack;

In this case the C<name> attribute accessor is called on the object created by
C<Duck-E<gt>new>. It assigns a new attribute value and then returns the C<Duck>
object, so the C<quack> method can be called on it afterwards. These method
chains can continue until one of the methods called does not return the C<Duck>
object.

=head1 FUNCTIONS

L<Mojo::Base::Tiny> implements the following functions, which can be imported with
the C<-base> flag or by setting a base class.

=head2 has

  has 'name';
  has ['name1', 'name2', 'name3'];
  has name => 'foo';
  has name => sub {...};
  has ['name1', 'name2', 'name3'] => 'foo';
  has ['name1', 'name2', 'name3'] => sub {...};
  has name => sub {...}, weak => 1;
  has name => undef, weak => 1;
  has ['name1', 'name2', 'name3'] => sub {...}, weak => 1;

Create attributes for hash-based objects, just like the L</"attr"> method.

=head1 METHODS

L<Mojo::Base::Tiny> implements the following methods.

=head2 attr

  $object->attr('name');
  SubClass->attr('name');
  SubClass->attr(['name1', 'name2', 'name3']);
  SubClass->attr(name => 'foo');
  SubClass->attr(name => sub {...});
  SubClass->attr(['name1', 'name2', 'name3'] => 'foo');
  SubClass->attr(['name1', 'name2', 'name3'] => sub {...});
  SubClass->attr(name => sub {...}, weak => 1);
  SubClass->attr(name => undef, weak => 1);
  SubClass->attr(['name1', 'name2', 'name3'] => sub {...}, weak => 1);

Create attribute accessors for hash-based objects, an array reference can be
used to create more than one at a time. Pass an optional second argument to set
a default value, it should be a constant or a callback. The callback will be
executed at accessor read time if there's no set value, and gets passed the
current instance of the object as first argument. Accessors can be chained, that
means they return their invocant when they are called with an argument.

These options are currently available:

=over 2

=item weak

  weak => $bool

Weaken attribute reference to avoid
L<circular references|perlref/"Circular-References"> and memory leaks.

=back

=head2 new

  my $object = SubClass->new;
  my $object = SubClass->new(name => 'value');
  my $object = SubClass->new({name => 'value'});

This base class provides a basic constructor for hash-based objects. You can
pass it either a hash or a hash reference with attribute values.

=head2 tap

  $object = $object->tap(sub {...});
  $object = $object->tap('some_method');
  $object = $object->tap('some_method', @args);

Tap into a method chain to perform operations on an object within the chain
(also known as a K combinator or Kestrel). The object will be the first argument
passed to the callback, and is also available as C<$_>. The callback's return
value will be ignored; instead, the object (the callback's first argument) will
be the return value. In this way, arbitrary code can be used within (i.e.,
spliced or tapped into) a chained set of object method calls.

  # Longer version
  $object = $object->tap(sub { $_->some_method(@args) });

  # Inject side effects into a method chain
  $object->foo('A')->tap(sub { say $_->foo })->foo('B');

=head2 with_roles

  my $new_class = SubClass->with_roles('SubClass::Role::One');
  my $new_class = SubClass->with_roles('+One', '+Two');
  $object       = $object->with_roles('+One', '+Two');

Create a new class with one or more L<Role::Tiny> roles. If called on a class
returns the new class, or if called on an object reblesses the object into the
new class. For roles following the naming scheme C<MyClass::Role::RoleName> you
can use the shorthand C<+RoleName>. Note that role support depends on
L<Role::Tiny> (2.000001+).

  # Create a new class with the role "SubClass::Role::Foo" and instantiate it
  my $new_class = SubClass->with_roles('+Foo');
  my $object    = $new_class->new;

=head1 SEE ALSO

L<Mojo::Base>, L<Mojolicious>.

=head1 AUTHOR

Sebastian Riedel - C<sri@cpan.org>

William Lindley - C<wlindley+remove+this@wlindley.com>

Maxim Vuets - C<mvuets@cpan.org>

Joel Berger - C<joel.a.berger@gmail.com>

Jan Henning Thorsen - C<jhthorsen@cpan.org>

Dan Book - C<dbook@cpan.org>

Elmar S. Heeb - C<heeb@cpan.org>

Dotan Dimet - C<dotan@cpan.org>

Zoffix Znet - C<cpan@zoffix.com>

Ask Bjørn Hansen - C<ask@perl.org>

Tekki (Rolf Stöckli) - C<tekki@cpan.org>

Mohammad S Anwar - C<mohammad.anwar@yahoo.com>

=head1 COPYRIGHT

© 2008-2019 Sebastian Riedel and others.

© 2019 Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
