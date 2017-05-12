use strict;
use warnings;
package Test::Tolerant;
# ABSTRACT: test routines for testing numbers against tolerances
$Test::Tolerant::VERSION = '1.708';
#pod =head1 SYNOPSIS
#pod
#pod   use Test::More;
#pod   use Test::Tolerant;
#pod
#pod   my $total = rand(6) + rand(6) + rand(6);
#pod   is_tol(10, [ qw( 3 to 18 ) ], "got an acceptable result from random dice");
#pod
#pod   done_testing;
#pod
#pod =head1 FUNCTIONS
#pod
#pod =head2 is_tol
#pod
#pod   is_tol($have, $want_spec, $comment);
#pod
#pod C<is_tol> is the only routine provided by Test::Tolerant, and is exported by
#pod default.  It beahves like C<L<is|Test::More/is>> from Test::More, asserting
#pod that two values must be equal, but it will always use numeric equality, and the
#pod second argument is not always used as the right hand side of comparison
#pod directly, but it used to produce a L<Number::Tolerant> to compare to.
#pod
#pod C<$have_spec> can be:
#pod
#pod   * a Number::Tolerant object
#pod   * an arrayref of args to Number::Tolerant->new
#pod   * a string to be passed to Number::Tolerant->from_string
#pod     * a literal number falls under this group
#pod
#pod If the value is outside of spec, you'll get a diagnostic message something like
#pod this:
#pod
#pod   given value is outside acceptable tolerances
#pod       have: 3
#pod       want: 5 < x
#pod
#pod =cut

use Carp ();
use Number::Tolerant qw(tolerance);
use Scalar::Util qw(blessed looks_like_number reftype);
use Test::Builder;

use Sub::Exporter -setup => {
  exports => [ qw(is_tol) ],
  groups  => [
    default => [ qw(is_tol) ],
  ],
};

my $Test = Test::Builder->new;

sub is_tol {
  my ($have, $spec, $desc) = @_;

  my $want;

  if (blessed $spec and $spec->isa('Number::Tolerant')) {
    $want = $spec;
  } elsif (ref $spec and not(blessed $spec) and reftype $spec eq 'ARRAY') {
    $want = tolerance(@$spec);
  } elsif (! ref $spec) {
    $want = Number::Tolerant->from_string($spec);
  }

  Carp::croak("couldn't build a tolerance from $spec") unless defined $want;

  return 1 if $Test->ok($have == $want, $desc);

  # XXX: make this work -- rjbs, 2010-11-29
  my $cmp = $have <=> $want;
  my $why = $cmp == -1 ? "is below"
          : $cmp ==  1 ? "is above"
          :              "is outside";

  $Test->diag("given value $why acceptable tolerances");
  $Test->diag(sprintf "%8s: %s\n%8s: %s\n", have => $have, want => $want);

  return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Tolerant - test routines for testing numbers against tolerances

=head1 VERSION

version 1.708

=head1 SYNOPSIS

  use Test::More;
  use Test::Tolerant;

  my $total = rand(6) + rand(6) + rand(6);
  is_tol(10, [ qw( 3 to 18 ) ], "got an acceptable result from random dice");

  done_testing;

=head1 FUNCTIONS

=head2 is_tol

  is_tol($have, $want_spec, $comment);

C<is_tol> is the only routine provided by Test::Tolerant, and is exported by
default.  It beahves like C<L<is|Test::More/is>> from Test::More, asserting
that two values must be equal, but it will always use numeric equality, and the
second argument is not always used as the right hand side of comparison
directly, but it used to produce a L<Number::Tolerant> to compare to.

C<$have_spec> can be:

  * a Number::Tolerant object
  * an arrayref of args to Number::Tolerant->new
  * a string to be passed to Number::Tolerant->from_string
    * a literal number falls under this group

If the value is outside of spec, you'll get a diagnostic message something like
this:

  given value is outside acceptable tolerances
      have: 3
      want: 5 < x

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
