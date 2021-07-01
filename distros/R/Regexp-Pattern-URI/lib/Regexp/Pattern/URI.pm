package Regexp::Pattern::URI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-01'; # DATE
our $DIST = 'Regexp-Pattern-URI'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %RE;

$RE{http} = {
    summary => 'Match an http/https URL',
    pat => qr{(?:(?:https?)://(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z])[.]?)|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)))(?::(?:(?:[0-9]*)))?(?:/(?:(?:(?:(?:(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)(?:;(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))*)(?:/(?:(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)(?:;(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))*))*))(?:[?](?:(?:(?:[;/?:@&=+\$,a-zA-Z0-9\-_.!~*'()]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)))?))?)}, # from Regexp::Common {URI}{HTTP} modified to support https
    examples => [
        {str=>'http://www.example.org/foo', matches=>1},
        {str=>'ftp://www.example.org/foo', matches=>0},
        {str=>'foo@example.org', matches=>0},
    ],
};

$RE{file} = {
    summary => 'Match a file:// URL',
    pat => qr{(?:(?:file)://(?:(?:(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z]))|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+))|localhost)?)(?:/(?:(?:(?:(?:[-a-zA-Z0-9\$_.+!*'(),:@&=]|(?:%[a-fA-F0-9][a-fA-F0-9]))*)(?:/(?:(?:[-a-zA-Z0-9\$_.+!*'(),:@&=]|(?:%[a-fA-F0-9][a-fA-F0-9]))*))*)))))}, # from Regexp::Common {URI}{file}
    examples => [
        {str=>'file://foo/bar.txt', matches=>1},
        {str=>'ftp://www.example.org/foo', matches=>0},
        {str=>'foo/bar.txt', matches=>0},
    ],
};

$RE{ftp} = {
    summary => 'Match an ftp:// URL',
    pat => qr{(?:(?:ftps?|sftp)://(?:(?:(?:(?:[a-zA-Z0-9\-_.!~*'();:&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))(?:)@)?(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z])[.]?)|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)))(?::(?:(?:[0-9]*)))?(?:/(?:(?:(?:(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)(?:/(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))*))(?:;type=(?:[AIai]))?))?)}, # from Regexp::Common {URI}{FTP}
    examples => [
        {str=>'ftp://www.example.org/foo', matches=>1},
        {str=>'http://www.example.org/foo', matches=>0},
        {str=>'foo/bar.txt', matches=>0},
    ],
};

$RE{ssh} = {
    summary => 'Match an ssh:// URL',
    pat => qr{(?:(?:ssh)://(?:(?:(?:(?:[a-zA-Z0-9\-_.!~*'();:&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))(?:)@)?(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z])[.]?)|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)))(?::(?:(?:[0-9]*)))?(?:/(?:(?:(?:(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)(?:/(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))*))(?:;type=(?:[AIai]))?))?)}, # from Regexp::Common {URI}{FTP} modified
    examples => [
        {str=>'ssh://user:pass@example.org:/foo/bar.git', matches=>1},
        {str=>'http://www.example.org/foo', matches=>0},
        {str=>'foo/bar.txt', matches=>0},
    ],
};

1;
# ABSTRACT: Regexp patterns related to URI

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::URI - Regexp patterns related to URI

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::URI (from Perl distribution Regexp-Pattern-URI), released on 2021-07-01.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("URI::file");

=head1 DESCRIPTION

This is currently a repackaging (lower startup-overhead version) of some of the
regexes in L<Regexp::Common::URI>.

=head1 REGEXP PATTERNS

=over

=item * file

Match a file:E<sol>E<sol> URL.

Examples:

Example #1.

 "file://foo/bar.txt" =~ re("URI::file");  # matches

Example #2.

 "ftp://www.example.org/foo" =~ re("URI::file");  # DOESN'T MATCH

Example #3.

 "foo/bar.txt" =~ re("URI::file");  # DOESN'T MATCH

=item * ftp

Match an ftp:E<sol>E<sol> URL.

Examples:

Example #1.

 "ftp://www.example.org/foo" =~ re("URI::ftp");  # matches

Example #2.

 "http://www.example.org/foo" =~ re("URI::ftp");  # DOESN'T MATCH

Example #3.

 "foo/bar.txt" =~ re("URI::ftp");  # DOESN'T MATCH

=item * http

Match an httpE<sol>https URL.

Examples:

Example #1.

 "http://www.example.org/foo" =~ re("URI::http");  # matches

Example #2.

 "ftp://www.example.org/foo" =~ re("URI::http");  # DOESN'T MATCH

Example #3.

 "foo\@example.org" =~ re("URI::http");  # DOESN'T MATCH

=item * ssh

Match an ssh:E<sol>E<sol> URL.

Examples:

Example #1.

 "ssh://user:pass\@example.org:/foo/bar.git" =~ re("URI::ssh");  # matches

Example #2.

 "http://www.example.org/foo" =~ re("URI::ssh");  # DOESN'T MATCH

Example #3.

 "foo/bar.txt" =~ re("URI::ssh");  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-URI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-URI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-URI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Common>, particularly L<Regexp::Common::URI>

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
