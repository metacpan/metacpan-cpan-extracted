package Sah::Schema::vivaldi::profile_name;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-19'; # DATE
our $DIST = 'Sah-Schemas-Vivaldi'; # DIST
our $VERSION = '0.001'; # VERSION

our $schema = [str => {
    min_len => 1,
    summary => 'Vivaldi profile name',
    'x.completion' => 'vivaldi_profile_name',
    examples => [
        {
            value   => '',
            valid   => 0,
        },
        {
            value   => 'Person 1',
            valid   => 1,
        },
    ],
}, {}];

1;
# ABSTRACT: Vivaldi profile name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::vivaldi::profile_name - Vivaldi profile name

=head1 VERSION

This document describes version 0.001 of Sah::Schema::vivaldi::profile_name (from Perl distribution Sah-Schemas-Vivaldi), released on 2020-04-19.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("vivaldi::profile_name*");
 say $vdr->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create a validator to return error message, coerced value,
 # even validators in other languages like JavaScript, from the same schema.
 # See its documentation for more details.

Using in L<Rinci> function metadata (to be used in L<Perinci::CmdLine>, etc):

 package MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['vivaldi::profile_name*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 undef  # INVALID

 undef  # valid

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Vivaldi>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Vivaldi>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Vivaldi>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
