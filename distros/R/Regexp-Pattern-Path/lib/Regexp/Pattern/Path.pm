package Regexp::Pattern::Path;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-01-02'; # DATE
our $DIST = 'Regexp-Pattern-Path'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %RE;

$RE{filename_unix} = {
    summary => 'Valid filename pattern on Unix',
    description => <<'_',

Length must be 1-255 characters. The only characters not allowed include "\0"
(null) and "/" (forward slash, for path separator).

_
    pat => qr![^\0/]{1,255}!,
    examples => [
        {str=>'foo', matches=>1},
        {str=>'foo bar', matches=>1},
        {str=>'', matches=>0, summary=>'Too short'},
        {str=>"a" x 256, anchor=>1, matches=>0, summary=>'Too long'},
        {str=>"foo/bar", anchor=>1, matches=>0, summary=>'contains slash'},
        {str=>"foo\0", anchor=>1, matches=>0, summary=>'contains null (\\0)'},
    ],
};

1;
# ABSTRACT: Regexp patterns related to path

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Path - Regexp patterns related to path

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::Path (from Perl distribution Regexp-Pattern-Path), released on 2020-01-02.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Path::filename_unix");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * filename_unix

Valid filename pattern on Unix.

Length must be 1-255 characters. The only characters not allowed include "\0"
(null) and "/" (forward slash, for path separator).


Examples:

 "foo" =~ re("Path::filename_unix");  # matches

 "foo bar" =~ re("Path::filename_unix");  # matches

Too short.

 "" =~ re("Path::filename_unix");  # doesn't match

Too long.

 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" =~ re("Path::filename_unix");  # doesn't match

contains slash.

 "foo/bar" =~ re("Path::filename_unix");  # doesn't match

contains null (\0).

 "foo\0" =~ re("Path::filename_unix");  # doesn't match

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Path>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Path>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Path>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
