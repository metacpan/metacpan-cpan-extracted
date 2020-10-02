package Software::Catalog::SW::phpmyadmin;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-02'; # DATE
our $DIST = 'Software-Catalog-SW-phpmyadmin'; # DIST
our $VERSION = '0.004'; # VERSION

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
        programs => [],
    }];
}

sub available_versions { [501, "Not implemented"] }

sub canon2native_arch_map {
}

sub download_url {
    my ($self, %args) = @_;

    my $version = $args{version} // $self->get_latest_version->[2];

    [200,
     "OK",
     "https://files.phpmyadmin.net/phpMyAdmin/$version/phpMyAdmin-$version-all-languages.zip",
     {'func.arch' => 'src'}];
}

sub homepage_url { "https://www.phpmyadmin.net/" }

sub is_dedicated_profile { 0 }

sub latest_version {
    my ($self, %args) = @_;

    extract_from_url(
        url => "https://www.phpmyadmin.net/",
        re  => qr! <a [^>]*href="https://files.phpmyadmin.net/phpMyAdmin/(\d+(?:\.\d+)*)/!,
    );
}

sub release_note { [501, "Not implemented"] }

1;
# ABSTRACT: phpMyAdmin

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog::SW::phpmyadmin - phpMyAdmin

=head1 VERSION

This document describes version 0.004 of Software::Catalog::SW::phpmyadmin (from Perl distribution Software-Catalog-SW-phpmyadmin), released on 2020-10-02.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Catalog-SW-phpmyadmin>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Catalog-SW-phpmyadmin>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Catalog-SW-phpmyadmin>

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
