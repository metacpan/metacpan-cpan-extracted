package Regexp::Pattern::OS;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-10'; # DATE
our $DIST = 'Regexp-Pattern-OS'; # DIST
our $VERSION = '0.002'; # VERSION

use Perl::osnames;

our %RE = (
    os_is_known => {
        summary => 'Check that operating system ($^O) is a known value',
        pat => $Perl::osnames::RE_OS_IS_KNOWN,
        tags => ['anchored'],
        examples => [
            {str=>'linux', matches=>1},
            {str=>'MSWin32', matches=>1},
            {str=>'foo', matches=>0},
        ],
    },
    os_is_unix => {
        summary => 'Check that operating system ($^O) is a Unix',
        pat => $Perl::osnames::RE_OS_IS_UNIX,
        tags => ['anchored'],
        examples => [
            {str=>'linux', matches=>1},
            {str=>'MSWin32', matches=>0},
        ],
    },
    os_is_posix => {
        summary => 'Check that operating system ($^O) is (mostly) POSIX compatible',
        pat => $Perl::osnames::RE_OS_IS_POSIX,
        tags => ['anchored'],
        examples => [
            {str=>'linux', matches=>1},
            {str=>'MSWin32', matches=>0},
        ],
    },
);

1;
# ABSTRACT: Regexp patterns related to OS names and Perl's $^O

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::OS - Regexp patterns related to OS names and Perl's $^O

=head1 VERSION

This document describes version 0.002 of Regexp::Pattern::OS (from Perl distribution Regexp-Pattern-OS), released on 2020-02-10.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("OS::os_is_known");

=head1 DESCRIPTION

This is basically a glue to L<Perl::osnames>.

=head1 PATTERNS

=over

=item * os_is_known

Check that operating system ($^O) is a known value.

Examples:

 "linux" =~ re("OS::os_is_known");  # matches

 "MSWin32" =~ re("OS::os_is_known");  # matches

 "foo" =~ re("OS::os_is_known");  # doesn't match

=item * os_is_posix

Check that operating system ($^O) is (mostly) POSIX compatible.

Examples:

 "linux" =~ re("OS::os_is_posix");  # matches

 "MSWin32" =~ re("OS::os_is_posix");  # doesn't match

=item * os_is_unix

Check that operating system ($^O) is a Unix.

Examples:

 "linux" =~ re("OS::os_is_unix");  # matches

 "MSWin32" =~ re("OS::os_is_unix");  # doesn't match

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-OS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-OS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-OS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perl::osnames>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
