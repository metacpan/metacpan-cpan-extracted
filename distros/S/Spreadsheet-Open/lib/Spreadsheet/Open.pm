package Spreadsheet::Open;

our $DATE = '2019-05-28'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use Log::ger;

use File::Which;

use Exporter qw(import);
our @EXPORT_OK = qw(open_spreadsheet);

my @known_commands = (
    # [os, program, params]
    ['', 'libreoffice', ['--calc']],
    ['', 'libreoffice6.2', ['--calc']],
    ['', 'libreoffice6.1', ['--calc']],
    ['', 'xdg-open', []],
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
}

1;
# ABSTRACT: Open spreadsheet in a spreadsheet program

__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::Open - Open spreadsheet in a spreadsheet program

=head1 VERSION

This document describes version 0.001 of Spreadsheet::Open (from Perl distribution Spreadsheet-Open), released on 2019-05-28.

=head1 SYNOPSIS

 use Spreadsheet::Open qw(open_spreadsheet);

 my $ok = open_spreadsheet("/path/to/my.xlsx");

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 open_spreadsheet

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Spreadsheet-Open>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Spreadsheet-Open>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Spreadsheet-Open>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

C<Browser::Open> to open a URL in a browser.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
