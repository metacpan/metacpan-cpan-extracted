package Sah::Schema::cryptoexchange::account;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-App-cryp'; # DIST
our $VERSION = '0.009'; # VERSION

our $schema = [str => {
    summary => 'Account at a cryptocurrency exchange',
    description => <<'_',

The format of this data is "<cryptoexchange>/<account>" where "<cryptoexchange>"
is the name of cryptoexchange (can be code, name or safename, but will be
normalized to its safename) and <account> is account nickname in the
cryptoexchange and must match /\A[A-Za-z0-9_-]+\z/. The "/<account>" part is
optional and will be assumed to be "/default" if not specified.

_
    'x.completion' => 'cryptoexchange_account',
    'x.perl.coerce_rules' => ['From_str::normalize_cryptoexchange_account'],
    examples => [
        {
            summary => 'Invalid account syntax',
            value   => 'indodax/a b',
            valid   => 0,
        },
        {
            summary => 'Account too long',
            value   => 'indodax/'.('a' x 65),
            valid   => 0,
        },
        {
            summary => 'Unknown cryptoexchange',
            value   => 'foo/acc1',
            valid   => 0,
        },
        {
            summary => 'Valid',
            value   => 'indodax',
            valid   => 1,
            validated_value => 'indodax/default',
        },
    ],
}, {}];

1;
# ABSTRACT: Account at a cryptocurrency exchange

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cryptoexchange::account - Account at a cryptocurrency exchange

=head1 VERSION

This document describes version 0.009 of Sah::Schema::cryptoexchange::account (from Perl distribution Sah-Schemas-App-cryp), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("cryptoexchange::account*");
 say $vdr->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create a validator to return error message, coerced value,
 # even validators in other languages like JavaScript, from the same schema.
 # See its documentation for more details.

Using in L<Rinci> function metadata (to be used with L<Perinci::CmdLine>, etc):

 package MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['cryptoexchange::account*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 "indodax/a b"  # INVALID (Invalid account syntax)

 "indodax/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"  # INVALID (Account too long)

 "foo/acc1"  # INVALID (Unknown cryptoexchange)

 "indodax"  # valid, becomes "indodax/default"

=head1 DESCRIPTION

The format of this data is "<cryptoexchange>/<account>" where "<cryptoexchange>"
is the name of cryptoexchange (can be code, name or safename, but will be
normalized to its safename) and <account> is account nickname in the
cryptoexchange and must match /\A[A-Za-z0-9_-]+\z/. The "/<account>" part is
optional and will be assumed to be "/default" if not specified.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-App-cryp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-App-cryp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-App-cryp>

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
