package Perl::Critic::Policy::RegularExpressions::ProhibitRegexForStringEquality 0.001;

# ABSTRACT: Compare a string with eq, not with a regex anchored at both ends.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use List::Util qw{all any};
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $EQ_DESC  => q{Regex used to test a string for equality};
Readonly::Scalar my $EQ_EXPL  => q{Use eq, or ne for !~};
Readonly::Scalar my $ANY_DESC => q{Regex used to test a string against a list of strings};
Readonly::Scalar my $ANY_EXPL => q{Use List::Util::any, or a hash lookup; none, or a failed lookup, for !~};

# The modifiers that change what a pattern of literal text matches: see MODIFIERS.
Readonly::Array my @EXEMPTING_MODIFIERS => qw{ i g };

Readonly::Scalar my $ALTERNATION     => q{|};
Readonly::Scalar my $PLAIN_GROUP     => q{?:};
Readonly::Scalar my $START_OF_STRING => '\A';
Readonly::Scalar my $START_OF_LINE   => q{^};
Readonly::Scalar my $END_OF_STRING   => '\z';


sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_MEDIUM }
sub default_themes       { return qw{ performance maintenance } }
sub applies_to           { return 'PPI::Token::Regexp::Match' }


sub violates {
    my ( $self, $elem, $doc ) = @_;

    return if _is_split_pattern($elem);

    my $re = $doc->ppix_regexp_from_element($elem) or return;
    return if $re->failures();
    return if any { $re->modifier_asserted($_) } @EXEMPTING_MODIFIERS;

    my $pattern = $re->regular_expression() or return;
    my @parts   = grep { $_->significant() } $pattern->children();

    my $start = shift @parts;
    my $end   = pop @parts;
    return if !_is_start( $start, $re->modifier_asserted('m') );
    return if !$end || !$end->isa('PPIx::Regexp::Token::Assertion') || $end->content() ne $END_OF_STRING;

    my $alternatives = _alternatives(@parts) or return;
    return $self->violation( $EQ_DESC,  $EQ_EXPL,  $elem ) if $alternatives == 1;
    return $self->violation( $ANY_DESC, $ANY_EXPL, $elem );
}

# \A always, and ^ unless /m makes it the start of a line.
sub _is_start {
    my ( $token, $multiline ) = @_;

    return 0 if !$token || !$token->isa('PPIx::Regexp::Token::Assertion');
    return 1 if $token->content() eq $START_OF_STRING;
    return !$multiline && $token->content() eq $START_OF_LINE;
}

# How many alternatives @parts spells: one for literal text, and one for each
# side of | inside a lone (?:...) of literal text.  Zero for anything else.
sub _alternatives {
    my (@parts) = @_;

    my ($group) = @parts;
    if ( @parts != 1 || !$group->isa('PPIx::Regexp::Structure') ) {
        return _literal_run(@parts) ? 1 : 0;
    }

    return 0 if !$group->isa('PPIx::Regexp::Structure::Modifier');
    my ($type) = $group->type();
    return 0 if !$type || $type->content() ne $PLAIN_GROUP;

    my @runs = ( [] );
    foreach my $token ( grep { $_->significant() } $group->children() ) {
        if ( $token->isa('PPIx::Regexp::Token::Operator') && $token->content() eq $ALTERNATION ) {
            push @runs, [];
            next;
        }
        push @{ $runs[-1] }, $token;
    }
    return 0 if !all { _literal_run(@$_) } @runs;
    return scalar @runs;
}

# At least one token, and every one of them literal text.
sub _literal_run {
    my (@tokens) = @_;
    return @tokens && all { $_->isa('PPIx::Regexp::Token::Literal') } @tokens;
}

