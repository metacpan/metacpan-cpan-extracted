package Sah::Schema::country::code;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-11-29'; # DATE
our $DIST = 'Sah-Schemas-Country'; # DIST
our $VERSION = '0.003'; # VERSION

use Locale::Codes::Country_Codes ();

my $codes = [sort (
    keys(%{ $Locale::Codes::Data{'country'}{'code2id'}{'alpha-2'} }),
    keys(%{ $Locale::Codes::Data{'country'}{'code2id'}{'alpha-3'} }),
)];
die "Can't extract country codes from Locale::Codes::Country_Codes"
    unless @$codes;

our $schema = [str => {
    summary => 'Country code (alpha-2 or alpha-3)',
    description => <<'_',

Accept only current (not retired) codes. Alpha-2 or alpha-3 codes are accepted.

Code will be converted to lowercase.

_
    match => '\A[a-z]{2,3}\z',
    in => $codes,
    'x.perl.coerce_rules' => ['From_str::to_lower'],
}, {}];

1;
# ABSTRACT: Country code (alpha-2 or alpha-3)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::country::code - Country code (alpha-2 or alpha-3)

=head1 VERSION

This document describes version 0.003 of Sah::Schema::country::code (from Perl distribution Sah-Schemas-Country), released on 2019-11-29.

=head1 DESCRIPTION

Accept only current (not retired) codes. Alpha-2 or alpha-3 codes are accepted.

Code will be converted to lowercase.

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

L<Sah::Schema::country::code::alpha2>

L<Sah::Schema::country::code::alpha3>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
