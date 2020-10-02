package Software::Catalog::SW::filezilla;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-02'; # DATE
our $DIST = 'Software-Catalog-SW-filezilla'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;
with 'Versioning::Scheme::Dotted';
with 'Software::Catalog::Role::Software';

use Software::Catalog::Util qw(extract_from_url);

sub archive_info {
    my ($self, %args) = @_;
    [200, "OK", {
        programs => [
            {name=>"filezilla", path=>"/bin"},
            # XXX fzputtygen
            # XXX fzsftp
            # XXX fzstorj
        ],
    }];
}

sub available_versions { [501, "Not implemented"] }

sub canon2native_arch_map {
    return +{
        'linux-x86_64' => 'linux',
        'win32' => 'win32',
        'win64' => 'win64',
    },
}

sub download_url {
    my ($self, %args) = @_;

    # XXX version, language
    extract_from_url(
        url => "https://filezilla-project.org/download.php?platform=" . $self->_canon2native_arch($args{arch}),
        re  => qr! <a id="quickdownloadbuttonlink" href="([^"]+?)"!,
    );
}

sub homepage_url { "https://filezilla-project.org" }

sub is_dedicated_profile { 0 }

sub latest_version {
    my ($self, %args) = @_;

    extract_from_url(
        url => "https://filezilla-project.org/download.php?platform=" . $self->_canon2native_arch($args{arch}),
        re  => qr! <a id="quickdownloadbuttonlink" href="[^"]+/FileZilla_(\d+(?:\.\d+)*)!,
    );
}

sub release_note { [501, "Not implemented"] }

1;
# ABSTRACT: FileZilla

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog::SW::filezilla - FileZilla

=head1 VERSION

This document describes version 0.003 of Software::Catalog::SW::filezilla (from Perl distribution Software-Catalog-SW-filezilla), released on 2020-10-02.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Catalog-SW-filezilla>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Catalog-SW-filezilla>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Catalog-SW-filezilla>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
