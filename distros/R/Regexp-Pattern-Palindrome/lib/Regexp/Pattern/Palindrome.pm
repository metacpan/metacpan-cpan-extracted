package Regexp::Pattern::Palindrome;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-11'; # DATE
our $DIST = 'Regexp-Pattern-Palindrome'; # DIST
our $VERSION = '0.002'; # VERSION

our %RE = (
    palindrome_alphanum => {
        summary => 'Palindrome alphanumeric word (single alphanum included)',
        pat => qr/((\w)(?1)\2|\w?)/,
        tags => ['capturing'],
        examples => [
            {str=>'foo', anchor=>1, matches=>0},
            {str=>'Aa', anchor=>1, matches=>0},
            {str=>'-', anchor=>1, matches=>0},
            {str=>'a-a', anchor=>1, matches=>0},

            {str=>'a', anchor=>1, matches=>1},
            {str=>'aa', anchor=>1, matches=>1},
            {str=>'zzz', anchor=>1, matches=>1},
            {str=>'kodok', anchor=>1, matches=>1},
            {str=>'20200202', anchor=>1, matches=>1, summary=>'Feb 2nd, 2020 in YYYYMMDD format'},
        ],
    },
    gen_palindrome_alphanum => {
        summary => 'Generate regex to match palindrome alphanumeric word of certain minimum length',
        gen_args => {
            min_len => {
                schema => ['int*', is=>[1,3,5,7,9,11,13,15]],
                req => 1,

            },
        },
        gen => sub {
            my %args = @_;
            my $min_len = $args{min_len};
            if    ($min_len ==  1) { return qr/                             ((\w)(?1)\2|\w?)               /x }
            elsif ($min_len ==  3) { return qr/                         (\w)((\w)(?2)\3|\w?)\1             /x }
            elsif ($min_len ==  5) { return qr/                     (\w)(\w)((\w)(?3)\4|\w?)\2\1           /x }
            elsif ($min_len ==  7) { return qr/                 (\w)(\w)(\w)((\w)(?4)\5|\w?)\3\2\1         /x }
            elsif ($min_len ==  9) { return qr/             (\w)(\w)(\w)(\w)((\w)(?5)\6|\w?)\4\3\2\1       /x }
            elsif ($min_len == 11) { return qr/         (\w)(\w)(\w)(\w)(\w)((\w)(?6)\7|\w?)\5\4\3\2\1     /x }
            elsif ($min_len == 13) { return qr/     (\w)(\w)(\w)(\w)(\w)(\w)((\w)(?7)\8|\w?)\6\5\4\3\2\1   /x }
            elsif ($min_len == 15) { return qr/ (\w)(\w)(\w)(\w)(\w)(\w)(\w)((\w)(?8)\9|\w?)\7\6\5\4\3\2\1 /x }
            else  { die "Invalid value for min_len" }
        },
        tags => ['capturing'],
        examples => [
            {str=>'a'    , anchor=>1, gen_args=>{min_len=>1}, matches=>1},

            {str=>'a'    , anchor=>1, gen_args=>{min_len=>3}, matches=>0},
            {str=>'aaa'  , anchor=>1, gen_args=>{min_len=>3}, matches=>1},
            {str=>'aba'  , anchor=>1, gen_args=>{min_len=>3}, matches=>1},
            {str=>'abba' , anchor=>1, gen_args=>{min_len=>3}, matches=>1},
            {str=>'abcba', anchor=>1, gen_args=>{min_len=>3}, matches=>1},
            {str=>'abc'  , anchor=>1, gen_args=>{min_len=>3}, matches=>0},

            {str=>'a'     , anchor=>1, gen_args=>{min_len=>5}, matches=>0},
            {str=>'abcba' , anchor=>1, gen_args=>{min_len=>5}, matches=>1},
            {str=>'abccba', anchor=>1, gen_args=>{min_len=>5}, matches=>1},
            {str=>'abcde' , anchor=>1, gen_args=>{min_len=>5}, matches=>0},

            {str=>'a'       , anchor=>1, gen_args=>{min_len=>7}, matches=>0},
            {str=>'abcdcba' , anchor=>1, gen_args=>{min_len=>7}, matches=>1},
            {str=>'abcddcba', anchor=>1, gen_args=>{min_len=>7}, matches=>1},
            {str=>'abcdefg' , anchor=>1, gen_args=>{min_len=>7}, matches=>0},

            {str=>'a'         , anchor=>1, gen_args=>{min_len=>9}, matches=>0},
            {str=>'abcdedcba' , anchor=>1, gen_args=>{min_len=>9}, matches=>1},
            {str=>'abcdeedcba', anchor=>1, gen_args=>{min_len=>9}, matches=>1},
            {str=>'abcdefghi' , anchor=>1, gen_args=>{min_len=>9}, matches=>0},

            {str=>'a'           , anchor=>1, gen_args=>{min_len=>11}, matches=>0},
            {str=>'abcdefedcba' , anchor=>1, gen_args=>{min_len=>11}, matches=>1},
            {str=>'abcdeffedcba', anchor=>1, gen_args=>{min_len=>11}, matches=>1},
            {str=>'abcdefghijk' , anchor=>1, gen_args=>{min_len=>11}, matches=>0},

            {str=>'a'             , anchor=>1, gen_args=>{min_len=>13}, matches=>0},
            {str=>'abcdefgfedcba' , anchor=>1, gen_args=>{min_len=>13}, matches=>1},
            {str=>'abcdefggfedcba', anchor=>1, gen_args=>{min_len=>13}, matches=>1},
            {str=>'abcdefghijklm' , anchor=>1, gen_args=>{min_len=>13}, matches=>0},

            {str=>'a'               , anchor=>1, gen_args=>{min_len=>15}, matches=>0},
            {str=>'abcdefghgfedcba' , anchor=>1, gen_args=>{min_len=>15}, matches=>1},
            {str=>'abcdefghhgfedcba', anchor=>1, gen_args=>{min_len=>15}, matches=>1},
            {str=>'abcdefghijklmno' , anchor=>1, gen_args=>{min_len=>15}, matches=>0},
        ],
    },
);

