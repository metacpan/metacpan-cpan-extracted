package Perl::Critic::Policy::Variables::ProhibitNumericNamesWithLeadingZero;

use 5.006001;
use strict;
use warnings;

use English qw{ -no_match_vars };

use PPIx::QuoteLike 0.011;
use PPIx::QuoteLike::Constant 0.011 qw{
    LOCATION_LINE
    LOCATION_LOGICAL_LINE
    LOCATION_CHARACTER
};

use PPIx::QuoteLike 0.011;
use PPIx::Regexp 0.071;
use Readonly;
# use Scalar::Util qw{ refaddr };

use Perl::Critic::Utils qw< :booleans :characters hashify :severities >;

use base 'Perl::Critic::Policy';

our $VERSION = '0.002';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q<Numeric variable name %s starts with 0>;
Readonly::Scalar my $EXPL =>
    q<Numeric variable names may not start with 0, except for $0 itself>; ## no critic (RequireInterpolationOfMetachars)

Readonly::Scalar my $PACKAGE    => '_' . __PACKAGE__;

Readonly::Scalar my $LEFT_BRACE => q<{>;    # } Seems P::C::U should have

Readonly::Hash my %IS_COMMA     => hashify( $COMMA, $FATCOMMA );
Readonly::Hash my %LOW_PRECEDENCE_BOOLEAN => hashify( qw{ and or xor } );

Readonly::Array my @DOUBLE_QUOTISH => qw{
    PPI::Token::Quote::Double
    PPI::Token::Quote::Interpolate
    PPI::Token::QuoteLike::Backtick
    PPI::Token::QuoteLike::Command
    PPI::Token::QuoteLike::Readline
    PPI::Token::HereDoc
};
Readonly::Array my @REGEXP_ISH => qw{
    PPI::Token::Regexp::Match
    PPI::Token::Regexp::Substitute
    PPI::Token::QuoteLike::Regexp
};

#-----------------------------------------------------------------------------

sub supported_parameters { return }

sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw< trw bug maintenance >  }
sub applies_to           { return qw< PPI::Document >    }

#-----------------------------------------------------------------------------

sub violates {
#   my ( $self, $elem, $document ) = @_;
    my ( $self, undef, $document ) = @_;

    return ( map { $_->[0] }
        sort { $a->[1] <=> $b->[1] || $a->[2] <=> $b->[2] }
        map { [ $_, $_->line_number(), $_->column_number() ] }
        $self->_critique_element( $document )
    );
}

#-----------------------------------------------------------------------------

sub _critique_element {
    my ( $self, $elem ) = @_;

    my @violations;

    # Find $0nnn
    push @violations, $self->_find_bare_violations( $elem );

    # Find ${0nnn}
    push @violations, $self->_find_bracketed_violations( $elem );

    # Find "$0nnn" and "${0nnn}"
    push @violations, $self->_find_string_violations( $elem );

    # Find m/$0nnn/ and m/${0nnn}/
    push @violations, $self->_find_regex_violations( $elem );

    return @violations;
}

#-----------------------------------------------------------------------------

# Find $0nnn
sub _find_bare_violations {
    my ( $self, $elem ) = @_;

    my @violations;

    # Find $0nnn
    foreach my $sym ( @{ $elem->find( 'PPI::Token::Magic' ) || [] } ) {
        my $name = $sym->symbol();
        $name =~ m/ \W 0 [0-9]+ \z /smx ## no critic (ProhibitEnumeratedClasses)
            or next;
        push @violations, $self->violation(
            sprintf( $DESC, $name ),
            $EXPL,
            $sym,
        );
    }

    return @violations;
}

#-----------------------------------------------------------------------------

# Find ${0nnn}
sub _find_bracketed_violations {
    my ( $self, $elem ) = @_;

    my @violations;

    foreach my $cast ( @{ $elem->find( 'PPI::Token::Cast' ) || [] }) {
        my $block = $cast->snext_sibling()
            or next;
        $block->isa( 'PPI::Structure::Block' )
            or next;
        my @tokens = @{ $block->find( 'PPI::Token' ) || [] }
            or next;
        @tokens > 1
            and next;
        $tokens[0]->isa( 'PPI::Token::Number' )
            or next;
        $tokens[0]->content() =~ m/ \A 0 [0-9]+ \z /smx ## no critic (ProhibitEnumeratedClasses)
            or next;
        push @violations, $self->violation(
            sprintf( $DESC, join q<>, $cast->content(), $block->content() ),
            $EXPL,
            $cast,
        );
    }

    return @violations;
}

#-----------------------------------------------------------------------------

# Find "$0nnn" and "${0nnn}"
sub _find_string_violations {
    my ( $self, $elem ) = @_;

    my @violations;

    foreach my $class ( @DOUBLE_QUOTISH ) {
        foreach my $ppi_str ( @{ $elem->find( $class ) || [] } ) {
            my $ppix_str = PPIx::QuoteLike->new( $ppi_str )
                or next;
            foreach my $interp (
                @{ $ppix_str->find( 'PPIx::QuoteLike::Token::Interpolation' ) || [] }
            ) {
                # NOTE that policy Variables::ProhibitUnusedVarsStricter
                # uses a wrapper for $elem->ppi() because it has to link
                # the little PPI documents it makes out of strings to
                # the parent PPI document. This is enforced by test
                # xt/author/require_wrapper.t. This policy has (so far)
                # no need to link the two documents together. If it
                # develops the need, copy this test in, fix all
                # violatioms, and be prepared to rewrite calls to
                # parent() and top().
                push @violations, $self->_critique_element( $interp->ppi() );
            }
        }
    }

    return @violations;
}

#-----------------------------------------------------------------------------

# Find m/$0nnn/ and m/${0nnn}/
sub _find_regex_violations {
    my ( $self, $elem ) = @_;

    my @violations;

    foreach my $class ( @REGEXP_ISH ) {
        foreach my $ppi_re ( @{ $elem->find( $class ) || [] } ) {
            my $ppix_re = PPIx::Regexp->new( $ppi_re )
                or next;
            foreach my $code (
                @{ $ppix_re->find( 'PPIx::Regexp::Token::Code' ) || [] }
            ) {
                # NOTE see previous note.
                push @violations, $self->_critique_element( $code->ppi() );
            }
        }
    }

    return @violations;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitNumericNamesWithLeadingZero - Don't use numeric variable names with leading zeroes.


=head1 AFFILIATION

This Policy is stand-alone, and is not part of the core
L<Perl::Critic|Perl::Critic>.


=head1 DESCRIPTION

Numeric variable names with leading zeroes are unsupported by Perl, and
can lead to obscure bugs. In particular, they are not (or not
straightforwardly) accessible as C<${0nnn}>.

Starting with Perl 5.32, these variables represent a syntax error, so
this policy is useless with current Perls. On the other hand, it may be
useful for those with an older code base, especially if they are
preparing to upgrade it.

=head1 CONFIGURATION

This policy supports no configuration items above and beyond the
standard ones.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Critic-Policy-Variables-ProhibitUnusedVarsStricter>,
L<https://github.com/trwyant/perl-Perl-Critic-Policy-Variables-ProhibitUnusedVarsStricter/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT

Copyright (C) 2022 Thomas R. Wyant, III

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 72
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=72 ft=perl expandtab shiftround :
