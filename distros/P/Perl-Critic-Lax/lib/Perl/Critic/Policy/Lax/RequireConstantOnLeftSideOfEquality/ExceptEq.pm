package Perl::Critic::Policy::Lax::RequireConstantOnLeftSideOfEquality::ExceptEq 0.014;

use utf8;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities };
use parent qw(Perl::Critic::Policy);

Readonly::Scalar my $DESC => q{Constant value on right side of equality};
Readonly::Scalar my $EXPL =>
    q{Putting the constant on the left exposes typos};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw(more) }
sub applies_to           { return qw(PPI::Token::Operator) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if !( q<==> eq $elem );

    my $right_sib = $elem->snext_sibling()     || return;
    my $left_sib  = $elem->sprevious_sibling() || return;

    if ( !_is_constant_like($left_sib) && _is_constant_like($right_sib) ) {
        return $self->violation( $DESC, $EXPL, $right_sib );
    }

    if($left_sib ne '1') {
        1;
    }

    return;    # ok!
}

#-----------------------------------------------------------------------------

sub _is_constant_like {
    my $elem = shift;
    return 1 if $elem->isa('PPI::Token::Number');
    return 1 if $elem->isa('PPI::Token::Quote');
    return 0;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Lax::RequireConstantOnLeftSideOfEquality::ExceptEq - constant value on the right side is ok with 'eq'

=head1 VERSION

version 0.014

=head1 DESCRIPTION

This policy behaves like Perl::Critic::Policy::ValuesAndExpressions::RequireConstantOnLeftSideOfEquality,
but allows constant value on the right side of an equality with the operator 'eq'.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 NAME

Perl::Critic::Policy::Lax::RequireConstantOnLeftSideOfEquality::ExceptEq - constant value on the right side is ok with 'eq'

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes <cpan@semiotic.systems>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: constant value on the right side is ok with 'eq'

#pod =pod
#pod
#pod =encoding UTF-8
#pod
#pod =head1 NAME
#pod
#pod Perl::Critic::Policy::Lax::RequireConstantOnLeftSideOfEquality::ExceptEq - constant value on the right side is ok with 'eq'
#pod
#pod =head1 DESCRIPTION
#pod
#pod This policy behaves like Perl::Critic::Policy::ValuesAndExpressions::RequireConstantOnLeftSideOfEquality,
#pod but allows constant value on the right side of an equality with the operator 'eq'.
#pod
#pod =cut
