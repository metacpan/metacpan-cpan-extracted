package Perl::Critic::Policy::CodeLayout::RequireBreakBeforeOperator;
use strict;
use warnings;
use parent qw[ Perl::Critic::Policy ];
use Perl::Critic::Utils qw[ :severities :booleans ];

use constant OPERATORS => qw(
  ++   --   **   !    ~    +    -
  =~   !~   *    /    %    x
  <<   >>   lt   gt   le   ge   cmp  ~~
  ==   !=   <=>  .    ..   ...
  &    |    ^    &&   ||   //
  ?    :    **=  +=   -=   .=   *=   /=
  %=   x=   &=   |=   ^=   <<=  >>=  &&=
  ||=  //=  <    >    <=   >=   <>   =>   ->
  and  or   xor  not  eq   ne
);
use constant PBP_PAGE => 28;

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw[ cosmetic pbp ] }
sub applies_to       { return 'PPI::Token::Operator' }

sub supported_parameters {
    return (
        {
            name                              => 'exclude',
            description                       => 'Exempt operators.',
            behavior                          => 'enumeration',
            enumeration_values                => [OPERATORS],
            enumeration_allow_multiple_values => 1,
            default_string                    => '',
        },
    );
}

sub initialize_if_enabled {
    my ($self, $config) = @_;

    $self->{_ops_to_check} = { map { $_ => 1 } grep { not $self->{_exclude}{$_} } OPERATORS };

    return $TRUE;
}

sub violates {
    my ($self, $elem, $doc) = @_;
    return if not $self->{_ops_to_check}{$elem};

    my $whitespace = $elem->next_sibling();
    return if not ref $whitespace;
    return if not $whitespace->isa('PPI::Token::Whitespace');

    if (index($whitespace->content, "\n") != -1) {
        return $self->violation('Expression broken after operator', PBP_PAGE, $elem);
    }

    return;
}

1;
__END__
=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireBreakBeforeOperator - multiline expressions should be broken before operator

=head1 AFFILIATION

This policy as a part of the L<Perl::Critic::PolicyBundle::SNEZ> distribution.

=head1 DESCRIPTION

Continuations of multiline expressions are easier to spot when they begin
with operators, which is unusual in Perl code. Therefore, in all multiline
expressions, newlines should be placed before operators, not after.

=head1 CONFIGURATION

Operators can be exempt from this rule with the exclude parameter:

  [Perl::Critic::Policy::CodeLayout::RequireBreakBeforeOperator]
  exclude = .. +

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
