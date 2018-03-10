package Sah::Schema::currency::code;

our $DATE = '2018-03-08'; # DATE
our $VERSION = '0.001'; # VERSION

use Locale::Codes::Currency_Codes ();

my $codes = [sort keys %{ $Locale::Codes::Data{'currency'}{'code2id'}{alpha} }];
die "Can't extract any currency codes from Locale::Codes::Currency_Codes"
    unless @$codes;

our $schema = [str => {
    summary => 'Currency code',
    description => <<'_',

Accept only current (not retired) codes.

_
    match => '\A[A-Z]{3}\z',
    in => $codes,
    'x.perl.coerce_rules' => ['str_toupper'],
}, {}];

1;
# ABSTRACT: Currency code

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::currency::code - Currency code

=head1 VERSION

This document describes version 0.001 of Sah::Schema::currency::code (from Perl distribution Sah-Schemas-Currency), released on 2018-03-08.

=head1 DESCRIPTION

Accept only current (not retired) codes.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Currency>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Currency>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Currency>

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
