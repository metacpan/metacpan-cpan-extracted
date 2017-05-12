use strict;
use warnings;
package Perl::Critic::Policy::Tics::ProhibitManyArrows;
# ABSTRACT: (this => is => not => good)
$Perl::Critic::Policy::Tics::ProhibitManyArrows::VERSION = '0.009';
#pod =head1 DESCRIPTION
#pod
#pod You are not clever if you do this:
#pod
#pod   my %hash = (key1=>value1=>key2=>value2=>key3=>'value3');
#pod
#pod You are even more not clever if you do this:
#pod
#pod   my %hash = (key1=>value1=>key2=>value2=>key3=>value3=>);
#pod
#pod =head1 CONFIGURATION
#pod
#pod There is one parameter for this policy, F<max_allowed>, which specifies the
#pod maximum number of fat arrows that may appear as item separators.  The default
#pod is two.  If you really hate the fat arrow, and never want to see it, you can
#pod set F<max_allowed> to zero and make any occurance of C<< => >> illegal.
#pod
#pod Here are some examples of code that would fail with various F<max_allowed>
#pod values:
#pod
#pod   max_allowed    failing code
#pod   0              (foo => bar)
#pod   1              (foo => bar => baz)
#pod   2              (foo => bar => baz => quux)
#pod
#pod =cut

use Perl::Critic::Utils;
use parent qw(Perl::Critic::Policy);

my $DESCRIPTION = q{Too many fat-arrow-separated values in a row};
my $EXPLANATION = q{Fat arrows should separate pairs, not produce long chains
of values};

sub default_severity { $SEVERITY_MEDIUM       }
sub default_themes   { qw(tics)               }
sub applies_to       { 'PPI::Token::Operator' }

sub supported_parameters { qw(max_allowed) }

sub new {
  my ($class, %arg) = @_;
  my $self = $class->SUPER::new(%arg);

  $arg{max_allowed} = 2 unless defined $arg{max_allowed};

  Carp::croak "max_allowed for Tics::ProhibitManyArrows must be a positive int"
    unless $arg{max_allowed} =~ /\A\d+\z/ and $arg{max_allowed} >= 0;

  $self->{max_allowed} = $arg{max_allowed};
  bless $self => $class;
}

sub _max_allowed { $_[0]->{max_allowed} }

sub violates {
  my ($self, $elem, $doc) = @_;

  return unless $elem eq '=>';
  return if eval { $elem->sprevious_sibling->sprevious_sibling } eq '=>';

  my $in_a_row = 1;

  my $start = $elem;
  while (my $next = eval { $start->snext_sibling->snext_sibling }) {
    last unless $next eq '=>';
    $in_a_row++;
    $start = $next;
  }

  return unless $in_a_row > $self->_max_allowed;

  # Must be a violation...
  return $self->violation($DESCRIPTION, $EXPLANATION, $start);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Tics::ProhibitManyArrows - (this => is => not => good)

=head1 VERSION

version 0.009

=head1 DESCRIPTION

You are not clever if you do this:

  my %hash = (key1=>value1=>key2=>value2=>key3=>'value3');

You are even more not clever if you do this:

  my %hash = (key1=>value1=>key2=>value2=>key3=>value3=>);

=head1 CONFIGURATION

There is one parameter for this policy, F<max_allowed>, which specifies the
maximum number of fat arrows that may appear as item separators.  The default
is two.  If you really hate the fat arrow, and never want to see it, you can
set F<max_allowed> to zero and make any occurance of C<< => >> illegal.

Here are some examples of code that would fail with various F<max_allowed>
values:

  max_allowed    failing code
  0              (foo => bar)
  1              (foo => bar => baz)
  2              (foo => bar => baz => quux)

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
