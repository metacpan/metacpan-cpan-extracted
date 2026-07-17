#!/bin/false
# PODNAME: Perl::Critic::Policy::Performance::ProhibitRegexForSimpleSubstring
# ABSTRACT: Use index() instead of regex for literal substring matching

use strict;
use warnings;

package Perl::Critic::Policy::Performance::ProhibitRegexForSimpleSubstring;
$Perl::Critic::Policy::Performance::ProhibitRegexForSimpleSubstring::VERSION = '0.01';
use Perl::Critic::Utils qw{ :severities };
use parent 'Perl::Critic::Policy';

#-----------------------------------------------------------------------------

my $DESC = q{Regex used for a simple substring match};
## no critic (RequireInterpolationOfMetachars)
my $EXPL = q{Use index($string, $substring) instead of a regex when looking for literal text.};
## use critic

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_MEDIUM }
sub default_themes       { return qw( performance ) }
sub applies_to           { return 'PPI::Token::Regexp::Match' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $re = $doc->ppix_regexp_from_element($elem)
        or return;
    $re->failures()
        and return;

    # /i: index() is case-sensitive, cannot replicate
    # /m,/s: not relevant for a simple literal match
    # /x: changes whitespace/comment meaning, skip for simplicity
    return if $re->modifier_asserted('i');
    return if $re->modifier_asserted('m');
    return if $re->modifier_asserted('s');
    return if $re->modifier_asserted('x');

    my $qr = $re->regular_expression()
        or return;

    # If every significant token in the regex is a Literal,
    # then the regex is just a substring match replaceable with index().
    my $has_literal = 0;

    for my $token ( map { $_->tokens() } $qr->children() ) {
        $token->significant() or next;

        if ( $token->isa('PPIx::Regexp::Token::Literal') ) {
            $has_literal = 1;
        }
        else {
            return;
        }
    }

    if ($has_literal) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Performance::ProhibitRegexForSimpleSubstring - Use index() instead of regex for literal substring matching

=head1 VERSION

version 0.01

=head1 DESCRIPTION

When searching for a literal substring in a string, using a regular expression
is avoidable overhead. The C<index()> function is significantly faster because
it avoids regex compilation and interpretation.

  # Bad: regex for simple substring
  if ( $str =~ m/foo/ )     { ... }
  if ( $str =~ /bar\.baz/ ) { ... }  # escaped dot is still a literal

  # Good: use index() instead
  if ( index( $str, 'foo' ) != -1 )     { ... }
  if ( index( $str, 'bar.baz' ) != -1 ) { ... }

This policy flags regex matches (C<m//> and bare C<//>) that contain only
literal characters and have no modifiers. It does not flag:

=over

=item *

Regexes with modifiers (C</i>, C</m>, C</s>, C</x>)

=item *

Regexes with any non-literal tokens (character classes, quantifiers,
anchors, groups, interpolation, alternation, etc.)

=item *

Regexes containing groups (C<(...)>, C<(?:...)>), even if the group
body is purely literal

=item *

Substitutions (C<s///>) and compiled regexes (C<qr//>)

=back

=head1 AFFILIATION

This policy is part of the Perl-Critic-Policy-Performance-ProhibitRegexForSimpleSubstring
distribution.

=head1 CONFIGURATION

This policy has no additional configuration options beyond the standard ones.

=head1 METHODS

=head2 supported_parameters

Returns an empty list. This policy has no configurable parameters.

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
