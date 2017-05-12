use strict;
use warnings;
package Sort::ByExample;
# ABSTRACT: sort lists to look like the example you provide
$Sort::ByExample::VERSION = '0.007';
#pod =head1 SYNOPSIS
#pod
#pod   use Sort::ByExample
#pod    cmp    => { -as => 'by_eng',   example => [qw(first second third fourth)] },
#pod    sorter => { -as => 'eng_sort', example => [qw(first second third fourth)] };
#pod
#pod   my @output = eng_sort(qw(second third unknown fourth first));
#pod   # --> first second third fourth unknown
#pod
#pod   # ...or...
#pod
#pod   my @output = sort by_eng qw(second third unknown fourth first);
#pod   # --> first second third fourth unknown
#pod
#pod   # ...or...
#pod
#pod   my $sorter = Sort::ByExample::sbe(\@example);
#pod   my @output = $sorter->( qw(second third unknown fourth first) );
#pod   # --> first second third fourth unknown
#pod
#pod   # ...or...
#pod
#pod   my $example = [ qw(charlie alfa bravo) ];
#pod   my @input   = (
#pod     { name => 'Bertrand', codename => 'bravo'   },
#pod     { name => 'Dracover', codename => 'zulu',   },
#pod     { name => 'Cheswick', codename => 'charlie' },
#pod     { name => 'Elbereth', codename => 'yankee'  },
#pod     { name => 'Algernon', codename => 'alfa'    },
#pod   );
#pod
#pod   my $fallback = sub {
#pod     my ($x, $y) = @_;
#pod     return $x cmp $y;
#pod   };
#pod
#pod   my $sorter = sbe(
#pod     $example,
#pod     {
#pod       fallback => $fallback,
#pod       xform    => sub { $_[0]->{codename} },
#pod     },
#pod   );
#pod
#pod   my @output = $sorter->(@input);
#pod
#pod   # --> (
#pod   #       { name => 'Cheswick', codename => 'charlie' },
#pod   #       { name => 'Algernon', codename => 'alfa'    },
#pod   #       { name => 'Bertrand', codename => 'bravo'   },
#pod   #       { name => 'Elbereth', codename => 'yankee'  },
#pod   #       { name => 'Dracover', codename => 'zulu',   },
#pod   #     );
#pod
#pod =head1 DESCRIPTION
#pod
#pod Sometimes, you need to sort things in a pretty arbitrary order.  You know that
#pod you might encounter any of a list of values, and you have an idea what order
#pod those values go in.  That order is arbitrary, as far as actual automatic
#pod comparison goes, but that's the order you want.
#pod
#pod Sort::ByExample makes this easy:  you give it a list of example input it should
#pod expect, pre-sorted, and it will sort things that way.  If you want, you can
#pod provide a fallback sub for sorting unknown or equally-positioned data.
#pod
#pod =cut

use Params::Util qw(_HASHLIKE _ARRAYLIKE _CODELIKE);
use Sub::Exporter -setup => {
  exports => {
    sbe    => undef,
    cmp    => \'_build_cmp',
    sorter => \'_build_sorter',
  },
};

