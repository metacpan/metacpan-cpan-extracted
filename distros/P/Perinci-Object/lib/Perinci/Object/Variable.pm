package Perinci::Object::Variable;

our $DATE = '2021-01-02'; # DATE
our $VERSION = '0.311'; # VERSION

use 5.010;
use strict;
use warnings;

use parent qw(Perinci::Object::Metadata);

sub type { "variable" }

1;
# ABSTRACT: Represent variable metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Object::Variable - Represent variable metadata

=head1 VERSION

This document describes version 0.311 of Perinci::Object::Variable (from Perl distribution Perinci-Object), released on 2020-01-02.

=head1 METHODS

=head2 $rivar->type => str

Will return C<variable>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Object>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Perinci-Object/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
