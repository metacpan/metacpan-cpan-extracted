package Shell::Cap;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-10'; # DATE
our $DIST = 'Shell-Cap'; # DIST
our $VERSION = '0.002'; # VERSION

use strict 'vars', 'subs';
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = qw(
    shell_supports_pipe
);

sub shell_supports_pipe {
    require ShellQuote::Any::PERLANCAR;

    my $cmd = join(
        " ",
        ShellQuote::Any::PERLANCAR::shell_quote($^X),
        "-e", ShellQuote::Any::PERLANCAR::shell_quote("print 2"),
        "|",
        ShellQuote::Any::PERLANCAR::shell_quote($^X),
        "-e", ShellQuote::Any::PERLANCAR::shell_quote("print <STDIN>*3"),
    );
    log_trace "Checking whether shell supports pipe with command $cmd";
    `$cmd` == 6 ? 1:0;
}

1;
# ABSTRACT: Probe shell's capabilities

__END__

=pod

=encoding UTF-8

=head1 NAME

Shell::Cap - Probe shell's capabilities

=head1 VERSION

This document describes version 0.002 of Shell::Cap (from Perl distribution Shell-Cap), released on 2020-03-10.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 shell_supports_pipe

Check whether shell supports pipe syntax.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Shell-Cap>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Shell-Cap>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Shell-Cap>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

The C<SHELL> environment variable.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
