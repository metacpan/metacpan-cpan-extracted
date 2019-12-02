package Sah::Schema::language::code::alpha2;

our $DATE = '2019-11-29'; # DATE
our $VERSION = '0.003'; # VERSION

use Locale::Codes::Language_Codes ();

my $codes = [sort (
    keys(%{ $Locale::Codes::Data{'language'}{'code2id'}{'alpha-2'} }),
)];
die "Can't extract language codes from Locale::Codes::Language_Codes"
    unless @$codes;

our $schema = [str => {
    summary => 'Language code (alpha-2)',
    description => <<'_',

Accept only current (not retired) codes. Only alpha-2 codes are accepted.

_
    match => '\A[a-z]{2}\z',
    in => $codes,
    'x.perl.coerce_rules' => ['From_str::to_lower'],
}, {}];

1;
# ABSTRACT: Language code (alpha-2)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::language::code::alpha2 - Language code (alpha-2)

=head1 VERSION

This document describes version 0.003 of Sah::Schema::language::code::alpha2 (from Perl distribution Sah-Schemas-Language), released on 2019-11-29.

=head1 DESCRIPTION

Accept only current (not retired) codes. Only alpha-2 codes are accepted.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Language>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Language>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Language>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::language::code::alpha3>

L<Sah::Schema::language::code>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
