package Perl::Critic::Policy::RegularExpressions::ProhibitEmptyAlternatives;

use 5.006001;
use strict;
use warnings;

use English qw{ -no_match_vars };
use PPIx::Regexp 0.070; # For is_quantifier()
use Readonly;

use Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue
    qw{ throw_policy_value };
use Perl::Critic::Utils qw< :booleans :characters hashify :severities >;

use base 'Perl::Critic::Policy';

our $VERSION = '0.005';
# The problem we are solving with the following is that older Perls do
# not like the underscore in a development version number. I do not
# believe this violates the spirit of the disabled policy.
$VERSION =~ s/ _ //smxg;    ## no critic (RequireConstantVersion)

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q<Empty alternative>;
Readonly::Scalar my $EXPL => q<Empty alternatives always match>;

Readonly::Scalar my $LAST_ELEMENT   => -1;
Readonly::Scalar my $MAIN_CLASS     => 'PPIx::Regexp::Structure::Main';
Readonly::Scalar my $NODE_CLASS     => 'PPIx::Regexp::Node';
Readonly::Scalar my $OPERATOR_CLASS => 'PPIx::Regexp::Token::Operator';

#-----------------------------------------------------------------------------

sub supported_parameters { return (
        {
            name        => 'allow_empty_final_alternative',
            description => 'Allow final alternative to be empty',
            behavior    => 'boolean',
            default_string  => '0',
        },
        {
            name        => 'allow_if_group_anchored',
            description => 'Allow empty alternatives if the group is anchored on the right',
            behavior    => 'boolean',
            default_string  => '0',
        },
        {
            name        => 'ignore_files',
            description => 'Ignore the specified files',
            behavior    => 'string',
            parser      => \&_make_ignore_regexp,
        },
    ) }

sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw< trw maintenance >  }
sub applies_to           { return qw<
                                PPI::Token::Regexp::Match
                                PPI::Token::Regexp::Substitute
                                PPI::Token::QuoteLike::Regexp
                                >  }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $document ) = @_;

    # Ignore if told to do so.
    if ( $self->{_ignore_files__re} &&
        defined( my $logical_filename = $document->logical_filename() )
    ) {
        $logical_filename =~ $self->{_ignore_files__re}
            and return;
    }

    # Make a PPIx::Regexp from the PPI element for further analysis.
    my $ppix = $document->ppix_regexp_from_element( $elem )
        or return;

    # We are only interested in the regexp portion.
    my $re = $ppix->regular_expression()
        or return;

    $self->_is_node_in_violation( $re )
        or return;

    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

# Analyze the given node. Return a true value if it represents a
# violation, and a false value otherwise.
sub _is_node_in_violation {
    my ( $self, $node ) = @_;

    my @schildren = $node->schildren()
        or return $FALSE;   # No children, no empty alternatives.

    my $prev_is_alternation = $TRUE;        # Assume just saw an alternation.
    my $found_empty_alternative = $FALSE;   # Have not found an empty one yet

    foreach my $kid ( @schildren ) {

        if ( $kid->isa( $OPERATOR_CLASS ) &&
            $PIPE eq $kid->content() ) {
            # $kid is an alternation operator
            $found_empty_alternative ||= $prev_is_alternation;
            $prev_is_alternation = $TRUE;
        } else {
            $kid->isa( $NODE_CLASS )
                and $self->_is_node_in_violation( $kid )
                and return $TRUE;   # Found violation.
            # $kid is something else
            $prev_is_alternation = $FALSE;
        }
    }

    # At this point:
    # $found_empty_alternative is true if at least one alternative
    #   before the last is empty;
    # $prev_is_alternation is true if the last alternative is empty.

    # IF we found no empty alternatives THEN we are not in violation.
    $found_empty_alternative
        or $prev_is_alternation
        or return $FALSE;

    # IF we are in an extended bracketed character class an empty
    # alternative is a syntax error. So we call it a violation.
    $node->in_regex_set()
        and return $TRUE;

    # IF the last alternative is empty AND no other alternative is empty
    # AND allow_empty_final_alternative is true THEN we are not in
    # violation.
    $prev_is_alternation
        and not $found_empty_alternative
        and $self->{_allow_empty_final_alternative}
        and return $FALSE;

    # IF allow_if_group_anchored is true AND the group is in fact
    # anchored THEN we are not in violation.
    $self->{_allow_if_group_anchored}
        and $self->_is_node_anchored( $node )
        and return $FALSE;

    # We have exhausted all appeals
    return $TRUE;
}

