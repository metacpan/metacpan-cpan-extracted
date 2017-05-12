package Regexp::Lexer;
use 5.010001;
use strict;
use warnings;
use B;
use Carp qw/croak/;
use Regexp::Lexer::TokenType;
use parent qw(Exporter);

our @EXPORT_OK = qw(tokenize);

our $VERSION = "0.05";

my %escapedSpecialChar = (
    t => Regexp::Lexer::TokenType::EscapedTab,
    n => Regexp::Lexer::TokenType::EscapedNewline,
    r => Regexp::Lexer::TokenType::EscapedReturn,
    f => Regexp::Lexer::TokenType::EscapedFormFeed,
    F => Regexp::Lexer::TokenType::EscapedFoldcase,
    a => Regexp::Lexer::TokenType::EscapedAlarm,
    e => Regexp::Lexer::TokenType::EscapedEscape,
    c => Regexp::Lexer::TokenType::EscapedControlChar,
    x => Regexp::Lexer::TokenType::EscapedCharHex,
    o => Regexp::Lexer::TokenType::EscapedCharOct,
    0 => Regexp::Lexer::TokenType::EscapedCharOct,
    l => Regexp::Lexer::TokenType::EscapedLowerNext,
    u => Regexp::Lexer::TokenType::EscapedUpperNext,
    L => Regexp::Lexer::TokenType::EscapedLowerUntil,
    U => Regexp::Lexer::TokenType::EscapedUpperUntil,
    Q => Regexp::Lexer::TokenType::EscapedQuoteMetaUntil,
    E => Regexp::Lexer::TokenType::EscapedEnd,
    w => Regexp::Lexer::TokenType::EscapedWordChar,
    W => Regexp::Lexer::TokenType::EscapedNotWordChar,
    s => Regexp::Lexer::TokenType::EscapedWhiteSpaceChar,
    S => Regexp::Lexer::TokenType::EscapedNotWhiteSpaceChar,
    d => Regexp::Lexer::TokenType::EscapedDigitChar,
    D => Regexp::Lexer::TokenType::EscapedNotDigitChar,
    p => Regexp::Lexer::TokenType::EscapedProp,
    P => Regexp::Lexer::TokenType::EscapedNotProp,
    X => Regexp::Lexer::TokenType::EscapedUnicodeExtendedChar,
    C => Regexp::Lexer::TokenType::EscapedCChar,
    1 => Regexp::Lexer::TokenType::EscapedBackRef,
    2 => Regexp::Lexer::TokenType::EscapedBackRef,
    3 => Regexp::Lexer::TokenType::EscapedBackRef,
    4 => Regexp::Lexer::TokenType::EscapedBackRef,
    5 => Regexp::Lexer::TokenType::EscapedBackRef,
    6 => Regexp::Lexer::TokenType::EscapedBackRef,
    7 => Regexp::Lexer::TokenType::EscapedBackRef,
    8 => Regexp::Lexer::TokenType::EscapedBackRef,
    9 => Regexp::Lexer::TokenType::EscapedBackRef,
    g => Regexp::Lexer::TokenType::EscapedBackRef,
    k => Regexp::Lexer::TokenType::EscapedBackRef,
    K => Regexp::Lexer::TokenType::EscapedKeepStuff,
    v => Regexp::Lexer::TokenType::EscapedVerticalWhitespace,
    V => Regexp::Lexer::TokenType::EscapedNotVerticalWhitespace,
    h => Regexp::Lexer::TokenType::EscapedHorizontalWhitespace,
    H => Regexp::Lexer::TokenType::EscapedNotHorizontalWhitespace,
    R => Regexp::Lexer::TokenType::EscapedLinebreak,
    b => Regexp::Lexer::TokenType::EscapedWordBoundary,
    B => Regexp::Lexer::TokenType::EscapedNotWordBoundary,
    A => Regexp::Lexer::TokenType::EscapedBeginningOfString,
    Z => Regexp::Lexer::TokenType::EscapedEndOfStringBeforeNewline,
    z => Regexp::Lexer::TokenType::EscapedEndOfString,
    G => Regexp::Lexer::TokenType::EscapedPos,
);

my %specialChar = (
    '.'  => Regexp::Lexer::TokenType::MatchAny,
    '|'  => Regexp::Lexer::TokenType::Alternation,
    '('  => Regexp::Lexer::TokenType::LeftParenthesis,
    ')'  => Regexp::Lexer::TokenType::RightParenthesis,
    '['  => Regexp::Lexer::TokenType::LeftBracket,
    ']'  => Regexp::Lexer::TokenType::RightBracket,
    '{'  => Regexp::Lexer::TokenType::LeftBrace,
    '}'  => Regexp::Lexer::TokenType::RightBrace,
    '<'  => Regexp::Lexer::TokenType::LeftAngle,
    '>'  => Regexp::Lexer::TokenType::RightAngle,
    '*'  => Regexp::Lexer::TokenType::Asterisk,
    '+'  => Regexp::Lexer::TokenType::Plus,
    '?'  => Regexp::Lexer::TokenType::Question,
    ','  => Regexp::Lexer::TokenType::Comma,
    '-'  => Regexp::Lexer::TokenType::Minus,
    '$'  => Regexp::Lexer::TokenType::ScalarSigil,
    '@'  => Regexp::Lexer::TokenType::ArraySigil,
    ':'  => Regexp::Lexer::TokenType::Colon,
    '#'  => Regexp::Lexer::TokenType::Sharp,
    '^'  => Regexp::Lexer::TokenType::Cap,
    '='  => Regexp::Lexer::TokenType::Equal,
    '!'  => Regexp::Lexer::TokenType::Exclamation,
    q<'> => Regexp::Lexer::TokenType::SingleQuote,
    q<"> => Regexp::Lexer::TokenType::DoubleQuote,
);

