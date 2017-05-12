package PERLANCAR::List::Util::PP;

our $DATE = '2015-12-18'; # DATE
our $VERSION = '0.04'; # VERSION

#IFUNBUILT
use strict 'vars', 'subs';
use warnings;
#END IFUNBUILT

require Exporter;
our @EXPORT_OK = qw(
                       all
                       any
                       max
                       maxstr
                       min
                       minstr
                       none
                       notall
                       pairfirst
                       pairgrep
                       pairkeys
                       pairmap
                       pairs
                       pairvalues
                       product
                       reduce
                       shuffle
                       sum
                       sum0
                       unpairs
               );

sub import {
  my $pkg = caller;

  # (RT88848) Touch the caller's $a and $b, to avoid the warning of
  #   Name "main::a" used only once: possible typo" warning
  #no strict 'refs';
  ${"${pkg}::a"} = ${"${pkg}::a"};
  ${"${pkg}::b"} = ${"${pkg}::b"};

  goto &Exporter::import;
}

# BEGIN_BLOCK: all
sub all (&@) {
  my $f = shift;
  $f->() or return 0
    foreach @_;
  return 1;
}
# END_BLOCK: all

# BEGIN_BLOCK: any
sub any (&@) {
  my $f = shift;
  $f->() and return 1
    foreach @_;
  return 0;
}
# END_BLOCK: any

# BEGIN_BLOCK: max
sub max(@) {
    return undef unless @_;
    my $res = $_[0];
    my $i = 0;
    while (++$i < @_) { $res = $_[$i] if $_[$i] > $res }
    $res;
}
# END_BLOCK: max

# BEGIN_BLOCK: maxstr
sub maxstr(@) {
    return undef unless @_;
    my $res = $_[0];
    my $i = 0;
    while (++$i < @_) { $res = $_[$i] if $_[$i] gt $res }
    $res;
}
# END_BLOCK: maxstr

# BEGIN_BLOCK: min
sub min(@) {
    return undef unless @_;
    my $res = $_[0];
    my $i = 0;
    while (++$i < @_) { $res = $_[$i] if $_[$i] < $res }
    $res;
}
# END_BLOCK: min

# BEGIN_BLOCK: minstr
sub minstr(@) {
    return undef unless @_;
    my $res = $_[0];
    my $i = 0;
    while (++$i < @_) { $res = $_[$i] if $_[$i] lt $res }
    $res;
}
# END_BLOCK: minstr

# BEGIN_BLOCK: none
sub none (&@) {
  my $f = shift;
  $f->() and return 0
    foreach @_;
  return 1;
}
# END_BLOCK: none

# BEGIN_BLOCK: notall
sub notall (&@) {
  my $f = shift;
  $f->() or return 1
    foreach @_;
  return 0;
}
# END_BLOCK: notall

