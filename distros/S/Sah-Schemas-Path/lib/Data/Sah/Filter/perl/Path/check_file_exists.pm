package Data::Sah::Filter::perl::Path::check_file_exists;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-08'; # DATE
our $DIST = 'Sah-Schemas-Path'; # DIST
our $VERSION = '0.030'; # VERSION

sub meta {
    +{
        v => 1,
        target_type => 'str',
        summary => 'Check that file exists and is a regular file (using -f)',
        might_fail => 1,
        description => <<'MARKDOWN',

This means that symlink is allowed if it points to a regular file. The check fails if
file does not exist or is a non-regular file type (e.g. directory, Unix socket, etc).

MARKDOWN
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; -f \$tmp ? [undef,\$tmp] : [qq('\$tmp' does not exist or is not a regular file), \$tmp] }",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Path::check_file_exists

=head1 VERSION

This document describes version 0.030 of Data::Sah::Filter::perl::Path::check_file_exists (from Perl distribution Sah-Schemas-Path), released on 2024-01-08.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Path>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Path>.

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

This software is copyright (c) 2024, 2023, 2020, 2019, 2018, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Path>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
