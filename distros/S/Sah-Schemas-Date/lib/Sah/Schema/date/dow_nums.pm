package Sah::Schema::date::dow_nums;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-Date'; # DIST
our $VERSION = '0.013'; # VERSION

our $schema = ['array' => {
    summary => 'Array of day-of-week numbers (1-7, 1=Monday)',
    of => ['date::dow_num', {}, {}],
    'x.perl.coerce_rules' => ['From_str::comma_sep'],
    'x.completion' => ['date_dow_nums'],
    examples => [
        {value=>'', valid=>1, validated_value=>[]},
        {value=>1, valid=>1, validated_value=>[1]},
        {value=>[1], valid=>1},
        {value=>[1,7], valid=>1},
        {value=>'1,7', valid=>1, validated_value=>[1,7]},
        {value=>[1,7,8], valid=>0},
        {value=>'1,7,8', valid=>0},
    ],
}, {}];

1;

# ABSTRACT: Array of day-of-week numbers (1-7, 1=Monday)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::dow_nums - Array of day-of-week numbers (1-7, 1=Monday)

=head1 VERSION

This document describes version 0.013 of Sah::Schema::date::dow_nums (from Perl distribution Sah-Schemas-Date), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("date::dow_nums*");
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
             schema => ['date::dow_nums*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 ""  # valid, becomes []

 1  # valid, becomes [1]

 [1]  # valid

 [1,7]  # valid

 "1,7"  # valid, becomes [1,7]

 [1,7,8]  # INVALID

 "1,7,8"  # INVALID

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
