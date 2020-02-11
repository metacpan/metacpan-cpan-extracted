package Sah::Schema::unix::local_uid;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-11'; # DATE
our $DIST = 'Sah-Schemas-Unix'; # DIST
our $VERSION = '0.010'; # VERSION

our $schema = ["unix::uid" => {
    summary => 'User identifier (UID) that has to exist (has associated username) on the system',
    description => <<'_',

Existing means having a user name associated with this UID, i.e. `getpwuid`
returns a record.

Support coercion from an existing user name.

_
    'prefilters' => ['Unix::convert_unix_user_to_uid', 'Unix::check_uid_exists'],
}, {}];

1;
# ABSTRACT: User identifier (UID) that has to exist (has associated username) on the system

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::unix::local_uid - User identifier (UID) that has to exist (has associated username) on the system

=head1 VERSION

This document describes version 0.010 of Sah::Schema::unix::local_uid (from Perl distribution Sah-Schemas-Unix), released on 2020-02-11.

=head1 DESCRIPTION

Existing means having a user name associated with this UID, i.e. C<getpwuid>
returns a record.

Support coercion from an existing user name.

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

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
