package Sah::Schema::twitter::username;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Sah-Schemas-Twitter'; # DIST
our $VERSION = '0.002'; # VERSION

our $schema = ["cistr", {
    summary => 'Twitter username',
    match => '\A[0-9A-Za-z_]{1,15}\z',

    examples => [
        {value=>'', valid=>0},
        {value=>'foo', valid=>1},
        {value=>'f2345678901234567', valid=>0, summary=>'Too long'},
    ],
}, {}];

1;

# ABSTRACT: Twitter username

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::twitter::username - Twitter username

=head1 VERSION

This document describes version 0.002 of Sah::Schema::twitter::username (from Perl distribution Sah-Schemas-Twitter), released on 2020-03-11.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("twitter::username*");
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
             schema => ['twitter::username*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 ""  # INVALID

 "foo"  # valid

 "f2345678901234567"  # INVALID (Too long)

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

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
