package TableData::Munge::Filter;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-14'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.025'; # VERSION

with 'TableDataRole::Munge::Filter';

our %SPEC;

$SPEC{new} = {
    v => 1.1,
    is_meth => 1,
    is_func => 0,
    args => {
        tabledata => {
            schema => 'any*', # TMP
            req => 1,
        },
        filter => {
            schema => ['any*', of=>['str*', 'code*']],
        },
        filter_hashref => {
            schema => ['any*', of=>['str*', 'code*']],
        },
    },
    args_rels => {
        req_one => [qw/filter filter_hashref/],
    },
};

1;
# ABSTRACT: Filter rows of another tabledata

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::Munge::Filter - Filter rows of another tabledata

=head1 VERSION

This document describes version 0.025 of TableData::Munge::Filter (from Perl distribution TableDataRoles-Standard), released on 2024-05-14.

=head1 SYNOPSIS

 use TableData::Munge::Filter;

 my $td = TableData::Munge::Filter->new(
     tabledata => 'CPAN::Release::Static::2021',
     filter_hashref => sub { my $row=shift; $_->{author} eq 'PERLANCAR' },
 );

=head1 DESCRIPTION

This is a TableData:: module that lets you filter rows from another tabledata.
See L<TableDataRole::Munge::Filter> for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 SEE ALSO

L<TableData>

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

This software is copyright (c) 2024, 2023, 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
