package Regexp::Pattern::Path;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-01-03'; # DATE
our $DIST = 'Regexp-Pattern-Path'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
#use utf8;

our %RE;

$RE{filename_unix} = {
    summary => 'Valid filename on Unix',
    description => <<'_',

Length must be 1-255 characters. The only characters not allowed include "\0"
(null) and "/" (forward slash, for path separator). Also cannot be '.' or '..'.

_
    pat => qr(\A(?:

                  # 1. does not contain forward slash or nul
                  (?!.*[\0/])

                  # 2. is not '.' or '..'
                  (?!\.\.?\z)

                  # 3. must be between 1-255 characters
                  .{1,255}

              )\z)x,
    tags => ['anchored'],
    examples => [
        {str=>'foo', matches=>1},
        {str=>'foo bar', matches=>1},
        {str=>'', matches=>0, summary=>'Too short'},
        {str=>"a" x 256, matches=>0, summary=>'Too long'},
        {str=>"foo/bar", matches=>0, summary=>'contains slash'},
        {str=>"/foo", matches=>0, summary=>'begins with slash'},
        {str=>"foo/", matches=>0, summary=>'ends with slash'},
        {str=>"foo\0", matches=>0, summary=>'contains null (\\0)'},
        {str=>'.', matches=>0, summary=>'Cannot be "."'},
        {str=>'..', matches=>0, summary=>'Cannot be ".."'},
        {str=>'...', matches=>1},
    ],
};

$RE{dirname_unix} = {
    summary => 'Valid directory name on Unix',
    description => <<'_',

Just like `filename_unix` but allows '.' and '..' (although strictly speaking
'.' and '..' are just special directory names instead of regular ones).

_
    pat => qr(\A(?:

                  # 1. does not contain forward slash or nul
                  (?!.*[\0/])

                  # 2. must be between 1-255 characters
                  .{1,255}

              )\z)x,
    tags => ['anchored'],
    examples => [
        {str=>'foo', matches=>1},
        {str=>'foo bar', matches=>1},
        {str=>'', matches=>0, summary=>'Too short'},
        {str=>"a" x 256, matches=>0, summary=>'Too long'},
        {str=>"foo/bar", matches=>0, summary=>'contains slash'},
        {str=>"/foo", matches=>0, summary=>'begins with slash'},
        {str=>"foo/", matches=>0, summary=>'ends with slash'},
        {str=>"foo\0", matches=>0, summary=>'contains null (\\0)'},
        {str=>'.', matches=>1},
        {str=>'..', matches=>1},
        {str=>'...', matches=>1},
    ],
};

$RE{filename_dos} = {
    summary => 'Valid filename on DOS (8.3/short filenames)',
    description => <<'_',

The following rules are used in this pattern:

1. Contains 1-8 characters, optionally followed by a period and 0-3 characters
(extension).

2. Valid characters include letters A-Z (a-z is also allowed in this regex),
numbers 0-9, and the following special characters:

    _ underscore            ^  caret
    $ dollar sign           ~  tilde
    ! exclamation point     #  number sign
    % percent sign          &  ampersand
      hyphen (-)            {} braces
    @ at sign               `  single quote
    ' apostrophe            () parentheses

3. The name cannot be one of the following reserved file names: CLOCK$, CON,
AUX, COM1, COM2, COM3, COM4, LPT1, LPT2, LPT3, LPT4, NUL, and PRN.

_
    pat => qr(\A(?:

                  # 2. does not contain invalid characters
                  (?!.*[^A-Za-z0-9_\$!\%\-\@'^~#&{}`().])

                  # 3. is not one of reserved filenames
                  (?!(?:CLOCK\$|CON|AUX|COM1|COM2|COM3|COM4|LPT1|LPT2|LPT3|LPT4|NUL|PRN)\z)

                  # 3. must be between 1-8 characters optionally followed by 0-3 characters of extension
                  [^.]{1,8} (?:\.[^.]{0,3})?

              )\z)x,
    tags => ['anchored'],
    examples => [
        {str=>'FOO', matches=>1},
        {str=>'foo', matches=>1, summary=>'Lowercase letters not allowed (convert your string to uppercase first if you want to accept lowercase letters)'},
        {str=>'FOOBARBA.TXT', matches=>1},
        {str=>'.FOO.TXT', matches=>0, summary=>'Contains period other than as filename-extension separator'},
        {str=>'.TXT', matches=>0, summary=>'Does not contain filename'},
        {str=>'', matches=>0, summary=>'Empty'},
        {str=>'FOOBARBAZ', matches=>0, summary=>'Name too long'},
        {str=>'FOOBARBA.TEXT', matches=>0, summary=>'Extension too long'},
        {str=>'CON', matches=>0, summary=>'reserved name CON'},
        {str=>'CONAUX', matches=>1},
        {str=>' FOO.BAR', matches=>0, summary=>'Starts with space'},
        {str=>'FOO .BAR', matches=>0, summary=>'Contains space'},
        {str=>'_$!%-@\'^.~#&', matches=>1},
        {str=>'{}`().', matches=>1},
        {str=>'FILE[1].TXT', matches=>0, summary=>'Contains invalid character [ and ]'},
    ],
};

