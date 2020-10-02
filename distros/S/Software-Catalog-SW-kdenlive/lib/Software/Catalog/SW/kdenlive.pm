package Software::Catalog::SW::kdenlive;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-02'; # DATE
our $DIST = 'Software-Catalog-SW-kdenlive'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use PerlX::Maybe;

use Role::Tiny::With;
with 'Versioning::Scheme::Dotted';
with 'Software::Catalog::Role::Software';

use Software::Catalog::Util qw(extract_from_url);

sub archive_info { [412, "Download URL is not archive"] }

sub available_versions { [501, "Not implemented"] }

sub canon2native_arch_map {
    return +{
        'linux-x86_64' => 'x86_64',
        'win64' => 'win',
    },
}

sub homepage_url { "https://kdenlive.org/" }

sub download_url {
    my ($self, %args) = @_;

    # https://files.kde.org/kdenlive/release/kdenlive-20.08.1-x86_64.appimage
    # https://files.kde.org/kdenlive/release/kdenlive-20.08.1.exe

    [200, "OK", "https://files.kde.org/kdenlive/release/kdenlive-$args{version}" . ($args{arch} =~ /win/ ? ".exe" : "-x86_64.appimage"), {
    }];
}

sub is_dedicated_profile { 0 }

sub latest_version {
    my ($self, %args) = @_;

    extract_from_url(
        url => "https://kdenlive.org/en/download/",
        re  => qr{\Qhttps://files.kde.org/kdenlive/release/kdenlive-\E(\d+(?:\.\d+)*)\Q-x86_64.appimage\E},
    );
}

sub release_note { [501, "Not implemented"] }

1;
# ABSTRACT: KDEnlive

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog::SW::kdenlive - KDEnlive

=head1 VERSION

This document describes version 0.001 of Software::Catalog::SW::kdenlive (from Perl distribution Software-Catalog-SW-kdenlive), released on 2020-10-02.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Catalog-SW-kdenlive>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Catalog-SW-kdenlive>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Catalog-SW-kdenlive>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
