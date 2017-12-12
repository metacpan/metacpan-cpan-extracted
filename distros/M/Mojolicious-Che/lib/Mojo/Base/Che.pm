package Mojo::Base::Che;
# ABSTRACT: current copied from Mojo::Base 7.57 + comment the line 33 + sub _lib_flags
use strict;
use warnings;
use utf8;
use feature ();

# No imports because we get subclassed, a lot!
use Carp         ();
use Scalar::Util ();

# Defer to runtime so Mojo::Util can use "-strict"
require Mojo::Util;

# Only Perl 5.14+ requires it on demand
use IO::Handle ();

# Role support requires Role::Tiny 2.000001+
use constant ROLES =>
  !!(eval { require Role::Tiny; Role::Tiny->VERSION('2.000001'); 1 });

# Protect subclasses using AUTOLOAD
sub DESTROY { }

sub attr {
  my ($self, $attrs, $value) = @_;
  return unless (my $class = ref $self || $self) && $attrs;

  Carp::croak 'Default has to be a code reference or constant value'
    if ref $value && ref $value ne 'CODE';

  for my $attr (@{ref $attrs eq 'ARRAY' ? $attrs : [$attrs]}) {
    # patch1
    #~ Carp::croak qq{Attribute "$attr" invalid} unless $attr =~ /^[a-zA-Z_]\w*$/;

    # Very performance-sensitive code with lots of micro-optimizations
    if (ref $value) {
      my $sub = sub {
        return
          exists $_[0]{$attr} ? $_[0]{$attr} : ($_[0]{$attr} = $value->($_[0]))
          if @_ == 1;
        $_[0]{$attr} = $_[1];
        $_[0];
      };
      Mojo::Util::monkey_patch($class, $attr, $sub);
    }
    elsif (defined $value) {
      my $sub = sub {
        return exists $_[0]{$attr} ? $_[0]{$attr} : ($_[0]{$attr} = $value)
          if @_ == 1;
        $_[0]{$attr} = $_[1];
        $_[0];
      };
      Mojo::Util::monkey_patch($class, $attr, $sub);
    }
    else {
      Mojo::Util::monkey_patch($class, $attr,
        sub { return $_[0]{$attr} if @_ == 1; $_[0]{$attr} = $_[1]; $_[0] });
    }
  }
}

sub import {
  my ($class, $caller) = (shift, caller);
  return unless my @flags = _lib_flags(@_);

  # Base
  if ($flags[0] eq '-base') { $flags[0] = $class }

  # Strict
  elsif ($flags[0] eq '-strict') { $flags[0] = undef }

  # Role
  elsif ($flags[0] eq '-role') {
    Carp::croak 'Role::Tiny 2.000001+ is required for roles' unless ROLES;
    eval "package $caller; use Role::Tiny; 1" or die $@;
  }

  # Module
  elsif ($flags[0] && !$flags[0]->can('new')) {
    require(Mojo::Util::class_to_path($flags[0]));
  }

  # "has" and possibly ISA
  if ($flags[0]) {
    no strict 'refs';
    push @{"${caller}::ISA"}, $flags[0] unless $flags[0] eq '-role';
    Mojo::Util::monkey_patch($caller, 'has', sub { attr($caller, @_) });
  }

  # Mojo modules are strict!
  $_->import for qw(strict warnings utf8);
  feature->import(':5.10');

  # Signatures (Perl 5.20+)
  if (($flags[1] || '') eq '-signatures') {
    Carp::croak 'Subroutine signatures require Perl 5.20+' if $] < 5.020;
    require experimental;
    experimental->import('signatures');
  }
}

sub _lib_flags {# patch2
  my ($flag, $findbin, @flags, @libs) = ();

  while ((my $it = shift) || @_) {# parse flags
    unshift @_, @$it
      and next
      if ref $it eq 'ARRAY';
     
    next
      unless defined($it) && $it =~ m'/|\w';# /  root lib? lets

    if ($it =~ s'^(-\w+)'') {# controll flag
      $flag = $1;
      push @flags, $flag
        and next
        unless $flag eq '-lib';

      unshift @_, split m'[:;]+', $it # -lib:foo;bar
        if $it;

      next;
    } elsif (!$flag || $flag ne '-lib') { # non controll
      push @flags, $it;
      next;
        #~ unless $flag && $flag eq '-lib';# non lib items
    }
    
    push @libs, $it # abs lib
      and next
      if $it =~ m'^/';
    
    $findbin ||= require FindBin && $FindBin::Bin;# relative lib
    push @libs, $findbin.'/'.$it;
  }
  
  my @ok_libs = grep { my $lib = $_; not scalar grep($lib eq $_, @INC) } @libs
    if @libs;
  require lib
    and lib->import(@ok_libs)
    if @ok_libs;
  
  return @flags;
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

1;

=pod

=encoding utf8

Доброго всем

=head1 Mojo::Base::Che

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojo::Base::Che - current copied from L<Mojo::Base> 7.57 where commented the line 33 + sub _lib_flags

=head1 DESCRIPTION

Чистая копия L<Mojo::Base> и небольшие патчи.

=head2 Причины патчей

1. Добавление путей в @INC;

2. Разрешены хазы/атрибуты не только латиницей;

=head1 SYNOPSIS

This module provide a extended form for add extra lib directories to perl's search path. See L<lib>

  use Mojo::Base::Che -lib, qw(rel/path/lib /abs/path/lib);
  use Mojo::Base::Che -lib, ['lib1', 'lib2'];
  use Mojo::Base::Che '-lib:lib1:lib2;lib3';
  use Mojo::Base::Che -strict, qw(-lib lib1 lib2);
  use Mojo::Base::Che qw(-base -lib lib1 lib2);
  use Mojo::Base::Che 'SomeBaseClass', qw(-lib lib1 lib2);
  
  # non latinic names allow
  has qw(хаз);

For relative lib path will use L<FindBin> module and C<$FindBin::Bin> is prepends to that lib.
Libs always applied first even its last on flags list.

Other L<Mojo::Base> forms works also.

=head1 SEE ALSO

L<Mojo::Base>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Che/issues>.

=head1 COPYRIGHT

Copyright 2016 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut