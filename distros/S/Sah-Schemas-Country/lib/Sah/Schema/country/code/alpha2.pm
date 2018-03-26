package Sah::Schema::country::code::alpha2;

our $DATE = '2018-03-25'; # DATE
our $VERSION = '0.001'; # VERSION

use Locale::Codes::Country_Codes ();

my $codes = [sort (
    keys(%{ $Locale::Codes::Data{'country'}{'code2id'}{'alpha-2'} }),
)];
die "Can't extract country codes from Locale::Codes::Language_Codes"
    unless @$codes;

our $schema = [str => {
    summary => 'Country code (alpha-2)',
    description => <<'_',

Accept only current (not retired) codes. Only alpha-2 codes are accepted.

_
    match => '\A[a-z]{2}\z',
    in => $codes,
    'x.perl.coerce_rules' => ['str_tolower'],
}, {}];

1;
# ABSTRACT: Country code (alpha-2)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::country::code::alpha2 - Country code (alpha-2)

=head1 VERSION

This document describes version 0.001 of Sah::Schema::country::code::alpha2 (from Perl distribution Sah-Schemas-Country), released on 2018-03-25.

=head1 DESCRIPTION

Accept only current (not retired) codes. Only alpha-2 codes are accepted.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Country>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Country>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Country>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::country::code::alpha3>

L<Sah::Schema::country::code>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
