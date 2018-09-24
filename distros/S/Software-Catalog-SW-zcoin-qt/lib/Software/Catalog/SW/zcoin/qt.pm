package Software::Catalog::SW::zcoin::qt;

our $DATE = '2018-09-21'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use PerlX::Maybe;

use Role::Tiny::With;
with 'Software::Catalog::Role::Software';
#with 'Software::Catalog::Role::VersionScheme::SemVer';

use Software::Catalog::Util qw(extract_from_url);

sub meta {
    return {
        homepage_url => "http://zcoin.io/",
    };
}

sub get_latest_version {
    my ($self, %args) = @_;

    extract_from_url(
        url => "https://github.com/zcoinofficial/zcoin/releases",
        re  => qr!/zcoinofficial/zcoin/releases/download/\d+(?:\.\d+)+/zcoin(?:-qt)?-(\d+(?:\.\d+)+)-linux64\.!,
    );
}

sub canon2native_arch_map {
    return +{
        'linux-x86_64' => 'linux64',
        'win64' => 'win64',
    },
}

# version
# arch
sub get_download_url {
    my ($self, %args) = @_;

    my $version = $args{version};
    if (!$version) {
        my $verres = $self->get_latest_version(maybe arch => $args{arch});
        return [500, "Can't get latest version: $verres->[0] - $verres->[1]"]
            unless $verres->[0] == 200;
        $version = $verres->[2];
    }

    my $filename;
    if ($args{arch} =~ /linux/) {
        $filename = "zcoin-$version-" . $self->_canon2native_arch($args{arch}) . ".tar.gz";
    } else {
        $filename = "zcoin-qt-$version-" . $self->_canon2native_arch($args{arch}) . ".exe";
    }

    [200, "OK",
     join(
         "",
         "https://github.com/zcoinofficial/zcoin/releases/download/$version/$filename",
     ), {
         'func.filename' => $filename,
     }];
}

sub get_programs {
    my ($self, %args) = @_;
    [200, "OK", [
        {name=>"zcoin-cli", path=>"/bin"},
        {name=>"zcoin-qt", path=>"/bin"},
        {name=>"zcoind", path=>"/bin"},
    ]];
}

1;
# ABSTRACT: Zcoin desktop GUI client

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog::SW::zcoin::qt - Zcoin desktop GUI client

=head1 VERSION

This document describes version 0.001 of Software::Catalog::SW::zcoin::qt (from Perl distribution Software-Catalog-SW-zcoin-qt), released on 2018-09-21.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Catalog-SW-zcoin-qt>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Catalog-SW-zcoin-qt>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Catalog-SW-zcoin-qt>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
