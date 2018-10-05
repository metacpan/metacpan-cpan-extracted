package Software::Catalog;

our $DATE = '2018-10-05'; # DATE
our $VERSION = '1.0.3'; # VERSION

1;
# ABSTRACT: Software catalog

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog - Software catalog

=head1 VERSION

This document describes version 1.0.3 of Software::Catalog (from Perl distribution Software-Catalog), released on 2018-10-05.

=head1 SYNOPSIS

=head1 DESCRIPTION

B<STATUS:> experimental.

L<Software::Catalog> is a specification for C<Software::Catalog::SW::*> modules.
Each C<Software::Catalog::SW::*> module describes a software (e.g.
L<firefox|Software::Catalog::SW::firefox>), including:

=over

=item * how to find out the latest version of the software

=item * where to download it

=item * possibly other information in the future

=back

=head1 FAQ

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
