package Perl::Critic::Policy::CodeLayout::RequireSpaceAroundBinaryOperators;
use strict;
use warnings;
use parent qw[ Perl::Critic::Policy ];
use Perl::Critic::Utils qw[ :severities :data_conversion :booleans ];
use List::MoreUtils qw[ all any ];

use constant BINARY_OPERATORS => qw(
  **   +    -
  =~   !~   *    /    %    x
  <<   >>   lt   gt   le   ge   cmp  ~~
  ==   !=   <=>  .    ..   ...
  &    |    ^    &&   ||   //
  **=  +=   -=   .=   *=   /=
  %=   x=   &=   |=   ^=   <<=  >>=  &&=
  ||=  //=  <    >    <=   >=   =>   ->
  and  or   xor  eq   ne
);    # comma specifically excluded, even though it's technically a binary operator
use constant OPERAND_CLASSES => qw(
    PPI::Token::HereDoc
    PPI::Token::Number
    PPI::Token::Quote
    PPI::Token::QuoteLike
    PPI::Token::Regexp
    PPI::Token::Symbol
    PPI::Structure::List
);
use constant PBP_PAGE => 14;

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw[ cosmetic pbp ] }
sub applies_to       { return 'PPI::Token::Operator' }

sub supported_parameters {
    return (
        {
            name                              => 'exclude',
            description                       => 'Exempt operators.',
            behavior                          => 'enumeration',
            enumeration_values                => [BINARY_OPERATORS],
            enumeration_allow_multiple_values => 1,
            default_string                    => '** ->',
        },
    );
}

sub initialize_if_enabled {
    my ($self, $config) = @_;

    $self->{_ops_to_check} = {
        map { $_ => 1 } grep { not $self->{_exclude}{$_} } BINARY_OPERATORS
    };

    return $TRUE;
}

sub violates {
    my ($self, $elem, $doc) = @_;
    my $op = $elem->content();
    return if not $self->{_ops_to_check}{$op};

    if ($op eq '+' or $op eq '-') {    # try to detect unary operators
        my $next_sig_sib = $elem->snext_sibling();
        my $prev_sig_sib = $elem->sprevious_sibling();
        return if any { not _is_operand($_) } $next_sig_sib, $prev_sig_sib;
    }

    my $next_sib = $elem->next_sibling();
    my $prev_sib = $elem->previous_sibling();

    # Treat ,=> as a single operator
    $prev_sib = $prev_sib->previous_sibling()
        if $elem eq '=>' and $prev_sib eq ',';

    if (not all { ref and $_->isa('PPI::Token::Whitespace') } $next_sib, $prev_sib) {
        return $self->violation("Binary $op operator used without surrounding whitespace",
            PBP_PAGE, $elem);
    }

    return;
}

sub _is_operand {
    my ($elem) = @_;
    return if not ref $elem;
    return any { $elem->isa($_) } OPERAND_CLASSES;
}

1;
__END__
=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireSpaceAroundBinaryOperators - put spaces around operators

=head1 AFFILIATION

This policy as a part of the L<Perl::Critic::PolicyBundle::SNEZ> distribution.

=head1 DESCRIPTION

Squashing operators and operands together produces less readable code.
Put spaces around binary operators.

=head1 CONFIGURATION

Operators can be exempt from this rule with the B<exclude> parameter:

  [Perl::Critic::Policy::CodeLayout::RequireSpaceAroundBinaryOperators]
  exclude = ** -> x

Note that B<**> and B<< -> >> are excluded by default.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
