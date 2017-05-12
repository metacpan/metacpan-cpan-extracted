package Perinci::Sub::ArgEntity::software_license;

our $DATE = '2015-09-06'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Module ();

sub complete_arg_val {
    my %args = @_;

    Complete::Module::complete_module(
        word      => $args{word},
        ci        => $args{ci},
        ns_prefix => 'Software::License',
    );
}

1;
# ABSTRACT: Data and code related to function arguments of entity type 'software_license'

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::ArgEntity::software_license - Data and code related to function arguments of entity type 'software_license'

=head1 VERSION

This document describes version 0.02 of Perinci::Sub::ArgEntity::software_license (from Perl distribution Perinci-Sub-ArgEntity-software_license), released on 2015-09-06.

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Perinci::Sub::ArgEntity>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-ArgEntity-software_license>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-ArgEntity-software_license>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-ArgEntity-software_license>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
