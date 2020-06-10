package Sah::Schema::cpan::pause_id;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-CPAN'; # DIST
our $VERSION = '0.010'; # VERSION

use strict;
use Regexp::Pattern::CPAN;

our $schema = ["str", {
    summary => "PAUSE author ID",
    match => qr/\A$Regexp::Pattern::CPAN::RE{pause_id}{pat}\z/,
    'x.perl.coerce_rules'=>['From_str::to_upper'],
    'x.completion'=>['lcpan_authorid'],
    examples => [
        {value=>'', valid=>0},
        {value=>'perlancar', valid=>1, validated_value=>'PERLANCAR'},
        {value=>'perlancar2', valid=>0, summary=>'Too long'},
    ],
}, {}];

1;

# ABSTRACT: PAUSE author ID

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cpan::pause_id - PAUSE author ID

=head1 VERSION

This document describes version 0.010 of Sah::Schema::cpan::pause_id (from Perl distribution Sah-Schemas-CPAN), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("cpan::pause_id*");
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
             schema => ['cpan::pause_id*'],
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

 "perlancar"  # valid, becomes "PERLANCAR"

 "perlancar2"  # INVALID (Too long)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-CPAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-CPAN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-CPAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern::CPAN>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
