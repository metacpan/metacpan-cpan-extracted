package Software::Catalog::Role::Software;

our $DATE = '2018-10-18'; # DATE
our $VERSION = '1.0.4'; # VERSION

use Role::Tiny;

requires 'canon2native_arch_map';
requires 'get_latest_version';
requires 'get_download_url';
requires 'get_archive_info';

# versioning scheme
requires qw(is_valid_version cmp_version);

sub _canon2native_arch {
    my ($self, $arch) = @_;

    my $map = $self->canon2native_arch_map;
    my $rmap = {reverse %$map};
    if ($map->{$arch}) {
        return $map->{$arch};
    } elsif ($rmap->{$arch}) {
        return $arch;
    } else {
        die "Unknown arch '$arch'";
    }
}

sub _native2canon_arch {
    my ($self, $arch) = @_;

    my $map = $self->canon2native_arch_map;
    my $rmap = {reverse %$map};
    if ($rmap->{$arch}) {
        return $rmap->{$arch};
    } elsif ($map->{$arch}) {
        return $arch;
    } else {
        die "Unknown arch '$arch'";
    }
}

1;
# ABSTRACT: Role for software

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog::Role::Software - Role for software

=head1 VERSION

This document describes version 1.0.4 of Software::Catalog::Role::Software (from Perl distribution Software-Catalog), released on 2018-10-18.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Catalog>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Catalog>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Catalog>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
