package String::Util::Match;

use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-10'; # DATE
our $DIST = 'String-Util-Match'; # DIST
our $VERSION = '0.004'; # VERSION

our @EXPORT_OK = qw(
                       match_string
                       match_array_or_regex
                       num_occurs
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'String utilities related to matching',
};

my $_str_or_re = ['any*'=>{of=>['re*','str*']}];

$SPEC{match_string} = {
    v => 1.1,
    summary => 'Match a string (with one of several choices)',
    args => {
        ignore_case => {
            schema => 'bool*',
            description => <<'MARKDOWN',

Only relevant for string vs string matching.

MARKDOWN
        },
        str => {
            summary => 'String to match against',
            schema => 'str*',
            req => 1,
        },
        matcher => {
            summary => 'Matcher',
            #schema => 'matcher::str*',
            schema => ['any*', of=> [
                'str*',
                'aos*',
                'obj::re*',
                'code*',
            ]],
        },
    },
    #args_as => 'array',
    result_naked => 1,
};
sub match_string {
    my %args = @_;

    my $str = $args{str};
    return 0 unless defined $str;

    my $matcher = $args{matcher};
    my $ref = ref $matcher;
    if (!$ref) {
        return $args{ignore_case} ? lc($str) eq lc($matcher) : $str eq $matcher;
    } elsif ($ref eq 'ARRAY') {
        if ($args{ignore_case}) {
            my $lc = lc $str;
            for (@$matcher) {
                return 1 if $lc eq lc($_);
            }
        } else {
            for (@$matcher) {
                return 1 if $str eq $_;
            }
        }
        return 0;
    } elsif ($ref eq 'Regexp') {
        return $str =~ $matcher;
    } elsif ($ref eq 'CODE') {
        return $matcher->($str) ? 1:0;
    } else {
        die "Matcher must be string/array/Regexp/code (got $ref)";
    }
}

$SPEC{match_array_or_regex} = {
    v => 1.1,
    summary => 'Check whether an item matches (list of) values/regexes',
    description => <<'_',

This routine can be used to match an item against a regex or a list of
strings/regexes, e.g. when matching against an ACL.

Since the smartmatch (`~~`) operator can already match against a list of strings
or regexes, this function is currently basically equivalent to:

    if (ref($haystack) eq 'ARRAY') {
        return $needle ~~ @$haystack;
    } else {
        return $needle =~ /$haystack/;
    }

except that the smartmatch operator covers more cases and is currently
deprecated in the current perl versions and might be removed in future versions.

_
    examples => [
        {args=>{needle=>"abc", haystack=>["abc", "abd"]}, result=>1},
        {args=>{needle=>"abc", haystack=>qr/ab./}, result=>1},
        {args=>{needle=>"abc", haystack=>[qr/ab./, "abd"]}, result=>1},
    ],
    args_as => 'array',
    args => {
        needle => {
            schema => ["str*"],
            pos => 0,
            req => 1,
        },
        haystack => {
            # XXX checking this schema might actually take longer than matching
            # the needle! so when arg validation is implemented, provide a way
            # to skip validating this schema

            schema => ["any*" => {
                of => [$_str_or_re, ["array*"=>{of=>$_str_or_re}]],
            }],
            pos => 1,
            req => 1,
        },
    },
    result_naked => 1,
};
sub match_array_or_regex {
    my ($needle, $haystack) = @_;
    my $ref = ref($haystack);
    if ($ref eq 'ARRAY') {
        for (@$haystack) {
            if (ref $_ eq 'Regexp') {
                return 1 if $needle =~ $_;
            } else {
                return 1 if $needle eq $_;
            }
        }
        return 0;
    } elsif (!$ref) {
        return $needle =~ /$haystack/;
    } elsif ($ref eq 'Regexp') {
        return $needle =~ $haystack;
    } else {
        die "Invalid haystack, must be regex or array of strings/regexes";
    }
}

$SPEC{num_occurs} = {
    v => 1.1,
    summary => "Count how many times a substring occurs (or a regex pattern matches) a string",
    args => {
        string => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        substring => {
            schema => $_str_or_re,
            req => 1,
            pos => 1,
        },
    },
    args_as => 'array',
    result => {
        schema => 'uint*',
    },
    result_naked => 1,
};
sub num_occurs {
    my ($string, $substr) = @_;

    if (ref $substr eq 'Regexp') {
        my $n = 0;
        $n++ while $string =~ /$substr/g;
        return $n;
    } else {
        my $n = 0;
        $n++ while $string =~ /\Q$substr\E/g;
        return $n;
    }
}

1;
# ABSTRACT: String utilities related to matching

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Util::Match - String utilities related to matching

=head1 VERSION

This document describes version 0.004 of String::Util::Match (from Perl distribution String-Util-Match), released on 2024-01-10.

=head1 SYNOPSIS

 use String::Util::Match qw(match_array_or_regex num_occurs);

 match_array_or_regex('bar',  ['foo', 'bar', qr/[xyz]/]); # true, matches string
 match_array_or_regex('baz',  ['foo', 'bar', qr/[xyz]/]); # true, matches regex
 match_array_or_regex('oops', ['foo', 'bar', qr/[xyz]/]); # false

 print num_occurs("foobarbaz", "a"); # => 2
 print num_occurs("foobarbaz", "A"); # => 0
 print num_occurs("foobarbaz", qr/a/i); # => 2
 print num_occurs("foobarbaz", qr/[aeiou]/); # => 4

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 match_array_or_regex

Usage:

 match_array_or_regex($needle, $haystack) -> any

Check whether an item matches (list of) valuesE<sol>regexes.

Examples:

=over

=item * Example #1:

 match_array_or_regex("abc", ["abc", "abd"]); # -> 1

=item * Example #2:

 match_array_or_regex("abc", qr/ab./); # -> 1

=item * Example #3:

 match_array_or_regex("abc", [qr/ab./, "abd"]); # -> 1

=back

This routine can be used to match an item against a regex or a list of
strings/regexes, e.g. when matching against an ACL.

Since the smartmatch (C<~~>) operator can already match against a list of strings
or regexes, this function is currently basically equivalent to:

 if (ref($haystack) eq 'ARRAY') {
     return $needle ~~ @$haystack;
 } else {
     return $needle =~ /$haystack/;
 }

except that the smartmatch operator covers more cases and is currently
deprecated in the current perl versions and might be removed in future versions.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$haystack>* => I<re|str|array[re|str]>

(No description)

=item * B<$needle>* => I<str>

(No description)


=back

Return value:  (any)



=head2 match_string

Usage:

 match_string(%args) -> any

Match a string (with one of several choices).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ignore_case> => I<bool>

Only relevant for string vs string matching.

=item * B<matcher> => I<str|aos|obj::re|code>

Matcher.

=item * B<str>* => I<str>

String to match against.


=back

Return value:  (any)



=head2 num_occurs

Usage:

 num_occurs($string, $substring) -> uint

Count how many times a substring occurs (or a regex pattern matches) a string.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$string>* => I<str>

(No description)

=item * B<$substring>* => I<re|str>

(No description)


=back

Return value:  (uint)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Util-Match>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Util-Match>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2023, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Util-Match>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