#pod =method sorter
#pod
#pod   my $sorter = Sort::ByExample->sorter($example, $fallback);
#pod   my $sorter = Sort::ByExample->sorter($example, \%arg);
#pod
#pod The sorter method returns a subroutine that will sort lists to look more like
#pod the example list.
#pod
#pod C<$example> may be a reference to an array, in which case input will be sorted
#pod into the same order as the data in the array reference.  Input not found in the
#pod example will be found at the end of the output, sorted by the fallback sub if
#pod given (see below).
#pod
#pod Alternately, the example may be a reference to a hash.  Values are used to
#pod provide sort orders for input values.  Input values with the same sort value
#pod are sorted by the fallback sub, if given.
#pod
#pod If given named arguments as C<%arg>, valid arguments are:
#pod
#pod   fallback - a sub to sort data 
#pod   xform    - a sub to transform each item into the key to sort
#pod
#pod If no other named arguments are needed, the fallback sub may be given in place
#pod of the arg hashref.
#pod
#pod The fallback sub should accept two inputs and return either 1, 0, or -1, like a
#pod normal sorting routine.  The data to be sorted are passed as parameters.  For
#pod uninteresting reasons, C<$a> and C<$b> can't be used.
#pod
#pod The xform sub should accept one argument and return the data by which to sort
#pod that argument.  In other words, to sort a group of athletes by their medals:
#pod
#pod   my $sorter = sbe(
#pod     [ qw(Gold Silver Bronze) ],
#pod     {
#pod       xform => sub { $_[0]->medal_metal },
#pod     },
#pod   );
#pod
#pod If both xform and fallback are given, then four arguments are passed to
#pod fallback:
#pod
#pod   a_xform, b_xform, a_original, b_original
#pod
#pod =method cmp
#pod
#pod   my $comparitor = Sort::ByExample->cmp($example, \%arg);
#pod
#pod This routine expects the same sort of arguments as C<L</sorter>>, but returns a
#pod subroutine that behaves like a C<L<sort|perlfunc/sort>> comparitor.  It will
#pod take two arguments and return 1, 0, or -1.
#pod
#pod C<cmp> I<must not> be given an C<xform> argument or an exception will be
#pod raised.  This behavior may change in the future, but because a
#pod single-comparison comparitor cannot efficiently perform a L<Schwartzian
#pod transform|http://en.wikipedia.org/wiki/Schwartzian_transform>, using a
#pod purpose-build C<L</sorter>> is a better idea.
#pod
#pod =head1 EXPORTS
#pod
#pod =head2 sbe
#pod
#pod C<sbe> behaves just like C<L</sorter>>, but is a function rather than a method.
#pod It may be imported by request.
#pod
#pod =head2 sorter
#pod
#pod The C<sorter> export builds a function that behaves like the C<sorter> method.
#pod
#pod =head2 cmp
#pod
#pod The C<cmp> export builds a function that behaves like the C<cmp> method.
#pod Because C<sort> requires a named sub, importing C<cmp> can be very useful:
#pod
#pod   use Sort::ByExample
#pod    cmp    => { -as => 'by_eng',   example => [qw(first second third fourth)] };
#pod
#pod   my @output = sort by_eng qw(second third unknown fourth first);
#pod   # --> first second third fourth unknown
#pod
#pod =cut

sub sbe { __PACKAGE__->sorter(@_) }

sub __normalize_args {
  my ($self, $example, $arg) = @_;

  my $score = 0;
  my %score = _HASHLIKE($example)  ? %$example
            : _ARRAYLIKE($example) ? (map { $_ => $score++ } @$example)
            : Carp::confess "invalid example data given to Sort::ByExample";

  my $fallback;
  if (_HASHLIKE($arg)) {
    $fallback = $arg->{fallback};
  } else {
    $fallback = $arg;
    $arg = {};
  }

  Carp::croak "invalid fallback routine"
    if $fallback and not _CODELIKE($fallback);

  return (\%score, $fallback, $arg);
}

sub __cmp {
  my ($self, $score, $fallback, $arg) = @_;

  return sub ($$) {
    my ($a, $b) = @_;
      (exists $score->{$a} && exists $score->{$b})
        ? ($score->{$a} <=> $score->{$b}) || ($fallback ? $fallback->($a, $b) : 0)
    : exists $score->{$a}                        ? -1
    : exists $score->{$b}                        ? 1
    : ($fallback ? $fallback->($a, $b) : 0)
  };
}

sub cmp {
  my ($self, $example, $rest) = @_;

  my ($score, $fallback, $arg) = $self->__normalize_args($example, $rest);

  Carp::confess "you may not build a transformation into a comparitor"
    if $arg->{xform};

  $self->__cmp($score, $fallback, $arg);
}

sub sorter {
  my ($self, $example, $rest) = @_;

  my ($score, $fallback, $arg) = $self->__normalize_args($example, $rest);

  if (my $xf = $arg->{xform}) {
    return sub {
      map  { $_->[1] }
      sort {
        (exists $score->{$a->[0]} && exists $score->{$b->[0]})
          ? ($score->{$a->[0]} <=> $score->{$b->[0]})
            || ($fallback ? $fallback->($a->[0], $b->[0], $a->[1], $b->[1]) : 0)
      : exists $score->{$a->[0]}                        ? -1
      : exists $score->{$b->[0]}                        ? 1
      : ($fallback ? $fallback->($a->[0], $b->[0], $a->[1], $b->[1]) : 0)
      } map { [ $xf->($_), $_ ] } @_;
    }
  }

  my $cmp = $self->__cmp($score, $fallback, $arg);

  sub { sort { $cmp->($a, $b) } @_ }
}

sub _build_sorter {
  my ($self, $name, $arg) = @_;
  my ($example) = $arg->{example};
  local $arg->{example};

  $self->sorter($example, $arg);
}

sub _build_cmp {
  my ($self, $name, $arg) = @_;
  my ($example) = $arg->{example};
  local $arg->{example};

  $self->cmp($example, $arg);
}

#pod =head1 TODO
#pod
#pod =for :list
#pod * provide a way to say "these things occur after any unknowns"
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::ByExample - sort lists to look like the example you provide

=head1 VERSION

version 0.007

