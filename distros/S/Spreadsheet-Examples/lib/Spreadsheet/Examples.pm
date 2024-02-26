## no critic: TestingAndDebugging::RequireUseStrict
package Spreadsheet::Examples;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-17'; # DATE
our $DIST = 'Spreadsheet-Examples'; # DIST
our $VERSION = '0.004'; # VERSION

1;
# ABSTRACT: A collection of various examples of spreadsheet files

__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::Examples - A collection of various examples of spreadsheet files

=head1 VERSION

This document describes version 0.004 of Spreadsheet::Examples (from Perl distribution Spreadsheet-Examples), released on 2023-11-17.

=head1 DESCRIPTION

This distribution contains, in its share directory, a collection of various
spreadsheet files, usually for testing or benchmarking purposes:

=over

=item * 10sheet-10row-10col

A workbook containing 10 sheets, each sheet containing 10 rows and 10 columns.
The cells are numbers. Minimum formatting.

=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/Spreadsheet-Examples-0.004/share/10sheet%2D10row%2D10col%2Eods">share/10sheet-10row-10col.ods</a><br />

=end html


=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/Spreadsheet-Examples-0.004/share/10sheet%2D10row%2D10col%2Exlsx">share/10sheet-10row-10col.xlsx</a><br />

=end html


=item * 10sheet-1000row-10col

A workbook containing 10 sheets, each sheet containing 1000 rows and 10 columns.
The cells are numbers. Minimum formatting.

=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/Spreadsheet-Examples-0.004/share/10sheet%2D1000row%2D10col%2Eods">share/10sheet-1000row-10col.ods</a><br />

=end html


=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/Spreadsheet-Examples-0.004/share/10sheet%2D1000row%2D10col%2Exlsx">share/10sheet-1000row-10col.xlsx</a><br />

=end html


=item * 10sheet-empty

Empty 10-sheet workbook.

=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/Spreadsheet-Examples-0.004/share/10sheet%2Dempty%2Eods">share/10sheet-empty.ods</a><br />

=end html


=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/Spreadsheet-Examples-0.004/share/10sheet%2Dempty%2Exlsx">share/10sheet-empty.xlsx</a><br />

=end html


=item * empty

Empty single-sheet workbook.

=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/Spreadsheet-Examples-0.004/share/empty%2Eods">share/empty.ods</a><br />

=end html


=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/Spreadsheet-Examples-0.004/share/empty%2Exlsx">share/empty.xlsx</a><br />

=end html


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Spreadsheet-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Spreadsheet-Examples>.

=head1 SEE ALSO

L<Acme::CPANModules::Spreadsheet> for spreadsheet-related modules.

Other C<*::Examples> modules e.g. L<TextDoc::Examples>. Also see
L<Acme::CPANModules::TextDoc>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Spreadsheet-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
