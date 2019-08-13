package Perl::Critic::Policy::ValuesAndExpressions::ProhibitListsInMultiConstants;
use strict;
use warnings;
use parent qw[ Perl::Critic::Policy ];
use Perl::Critic::Utils qw[ :severities :classification ];

use constant {    # PPI search return values
    MATCH      => 1,
    NO_MATCH   => 0,
    NO_DESCEND => undef,
};

sub default_severity { return $SEVERITY_HIGH }
sub default_themes   { return qw[ bugs ] }
sub applies_to       { return 'PPI::Statement::Include' }

sub violates {
    my ($self, $elem, $doc) = @_;
    return if not $elem->pragma;
    return if $elem->module ne 'constant';

    my ($hash) = $elem->arguments;
    return if not $hash;
    return if not $hash->isa('PPI::Structure::Constructor');
    return if $hash->braces ne '{}';

    my $lists_ref = $hash->find(sub {
        my $el = $_[1];

        if ($el->isa('PPI::Structure::List')) {
            return _is_function_arg($el) ? NO_DESCEND : MATCH;
        }
        return MATCH if $el->isa('PPI::Token::QuoteLike::Words');

        # descend only into top-level expressions
        return NO_DESCEND if not $el->isa('PPI::Statement::Expression');
        return NO_DESCEND if $el->parent->isa('PPI::Statement::Expression');

        return NO_MATCH;    
    });
    return if not $lists_ref;

    my @violations = map {
        $self->violation('List inside a multiple constant declaration',
            'Use a separate constant declaration to use a list', $_)
    } @$lists_ref;
    return @violations;
}

sub _is_function_arg {
    my ($elem) = @_;
    my $prev = $elem->sprevious_sibling;
    return if not $prev->isa('PPI::Token::Word');
    return is_function_call($prev);
}

1;
__END__
=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitListsInMultiConstants - use a single-constant declaration for lists

=head1 AFFILIATION

This policy as a part of the L<Perl::Critic::PolicyBundle::SNEZ> distribution.

=head1 DESCRIPTION

Constants can be lists, however, this can only work if a single constant
is declared at a time.

  ## this is fine
  use constant MULTI  => ('one', 'two', 'three');
  use constant SINGLE => 1;
  #
  # produces two constants:
  # SINGLE = 1
  # MULTI  = ('one', 'two', 'three')

  ## this is not
  use constant {
      MULTI  => ('one', 'two', 'three'),
      SINGLE => 1,
  };
  #
  # produces three constants:
  # SINGLE = 1
  # MULTI  = 'one'
  # two    = 'three'

This policy detects raw lists in the hashref form of constant declaration.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
