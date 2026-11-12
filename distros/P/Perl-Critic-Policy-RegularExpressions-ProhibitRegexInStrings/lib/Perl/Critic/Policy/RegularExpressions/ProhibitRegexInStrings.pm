package Perl::Critic::Policy::RegularExpressions::ProhibitRegexInStrings 0.001;

# ABSTRACT: Write a regular expression as qr//, not as a string that somebody compiles later.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use Readonly;
use PPIx::Regexp;

use Perl::Critic::Utils qw{ :severities };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC_KEY => q{Regular expression in a string, as the value of '%s'};
Readonly::Scalar my $DESC_VAR => q{Regular expression in a string, in %s, which a match uses};
Readonly::Scalar my $EXPL     => q{Write it as qr//, and give "$qr" where a string is needed};

# A double-quoted string that holds one scalar and nothing else, which is how
# a qr// becomes a string: "$name", "${name}" or "$Package::name".
Readonly::Scalar my $IDENTIFIER => qr/[[:alpha:]_][[:alnum:]_]*/xs;
Readonly::Scalar my $ONE_SCALAR => qr/\A \$ (?: $IDENTIFIER (?: :: [[:alnum:]_]+ )* | \{ $IDENTIFIER \} ) \z/xs;

# An interpolation in braces, such as ${re}, and the name inside them.
Readonly::Scalar my $IN_BRACES => qr/\A \$ \{ ([^}]+) \} \z/xs;

Readonly::Hash my %BINDING     => map { $_ => 1 } qw{ =~ !~ };
Readonly::Hash my %REGEX_TOKEN => map { $_ => 1 } qw{ PPI::Token::Regexp::Match PPI::Token::Regexp::Substitute PPI::Token::QuoteLike::Regexp };


