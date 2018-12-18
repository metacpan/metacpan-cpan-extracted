package Sah::Schema::domain::name;

our $DATE = '2018-12-17'; # DATE
our $VERSION = '0.001'; # VERSION

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
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::domain::name

=head1 VERSION

version 0.001

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
