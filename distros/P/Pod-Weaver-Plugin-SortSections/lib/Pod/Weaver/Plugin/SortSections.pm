package Pod::Weaver::Plugin::SortSections;

our $DATE = '2016-10-14'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use Moose;

with 'Pod::Weaver::Role::Finalizer';
with 'Pod::Weaver::Role::SortSections';

use namespace::autoclean;

has section => (
    is => 'rw',
);

sub mvp_multivalue_args { qw(section) }

sub finalize_document {
    my ($self, $document, $input) = @_;

    my $spec = [];
    for my $section (@{ $self->section // [] }) {
        if ($section =~ m#\A/.*/\z#) {
            $section = qr/$section/;
        }
        push @$spec, $section;
    }

    $self->sort_sections($document, $spec);
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Sort POD sections

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::SortSections - Sort POD sections

=head1 VERSION

This document describes version 0.001 of Pod::Weaver::Plugin::SortSections (from Perl distribution Pod-Weaver-Plugin-SortSections), released on 2016-10-14.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-SortSections]
 section=NAME
 section=VERSION
 section=SYNOPSIS
 section=DESCRIPTION
 ; put everything else here
 section=/./
 section=FUNCTIONS
 section=EXPORTS
 section=ATTRIBUTES
 section=METHODS
 section=ENVIRONMENT
 section=FILES
 section=HOMEPAGE
 section=SOURCE
 section=BUGS
 section=SEE ALSO
 section=AUTHOR
 section=COPYRIGHT AND LICENSE

=head1 DESCRIPTION

This plugin lets you sort POD sections.

=for Pod::Coverage ^(finalize_document|mvp_multivalue_args)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-SortSections>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-SortSections>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-SortSections>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Pod::Weaver::Role::SortSections>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