1;
# ABSTRACT: Regexp patterns related to palindrome

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Palindrome - Regexp patterns related to palindrome

=head1 VERSION

This document describes version 0.002 of Regexp::Pattern::Palindrome (from Perl distribution Regexp-Pattern-Palindrome), released on 2020-02-11.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Palindrome::gen_palindrome_alphanum");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * gen_palindrome_alphanum

Generate regex to match palindrome alphanumeric word of certain minimum length.

This is a dynamic pattern which will be generated on-demand.

The following arguments are available to customize the generated pattern:

=over

=item * min_len

=back



Examples:

 "a" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>1});  # matches

 "a" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>3});  # doesn't match

 "aaa" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>3});  # matches

 "aba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>3});  # matches

 "abba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>3});  # matches

 "abcba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>3});  # matches

 "abc" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>3});  # doesn't match

 "a" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>5});  # doesn't match

 "abcba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>5});  # matches

 "abccba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>5});  # matches

 "abcde" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>5});  # doesn't match

 "a" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>7});  # doesn't match

 "abcdcba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>7});  # matches

 "abcddcba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>7});  # matches

 "abcdefg" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>7});  # doesn't match

 "a" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>9});  # doesn't match

 "abcdedcba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>9});  # matches

 "abcdeedcba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>9});  # matches

 "abcdefghi" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>9});  # doesn't match

 "a" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>11});  # doesn't match

 "abcdefedcba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>11});  # matches

 "abcdeffedcba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>11});  # matches

 "abcdefghijk" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>11});  # doesn't match

 "a" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>13});  # doesn't match

 "abcdefgfedcba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>13});  # matches

 "abcdefggfedcba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>13});  # matches

 "abcdefghijklm" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>13});  # doesn't match

 "a" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>15});  # doesn't match

 "abcdefghgfedcba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>15});  # matches

 "abcdefghhgfedcba" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>15});  # matches

 "abcdefghijklmno" =~ re("Palindrome::gen_palindrome_alphanum", {min_len=>15});  # doesn't match

=item * palindrome_alphanum

Palindrome alphanumeric word (single alphanum included).

Examples:

 "foo" =~ re("Palindrome::palindrome_alphanum");  # doesn't match

 "Aa" =~ re("Palindrome::palindrome_alphanum");  # doesn't match

 "-" =~ re("Palindrome::palindrome_alphanum");  # doesn't match

 "a-a" =~ re("Palindrome::palindrome_alphanum");  # doesn't match

 "a" =~ re("Palindrome::palindrome_alphanum");  # matches

 "aa" =~ re("Palindrome::palindrome_alphanum");  # matches

 "zzz" =~ re("Palindrome::palindrome_alphanum");  # matches

 "kodok" =~ re("Palindrome::palindrome_alphanum");  # matches

Feb 2nd, 2020 in YYYYMMDD format.

 20200202 =~ re("Palindrome::palindrome_alphanum");  # matches

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Palindrome>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Palindrome>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Palindrome>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
