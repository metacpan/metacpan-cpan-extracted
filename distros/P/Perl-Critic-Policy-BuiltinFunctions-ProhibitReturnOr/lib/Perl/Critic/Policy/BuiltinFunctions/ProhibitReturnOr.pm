package Perl::Critic::Policy::BuiltinFunctions::ProhibitReturnOr;
use 5.008_001;
use strict;
use warnings;

use Perl::Critic::Utils;

use base 'Perl::Critic::Policy';

our $VERSION = "0.01";

my $DESCRIPTION = q{Low precedence operator after return is never evaluated};
my $EXPLANATION = q{Return has higher precedence than %s, so it returns before evaluating the rest of the expression.};
my %PROHIBITED = hashify( qw(or and xor) );

sub default_severity  { return $SEVERITY_MEDIUM   }
sub default_themes    { return qw(bugs zr)        }
sub applies_to        { return 'PPI::Token::Word' }

sub violates {
  my ($self, $elem) = @_;
  return unless $elem->content eq 'return';
  return if is_hash_key($elem);

  for (my $sib = $elem->snext_sibling; $sib; $sib = $sib->snext_sibling) {

    # don't squawk on "return $x if $y or $z" or "return $x unless $y or $z"
    last if $sib->content eq 'if' or $sib->content eq 'unless';

    next unless $sib->isa('PPI::Token::Operator');
    if ($PROHIBITED{$sib}) {
      my $explain = sprintf($EXPLANATION, $sib->content);
      return $self->violation($DESCRIPTION, $explain, $elem);
    }
  }

  return;
}


1;
__END__

=pod

=encoding utf-8

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitReturnOr - Check for "return $x or ..."

=head1 DESCRIPTION

C<return> when encountered in an expression returns from the enclosing
subroutine, without evaluating the rest of the expression. So a
lower-precedence operator (C<or>, C<and>, C<xor>) won't get evaluated
after a C<return>. This most commonly appears as the mis-idiom:

    # NO! DON'T DO THIS!
    return $x or die 'Aaaagh! $x was zero!';

Instead, use the higher-precedence C<||> operator, like  this:

    return $x || die 'Aaaagh! $x was zero!';

Or separate the two operations, like this:

    $x or die 'Aaaagh! $x was zero!';
    return $x;

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 LICENSE

Copyright (C) 2016 Jeremy Leader.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jeremy Leader E<lt>jeremy@ziprecruiter.comE<gt>

=head1 SEE ALSO

L<Perl::Critic>

=cut