$RE{filename_windows} = {
    summary => 'Valid filename on Windows (long filenames)',
    description => <<'_',

The following rules are used in this pattern:

1. Contains 1-260 characters (including extension).

2. Does not contain the characters \0, [\x01-\x1f], <, >, :, ", /, \, |, ?, *.

3. The name cannot be one of the following reserved file names: CON, PRN, AUX,
NUL, COM1, COM2, COM3, COM4, COM5, COM6, COM7, COM8, COM9, LPT1, LPT2, LPT3,
LPT4, LPT5, LPT6, LPT7, LPT8, and LPT9.

4. Does not end with a period.

5. Does not begin with a period.

5. Cannot be '.' or '..'.

References:
- <https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file>

_
    pat => qr(\A(?:

                  # does not contain invalid characters
                  (?!.*[\x00-\x1f<>:"/\\|?*])

                  # is not one of reserved filenames
                  (?!(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])\z)

                  # is not . or ..
                  (?!\.\.?\z)

                  # does not begin with .
                  (?!\.)

                  # does not end with .
                  (?!.*\.\z)

                  # 3. must be between 1-260 characters
                  .{1,260}

              )\z)x,
    tags => ['anchored'],
    examples => [
        {str=>'', matches=>0, summary=>'Empty'},
        {str=>'FOO', matches=>1},
        {str=>'foo', matches=>1},
        {str=>'FOOBARBA.TXT', matches=>1},
        {str=>'.FOO.TXT', matches=>0, summary=>'Starts with period'},
        {str=>'bar.', matches=>0, summary=>'Ends with period'},
        {str=>'CON', matches=>0, summary=>'reserved name CON'},
        {str=>'LPT3', matches=>0, summary=>'reserved name LPT3'},
        {str=>'CONAUX', matches=>1},
        #{str=>' FOO.BAR', matches=>0, summary=>'Starts with space'},
        {str=>'FOO .BAR', matches=>1},
        {str=>'foo[1].txt', matches=>1},
        {str=>'foo(2).txt', matches=>1},
        {str=>"foo\0", matches=>0, summary=>'Contains invalid character \0'},
        {str=>"foo\b", matches=>0, summary=>'Contains control character'},
        {str=>"foo/bar", matches=>0, summary=>'Contains invalid character /'},
        {str=>"foo<bar>", matches=>0, summary=>'Contains invalid characters <>'},
        {str=>"foo:bar", matches=>0, summary=>'Contains invalid character :'},
        {str=>"foo's file", matches=>1},
        {str=>'foo "bar"', matches=>0, summary=>'Contains invalid character "'},
        {str=>'foo\\bar', matches=>0, summary=>'Contains invalid character \\'},
        {str=>'foo|bar', matches=>0, summary=>'Contains invalid character |'},
        {str=>'foo?', matches=>0, summary=>'Contains invalid character ?'},
        {str=>'foo*', matches=>0, summary=>'Contains invalid character *'},
        {str=>'a' x 261, matches=>0, summary=>'Too long'},
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

This document describes version 0.003 of Regexp::Pattern::Path (from Perl distribution Regexp-Pattern-Path), released on 2020-01-03.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Path::dirname_unix");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * dirname_unix

Valid directory name on Unix.

Just like C<filename_unix> but allows '.' and '..' (although strictly speaking
'.' and '..' are just special directory names instead of regular ones).


Examples:

 "foo" =~ re("Path::dirname_unix");  # matches

 "foo bar" =~ re("Path::dirname_unix");  # matches

Too short.

 "" =~ re("Path::dirname_unix");  # doesn't match

Too long.

 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" =~ re("Path::dirname_unix");  # doesn't match

contains slash.

 "foo/bar" =~ re("Path::dirname_unix");  # doesn't match

begins with slash.

 "/foo" =~ re("Path::dirname_unix");  # doesn't match

ends with slash.

 "foo/" =~ re("Path::dirname_unix");  # doesn't match

contains null (\0).

 "foo\0" =~ re("Path::dirname_unix");  # doesn't match

 "." =~ re("Path::dirname_unix");  # matches

 ".." =~ re("Path::dirname_unix");  # matches

 "..." =~ re("Path::dirname_unix");  # matches

=item * filename_dos

Valid filename on DOS (8.3E<sol>short filenames).

The following rules are used in this pattern:

=over

=item 1. Contains 1-8 characters, optionally followed by a period and 0-3 characters
(extension).

=item 2. Valid characters include letters A-Z (a-z is also allowed in this regex),
numbers 0-9, and the following special characters:

_ underscore            ^  caret
$ dollar sign           ~  tilde
! exclamation point     #  number sign
% percent sign          &  ampersand
  hyphen (-)            {} braces
@ at sign               `  single quote
' apostrophe            () parentheses

=item 3. The name cannot be one of the following reserved file names: CLOCK$, CON,
AUX, COM1, COM2, COM3, COM4, LPT1, LPT2, LPT3, LPT4, NUL, and PRN.

=back


Examples:

 "FOO" =~ re("Path::filename_dos");  # matches

Lowercase letters not allowed (convert your string to uppercase first if you want to accept lowercase letters).

 "foo" =~ re("Path::filename_dos");  # matches

 "FOOBARBA.TXT" =~ re("Path::filename_dos");  # matches

Contains period other than as filename-extension separator.

 ".FOO.TXT" =~ re("Path::filename_dos");  # doesn't match

Does not contain filename.

 ".TXT" =~ re("Path::filename_dos");  # doesn't match

Empty.

 "" =~ re("Path::filename_dos");  # doesn't match

Name too long.

 "FOOBARBAZ" =~ re("Path::filename_dos");  # doesn't match

Extension too long.

 "FOOBARBA.TEXT" =~ re("Path::filename_dos");  # doesn't match

reserved name CON.

 "CON" =~ re("Path::filename_dos");  # doesn't match

 "CONAUX" =~ re("Path::filename_dos");  # matches

Starts with space.

 " FOO.BAR" =~ re("Path::filename_dos");  # doesn't match

Contains space.

 "FOO .BAR" =~ re("Path::filename_dos");  # doesn't match

 "_\$!%-\@'^.~#&" =~ re("Path::filename_dos");  # matches

 "{}`()." =~ re("Path::filename_dos");  # matches

Contains invalid character [ and ].

 "FILE[1].TXT" =~ re("Path::filename_dos");  # doesn't match

=item * filename_unix

Valid filename on Unix.

Length must be 1-255 characters. The only characters not allowed include "\0"
(null) and "/" (forward slash, for path separator). Also cannot be '.' or '..'.


Examples:

 "foo" =~ re("Path::filename_unix");  # matches

 "foo bar" =~ re("Path::filename_unix");  # matches

Too short.

 "" =~ re("Path::filename_unix");  # doesn't match

Too long.

 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" =~ re("Path::filename_unix");  # doesn't match

contains slash.

 "foo/bar" =~ re("Path::filename_unix");  # doesn't match

begins with slash.

 "/foo" =~ re("Path::filename_unix");  # doesn't match

ends with slash.

 "foo/" =~ re("Path::filename_unix");  # doesn't match

contains null (\0).

 "foo\0" =~ re("Path::filename_unix");  # doesn't match

Cannot be ".".

 "." =~ re("Path::filename_unix");  # doesn't match

Cannot be "..".

 ".." =~ re("Path::filename_unix");  # doesn't match

 "..." =~ re("Path::filename_unix");  # matches

=item * filename_windows

Valid filename on Windows (long filenames).

The following rules are used in this pattern:

=over

=item 1. Contains 1-260 characters (including extension).

=item 2. Does not contain the characters \0, [\x01-\x1f], <, >, :, ", /, \, |, ?, *.

=item 3. The name cannot be one of the following reserved file names: CON, PRN, AUX,
NUL, COM1, COM2, COM3, COM4, COM5, COM6, COM7, COM8, COM9, LPT1, LPT2, LPT3,
LPT4, LPT5, LPT6, LPT7, LPT8, and LPT9.

=item 4. Does not end with a period.

=item 5. Does not begin with a period.

=item 6. Cannot be '.' or '..'.

=back

References:
- L<https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file>


Examples:

Empty.

 "" =~ re("Path::filename_windows");  # doesn't match

 "FOO" =~ re("Path::filename_windows");  # matches

 "foo" =~ re("Path::filename_windows");  # matches

 "FOOBARBA.TXT" =~ re("Path::filename_windows");  # matches

Starts with period.

 ".FOO.TXT" =~ re("Path::filename_windows");  # doesn't match

Ends with period.

 "bar." =~ re("Path::filename_windows");  # doesn't match

reserved name CON.

 "CON" =~ re("Path::filename_windows");  # doesn't match

reserved name LPT3.

 "LPT3" =~ re("Path::filename_windows");  # doesn't match

 "CONAUX" =~ re("Path::filename_windows");  # matches

 "FOO .BAR" =~ re("Path::filename_windows");  # matches

 "foo[1].txt" =~ re("Path::filename_windows");  # matches

 "foo(2).txt" =~ re("Path::filename_windows");  # matches

Contains invalid character \0.

 "foo\0" =~ re("Path::filename_windows");  # doesn't match

Contains control character.

 "foo\b" =~ re("Path::filename_windows");  # doesn't match

Contains invalid character E<sol>.

 "foo/bar" =~ re("Path::filename_windows");  # doesn't match

Contains invalid characters <E<gt>.

 "foo<bar>" =~ re("Path::filename_windows");  # doesn't match

Contains invalid character :.

 "foo:bar" =~ re("Path::filename_windows");  # doesn't match

 "foo's file" =~ re("Path::filename_windows");  # matches

Contains invalid character ".

 "foo \"bar\"" =~ re("Path::filename_windows");  # doesn't match

Contains invalid character \.

 "foo\\bar" =~ re("Path::filename_windows");  # doesn't match

Contains invalid character E<verbar>.

 "foo|bar" =~ re("Path::filename_windows");  # doesn't match

Contains invalid character ?.

 "foo?" =~ re("Path::filename_windows");  # doesn't match

Contains invalid character *.

 "foo*" =~ re("Path::filename_windows");  # doesn't match

Too long.

 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" =~ re("Path::filename_windows");  # doesn't match

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