# Whether $elem is the first argument of split, which takes a regex whatever it
# says.  Looks through parentheses around the call's arguments.
sub _is_split_pattern {
    my ($elem) = @_;

    my $before = $elem->sprevious_sibling();
    if ( !$before ) {
        my $expression = $elem->parent();
        my $list       = $expression && $expression->parent();
        return 0 if !$list || !$list->isa('PPI::Structure::List');
        $before = $list->sprevious_sibling();
    }
    return 0 if !$before || !$before->isa('PPI::Token::Word');
    return any { $before->content() eq $_ } qw{split CORE::split};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitRegexForStringEquality - Compare a string with eq, not with a regex anchored at both ends.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::RegularExpressions::ProhibitRegexForStringEquality

A match of literal text anchored at both ends asks whether a string is that
text, which is C<eq>.  An anchored group of literal alternatives asks whether a
string is one of several, which is C<any> from L<List::Util>, or a hash lookup.
Either one says what it does in plain words, and runs no pattern:

    if ( $name =~ m/\Afoo\z/ ) { ... }                   # reported
    if ( $name eq 'foo' ) { ... }

    return if $tool =~ m/\A(?:Skill|Read)\z/;           # reported
    return if List::Util::any { $tool eq $_ } qw{Skill Read};

=head2 PROHIBITED

    $str =~ m/\Afoo\z/          # eq
    $str !~ m/\Afoo\z/          # ne
    $str =~ m/^foo\z/           # ^ is the start without /m
    $str =~ m/\Afoo\.bar\z/     # an escaped character is still literal text
    $str =~ m/\A foo \z/x       # under /x this is the string foo
    $str =~ m/\A(?:foo)\z/      # a group of one alternative is still eq
    $str =~ m/\A(?:a|b|c)\z/    # any, or a hash lookup
    $str !~ m/\A(?:a|b)\z/      # none, or a failed hash lookup
    grep { m/\Afoo\z/ } @names  # a match against $_ counts too

=head2 ALLOWED

    $str =~ m/\Afoo$/           # $ also matches before a trailing newline
    $str =~ m/\Afoo\Z/          # so does \Z
    $str =~ m/^foo\z/m          # /m: ^ is the start of any line
    $str =~ m/\Afoo\z/i         # /i, which eq cannot do
    $str =~ m/\A(foo|bar)\z/    # a capture, which the code may use
    $str =~ m/\A(?i:a|b)\z/     # a group with modifiers of its own
    $str =~ m/\Afoo|bar\z/      # alternation outside a group anchors each side once
    $str =~ m/\Afo+\z/          # a quantifier
    $str =~ m/\A[ab]\z/         # a character class
    $str =~ m/\A$foo\z/         # interpolation
    $str =~ m/\A\z/             # nothing between the anchors, see CAVEATS
    $str =~ s/\Afoo\z/bar/      # a substitution
    my $rx = qr/\Afoo\z/;       # a compiled regex
    split m/\Afoo\z/, $str;     # the pattern that split takes

=head2 MODIFIERS

C</i> exempts a pattern, because C<eq> is case sensitive.  C<fc> on both sides
would do, but that is a rewrite and not a substitution.

C</m> exempts a pattern that starts with C<^>, because C<^> then matches at the
start of any line.  A pattern that starts with C<\A> is reported under C</m> too.

C</g> exempts a pattern, because in scalar context it moves C<pos>, which C<eq>
does not.

C</s> and C</x> change nothing here: there is no C<.> in literal text, and
whitespace under C</x> is not text.

A modifier in scope from a C<use re> counts the same as one written on the
match, so a file under C<use re '/i'> is exempt throughout.

=head2 CAVEATS

C<m/\A\z/> is C<eq q{}>, or C<!length>, but it is not reported.  The policy asks
for text between the anchors.

A group of one alternative is reported as C<eq>, and a group of more than one as
C<any>.  Where the alternatives are many, or the test runs in a loop, a hash of
them built once is faster than C<any>.

=head2 METHODS

=head3 supported_parameters

=head3 default_severity

=head3 default_themes

=head3 applies_to

=head3 violates

Standard L<Perl::Critic::Policy> interface.  Returns a violation for a match
whose pattern is literal text, or a plain group of literal alternatives,
between a start anchor and C<\z>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitregexforstringequality/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
