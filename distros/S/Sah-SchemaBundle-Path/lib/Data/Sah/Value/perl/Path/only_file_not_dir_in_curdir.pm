package Data::Sah::Value::perl::Path::only_file_not_dir_in_curdir;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-16'; # DATE
our $DIST = 'Sah-SchemaBundle-Path'; # DIST
our $VERSION = '0.031'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Only file in current directory (subdirectories are ignored)',
        description => <<'MARKDOWN',

This default value rule will return filename if there is a plain file in the
current directory (or subdirectories) and nothing else. See
<pm:File::Util::Test>'s `get_dir_only_file`, with the option `ignore_dir`.

MARKDOWN
        args => {
        },
    };
}

sub value {
    my %cargs = @_;

    my $gen_args = $cargs{args} // {};
    my $res = {};

    $res->{modules}{"File::Util::Test"} //= 0.628;

    $res->{expr_value} = join(
        '',
        'File::Util::Test::get_dir_only_file({ignore_dir=>1})',
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Value::perl::Path::only_file_not_dir_in_curdir

=head1 VERSION

This document describes version 0.031 of Data::Sah::Value::perl::Path::only_file_not_dir_in_curdir (from Perl distribution Sah-SchemaBundle-Path), released on 2024-02-16.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|value)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Path>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Path>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Path>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
