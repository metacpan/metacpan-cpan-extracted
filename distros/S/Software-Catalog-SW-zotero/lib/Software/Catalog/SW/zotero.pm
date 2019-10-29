package Software::Catalog::SW::zotero;

our $DATE = '2019-10-26'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

use PerlX::Maybe;
use Software::Catalog::Util qw(extract_from_url);

use Role::Tiny::With;
with 'Versioning::Scheme::Dotted';
with 'Software::Catalog::Role::Software';

sub homepage_url { "https://www.zotero.org/" }

sub latest_version {
    my ($self, %args) = @_;

    my $carch = $args{arch};
    return [400, "Please specify arch"] unless $carch;

    my $narch = $self->_canon2native_arch($carch);

    extract_from_url(
        url => "https://www.zotero.org/download/",
        re  => qr!"standaloneVersions".+"\Q$narch\E":"([^"]+)"!,
    );
}

sub canon2native_arch_map {
    return +{
        # XXX mac
        'linux-x86' => 'linux-i686',
        'linux-x86_64' => 'linux-x86_64',
        'win32' => 'win32',
    },
}

sub download_url {
    my ($self, %args) = @_;

    my $version = $args{version};
    if (!$version) {
        my $verres = $self->latest_version(arch => $args{arch});
        return [500, "Can't get latest version: $verres->[0] - $verres->[1]"]
            unless $verres->[0] == 200;
        $version = $verres->[2];
    }

    my $narch = $self->_canon2native_arch($args{arch});

    [200, "OK",
     join(
         "",
         "https://www.zotero.org/download/client/dl?channel=release&platform=$narch&version=$version",
     ), {
         'func.version' => $version,
     }];
}

sub archive_info {
    my ($self, %args) = @_;
    [200, "OK", {
        programs => [
            {name=>"zotero", path=>"/"},
        ],
    }];
}

1;
# ABSTRACT: Zotero

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog::SW::zotero - Zotero

=head1 VERSION

This document describes version 0.005 of Software::Catalog::SW::zotero (from Perl distribution Software-Catalog-SW-zotero), released on 2019-10-26.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Catalog-SW-zotero>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Catalog-SW-zotero>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Catalog-SW-zotero>

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
