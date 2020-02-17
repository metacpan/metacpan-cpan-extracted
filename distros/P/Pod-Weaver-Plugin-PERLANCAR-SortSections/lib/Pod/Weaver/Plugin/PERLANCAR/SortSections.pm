package Pod::Weaver::Plugin::PERLANCAR::SortSections;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-16'; # DATE
our $DIST = 'Pod-Weaver-Plugin-PERLANCAR-SortSections'; # DIST
our $VERSION = '0.081'; # VERSION

use 5.010001;
use Moose;

with 'Pod::Weaver::Role::Finalizer';
with 'Pod::Weaver::Role::SortSections';

use Sort::Sub::pod_sections_ala_perlancar;
use namespace::autoclean;

sub finalize_document {
    my ($self, $document, $input) = @_;

    $self->sort_sections(
        $document,
        $Sort::Sub::pod_sections_ala_perlancar::SORT_SPEC,
    );
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Sort POD sections like PERLANCAR

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::PERLANCAR::SortSections - Sort POD sections like PERLANCAR

=head1 VERSION

This document describes version 0.081 of Pod::Weaver::Plugin::PERLANCAR::SortSections (from Perl distribution Pod-Weaver-Plugin-PERLANCAR-SortSections), released on 2020-02-16.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-PERLANCAR::SortSections]

=for Pod::Coverage ^(finalize_document)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-PERLANCAR-SortSections>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-PERLANCAR-SortSections>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-PERLANCAR-SortSections>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sort::Sub::pod_sections_ala_perlancar>, the backend

L<Pod::Weaver::Plugin::SortSections>, the generic/configurable version

L<Pod::Weaver::Role::SortSections>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
