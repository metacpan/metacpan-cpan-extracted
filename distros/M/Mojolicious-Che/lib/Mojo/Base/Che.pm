package Mojo::Base::Che;

use strict;
use warnings;
use utf8;
use feature ();
#~ binmode(STDOUT, ":utf8");
#~ binmode(STDERR, ":utf8");

# No imports because we get subclassed, a lot!
use Carp ();

# Only Perl 5.14+ requires it on demand
use IO::Handle ();

# Supported on Perl 5.22+
my $NAME
  = eval { require Sub::Util; Sub::Util->can('set_subname') } || sub { $_[1] };

# Protect subclasses using AUTOLOAD
sub DESTROY { }

# Declared here to avoid circular require problems in Mojo::Util
sub _monkey_patch {
  my ($class, %patch) = @_;
  no strict 'refs';
  no warnings 'redefine';
  *{"${class}::$_"} = $NAME->("${class}::$_", $patch{$_}) for keys %patch;
}

sub attr {
  my ($self, $attrs, $value) = @_;
  return unless (my $class = ref $self || $self) && $attrs;

  Carp::croak 'Default has to be a code reference or constant value'
    if ref $value && ref $value ne 'CODE';

  for my $attr (@{ref $attrs eq 'ARRAY' ? $attrs : [$attrs]}) {
    #~ Carp::croak qq{Attribute "$attr" invalid} unless $attr =~ /^[a-zA-Z_]\w*$/;

    # Very performance-sensitive code with lots of micro-optimizations
    if (ref $value) {
      _monkey_patch $class, $attr, sub {
        return
          exists $_[0]{$attr} ? $_[0]{$attr} : ($_[0]{$attr} = $value->($_[0]))
          if @_ == 1;
        $_[0]{$attr} = $_[1];
        $_[0];
      };
    }
    elsif (defined $value) {
      _monkey_patch $class, $attr, sub {
        return exists $_[0]{$attr} ? $_[0]{$attr} : ($_[0]{$attr} = $value)
          if @_ == 1;
        $_[0]{$attr} = $_[1];
        $_[0];
      };
    }
    else {
      _monkey_patch $class, $attr,
        sub { return $_[0]{$attr} if @_ == 1; $_[0]{$attr} = $_[1]; $_[0] };
    }
  }
}

sub import {
  my $class = shift;
  #~ return unless my $flag = shift;
  
  my ($flag, $findbin,);
  my @flags = ();
  my @libs = ();

  # parse flags
  while ((my $it = shift) || @_) {
    unshift @_, @$it
      and next
      if ref $it eq 'ARRAY';
    
    next 
      unless defined($it) && $it =~ m'/|\w';# /  root lib? lets
    
    # controll flag
    if ($it =~ s'^(-\w+)'') {
      
      $flag = $1;
      push @flags, $flag
        and next
        unless $flag eq '-lib';
      
      unshift @_, split m'[:;]+', $it # -lib:foo;bar
        if $it;
      
      next;
      
    } else { # non controll
      
      push @flags, $it
        and next
        unless $flag && $flag eq '-lib';# non lib items
      
    }
    
    # abs lib
    push @libs, $it
      and next
      if $it =~ m'^/';
    
    # relative lib
    $findbin ||= do {
      require FindBin;
      $FindBin::Bin;
    };
    push @libs, $findbin.'/'.$it;
  }
  
  if ( @libs && (my @ok_libs = grep{ my $lib = $_; not scalar grep($lib eq $_, @INC) } @libs) ) {
    require lib;
    lib->import(@ok_libs);
  }
  
  $flag = shift @flags
    or return;

  # Base
  if ($flag eq '-base') { $flag = $class }

  # Strict
  elsif ($flag eq '-strict') { $flag = undef }

  # Module
  elsif ((my $file = $flag) && !$flag->can('new')) {
    $file =~ s!::|'!/!g;
    require "$file.pm";
  }

  # ISA
  if ($flag) {
    my $caller = caller;
    no strict 'refs';
    push @{"${caller}::ISA"}, $flag;
    _monkey_patch $caller, 'has', sub { attr($caller, @_) };
  }

  # Mojo modules are strict!
  $_->import for qw(strict warnings utf8);
  feature->import(':5.10');
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

1;

=pod

=encoding utf8

Доброго всем

=head1 Mojo::Base::Che

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojo::Base::Che - use Mojo::Base::Che 'SomeBaseClass',-lib, qw(rel/path/lib /abs/path/lib);

=head1 DESCR

Чистая копия L<Mojo::Base> и небольшие патчи.

=head2 Причины патчей

1. Добавление путей в @INC;

2. Разрешены хазы не латиницей;

=head1 SYNOPSIS

This module provide a fourth extended form for add extra lib directories to perl's search path. See <lib>

  use Mojo::Base::Che -lib, qw(rel/path/lib /abs/path/lib);
  use Mojo::Base::Che -lib, ['lib1', 'lib2'];
  use Mojo::Base::Che '-lib:lib1:lib2;lib3';
  use Mojo::Base::Che -strict, qw(-lib lib1 lib2);
  use Mojo::Base::Che qw(-base -lib lib1 lib2);
  use Mojo::Base::Che 'SomeBaseClass', qw(-lib lib1 lib2);
  
  has qw(хаз);

For relative lib path will use L<FindBin> module and C<$FindBin::Bin> is prepends to that lib.
Libs always applied first even its last on flags list.

All three L<Mojo::Base> forms works also.

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