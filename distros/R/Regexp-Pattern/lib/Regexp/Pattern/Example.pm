package Regexp::Pattern::Example;

our $DATE = '2020-04-01'; # DATE
our $VERSION = '0.2.14'; # VERSION

use 5.010001;

# BEGIN_BLOCK: def

our %RE = (
    # the minimum spec
    re1 => { pat => qr/\d{3}-\d{3}/ },

    # more complete spec
    re2 => {
        summary => 'This is regexp for blah', # plaintext
        description => <<'_',

A longer description in *Markdown* format.

_
        pat => qr/\d{3}-\d{3}(?:-\d{5})?/,
        tags => ['A','B'],
        examples => [
            # examples can be tested using 'test-regexp-pattern' script
            # (distributed in Test-Regexp-Pattern distribution). examples can
            # also be rendered in your POD using
            # Pod::Weaver::Plugin::Regexp::Pattern.
            {
                str => '123-456',
                matches => 1,
            },
            {
                summary => 'Another example that matches',
                str => '123-456-78901',
                matches => 1,
            },
            {
                summary => 'An example that does not match',
                str => '123456',
                matches => 0,
            },
            {
                summary => 'An example that does not get tested',
                str => '123456',
            },
            {
                summary => 'Another example that does not get tested nor rendered to POD',
                str => '234567',
                matches => 0,
                test => 0,
                doc => 0,
            },
        ],
    },

    # dynamic (regexp generator)
    re3 => {
        summary => 'This is a regexp for blah blah',
        description => <<'_',

...

_
        gen => sub {
            my %args = @_;
            my $variant = $args{variant} || 'A';
            if ($variant eq 'A') {
                return qr/\d{3}-\d{3}/;
            } else { # B
                return qr/\d{3}-\d{2}-\d{5}/;
            }
        },
        gen_args => {
            variant => {
                summary => 'Choose variant',
                schema => ['str*', in=>['A','B']],
                default => 'A',
                req => 1,
            },
        },
        tags => ['B','C'],
        examples => [
            {
                summary => 'An example that matches',
                gen_args => {variant=>'A'},
                str => '123-456',
                matches => 1,
            },
            {
                summary => "An example that doesn't match",
                gen_args => {variant=>'B'},
                str => '123-456',
                matches => 0,
            },
        ],
    },

    re4 => {
        summary => 'This is a regexp that does capturing',
        # it is recommended that your pattern does not capture, unless
        # necessary. capturing pattern should tag with 'capturing' to let
        # users/tools know.
        tags => ['capturing'],
        pat => qr/(\d{3})-(\d{3})/,
        examples => [
            {str=>'123-456', matches=>[123, 456]},
            {str=>'foo-bar', matches=>[]},
        ],
    },

    re5 => {
        summary => 'This is another regexp that is anchored and does (named) capturing',
        # it is recommended that your pattern is not anchored for more
        # reusability, unless necessary. anchored pattern should tag with
        # 'anchored' to let users/tools know.
        tags => ['capturing', 'anchored'],
        pat => qr/^(?<cap1>\d{3})-(?<cap2>\d{3})/,
        examples => [
            {str=>'123-456', matches=>{cap1=>123, cap2=>456}},
            {str=>'something 123-456', matches=>{}},
        ],
    },
);

# END_BLOCK: def

1;
# ABSTRACT: An example Regexp::Pattern::* module

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Example - An example Regexp::Pattern::* module

=head1 VERSION

This document describes version 0.2.14 of Regexp::Pattern::Example (from Perl distribution Regexp-Pattern), released on 2020-04-01.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Example::re1");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * re1

=item * re2

This is regexp for blah.

A longer description in I<Markdown> format.


Examples:

 "123-456" =~ re("Example::re2");  # matches

Another example that matches.

 "123-456-78901" =~ re("Example::re2");  # matches

An example that does not match.

 123456 =~ re("Example::re2");  # doesn't match

An example that does not get tested.

 123456 =~ re("Example::re2");  # doesn't match

=item * re3

This is a regexp for blah blah.

...


This is a dynamic pattern which will be generated on-demand.

The following arguments are available to customize the generated pattern:

=over

=item * variant

Choose variant.

=back



Examples:

An example that matches.

 "123-456" =~ re("Example::re3", {variant=>"A"});  # matches

An example that doesn't match.

 "123-456" =~ re("Example::re3", {variant=>"B"});  # doesn't match

=item * re4

This is a regexp that does capturing.

Examples:

 "123-456" =~ re("Example::re4"); # matches, $1=123, $2=456

 "foo-bar" =~ re("Example::re4");  # doesn't match

=item * re5

This is another regexp that is anchored and does (named) capturing.

Examples:

 "123-456" =~ re("Example::re5"); # matches, $+{"cap1"}=123, $+{"cap2"}=456

 "something 123-456" =~ re("Example::re5");  # doesn't match

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
