package Sah::Schema::cryptocurrency::code_or_name;

our $DATE = '2018-04-06'; # DATE
our $VERSION = '0.005'; # VERSION

our $schema = [str => {
    summary => 'Cryptocurrency code or name',
    'x.completion' => 'cryptocurrency_code_or_name',
}, {}];

1;
# ABSTRACT: Cryptocurrency code or name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cryptocurrency::code_or_name - Cryptocurrency code or name

=head1 VERSION

This document describes version 0.005 of Sah::Schema::cryptocurrency::code_or_name (from Perl distribution Sah-Schemas-CryptoCurrency), released on 2018-04-06.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-CryptoCurrency>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-CryptoCurrency>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-CryptoCurrency>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
