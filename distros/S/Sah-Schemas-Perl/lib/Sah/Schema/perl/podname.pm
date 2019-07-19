package Sah::Schema::perl::podname;

our $DATE = '2019-07-05'; # DATE
our $VERSION = '0.020'; # VERSION

our $schema = ['str' => {
    summary => 'Perl POD name',
    description => <<'_',

Perl POD name, e.g. `Config`, `Some::Other::POD`.

Basically the same as `perl::modname`, but with a different completion.

_
    match => '\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\z',

    'x.perl.coerce_rules' => [
        'str_normalize_perl_modname',
    ],

    # provide a default completion which is from list of installed perl PODs
    'x.completion' => 'perl_modname',

}, {}];

1;
# ABSTRACT: Perl POD name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::podname - Perl POD name

=head1 VERSION

This document describes version 0.020 of Sah::Schema::perl::podname (from Perl distribution Sah-Schemas-Perl), released on 2019-07-05.

=head1 DESCRIPTION

Perl POD name, e.g. C<Config>, C<Some::Other::POD>.

Basically the same as C<perl::modname>, but with a different completion.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
