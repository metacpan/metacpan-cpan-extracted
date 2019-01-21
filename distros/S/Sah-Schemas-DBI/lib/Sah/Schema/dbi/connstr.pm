package Sah::Schema::dbi::connstr;

our $DATE = '2019-01-20'; # DATE
our $VERSION = '0.001'; # VERSION

our $schema = [str => {
    summary => 'DBI connection string',
    description => <<'_',


_
    match => '\Adbi:\w+:.+\z',
    'x.completion' => ['dbi_connstr'],
}, {}];

1;
# ABSTRACT: DBI connection string

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::dbi::connstr - DBI connection string

=head1 VERSION

This document describes version 0.001 of Sah::Schema::dbi::connstr (from Perl distribution Sah-Schemas-DBI), released on 2019-01-20.

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

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