# BEGIN_BLOCK: pairfirst
sub pairfirst (&@) {
  my $f = shift;
  if (@_ % 2) {
    warn "Odd number of elements in pairfirst";
  }

  my $pkg = caller;
  #no strict 'refs';
  my $glob_a = \*{"${pkg}::a"};
  my $glob_b = \*{"${pkg}::b"};

  foreach my $i (map $_*2, 0 .. int($#_/2)) {
    local (*$glob_a, *$glob_b) = \( @_[$i,$i+1] );
    return wantarray ? @_[$i,$i+1] : 1
      if $f->();
  }
  return ();
}
# END_BLOCK: pairfirst

# BEGIN_BLOCK: pairgrep
sub pairgrep (&@) {
  my $f = shift;
  if (@_ % 2) {
    warn "Odd number of elements in pairgrep";
  }

  my $pkg = caller;
  #no strict 'refs';
  my $glob_a = \*{"${pkg}::a"};
  my $glob_b = \*{"${pkg}::b"};

  return
    map {
      local (*$glob_a, *$glob_b) = \( @_[$_,$_+1] );
      $f->() ? (wantarray ? @_[$_,$_+1] : 1) : ();
    }
    map $_*2,
    0 .. int ($#_/2);
}
# END_BLOCK: pairgrep

# BEGIN_BLOCK: pairkeys
sub pairkeys (@) {
  if (@_ % 2) {
    warn "Odd number of elements in pairkeys";
  }

  return
    map $_[$_*2],
    0 .. int($#_/2);
}
# END_BLOCK: pairkeys

# BEGIN_BLOCK: pairmap
sub pairmap (&@) {
  my $f = shift;
  if (@_ % 2) {
    warn "Odd number of elements in pairmap";
  }

  my $pkg = caller;
  #no strict 'refs';
  my $glob_a = \*{"${pkg}::a"};
  my $glob_b = \*{"${pkg}::b"};

  return
    map {
      local (*$glob_a, *$glob_b) = \( @_[$_,$_+1] );
      $f->();
    }
    map $_*2,
    0 .. int($#_/2);
}
# END_BLOCK: pairmap

# BEGIN_BLOCK: pairs
sub pairs (@) {
  if (@_ % 2) {
    warn 'Odd number of elements in pairs';
  }

  return
    map { bless [ @_[$_, $_ + 1] ], 'List::Util::PP::_Pair' }
    map $_*2,
    0 .. int($#_/2);
}
sub List::Util::PP::_Pair::key   { $_[0][0] }
sub List::Util::PP::_Pair::value { $_[0][1] }
# END_BLOCK: pairs

# BEGIN_BLOCK: pairvalues
sub pairvalues (@) {
  if (@_ % 2) {
    #require Carp;
    warn 'Odd number of elements in pairvalues';
  }

  return
    map $_[$_*2 + 1],
    0 .. int($#_/2);
}
# END_BLOCK: pairvalues

# BEGIN_BLOCK: product
sub product (@) {
  my $p = 1;
  $p *= $_ foreach @_;
  return $p;
}
# END_BLOCK: product

# BEGIN_BLOCK: reduce
sub reduce (&@) {
  my $f = shift;
  unless ( ref $f && eval { \&$f } ) {
    #require Carp;
    die "Not a subroutine reference";
  }

  return shift unless @_ > 1;

  my $pkg = caller;
  my $a = shift;

  #no strict 'refs';
  local *{"${pkg}::a"} = \$a;
  my $glob_b = \*{"${pkg}::b"};

  foreach my $b (@_) {
    local *$glob_b = \$b;
    $a = $f->();
  }

  $a;
}
# END_BLOCK: reduce

# BEGIN_BLOCK: shuffle
sub shuffle (@) {
  my @a=\(@_);
  my $n;
  my $i=@_;
  map {
    $n = rand($i--);
    (${$a[$n]}, $a[$n] = $a[$i])[0];
  } @_;
}
# END_BLOCK: shuffle

# BEGIN_BLOCK: sum
sub sum (@) {
  return undef unless @_;
  my $s = 0;
  $s += $_ foreach @_;
  return $s;
}
# END_BLOCK: sum

# BEGIN_BLOCK: sum0
sub sum0 (@) {
  my $s = 0;
  $s += $_ foreach @_;
  return $s;
}
# END_BLOCK: sum0

# BEGIN_BLOCK: unpairs
sub unpairs (@) {
  map @{$_}[0,1], @_;
}
# END_BLOCK: unpairs

1;
# ABSTRACT: Pure-perl implementation of List::Util

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::List::Util::PP - Pure-perl implementation of List::Util

=head1 VERSION

This document describes version 0.04 of PERLANCAR::List::Util::PP (from Perl distribution PERLANCAR-List-Util-PP), released on 2015-12-18.

=head1 SYNOPSIS

Use as you would use List::Util:

 use PERLANCAR::List::Util::PP qw(max min maxstr minstr);

 my $max = max @list;
 my $min = min @list;

=head1 DESCRIPTION

Most of the time you will not need this module. Use L<List::Util> instead. This
module is useful for testing/benchmarking, or perhaps in the rare case where you
cannot use any XS module (even core ones) or in the rare case where you cannot
use I<any> module, in which case you can copy-and-paste the routines from this
module (or, if you use L<Dist::Zilla>, you can also use
L<Dist::Zilla::Plugin::InsertBlock>).

Most of the code is from the old List::Util::PP code [2], which was dropped from
the Scalar-List-Utils distribution and was no longer part of core perl.

=head1 FUNCTIONS

For more details on each function, see List::Util.

=head2 all

=head2 any

=head2 first

=head2 max

=head2 maxstr

=head2 min

=head2 minstr

=head2 none

=head2 notall

=head2 pairfirst

=head2 pairgrep

=head2 pairkeys

=head2 pairmap

=head2 pairs

=head2 pairvalues

=head2 product

=head2 reduce

=head2 shuffle

=head2 sum

=head2 sum0

=head2 unpairs

=head1 SEE ALSO

[1] L<List::Util>

[2] L<https://github.com/haarg/List-Util/blob/pp/lib/List/Util/PP.pm>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PERLANCAR-List-Util-PP>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-List-Util-PP>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PERLANCAR-List-Util-PP>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
