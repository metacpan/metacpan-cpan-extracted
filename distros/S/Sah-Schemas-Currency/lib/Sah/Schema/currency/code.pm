package Sah::Schema::currency::code;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-02'; # DATE
our $DIST = 'Sah-Schemas-Currency'; # DIST
our $VERSION = '0.005'; # VERSION

use Locale::Codes::Currency_Codes ();

my $codes = [sort keys %{ $Locale::Codes::Data{'currency'}{'code2id'}{alpha} }];
die "Can't extract any currency codes from Locale::Codes::Currency_Codes"
    unless @$codes;

our $schema = [str => {
    summary => 'Currency code',
    description => <<'_',

Accept only current (not retired) codes. Code will be converted to uppercase.

_
    match => '\A[A-Z]{3}\z',
    in => $codes,
    'x.perl.coerce_rules' => ['From_str::to_upper'],
    examples => [
        {data=>'', valid=>0},
        {data=>'idr', valid=>1, res=>'IDR'},
        {data=>'foo', valid=>0},
    ],
}, {}];

1;
# ABSTRACT: Currency code

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::currency::code - Currency code

=head1 VERSION

This document describes version 0.005 of Sah::Schema::currency::code (from Perl distribution Sah-Schemas-Currency), released on 2020-03-02.

=head1 SYNOPSIS

Sample data:

 ""  # INVALID

 "idr"  # valid, becomes "IDR"

 "foo"  # INVALID

=head1 DESCRIPTION

Accept only current (not retired) codes. Code will be converted to uppercase.

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

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