#-----------------------------------------------------------------------------

Readonly::Hash my %ZERO_LENGTH_LOOKBEHIND   => hashify( qw{
    ?<! *nlb: *negative_lookbehind: ?<= *plb: *positive_lookbehind:
} );

sub _is_node_anchored {
    my ( $self, $node ) = @_;
    my $elem = $node;

    while ( $elem = $elem->snext_sibling() || $elem->parent() ) {

        # If $elem is a main structure we must terminate in failure,
        # since anything beyond can not be an anchor.
        $elem->isa( $MAIN_CLASS )
            and return $FALSE;

        # If $elem is an alternation operator we need to skip to the end
        # of the group.
        if ( $elem->isa( $OPERATOR_CLASS ) &&
            $PIPE eq $elem->content() ) {
            $elem = _last_ssibling( $elem );
            next;
        }

        # If $is_matcher is undef it means we can not determine whether
        # $elem is a matcher or not. It is (or at least used to be) the
        # policy to prefer false negatives over false positives, so if
        # we get undef we assume the empty alternation is anchored.
        my $is_matcher;
        defined( $is_matcher = $elem->is_matcher() )
            or return $TRUE;    # Assume anchored.

        # If $is_matcher is defined but false it means we are something
        # that does not actually do matching -- say, an operator,
        # something that does control like \Q, or some such. In this
        # case we keep looking for matchers.
        not $is_matcher
            and next;

        # If the element can be quantified to zero it is not a
        # suitable anchor, but maybe something beyond it is.
        _maybe_quantified_to_zero( $elem )
            and next;

        # A zero-length lookbehind does not provide a suitable
        # anchor. Look some more.
        $elem->isa( 'PPIx::Regexp::Structure::Assertion' )
            and $ZERO_LENGTH_LOOKBEHIND{ $elem->content() }
            and next;

        # At this point some hand-waving occurs.

        # What I believe we have here is one of the following:
        # * An assertion;
        # * A character class;
        # * A literal;
        # * A reference; or
        # * A group.
        #
        # All but the last two should be OK.
        #
        # The reference is problematic because since Perl 5.10 it is not
        # possible to unambiguously identify what a reference refers to.
        # There can be more than one capture of a given name, and
        # without actually running the regexp against the actual string
        # we can't realy know which one(s) actually captured something.
        # Numbered captures would be better, except that numbers are
        # duplicated inside a branch reset.
        #
        # Groups can in principal be analyzed, but whether they can all
        # be analyzed adequately is another question.
        #
        # In practice what we do is punt using the aforementioned
        # "prefer false negatives" convention.

        return $TRUE;   # Anchored.
    }

    # We hit the end of the regex without finding a suitable anchor.
    return $FALSE;  # Not anchored.
}

#-----------------------------------------------------------------------------

# Return the last significant sibling of the given element. This may be
# the element passed in.
sub _last_ssibling {
    my ( $elem ) = @_;
    my $parent = $elem->parent()
        or return $elem;
    return $parent->schild( $LAST_ELEMENT ) || $elem;
}

#-----------------------------------------------------------------------------

