package Sah::Schema::percent;

our $DATE = '2020-03-08'; # DATE
our $VERSION = '0.008'; # VERSION

our $schema = ['float', {
    summary => 'A float',
    description => <<'_',

This type is basically `float`, with `str_as_percent` coerce rule. So the
percent sign is optional, but the number is always interpreted as percent, e.g.
"1" is interpreted as 1% (0.01).

_
    'x.perl.coerce_rules' => [
        'From_str::as_percent',
    ],

    examples => [
        {value=>0, valid=>1, validated_value=>0},
        {value=>0.5, valid=>1, validated_value=>0.005},
        {value=>5, valid=>1, validated_value=>0.05},
        {value=>'5%', valid=>1, validated_value=>0.05},
    ],
}, {}];

1;
# ABSTRACT: A float

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::percent - A float

=head1 VERSION

This document describes version 0.008 of Sah::Schema::percent (from Perl distribution Sah-Schemas-Float), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("percent*");
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
             schema => ['percent*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 0  # valid, becomes 0

 0.5  # valid, becomes 0.005

 5  # valid, becomes 0.05

 "5%"  # valid, becomes 0.05

=head1 DESCRIPTION

This type is basically C<float>, with C<str_as_percent> coerce rule. So the
percent sign is optional, but the number is always interpreted as percent, e.g.
"1" is interpreted as 1% (0.01).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Float>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Float>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Float>

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