sub supported_parameters {
    return (
        {
            name           => 'keys',
            description    => 'The keys whose value is a regular expression',
            default_string => 'pattern regex regexp',
            behavior       => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw{ bugs maintenance } }
sub applies_to       { return 'PPI::Token::Quote' }


sub violates {
    my ( $self, $elem, undef ) = @_;

    # A qr// in a string, which is what this policy asks for.
    return if ( $elem->isa('PPI::Token::Quote::Double') || $elem->isa('PPI::Token::Quote::Interpolate') ) && $elem->string =~ $ONE_SCALAR;

    my $previous = $elem->sprevious_sibling or return;
    return unless $previous->isa('PPI::Token::Operator');

    if ( $previous->content eq '=>' ) {
        my $key  = $previous->sprevious_sibling or return;
        my $name = $key->isa('PPI::Token::Word') ? $key->content : $key->isa('PPI::Token::Quote') ? $key->string : return;
        my $keys = $self->{_keys};
        return unless $keys->{$name};
        return $self->violation( sprintf( $DESC_KEY, $name ), $EXPL, $elem );
    }

    my $name = _declared_scalar($elem) // return;
    return unless _used_as_regex( $elem->statement, $name );
    return $self->violation( sprintf( $DESC_VAR, $name ), $EXPL, $elem );
}

# The name of the one scalar that a declaration sets to the string $quote and
# to nothing else, as a declaration of one lexical does, or undef.
sub _declared_scalar {
    my ($quote) = @_;

    my $previous = $quote->sprevious_sibling;
    return unless $previous && $previous->isa('PPI::Token::Operator') && $previous->content eq q{=};
    my $statement = $quote->statement;
    return unless $statement && $statement->isa('PPI::Statement::Variable');
    my @names = $statement->variables;
    return unless @names == 1 && substr( $names[0], 0, 1 ) eq q{$};
    my $next = $quote->snext_sibling;
    return if $next && !( $next->isa('PPI::Token::Structure') && $next->content eq q{;} );
    return $names[0];
}

# Whether the block around the statement $declaration uses the scalar $name
# as a regular expression after it, as _regex_use says.
sub _used_as_regex {
    my ( $declaration, $name ) = @_;

    my $scope = $declaration->parent or return;
    my $from  = _position($declaration);
    my $found = $scope->find(
        sub {
            my ( undef, $node ) = @_;
            my $at = _position($node);
            return 0 if $at->[0] < $from->[0] || ( $at->[0] == $from->[0] && $at->[1] < $from->[1] );
            return _regex_use( $node, $name ) ? 1 : 0;
        }
    );
    return $found ? 1 : 0;
}

# Whether the element $node uses the scalar $name as a regular expression:
# interpolated into the expression of a match, a substitution or a qr//, and
# not into the replacement of a substitution; bound with =~ or !~; or the first
# argument of split, with or without parentheses.
sub _regex_use {
    my ( $node, $name ) = @_;

    if ( $REGEX_TOKEN{ ref $node } ) {
        my $regexp = PPIx::Regexp->new($node)    or return;
        my $re     = $regexp->regular_expression or return;
        foreach my $interpolation ( @{ $re->find('PPIx::Regexp::Token::Interpolation') || [] } ) {
            my $content = $interpolation->content;
            my ($inner) = $content =~ $IN_BRACES;
            return 1 if ( defined $inner ? "\$$inner" : $content ) eq $name;
        }
        return;
    }

    return unless $node->isa('PPI::Token::Symbol') && $node->symbol eq $name;
    my $before = $node->sprevious_sibling;
    return 1 if $before && $before->isa('PPI::Token::Operator') && $BINDING{ $before->content };
    return 1 if $before && $before->isa('PPI::Token::Word')     && $before->content eq 'split';
    return   if $before;

    my $list = $node->parent && $node->parent->parent;
    return unless $list && $list->isa('PPI::Structure::List');
    my $call = $list->sprevious_sibling;
    return $call && $call->isa('PPI::Token::Word') && $call->content eq 'split';
}

# The line and the column of $node.
sub _position {
    my ($node) = @_;
    my $location = $node->location or return [ 0, 0 ];
    return [ @{$location}[ 0, 1 ] ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitRegexInStrings - Write a regular expression as qr//, not as a string that somebody compiles later.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::RegularExpressions::ProhibitRegexInStrings

A regular expression held in a string is compiled somewhere else, later, under
the rules of that place and not of the file that wrote it.  Two things go
wrong with it, and nothing reports either:

=over 4

=item * The modifiers of the file do not reach it.  Under C<use re '/aa'>,
C<[[:alnum:]]>, C<\d> and C<\w> match only ASCII in the code of the file.  In a
string that JSON::Validator compiles as the C<pattern> of a schema, they match
any letter or digit of Unicode.

=item * The policies of Perl::Critic do not read it.  They read C<m//>,
C<qr//>, C<s///> and C<split>, and a string is a string to them.  So
C<'^[A-Za-z0-9]+$'> passes C<ProhibitEnumeratedClasses> and
C<RequireExtendedFormatting>, and its C<$>, which also matches before a
newline at the end, passes everything:

    pattern => '^[a-z_][a-z0-9_-]*$'    # reported: accepts "bob\n"

=back

Write the expression as C<qr//>, where the file and the policies can see it.
Where a string is what the other end takes, give it the C<qr//> in a string.
A compiled expression keeps its modifiers when it becomes one, as
C<(?^aa:...)>:

    my $USER = qr/\A [[:lower:]_] [[:lower:][:digit:]_-]* \z/x;
    ...
    pattern => "$USER"

This policy reports two kinds of string.

=head2 PROHIBITED

The value of a key that names a regular expression, C<pattern>, C<regex> or
C<regexp> by default, in a list of pairs:

    { type => 'string', pattern => '^[a-z]+$' }
    validate( value => $v, regex => q{\A\d+\z} )
    { 'regexp' => "^$prefix-" }

A lexical scalar declared with a string, and used as a regular expression in
its scope: interpolated into a match, a substitution or a C<qr//>, bound with
C<=~> or C<!~>, or given to C<split>:

    my $sep = '\s*,\s*';
    my @parts = split $sep, $line;

    my $name = '[A-Za-z]+';
    return unless $value =~ m/\A$name\z/;

=head2 ALLOWED

    pattern => "$USER"                  # a qr// in a string
    pattern => "${USER}"
    pattern => qr/\A[a-z]+\z/
    name    => '^not a pattern$'        # a key that names no expression
    my $sep = qr/\s*,\s*/;              # a qr//
    my $text = 'abc';                   # a string that no match uses
    $value =~ m/\Q$literal\E/;          # see CAVEATS

=head2 CONFIGURATION

C<keys> is the list of the keys whose value is a regular expression, separated
by spaces.  It replaces the default, C<pattern regex regexp>:

    [RegularExpressions::ProhibitRegexInStrings]
    keys = pattern regex regexp match_re

=head2 CAVEATS

The second kind is found by its name, in the block that declares it and after
the declaration.  So a scalar that the block declares again with another value
can be reported for a match that uses the second one, and a package variable
that another file matches with is not seen.

A string that a match quotes with C<\Q> is a literal, and not a pattern, but
the policy does not look inside C<\Q>.  Say C<## no critic
(ProhibitRegexInStrings)> there, or use C<index>.

A key is matched by its name, whatever the hash is for.  A C<pattern> key that
holds a glob or a C<sprintf> format is reported too.  Take the key out of
C<keys> for such a code base.

=head2 METHODS

=head3 supported_parameters

=head3 default_severity

=head3 default_themes

=head3 applies_to

=head3 violates

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/perl-critic-policy-prohibitregexinstrings/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 CONTRIBUTOR

=for stopwords troglodyne-robot

troglodyne-robot <trogbot@troglodyne.net>

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
