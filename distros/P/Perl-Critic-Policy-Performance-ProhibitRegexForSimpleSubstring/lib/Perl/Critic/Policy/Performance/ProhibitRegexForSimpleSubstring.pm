#!/bin/false
# PODNAME: Perl::Critic::Policy::Performance::ProhibitRegexForSimpleSubstring
# ABSTRACT: Use index() instead of regex for literal substring matching

use strict;
use warnings;

package Perl::Critic::Policy::Performance::ProhibitRegexForSimpleSubstring;
$Perl::Critic::Policy::Performance::ProhibitRegexForSimpleSubstring::VERSION = '0.02';
use Perl::Critic::Utils qw{ $EMPTY :severities is_function_call is_method_call };
use parent 'Perl::Critic::Policy';

#-----------------------------------------------------------------------------

my $DESC = q{Regex used for a simple substring match};

## no critic (RequireInterpolationOfMetachars)
my $EXPLANATION_FORMAT  = q{Use index($string, %s) instead of a regex when looking for literal text.};
my $EXPLANATION_GENERIC = q{Use index($string, $substring) instead of a regex when looking for literal text.};
## use critic

# index() is case sensitive. /m, /s, and /x do not change a pattern of literals.
my $EXEMPTING_MODIFIER = 'i';

my $APOSTROPHE            = q{'};
my $BACKSLASH             = q{\\};
my $CARRIAGE_RETURN       = "\r";
my $NEWLINE               = "\n";
my $PRINTABLE_ASCII_FIRST = q{ };
my $PRINTABLE_ASCII_LAST  = q{~};
my $TAB                   = "\t";

# A neighbor operator ends the argument when it is one of these. Logical
# operators bind the surrounding expression to the match instead.
my %ARGUMENT_SEPARATOR = (
    q{,}  => 1,
    q{=>} => 1,
);

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {   behavior       => 'string list',
            default_string => $EMPTY,
            description    =>
                'Functions and methods whose first argument may be a literal regex. split is always included.',
            list_always_present_values => [qw{ split }],
            name                       => 'allow',
        },
    );
}
sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw( performance ) }
sub applies_to       { return 'PPI::Token::Regexp::Match' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $literal = _decoded_literal( $elem, $doc );
    return if !$literal;

    return if _allowed_call( $elem, $self->{_allow} );

    my $explanation = $EXPLANATION_GENERIC;
    if ( defined $literal->{text} ) {
        $explanation = sprintf $EXPLANATION_FORMAT, _quoted_literal( $literal->{text} );
    }

    return $self->violation( $DESC, $explanation, $elem );
}

# A pure literal pattern, or nothing. text is the string index() searches
# for, and is missing when a literal has no ordinal.
sub _decoded_literal {
    my ( $elem, $doc ) = @_;

    my $re = $doc->ppix_regexp_from_element($elem)
        or return;
    return if $re->failures();
    return if $re->modifier_asserted($EXEMPTING_MODIFIER);

    my $pattern = $re->regular_expression()
        or return;

    my $literal_count         = 0;
    my $saw_undefined_ordinal = 0;
    my @characters;

    for my $token ( map { $_->tokens() } $pattern->children() ) {
        next   if !$token->significant();
        return if !$token->isa('PPIx::Regexp::Token::Literal');

        $literal_count++;

        my $ordinal = $token->ordinal();
        if ( !defined $ordinal ) {
            $saw_undefined_ordinal = 1;
            next;
        }

        push @characters, chr $ordinal;
    }

    return if $literal_count == 0;

    # No ordinal means the explanation cannot name the literal.
    return {} if $saw_undefined_ordinal;

    return { text => join q{}, @characters };
}

# A Perl string literal for the text index() searches for.
sub _quoted_literal {
    my ($text) = @_;

    my $needs_double_quotes = 0;

    for my $character ( split //, $text ) {
        my $ordinal = ord $character;
        if ( $ordinal < ord $PRINTABLE_ASCII_FIRST || $ordinal > ord $PRINTABLE_ASCII_LAST ) {
            $needs_double_quotes = 1;
            last;
        }
    }

    return _double_quoted($text) if $needs_double_quotes;

    return _single_quoted($text);
}

