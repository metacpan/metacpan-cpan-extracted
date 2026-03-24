use v5.36.0;
package Sieve::Generator::Lines::IfElse 0.001;
# ABSTRACT: a Sieve if/elsif/else conditional construct

use Moo;
with 'Sieve::Generator::Lines';

#pod =head1 DESCRIPTION
#pod
#pod An C<IfElse> object renders a Sieve C<if>/C<elsif>/C<else> construct.  It
#pod consists of a required condition and true-branch, optional additional
#pod condition/branch pairs for C<elsif> clauses, and an optional final C<else>
#pod branch.
#pod
#pod =attr cond
#pod
#pod This attribute holds the condition for the C<if> clause.  It may be a plain
#pod string or an object doing L<Sieve::Generator::Text>.
#pod
#pod =attr true
#pod
#pod This attribute holds the block or command to execute when the C<if> condition
#pod is true.  It should be an object doing L<Sieve::Generator::Lines>.
#pod
#pod =attr elsifs
#pod
#pod This attribute holds an arrayref of alternating condition/block pairs for
#pod C<elsif> clauses.  Each pair follows the same rules as C<cond> and C<true>.
#pod If not provided, no C<elsif> clauses are rendered.
#pod
#pod =attr else
#pod
#pod This attribute holds the block or command for the plain C<else> clause.  If
#pod not provided, no C<else> clause is rendered.
#pod
#pod =cut

has cond    => (is => 'ro', required => 1);
has true    => (is => 'ro', required => 1, init_arg => 'true');
has elsifs  => (is => 'ro');
has else    => (is => 'ro');

sub as_sieve ($self, $i = undef) {
  $i //= 0;
  my $indent = q{  } x $i;

  my $str = q{};

  my $in_else;

  use experimental qw(for_list);
  for my ($cond, $block) ($self->cond, $self->true, ($self->elsifs ? $self->elsifs->@* : ())) {
    my $cond_str = ref $cond ? $cond->as_sieve($i) : $cond;
    $cond_str =~ s/\A\Q$indent\E// if ref $cond;
    chomp $cond_str;

    if ($in_else) {
      chomp $str;
      $str .= " elsif $cond_str " . $block->as_sieve($i);
    } else {
      $str .= $indent . "if $cond_str " . $block->as_sieve($i);
    }
    $in_else = 1;
  }

  if ($self->else) {
    chomp $str;
    $str .= " else " . $self->else->as_sieve($i);
  }

  return $str;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Lines::IfElse - a Sieve if/elsif/else conditional construct

=head1 VERSION

version 0.001

=head1 DESCRIPTION

An C<IfElse> object renders a Sieve C<if>/C<elsif>/C<else> construct.  It
consists of a required condition and true-branch, optional additional
condition/branch pairs for C<elsif> clauses, and an optional final C<else>
branch.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 cond

This attribute holds the condition for the C<if> clause.  It may be a plain
string or an object doing L<Sieve::Generator::Text>.

=head2 true

This attribute holds the block or command to execute when the C<if> condition
is true.  It should be an object doing L<Sieve::Generator::Lines>.

=head2 elsifs

This attribute holds an arrayref of alternating condition/block pairs for
C<elsif> clauses.  Each pair follows the same rules as C<cond> and C<true>.
If not provided, no C<elsif> clauses are rendered.

=head2 else

This attribute holds the block or command for the plain C<else> clause.  If
not provided, no C<else> clause is rendered.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
