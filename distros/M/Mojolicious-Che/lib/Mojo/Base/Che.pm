package Mojo::Base::Che;
# ABSTRACT: some patch for Mojo::Base(current 7.61)

use Mojo::Base -strict;

# copy-paste sub Mojo::Base::attr + patch 1 line
sub Mojo::Base::attr {
  my ($self, $attrs, $value) = @_;
  return unless (my $class = ref $self || $self) && $attrs;

  Carp::croak 'Default has to be a code reference or constant value'
    if ref $value && ref $value ne 'CODE';

  for my $attr (@{ref $attrs eq 'ARRAY' ? $attrs : [$attrs]}) {
    # patch
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


#~ sub import {
  #~ my ($class, $caller) = (shift, caller);
  #~ my @flags = _lib_flags(@_);
  #~ Mojo::Base->import(@flags); # patch 2
#~ }


#~ sub _lib_flags {# patch2
  #~ my ($flag, $findbin, @flags, @libs) = ();

  #~ while ((my $it = shift) || @_) {# parse flags
    #~ unshift @_, @$it
      #~ and next
      #~ if ref $it eq 'ARRAY';
     
    #~ next
      #~ unless defined($it) && $it =~ m'/|\w';# /  root lib? lets

    #~ if ($it =~ s'^(-\w+)'') {# controll flag
      #~ $flag = $1;
      #~ push @flags, $flag
        #~ and next
        #~ unless $flag eq '-lib';

      #~ unshift @_, split m'[:;]+', $it # -lib:foo;bar
        #~ if $it;

      #~ next;
    #~ } elsif (!$flag || $flag ne '-lib') { # non controll
      #~ push @flags, $it;
      #~ next;
        #~ # unless $flag && $flag eq '-lib';# non lib items
    #~ }
    
    #~ push @libs, $it # abs lib
      #~ and next
      #~ if $it =~ m'^/';
    
    #~ $findbin ||= require FindBin && $FindBin::Bin;# relative lib
    #~ push @libs, $findbin.'/'.$it;
  #~ }
  
  #~ my @ok_libs = grep { my $lib = $_; not scalar grep($lib eq $_, @INC) } @libs
    #~ if @libs;
  #~ require lib
    #~ and lib->import(@ok_libs)
    #~ if @ok_libs;
  
  #~ return @flags;
#~ }

1;

=pod

=encoding utf8

Доброго всем

=head1 Mojo::Base::Che

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojo::Base::Che - some patch for Mojo::Base

=head1 DESCRIPTION

Патчи L<Mojo::Base>.

=head2 Причины патчей

1. НЕТ!!NO!!!1111 Добавление путей в @INC;

2. Разрешены хазы/атрибуты не только латиницей;

=head1 SYNOPSIS

НЕТ!!NO!!!1111 This module provide a extended form for add extra lib directories to perl's search path. See L<lib>

  НЕТ!!NO!!!1111 use Mojo::Base::Che -lib, qw(rel/path/lib /abs/path/lib);
  НЕТ!!NO!!!1111 use Mojo::Base::Che -lib, ['lib1', 'lib2'];
  НЕТ!!NO!!!1111 use Mojo::Base::Che '-lib:lib1:lib2;lib3';
  НЕТ!!NO!!!1111 use Mojo::Base::Che -strict, qw(-lib lib1 lib2);
  НЕТ!!NO!!!1111 use Mojo::Base::Che qw(-base -lib lib1 lib2);
  НЕТ!!NO!!!1111 use Mojo::Base::Che 'SomeBaseClass', qw(-lib lib1 lib2);
  
  use lib 'lib';
  use Mojo::Base  'Foo';
  use Mojo::Base::Che; # apply patch
  # GLORY utf names allow
  has [qw(☭хаза ☆маза)];

НЕТ!!NO!!!1111 For relative lib path will use L<FindBin> module and C<$FindBin::Bin> is prepends to that lib.
НЕТ!!NO!!!1111 Libs always applied first even its last on flags list.

=head1 SEE ALSO

L<Mojo::Base>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Che/issues>.

=head1 COPYRIGHT

Copyright 2016-2018+ Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut