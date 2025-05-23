package Data::Sah::Filter::perl::Unix::try_convert_gid_to_unix_group;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-15'; # DATE
our $DIST = 'Sah-SchemaBundle-Unix'; # DIST
our $VERSION = '0.022'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Try to convert GID into Unix groupname, leave as-is if cannot convert',
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; if (\$tmp =~ /\\A[0-9]+\\z/) { my \@gr = getgrgid(\$tmp); \@gr ? \$gr[0] : \$tmp } else { \$tmp } }",
    );

    $res;
}

1;
# ABSTRACT: Try to convert GID into Unix groupname, leave as-is if cannot convert

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Unix::try_convert_gid_to_unix_group - Try to convert GID into Unix groupname, leave as-is if cannot convert

=head1 VERSION

This document describes version 0.022 of Data::Sah::Filter::perl::Unix::try_convert_gid_to_unix_group (from Perl distribution Sah-SchemaBundle-Unix), released on 2024-11-15.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Unix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Unix>.

=head1 SEE ALSO

L<Data::Sah::Filter::perl::Unix::convert_gid_to_unix_group> which dies when
failing to convert. Most of the time you'd want this rule.

L<Data::Sah::Filter::perl::Unix::try_convert_uid_to_unix_user>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Unix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
