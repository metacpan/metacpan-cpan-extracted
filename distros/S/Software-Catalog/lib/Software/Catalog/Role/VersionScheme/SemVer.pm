package Software::Catalog::Role::VersionScheme::SemVer;

our $DATE = '2018-09-13'; # DATE
our $VERSION = '1.0.1'; # VERSION

use 5.010001;
use Role::Tiny;

use SemVer;

sub _cmp_version {
    my ($self, $a, $b) = @_;
    SemVer->new($a) <=> SemVer->new($b);
}

1;
# ABSTRACT: Semantic versioning scheme

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog::Role::VersionScheme::SemVer - Semantic versioning scheme

=head1 VERSION

This document describes version 1.0.1 of Software::Catalog::Role::VersionScheme::SemVer (from Perl distribution Software-Catalog), released on 2018-09-13.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Catalog>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Catalog>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Catalog>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://semver.org>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
