package Sah::Schema::twitter::username;

our $DATE = '2017-01-22'; # DATE
our $VERSION = '0.001'; # VERSION

our $schema = ["cistr", {
    summary => 'Twitter username',
    match => '\A[0-9A-Za-z_]{1,15}\z',
}, {}];

1;

# ABSTRACT: Twitter username

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::twitter::username - Twitter username

=head1 VERSION

This document describes version 0.001 of Sah::Schema::twitter::username (from Perl distribution Sah-Schemas-Twitter), released on 2017-01-22.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Twitter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Twitter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Twitter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern::Twitter>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
