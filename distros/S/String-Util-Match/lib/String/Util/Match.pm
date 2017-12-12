package String::Util::Match;

our $DATE = '2017-12-10'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       match_array_or_regex
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'String utilities related to matching',
};

my $_str_or_re = ['any*'=>{of=>['re*','str*']}];

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

1;
# ABSTRACT: String utilities related to matching

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Util::Match - String utilities related to matching

=head1 VERSION

This document describes version 0.002 of String::Util::Match (from Perl distribution String-Util-Match), released on 2017-12-10.

=head1 SYNOPSIS

 use String::Util::Match qw(match_array_or_regex);

 match_array_or_regex('bar',  ['foo', 'bar', qr/[xyz]/]); # true, matches string
 match_array_or_regex('baz',  ['foo', 'bar', qr/[xyz]/]); # true, matches regex
 match_array_or_regex('oops', ['foo', 'bar', qr/[xyz]/]); # false

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 match_array_or_regex

Usage:

 match_array_or_regex($needle, $haystack) -> any

Check whether an item matches (list of) values/regexes.

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

=item * B<$needle>* => I<str>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Util-Match>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Util-Match>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Util-Match>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
