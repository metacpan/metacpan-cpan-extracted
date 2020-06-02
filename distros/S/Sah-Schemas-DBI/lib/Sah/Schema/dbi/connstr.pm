package Sah::Schema::dbi::connstr;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-02'; # DATE
our $DIST = 'Sah-Schemas-DBI'; # DIST
our $VERSION = '0.002'; # VERSION

our $schema = [str => {
    summary => 'DBI connection string',
    description => <<'_',


_
    match => '\Adbi:\w+:.+\z',
    'x.completion' => ['dbi_connstr'],
    examples => [
        {data=>'', valid=>0},
        {data=>'dbi:SQLite:dbname=foo', valid=>1},
        {data=>'DBI:SQLite:dbname=foo', valid=>0},
        {data=>'dbi:Foo', valid=>0},
        {data=>'dbi:Foo:bar=baz', valid=>1},
    ],
}, {}];

1;
# ABSTRACT: DBI connection string

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::dbi::connstr - DBI connection string

=head1 VERSION

This document describes version 0.002 of Sah::Schema::dbi::connstr (from Perl distribution Sah-Schemas-DBI), released on 2020-03-02.

=head1 SYNOPSIS

Sample data:

 ""  # INVALID

 "dbi:SQLite:dbname=foo"  # valid

 "DBI:SQLite:dbname=foo"  # INVALID

 "dbi:Foo"  # INVALID

 "dbi:Foo:bar=baz"  # valid

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-DBI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-DBI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-DBI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
