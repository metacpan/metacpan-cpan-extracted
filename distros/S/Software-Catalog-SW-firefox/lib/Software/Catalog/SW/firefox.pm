package Software::Catalog::SW::firefox;

our $DATE = '2019-10-26'; # DATE
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;
with 'Versioning::Scheme::Dotted';
with 'Software::Catalog::Role::Software';

use Software::Catalog::Util qw(extract_from_url);

sub meta {
    return {
        homepage_url => "https://mozilla.org/firefox",
    };
}

sub latest_version {
    my ($self, %args) = @_;

    extract_from_url(
        url => "https://www.mozilla.org/en-US/firefox/all/",
        re  => qr/ data-latest-firefox="([^"]+)"/,
    );
}

sub canon2native_arch_map {
    return +{
        'linux-x86' => 'linux',
        'linux-x86_64' => 'linux64',
        'win32' => 'win',
        'win64' => 'win64',
    },
}

sub download_url {
    my ($self, %args) = @_;

    # XXX version, language
    [200, "OK",
     join(
         "",
         "https://download.mozilla.org/?product=firefox-latest-ssl&amp;os=", $self->_canon2native_arch($args{arch}),
         "&amp;lang=", "en-US",
     )];

    # XXX if source=1, but we need to retrieve (and preferably cache too) latest
    # version, if version is not specified

    # "https://archive.mozilla.org/pub/firefox/releases/62.0/source/"
}

sub archive_info {
    my ($self, %args) = @_;
    [200, "OK", {
        programs => [
            {name=>"firefox", path=>"/"},
        ],
    }];
}

sub dedicated_profile { 1 }

1;
# ABSTRACT: Firefox

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog::SW::firefox - Firefox

=head1 VERSION

This document describes version 0.006 of Software::Catalog::SW::firefox (from Perl distribution Software-Catalog-SW-firefox), released on 2019-10-26.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Catalog-SW-firefox>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Catalog-SW-firefox>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Catalog-SW-firefox>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
