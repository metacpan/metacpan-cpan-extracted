package Perl::Critic::Policy::CodeLayout::RequireKRParens;
use strict;
use warnings;
use parent qw[ Perl::Critic::Policy ];
use Perl::Critic::Utils qw[ :severities :classification ];

use constant PBP_PAGE => 9;

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw[ cosmetic pbp ] }

sub applies_to {
    return qw[
      PPI::Token::Word
      PPI::Structure::Condition
      PPI::Statement::Compound
    ];
}

sub violates {
    my ($self, $elem, $doc) = @_;

    goto &_violates_subroutine if $elem->isa('PPI::Token::Word');
    goto &_violates_condition  if $elem->isa('PPI::Structure::Condition');
    goto &_violates_compound;    # PPI::Statement::Compound
}

sub _violates_condition {
    my ($self, $elem, $doc) = @_;

    my @violations;
    my $prev = $elem->previous_sibling;
    if (ref $prev and not $prev->isa('PPI::Token::Whitespace')) {
        push @violations,
          $self->violation('No whitespace before opening condition parenthesis', PBP_PAGE, $elem);
    }

    my $next = $elem->next_sibling;    # end of statement means it's a trailing condition
    if (ref $next and not $next->isa('PPI::Token::Whitespace') and not _is_end_of_statement($next)) {
        push @violations,
          $self->violation('No whitespace after closing condition parenthesis', PBP_PAGE, $elem);
    }

    return @violations;
}

sub _violates_subroutine {
    my ($self, $elem, $doc) = @_;
    return if is_perl_builtin($elem);
    return if not is_function_call($elem) and not is_method_call($elem);

    # Check for calls with no parentheses
    my $parens = $elem->snext_sibling();
    return if ref $parens and not $parens->isa('PPI::Structure::List');

    my $next_sib = $elem->next_sibling();
    if (ref $next_sib and $next_sib->isa('PPI::Token::Whitespace')) {
        return $self->violation('Whitespace between subroutine name and its opening parenthesis',
            PBP_PAGE, $elem);
    }

    return;
}

sub _violates_compound {
    my ($self, $elem, $doc) = @_;
    my $type = $elem->type;

    my $parens =
        $type eq 'foreach' ? $elem->find_first('PPI::Structure::List')
      : $type eq 'for'     ? $elem->find_first('PPI::Structure::For')
      :                      return;    # if and while are handled in _violates_condition()

    my @violations;
    my $prev = $parens->previous_sibling;
    if (ref $prev and not $prev->isa('PPI::Token::Whitespace')) {
        push @violations,
          $self->violation("No whitespace before opening $type parenthesis", PBP_PAGE, $parens);
    }

    my $next = $parens->next_sibling;
    if (ref $next and not $next->isa('PPI::Token::Whitespace')) {
        push @violations,
          $self->violation("No whitespace after closing $type parenthesis", PBP_PAGE, $parens);
    }

    return @violations;
}

sub _is_end_of_statement {
    my ($elem) = @_;
    return if not ref $elem;
    return if not $elem->isa('PPI::Token::Structure');
    return ($elem eq '}' or $elem eq ';');
}

1;
__END__
=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireKRParens - parenthesise in K&R style

=head1 AFFILIATION

This policy as a part of the L<Perl::Critic::PolicyBundle::SNEZ> distribution.

=head1 DESCRIPTION

Put spaces on the outside of parentheses when they are not argument lists.

  # not ok
  do_something (12);
  foreach my $elem(@array) {
      ...
  }

  # ok
  do_something(12);
  foreach my $elem (@array) {
      ...
  }

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