sub tokenize {
    my ($re) = @_;

    if (ref $re ne 'Regexp') {
        croak "Not regexp quoted argument is given";
    }

    # B::cstring() is used to escape backslashes
    my $re_cluster_string = B::cstring($re);

    # to remove double-quotes and parenthesis on leading and trailing
    my $re_str = substr(substr($re_cluster_string, 2), 0, -2);

    $re_str =~ s/\\"/"/g; # for double quote which is converted by B::cstring

    # extract modifiers
    $re_str =~ s/\A[?]([^:]*)://;
    my @modifiers;
    for my $modifier (split //, $1) {
        push @modifiers, $modifier;
    }

    my @chars = split //, $re_str;

    my @tokens;
    my $index = 0;

    my $end_of_line_exists = 0;
    if (defined $chars[-1] && $chars[-1] eq '$') {
        pop @chars;
        $end_of_line_exists = 1;
    }

    if (defined $chars[0] && $chars[0] eq '^') {
        push @tokens, {
            char  => shift @chars,
            index => ++$index,
            type  => Regexp::Lexer::TokenType::BeginningOfLine,
        };
    }

    my $backslashes = 0;
    my $next_c;
    for (my $i = 0; defined(my $c = $chars[$i]); $i++) {
        if ($c eq '\\') {
            if ($backslashes <= 1) {
                $backslashes++;
                next;
            }

            # now status -> '\\\\\\'
            if ($backslashes == 2) {
                $next_c = $chars[++$i];
                if (!defined $next_c || $next_c ne '\\') {
                    croak "Invalid syntax regexp is given"; # fail safe
                }

                push @tokens, {
                    char  => '\\\\',
                    index => ++$index,
                    type  => Regexp::Lexer::TokenType::EscapedCharacter,
                };

                $backslashes = 0;
                next;
            }
        }

        # To support *NOT META* newline character which is in regexp
        if ($backslashes == 1) {
            my $type = Regexp::Lexer::TokenType::Unknown;
            if ($c eq 'n') {
                $type = Regexp::Lexer::TokenType::Newline;
            }
            elsif ($c eq 'r') { # XXX maybe unreachable
                $type = Regexp::Lexer::TokenType::Return;
            }

            push @tokens, {
                char  => '\\' . $c,
                index => ++$index,
                type  => $type,
            };

            $backslashes = 0;
            next;
        }

        if ($backslashes == 2) {
            my $type = $escapedSpecialChar{$c};

            # Determine meaning of \N
            if ($c eq 'N') {
                $type = Regexp::Lexer::TokenType::EscapedCharUnicode;

                $next_c = $chars[$i+1];
                if (!defined $next_c || $next_c ne '{') {
                    $type = Regexp::Lexer::TokenType::EscapedNotNewline;
                }
            }

            push @tokens, {
                char  => '\\' . $c,
                index => ++$index,
                type  => $type || Regexp::Lexer::TokenType::EscapedCharacter,
            };

            $backslashes = 0;
            next;
        }

        push @tokens, {
            char  => $c,
            index => ++$index,
            type  => $specialChar{$c} || Regexp::Lexer::TokenType::Character,
        };

        $backslashes = 0; # for fail safe
    }

    if ($end_of_line_exists) {
        push @tokens, {
            char  => '$',
            index => ++$index,
            type  => Regexp::Lexer::TokenType::EndOfLine,
        };
    }

    return {
        tokens    => \@tokens,
        modifiers => \@modifiers,
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Regexp::Lexer - Lexer for regular expression of perl

=head1 SYNOPSIS

    use Regexp::Lexer qw(tokenize);
    my $tokens = tokenize(qr{\Ahello\s+world\z}i);

=head1 DESCRIPTION

Regexp::Lexer is a lexer for regular expression of perl.

This module splits the regular expression string to tokens
which has minimum meaning.

=head1 FUNCTIONS

=over 4

=item * C<tokenize($re:Regexp)>

Tokenizes the regular expression.

This function takes an argument as C<Regexp>, namely it must be regexp quoted variable (i.e. C<qr/SOMETHING/>).
If not C<Regexp> argument is given, this function throws exception.

This function returns the result like so;

    {
        tokens => [
            {
                char => '\A',
                index => 1,
                type => {
                    id => 67,
                    name => 'EscapedBeginningOfString',
                },
            },
            {
                char => 'h',
                index => 2,
                type => {
                    id => 1,
                    name => 'Character',
                },
            },
            ...
        ],
        modifiers => ['^', 'i'],
    }

C<tokens> is the tokens list. Information about C<type> of token is located in the L<Regexp::Lexer::TokenType>.

C<modifiers> is the list of modifiers of regular expression. Please see also L<perlre>.

=back

=head1 SEE ALSO

=over 4

=item * L<perlre>

=item * L<perlrebackslash>

=item * L<Regexp::Lexer::TokenType>

=back

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

