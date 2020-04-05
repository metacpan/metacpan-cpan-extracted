package Sah::Schema::youtube::videoid;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Sah-Schemas-YouTube'; # DIST
our $VERSION = '0.003'; # VERSION

our $schema = [str => {
    summary => 'YouTube video ID',
    len => 11,
    match => '\A[A-Za-z0-9_-]{11}\z',

    examples => [
        {value=>'', valid=>0},
        {value=>'ElSJb6CmS3c', valid=>1},
        {value=>'ElSJb6CmS3c_', valid=>0, summary=>'Too long'},
    ],
}, {}];

1;
# ABSTRACT: YouTube video ID

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::youtube::videoid - YouTube video ID

=head1 VERSION

This document describes version 0.003 of Sah::Schema::youtube::videoid (from Perl distribution Sah-Schemas-YouTube), released on 2020-03-11.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("youtube::videoid*");
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
             schema => ['youtube::videoid*'],
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

 "ElSJb6CmS3c"  # valid

 "ElSJb6CmS3c_"  # INVALID (Too long)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-YouTube>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-YouTube>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-YouTube>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
