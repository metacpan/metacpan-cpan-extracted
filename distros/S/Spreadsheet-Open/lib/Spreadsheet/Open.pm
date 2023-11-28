package Spreadsheet::Open;

use strict;
use warnings;
use Log::ger;

use File::Which;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-09'; # DATE
our $DIST = 'Spreadsheet-Open'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(open_spreadsheet);

my @libreoffice_versions = qw(
                                 7.5 7.4 7.3 7.2 7.1 7.0
                                 6.4 6.3 6.2 6.1
                         );

my @known_commands = (
    # [os, program, params]
    ['', 'libreoffice', ['--calc']],
    (map { ['', "libreoffice$_", ['--calc']] } @libreoffice_versions),
);

sub open_spreadsheet {
    my $path = shift;

    for my $e (@known_commands) {
        next if $e->[0] && $^O ne $e->[0];
        my $which = which($e->[1]);
        next unless $which;
        log_trace "Opening file %s in spreadsheet program %s ...",
            $path, $which;
        return system($which, @{ $e->[2] }, $path);
    }

    log_trace "Falling back to using Desktop::Open ...";
    require Desktop::Open;
    return Desktop::Open::open_desktop($path);
}

1;
# ABSTRACT: Open spreadsheet in a spreadsheet program

__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::Open - Open spreadsheet in a spreadsheet program

=head1 VERSION

This document describes version 0.002 of Spreadsheet::Open (from Perl distribution Spreadsheet-Open), released on 2023-11-09.

=head1 SYNOPSIS

 use Spreadsheet::Open qw(open_spreadsheet);

 my $ok = open_spreadsheet("/path/to/my.xlsx");

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 open_spreadsheet

Usage:

 $status = open_spreadsheet($path);

Try a few programs to open a spreadsheet. Currently, in order, LibreOffice (in
decreasing order of version), then failing that, L<Desktop::Open>

C<$ok> is what returned by C<system()> or Desktop::Open.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Spreadsheet-Open>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Spreadsheet-Open>.

=head1 SEE ALSO

C<Browser::Open> to open a URL in a browser.

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

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Spreadsheet-Open>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
