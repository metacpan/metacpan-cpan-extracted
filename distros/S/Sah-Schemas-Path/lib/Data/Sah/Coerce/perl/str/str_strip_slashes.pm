package Data::Sah::Coerce::perl::str::str_strip_slashes;

our $DATE = '2019-07-25'; # DATE
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "1";
    $res->{expr_coerce} = join(
        "",
        "do { my \$tmp = $dt; \$tmp =~ s!/{2,}!/!g; \$tmp =~ s!/\\z!!g unless \$tmp =~ m!\\A/\\z!; \$tmp }",
    );

    $res;
}

1;
# ABSTRACT: Strip extra and trailing slash from a string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::str::str_strip_slashes - Strip extra and trailing slash from a string

=head1 VERSION

This document describes version 0.008 of Data::Sah::Coerce::perl::str::str_strip_slashes (from Perl distribution Sah-Schemas-Path), released on 2019-07-25.

=head1 DESCRIPTION

Extra slashes: This coercion rule removes extra slashes ("/foo//bar" becomes
"/foo/bar").

Trailing slash: Functions might not expect a filename or dirname to have a
trailing slash (e.g. C<-d>, C<opendir()>, etc will not work if we add slash to a
directory name), but shell tab completion usually adds a trailing slash. So this
coercion rule provides the convenience of stripping the trailing slash for the
functions.

=for Pod::Coverage ^(meta|coerce)$

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

This software is copyright (c) 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
