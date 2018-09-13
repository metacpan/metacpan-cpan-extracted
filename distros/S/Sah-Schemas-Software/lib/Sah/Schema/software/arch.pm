package Sah::Schema::software::arch;

our $DATE = '2018-09-13'; # DATE
our $VERSION = '0.001'; # VERSION

# XXX currently very simple, will be improved upon later

our $schema = ["str", {
    summary => 'Software architecture name',
    in => [qw/
                 linux-x86
                 linux-x86_64
                 win32
                 win64
             /],
}, {}];

1;

# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::software::arch

=head1 VERSION

This document describes version 0.001 of Sah::Schema::software::arch (from Perl distribution Sah-Schemas-Software), released on 2018-09-13.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Software>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Software>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Software>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
