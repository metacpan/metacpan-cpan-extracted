package Data::Sah::Filter::perl::Path::strip_slashes_when_on_unix;

# AUTHOR
our $DATE = '2020-02-11'; # DATE
our $DIST = 'Sah-Schemas-Path'; # DIST
our $VERSION = '0.013'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perl::osnames;

sub meta {
    +{
        v => 1,
        target_type => 'str',
        summary => 'Strip extra and trailing slash from a string',
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; if (\$^O =~ qr/$Perl::osnames::RE_OS_IS_UNIX/) { \$tmp =~ s!/{2,}!/!g; \$tmp =~ s!/\\z!!g unless \$tmp =~ m!\\A/\\z!; } \$tmp }",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Path::strip_slashes_when_on_unix

=head1 VERSION

This document describes version 0.013 of Data::Sah::Filter::perl::Path::strip_slashes_when_on_unix (from Perl distribution Sah-Schemas-Path), released on 2020-02-11.

=head1 DESCRIPTION

This filter rule is exactly like
L<Path::strip_slashes|Data::Sah::Filter::perl::Path::strip_slashes> rule, except
that the stripping is only done when running on Unix platforms.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Path>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Path>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Path>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
