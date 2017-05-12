use strict;
use warnings;
package Perl::Critic::Policy::Lax::RequireEndWithTrueConst;
# ABSTRACT: ending your package with a simple, fun true value is okay
$Perl::Critic::Policy::Lax::RequireEndWithTrueConst::VERSION = '0.013';
#pod =head1 DESCRIPTION
#pod
#pod This policy behaves like L<Perl::Critic::Policy::Modules::RequireEndWithOne>,
#pod but allows frivolity like ending with C<"Club sandwich">.
#pod
#pod The return value must be the final statement of the module.
#pod
#pod =head1 WARNINGS
#pod
#pod There are I<many> true values that this won't actually accept.  The biggest
#pod issue is returning lists or other comma-delimited values.  While it would be
#pod nice to support these, they're not the sort of club sandwich with which I
#pod usually end my code, so I'm not likely to code the fix myself.
#pod
#pod Patches welcome.
#pod
#pod =cut

use Perl::Critic::Utils;
use parent qw(Perl::Critic::Policy);

my $DESCRIPTION = q{Module does not end with true constant};
my $EXPLANATION = q{Must end with a recognizable true value};

sub default_severity { $SEVERITY_HIGH  }
sub default_themes   { qw(lax)         }
sub applies_to       { 'PPI::Document' }

sub violates {
  my ($self, $elem, $doc) = @_;
  return if $doc->is_program; #Must be a library or module.

  # Last statement should be a true constant.
  my @significant = grep { _is_code($_) } $doc->schildren();
  my $match = $significant[-1];
  return if !$match;

  return if $self->_is_true_enough($match);

  # Must be a violation...
  return $self->violation($DESCRIPTION, $EXPLANATION, $match);
}

sub _is_true_enough {
  my ($self, $element) = @_;

  if ($element->isa('PPI::Statement::Break')) {
    my ($head, @tail) = $element->schildren;
    return unless $head eq 'return';
    pop @tail if $tail[-1]->isa('PPI::Token::Structure')
             and $tail[-1] eq ';';
    $element = $tail[-1]; # If returning a list, only last one matters.
  }

  if ($element->isa('PPI::Statement') and $element->schildren < 3) {
    ($element) = $element->schildren;
  }

  while ($element->isa('PPI::Structure::List')) {
    my @list_elements = $element->schildren;
    return unless @list_elements;
    $element = $list_elements[-1];
  }

  if ($element->isa('PPI::Token::Number')) {
    return $element ne '0'; # Any other number is true.
  }

  if ($element->isa('PPI::Token::Quote')) {
    my $string = $element->string;
    return((length $string) and ($string ne '0'));
  }

  # PPI::Statement::Expression for lists?  Probably too far to the edge.

  return;
}

sub _is_code {
  my $elem = shift;
  return ! ($elem->isa('PPI::Statement::End')
        ||  $elem->isa('PPI::Statement::Data'));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Lax::RequireEndWithTrueConst - ending your package with a simple, fun true value is okay

=head1 VERSION

version 0.013

=head1 DESCRIPTION

This policy behaves like L<Perl::Critic::Policy::Modules::RequireEndWithOne>,
but allows frivolity like ending with C<"Club sandwich">.

The return value must be the final statement of the module.

=head1 WARNINGS

There are I<many> true values that this won't actually accept.  The biggest
issue is returning lists or other comma-delimited values.  While it would be
nice to support these, they're not the sort of club sandwich with which I
usually end my code, so I'm not likely to code the fix myself.

Patches welcome.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ricardo Signes <rjbs@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
