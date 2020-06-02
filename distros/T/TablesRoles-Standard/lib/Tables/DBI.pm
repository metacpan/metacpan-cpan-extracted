package Tables::DBI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-01'; # DATE
our $DIST = 'TablesRoles-Standard'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use Role::Tiny::With;
with 'TablesRole::Source::DBI';

1;
# ABSTRACT: Get table data from DBI

__END__

=pod

=encoding UTF-8

=head1 NAME

Tables::DBI - Get table data from DBI

=head1 VERSION

This document describes version 0.003 of Tables::DBI (from Perl distribution TablesRoles-Standard), released on 2020-06-01.

=head1 SYNOPSIS

 use Tables::DBI;

 my $table = Tables::DBI->new(
     sth           => $dbh->prepare("SELECT * FROM mytable"),
     row_count_sth => $dbh->prepare("SELECT COUNT(*) FROM table"),
 );

 # or
 my $table = Tables::DBI->new(
     dsn           => "DBI:mysql:database=mydb",
     user          => "...",
     password      => "...",
     table         => "mytable",
 );

=head1 DESCRIPTION

This is a Tables:: module to get list of words from a L<DBI> query.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TablesRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TablesRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TablesRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBI>

L<Tables>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
