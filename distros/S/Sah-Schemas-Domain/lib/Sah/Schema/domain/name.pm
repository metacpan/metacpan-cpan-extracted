package Sah::Schema::domain::name;

our $DATE = '2018-12-19'; # DATE
our $VERSION = '0.002'; # VERSION

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
    'x.perl.coerce_rules'=>['str_tolower'],
}, {}];

1;
# ABSTRACT: Domain name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::domain::name - Domain name

=head1 VERSION

This document describes version 0.002 of Sah::Schema::domain::name (from Perl distribution Sah-Schemas-Domain), released on 2018-12-19.

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

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
