package Data::Sah::Filter::perl::Unix::try_convert_uid_to_unix_user;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-24'; # DATE
our $DIST = 'Sah-Schemas-Unix'; # DIST
our $VERSION = '0.019'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Try to convert UID into Unix username, leave as-is if cannot convert',
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; if (\$tmp =~ /\\A[0-9]+\\z/) { my \@pw = getpwuid(\$tmp); \@pw ? \$pw[0] : \$tmp } else { \$tmp } }",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Unix::try_convert_uid_to_unix_user

=head1 VERSION

This document describes version 0.019 of Data::Sah::Filter::perl::Unix::try_convert_uid_to_unix_user (from Perl distribution Sah-Schemas-Unix), released on 2022-07-24.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Unix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Unix>.

=head1 SEE ALSO

L<Data::Sah::Filter::perl::Unix::convert_uid_to_unix_user> which dies when
failing to convert. Most of the time you'd want this rule.

L<Data::Sah::Filter::perl::Unix::try_convert_gid_to_unix_group>

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

This software is copyright (c) 2022, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Unix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
