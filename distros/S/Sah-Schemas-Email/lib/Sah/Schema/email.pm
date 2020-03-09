package Sah::Schema::email;

our $DATE = '2020-03-08'; # DATE
our $VERSION = '0.003'; # VERSION

# we deliberately are very loose with the regex here, to be very flexible
our $schema = ["str", {
    summary => 'Email address',
    match => '@',

    examples => [
        {value=>'foo', valid=>0},
        {value=>'foo@bar', valid=>1},
        {value=>'<foo@bar>', valid=>1},
        {value=>'"some name" <foo@bar.baz>', valid=>1},
    ],
}, {}];

1;

# ABSTRACT: Email address

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::email - Email address

=head1 VERSION

This document describes version 0.003 of Sah::Schema::email (from Perl distribution Sah-Schemas-Email), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("email*");
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
             schema => ['email*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 "foo"  # INVALID

 "foo\@bar"  # valid

 "<foo\@bar>"  # valid

 "\"some name\" <foo\@bar.baz>"  # valid

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Email>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Email>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Email>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
