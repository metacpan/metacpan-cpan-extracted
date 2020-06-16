package Sah::Schema::domain::name;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-Domain'; # DIST
our $VERSION = '0.005'; # VERSION

our $schema = [str => {
    summary => 'Domain name',
    description => <<'_',

This schema is currently very simple, it just checks for strings with this
pattern:

    /^[0-9a-z]([0-9a-z-]*[0-9a-z])?
      (\.[0-9a-z]([0-9a-z-]*[0-9a-z]?))+$/x

and coerced to lowercase. Does not allow internationalized domain name (but you
can use its Punycode (xn--) representation. Does not check for valid public
suffixes.

_
    match => '\A[0-9a-z]([0-9a-z-]*[0-9a-z])?(\.[0-9a-z]([0-9a-z-]*[0-9a-z]?))+\z',
    'x.perl.coerce_rules'=>['From_str::to_lower'],

    examples => [
        {value=>'FOO-BAR.COM', valid=>1, validated_value=>'foo-bar.com'},
        {value=>'foobar', valid=>0, summary=>'At least two parts are needed'},
        {value=>'foo-.com', valid=>0, validated_value=>'dash at the end of part is not allowed'},
        {value=>'-foo.com', valid=>0, validated_value=>'dash at the beginning of part is not allowed'},
        {value=>'foo!.com', valid=>0, validated_value=>'invalid character !'},
        {value=>'foo_bar.com', valid=>0, validated_value=>'invalid character _'},
    ],
}, {}];

1;
# ABSTRACT: Domain name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::domain::name - Domain name

=head1 VERSION

This document describes version 0.005 of Sah::Schema::domain::name (from Perl distribution Sah-Schemas-Domain), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("domain::name*");
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
             schema => ['domain::name*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 "FOO-BAR.COM"  # valid, becomes "foo-bar.com"

 "foobar"  # INVALID (At least two parts are needed)

 "foo-.com"  # INVALID

 "-foo.com"  # INVALID

 "foo!.com"  # INVALID

 "foo_bar.com"  # INVALID

=head1 DESCRIPTION

This schema is currently very simple, it just checks for strings with this
pattern:

 /^[0-9a-z]([0-9a-z-]*[0-9a-z])?
   (\.[0-9a-z]([0-9a-z-]*[0-9a-z]?))+$/x

and coerced to lowercase. Does not allow internationalized domain name (but you
can use its Punycode (xn--) representation. Does not check for valid public
suffixes.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Domain>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Domain>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Domain>

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
