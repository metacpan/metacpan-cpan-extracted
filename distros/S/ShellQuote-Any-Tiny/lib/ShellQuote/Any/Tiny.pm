package ShellQuote::Any::Tiny;

our $DATE = '2017-09-20'; # DATE
our $VERSION = '0.007'; # VERSION

use strict;
#use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(shell_quote);
our $OS;

sub shell_quote {
    my $arg = shift;

    my $os = $OS || $^O;

    if ($os eq 'MSWin32') {
        if ($arg =~ /\A\w+\z/) {
            return $arg;
        }
        $arg =~ s/\\(?=\\*(?:"|$))/\\\\/g;
        $arg =~ s/"/\\"/g;
        return qq("$arg");
    } else {
        if ($arg =~ /\A\w+\z/) {
            return $arg;
        }
        $arg =~ s/'/'"'"'/g;
        return "'$arg'";
    }
}

1;
# ABSTRACT: Escape string for the Unix/Windows shell

__END__

=pod

=encoding UTF-8

=head1 NAME

ShellQuote::Any::Tiny - Escape string for the Unix/Windows shell

=head1 VERSION

This document describes version 0.007 of ShellQuote::Any::Tiny (from Perl distribution ShellQuote-Any-Tiny), released on 2017-09-20.

=head1 SYNOPSIS

 use ShellQuote::Any::Tiny qw(shell_quote);

 my $cmd = 'echo ' . shell_quote("hello world");

 # On Windows, $cmd becomes 'echo "hello world"'.
 # On Unix, $cmd becomes q(echo 'hello world').

=head1 DESCRIPTION

This module tries to quote command-line argument when passed to shell (either
Unix shells or Windows) using as little code as possible. For more proper
quoting, see See Also section.

=head1 FUNCTIONS

=head2 shell_quote($str) => str

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ShellQuote-Any-Tiny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ShellQuote-Any-Tiny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ShellQuote-Any-Tiny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<String::ShellQuote> for Unix shells

L<Win32::ShellQuote> for Windows shells

L<PERLANCAR::ShellQuote::Any>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
