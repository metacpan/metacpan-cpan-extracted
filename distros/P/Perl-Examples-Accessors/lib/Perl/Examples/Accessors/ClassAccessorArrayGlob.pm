package Perl::Examples::Accessors::ClassAccessorArrayGlob;

our $DATE = '2017-09-01'; # DATE
our $VERSION = '0.130'; # VERSION

use Class::Accessor::Array::Glob {
    constructor => 'new',
    accessors => {
        attr1 => 0,
    },
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Examples::Accessors::ClassAccessorArrayGlob

=head1 VERSION

This document describes version 0.130 of Perl::Examples::Accessors::ClassAccessorArrayGlob (from Perl distribution Perl-Examples-Accessors), released on 2017-09-01.

=head1 DESCRIPTION

This is an example of a class which uses L<Class::Accessor::Array::Glob>. It is
array-based.

=head1 ATTRIBUTES

=head2 attr1

=head1 METHODS

=head2 new() => obj

Constructor. Note that it does not accept any arguments to set initial attribute
value.

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