# Custom parser for the ignore_files configuration item. The regexp
# ends up in {_ignore_files__re}.
sub _make_ignore_regexp {
    my ( $self, $parameter, $config_string ) = @_;
    if ( defined $config_string && $EMPTY ne $config_string ) {
        $self->{_ignore_files__re} = eval {
            qr<$config_string>; ## no critic (RequireDotMatchAnything,RequireExtendedFormatting,RequireLineBoundaryMatching)
        } or throw_policy_value
            policy          => $self->get_short_name(),
            option_name     => $parameter->get_name(),
            option_value    => $config_string,
            message_suffix  => "failed to parse: $EVAL_ERROR",
            ;
    }
    return;
}

#-----------------------------------------------------------------------------

# Return true if the given element is quantified AND 0 is an allowed
# quantity. In practice this means quantifiers *, ?, {0}, {0,...}
sub _maybe_quantified_to_zero {
    my ( $elem ) = @_;
    my $quant = $elem->snext_sibling()
        or return $FALSE;
    $quant->is_quantifier()
        or return $FALSE;
    local $_ = $quant->content();
    return m/ \A (?: [*?] \z | [{] 0+ [,}] ) /smx;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitEmptyAlternatives - Beware empty alternatives, because they always match.

=head1 AFFILIATION

This Policy is stand-alone, and is not part of the core
L<Perl::Critic|Perl::Critic>.

=head1 DESCRIPTION

This L<Perl::Critic|Perl::Critic> policy checks for empty alternatives;
that is, things like C</a||b/>. The problem with these is that they
always match, which is very probably not what you want.

The possible exception is the final alternative, where you may indeed
want something like C</glass(?es|y|)/> to match C<'glass'>, C<'glassy'>,
or C<'glasses'>, though this is not the usual idiom. This policy does
not allow empty final alternatives by default, but it can be configured
to do so.

B<Note> that empty alternatives are syntax errors in extended bracketed
character classes, so this policy treats them as violations no matter
how it is configured.

This policy was inspired by y's
L<https://github.com/Perl-Critic/Perl-Critic/issues/727>.

=head1 CONFIGURATION

This policy supports the following configuration items.

=head2 allow_empty_final_alternative

By default, this policy prohibits all empty alternatives, since they
match anything. It may make sense, though, to leave the final
alternative in a regexp or group empty. For example,
C</(?:Larry|Moe|Curly|)/> is equivalent to the perhaps-more-usual idiom
C</(?:Larry|Moe|Curly)?/>.

If you wish to allow this, you can add a block like this to your
F<.perlcriticrc> file:

    [RegularExpressions::ProhibitEmptyAlternatives]
    allow_empty_final_alternative = 1

=head2 allow_if_group_anchored

It may make sense to allow empty alternatives if they occur in a group
that is anchored on the right. For example,

 "What ho, Porthos!" =~ /(|Athos|Porthos|Aramis)!/

captures C<'Porthos'> because the regular expression engine sees
C<'Porthos!'> before it sees C<'!'>.

If you wish to allow this, you can add a block like this to your
F<.perlcriticrc> file:

    [RegularExpressions::ProhibitEmptyAlternatives]
    allow_if_group_anchored = 1

B<Caveat:> I believe that a full static analysis of this case is not
possible when back references or recursions must be considered as
anchors. Correct analysis of groups (captures or otherwise) is not
currently attempted. In these cases the code assumes that the
entity represents an anchor.

=head2 ignore_files

It may make sense to ignore some files. For example,
L<Module::Install|Module::Install> component
F<inc/Module/Install/Metadata.pm> is known to violate this policy, at
least in its default configuration -- though it passes if
C<allow_empty_final_alternative> is enabled.

If you wish to ignore certain files, you can add a block like this to
your F<.perlcriticrc> file:

    [RegularExpressions::ProhibitEmptyAlternatives]
    allow_if_group_anchored = inc/Module/Install/Metadata\.pm\z

The value is a regular expression.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Critic-Policy-RegularExpressions-ProhibitEmptyAlternatives>,
L<https://github.com/trwyant/perl-Perl-Critic-Policy-RegularExpressions-ProhibitEmptyAlternatives/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT

Copyright (C) 2020-2021 Thomas R. Wyant, III

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
