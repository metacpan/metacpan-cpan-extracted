package Perl::Examples::Accessors::ClassXSAccessor;

our $DATE = '2017-10-15'; # DATE
our $VERSION = '0.131'; # VERSION

use Class::XSAccessor {
    constructor => 'new',
    accessors => [qw/attr1/],
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Examples::Accessors::ClassXSAccessor

=head1 VERSION

This document describes version 0.131 of Perl::Examples::Accessors::ClassXSAccessor (from Perl distribution Perl-Examples-Accessors), released on 2017-10-15.

=head1 DESCRIPTION

This is an example of a class which uses L<Class::XSAccessor>. It is hash-based.

=head1 ATTRIBUTES

=head2 attr1

=head1 METHODS

=head2 new(%attrs) => obj

Constructor. Accept a I<hash> to set attributes.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perl-Examples-Accessors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perl-Examples-Accessors>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Examples-Accessors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
