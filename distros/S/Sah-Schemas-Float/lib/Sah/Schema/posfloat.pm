package Sah::Schema::posfloat;

our $DATE = '2019-04-08'; # DATE
our $VERSION = '0.003'; # VERSION

our $schema = [float => {
    summary   => 'Positive float',
    xmin      => 0,
    description => <<'_',

_
}, {}];

1;
# ABSTRACT: Positive float

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::posfloat - Positive float

=head1 VERSION

This document describes version 0.003 of Sah::Schema::posfloat (from Perl distribution Sah-Schemas-Float), released on 2019-04-08.

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Float>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Float>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Float>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
