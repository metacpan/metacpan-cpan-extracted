package Sah::Schema::unix::username;

our $DATE = '2019-07-12'; # DATE
our $VERSION = '0.004'; # VERSION

our $schema = [str => {
    summary => 'Unix account name',
    description => <<'_',

The checking follows POSIX rules: does not begin with a hyphen and only contains
[A-Za-z0-9._-].

The above rule allows integers like 1234, which can be confused with UID, so
this schema disallows pure integers.

The maximum length is 32 following libc6's limit.

_
    min_len => 1,
    max_len => 32,
    match => qr/(?=\A[A-Za-z0-9._][A-Za-z0-9._-]{0,31}\z)(?=.*[A-Za-z._-])/,
}, {}];

1;
# ABSTRACT: Unix account name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::unix::username - Unix account name

=head1 VERSION

This document describes version 0.004 of Sah::Schema::unix::username (from Perl distribution Sah-Schemas-Unix), released on 2019-07-12.

=head1 DESCRIPTION

The checking follows POSIX rules: does not begin with a hyphen and only contains
[A-Za-z0-9._-].

The above rule allows integers like 1234, which can be confused with UID, so
this schema disallows pure integers.

The maximum length is 32 following libc6's limit.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Unix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Unix>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Unix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