=head1 SYNOPSIS

  use Sort::ByExample
   cmp    => { -as => 'by_eng',   example => [qw(first second third fourth)] },
   sorter => { -as => 'eng_sort', example => [qw(first second third fourth)] };

  my @output = eng_sort(qw(second third unknown fourth first));
  # --> first second third fourth unknown

  # ...or...

  my @output = sort by_eng qw(second third unknown fourth first);
  # --> first second third fourth unknown

  # ...or...

  my $sorter = Sort::ByExample::sbe(\@example);
  my @output = $sorter->( qw(second third unknown fourth first) );
  # --> first second third fourth unknown

  # ...or...

  my $example = [ qw(charlie alfa bravo) ];
  my @input   = (
    { name => 'Bertrand', codename => 'bravo'   },
    { name => 'Dracover', codename => 'zulu',   },
    { name => 'Cheswick', codename => 'charlie' },
    { name => 'Elbereth', codename => 'yankee'  },
    { name => 'Algernon', codename => 'alfa'    },
  );

  my $fallback = sub {
    my ($x, $y) = @_;
    return $x cmp $y;
  };

  my $sorter = sbe(
    $example,
    {
      fallback => $fallback,
      xform    => sub { $_[0]->{codename} },
    },
  );

  my @output = $sorter->(@input);

  # --> (
  #       { name => 'Cheswick', codename => 'charlie' },
  #       { name => 'Algernon', codename => 'alfa'    },
  #       { name => 'Bertrand', codename => 'bravo'   },
  #       { name => 'Elbereth', codename => 'yankee'  },
  #       { name => 'Dracover', codename => 'zulu',   },
  #     );

=head1 DESCRIPTION

Sometimes, you need to sort things in a pretty arbitrary order.  You know that
you might encounter any of a list of values, and you have an idea what order
those values go in.  That order is arbitrary, as far as actual automatic
comparison goes, but that's the order you want.

Sort::ByExample makes this easy:  you give it a list of example input it should
expect, pre-sorted, and it will sort things that way.  If you want, you can
provide a fallback sub for sorting unknown or equally-positioned data.

=head1 METHODS

=head2 sorter

  my $sorter = Sort::ByExample->sorter($example, $fallback);
  my $sorter = Sort::ByExample->sorter($example, \%arg);

The sorter method returns a subroutine that will sort lists to look more like
the example list.

C<$example> may be a reference to an array, in which case input will be sorted
into the same order as the data in the array reference.  Input not found in the
example will be found at the end of the output, sorted by the fallback sub if
given (see below).

Alternately, the example may be a reference to a hash.  Values are used to
provide sort orders for input values.  Input values with the same sort value
are sorted by the fallback sub, if given.

If given named arguments as C<%arg>, valid arguments are:

  fallback - a sub to sort data 
  xform    - a sub to transform each item into the key to sort

If no other named arguments are needed, the fallback sub may be given in place
of the arg hashref.

The fallback sub should accept two inputs and return either 1, 0, or -1, like a
normal sorting routine.  The data to be sorted are passed as parameters.  For
uninteresting reasons, C<$a> and C<$b> can't be used.

The xform sub should accept one argument and return the data by which to sort
that argument.  In other words, to sort a group of athletes by their medals:

  my $sorter = sbe(
    [ qw(Gold Silver Bronze) ],
    {
      xform => sub { $_[0]->medal_metal },
    },
  );

If both xform and fallback are given, then four arguments are passed to
fallback:

  a_xform, b_xform, a_original, b_original

=head2 cmp

  my $comparitor = Sort::ByExample->cmp($example, \%arg);

This routine expects the same sort of arguments as C<L</sorter>>, but returns a
subroutine that behaves like a C<L<sort|perlfunc/sort>> comparitor.  It will
take two arguments and return 1, 0, or -1.

C<cmp> I<must not> be given an C<xform> argument or an exception will be
raised.  This behavior may change in the future, but because a
single-comparison comparitor cannot efficiently perform a L<Schwartzian
transform|http://en.wikipedia.org/wiki/Schwartzian_transform>, using a
purpose-build C<L</sorter>> is a better idea.

=head1 EXPORTS

=head2 sbe

C<sbe> behaves just like C<L</sorter>>, but is a function rather than a method.
It may be imported by request.

=head2 sorter

The C<sorter> export builds a function that behaves like the C<sorter> method.

=head2 cmp

The C<cmp> export builds a function that behaves like the C<cmp> method.
Because C<sort> requires a named sub, importing C<cmp> can be very useful:

  use Sort::ByExample
   cmp    => { -as => 'by_eng',   example => [qw(first second third fourth)] };

  my @output = sort by_eng qw(second third unknown fourth first);
  # --> first second third fourth unknown

=head1 TODO

=over 4

=item *

provide a way to say "these things occur after any unknowns"

=back

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
