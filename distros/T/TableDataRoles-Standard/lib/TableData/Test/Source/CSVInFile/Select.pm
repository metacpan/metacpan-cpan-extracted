package ## no critic: Modules::RequireFilenameMatchesPackage
    # hide from PAUSE
    TableDataRole::Test::Source::CSVInFile::Select;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
with 'TableDataRole::Source::CSVInFile';

around new => sub {
    my $orig = shift;
    my ($class, %args) = @_;

    my $which = delete($args{which}) + 0;

    require File::Basename;
    my $filename = File::Basename::dirname(__FILE__) . "/../../../../../share/examples/eng-ind$which.csv";
    unless (-f $filename) {
        require File::ShareDir;
        $filename = File::ShareDir::dist_file('TableDataRoles-Standard', "examples/eng-ind$which.csv");
    }
    $args{filename} = $filename;
    $orig->($class, %args);
};

package TableData::Test::Source::CSVInFile::Select;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-20'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.014'; # VERSION

with 'TableDataRole::Test::Source::CSVInFile::Select';

1;
# ABSTRACT: Some English words with Indonesian equivalents

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Test::Source::CSVInFile::Select - Some English words with Indonesian equivalents

=head1 VERSION

This document describes version 0.014 of TableDataRole::Test::Source::CSVInFile::Select (from Perl distribution TableDataRoles-Standard), released on 2022-02-20.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