sub _double_quoted {
    my ($text) = @_;

    my $body = q{};

    for my $character ( split //, $text ) {
        if ( $character eq $NEWLINE ) {
            $body .= q{\\n};
            next;
        }

        if ( $character eq $CARRIAGE_RETURN ) {
            $body .= q{\\r};
            next;
        }

        if ( $character eq $TAB ) {
            $body .= q{\\t};
            next;
        }

        if (   $character eq q{"}
            || $character eq q{$}
            || $character eq q{@}
            || $character eq $BACKSLASH ) {
            $body .= $BACKSLASH . $character;
            next;
        }

        my $ordinal = ord $character;
        if ( $ordinal < ord $PRINTABLE_ASCII_FIRST || $ordinal > ord $PRINTABLE_ASCII_LAST ) {
            ## no critic (RequireInterpolationOfMetachars)
            $body .= sprintf q{\x{%x}}, $ordinal;
            ## use critic
            next;
        }

        $body .= $character;
    }

    return q{"} . $body . q{"};
}

sub _single_quoted {
    my ($text) = @_;

    my $body = q{};

    for my $character ( split //, $text ) {
        if ( $character eq $APOSTROPHE || $character eq $BACKSLASH ) {
            $body .= $BACKSLASH . $character;
            next;
        }

        $body .= $character;
    }

    return $APOSTROPHE . $body . $APOSTROPHE;
}

# The call whose entire first argument is this element, when that call is allowed.
sub _allowed_call {
    my ( $elem, $allow ) = @_;

    my $word = _call_word($elem);
    return if !$word;

    return _name_is_allowed( $word, $allow );
}

sub _call_word {
    my ($elem) = @_;

    return if _glued($elem);

    my $previous = _previous_sibling($elem);
    return $previous if _names_a_call($previous);
    return           if $previous;

    return _call_word_from_list($elem);
}

# Parentheses only. A block, a subscript, or an anonymous array stops the walk.
sub _call_word_from_list {
    my ($node) = @_;

    my $statement = $node->parent();
    return if !$statement;
    return if !$statement->isa('PPI::Statement');

    my $next = _next_sibling($node);
    return _word_before_list($statement) if $next;

    my $list = $statement->parent();
    return if !$list;
    return if !$list->isa('PPI::Structure::List');
    return if _previous_sibling($statement);

    return _word_around_grouping($list);
}

sub _glued {
    my ($node) = @_;

    return 1 if _operator_binds( _previous_sibling($node) );
    return 1 if _operator_binds( _next_sibling($node) );

    return;
}

sub _is_separator {
    my ($sibling) = @_;

    return if !$sibling;
    return if !$sibling->isa('PPI::Token::Operator');

    return $ARGUMENT_SEPARATOR{$sibling};
}

sub _name_is_allowed {
    my ( $word, $allow ) = @_;

    my $written_name = $word->content();
    my $short_name   = $written_name;
    $short_name =~ s/\A.*:://;

    my $package_name   = _package_name( $word, $written_name );
    my $qualified_name = $short_name;
    if ( defined $package_name ) {
        $qualified_name = $package_name . q{::} . $short_name;
    }

    return 1 if $allow->{$qualified_name};

    for my $allowed_name ( sort keys %{$allow} ) {
        next if index( $allowed_name, q{::} ) >= 0;

        return 1 if $allowed_name eq $short_name;
    }

    return;
}

sub _names_a_call {
    my ($word) = @_;

    return if !$word;
    return if !$word->isa('PPI::Token::Word');
    return if !is_function_call($word) && !is_method_call($word);

    return 1;
}

sub _next_sibling {
    my ($elem) = @_;

    my $sibling = $elem->snext_sibling();
    return if !$sibling;

    return $sibling;
}

sub _operator_binds {
    my ($sibling) = @_;

    return if !$sibling;
    return if !$sibling->isa('PPI::Token::Operator');
    return if $ARGUMENT_SEPARATOR{$sibling};

    return 1;
}

sub _package_name {
    my ( $word, $written_name ) = @_;

    if ( is_method_call($word) ) {

        # A namespace written on the method wins; it sets the resolution start.
        if ( index( $written_name, q{::} ) >= 0 ) {
            my $package_name = $written_name;
            $package_name =~ s/::[^:]*\z//;

            return $package_name;
        }

        my $arrow    = _previous_sibling($word);
        my $invocant = _previous_sibling($arrow);
        return if !$invocant;
        return if !$invocant->isa('PPI::Token::Word');

        my $package_name = $invocant->content();
        $package_name =~ s/::\z//;

        return $package_name;
    }

    return if index( $written_name, q{::} ) < 0;

    my $package_name = $written_name;
    $package_name =~ s/::[^:]*\z//;

    return $package_name;
}

sub _previous_sibling {
    my ($elem) = @_;

    my $sibling = $elem->sprevious_sibling();
    return if !$sibling;

    return $sibling;
}

sub _word_around_grouping {
    my ($list) = @_;

    while ($list) {
        my $word = _previous_sibling($list);
        return $word if _names_a_call($word);
        return       if $word;

        my $list_statement = $list->parent();
        return if !$list_statement;
        return if !$list_statement->isa('PPI::Statement');

        my $after = _next_sibling($list);
        return if $after && !_is_separator($after);

        my $outer = $list_statement->parent();
        return if !$outer;
        return if !$outer->isa('PPI::Structure::List');
        return if _previous_sibling($list_statement);

        if ($after) {
            my $outer_word = _previous_sibling($outer);
            return $outer_word if _names_a_call($outer_word);

            return;
        }

        $list = $outer;
    }

    return;
}

sub _word_before_list {
    my ($statement) = @_;

    return if _previous_sibling($statement);

    my $list = $statement->parent();
    return if !$list;
    return if !$list->isa('PPI::Structure::List');

    my $word = _previous_sibling($list);
    return $word if _names_a_call($word);

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

version 0.02

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
literal characters. The explanation names the text C<index> searches for,
after escapes are decoded and after C</x> drops spaces and comments.
It does not flag:

=over

=item *

C</i>, including C</i> turned on by C<use re> in scope. C<index> is case
sensitive. C</m>, C</s>, and C</x> are reported.

=item *

The first argument of C<split>, including C<CORE::split> and a method named
C<split>. The match has to be that whole argument. A ternary there is
reported on both branches. An object method named C<split> is exempt because
the policy cannot tell which class it will call.

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

C<allow> adds function and method names. C<split> is always included, and a
profile cannot remove it. A name with no package matches any call of that
name: a bare call, C<Pkg::name>, an object method, and C<Pkg-E<gt>name>. A
name with a package matches C<Pkg::name(...)> and C<Pkg-E<gt>name(...)> only.
The split limits in the description still apply.

    [Performance::ProhibitRegexForSimpleSubstring]
    allow = grep_lines My::Util::match_all

=head1 METHODS

=head2 supported_parameters

The C<allow> string list. C<split> is always present.

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
