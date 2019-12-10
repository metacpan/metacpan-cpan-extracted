package Sah::Schema::unix::local_username;

# AUTHOR
our $DATE = '2019-12-09'; # DATE
our $DIST = 'Sah-Schemas-Unix'; # DIST
our $VERSION = '0.009'; # VERSION

our $schema = ['unix::username' => {
    summary => 'Unix user name that must exist on the system',
    description => <<'_',

Support coercion from UID.

_
    'x.perl.coerce_rules' => ['From_int::convert_uid_to_unix_user', 'From_str::check_unix_user_exists'],
}, {}];

1;
# ABSTRACT: Unix user name that must exist on the system

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::unix::local_username - Unix user name that must exist on the system

=head1 VERSION

This document describes version 0.009 of Sah::Schema::unix::local_username (from Perl distribution Sah-Schemas-Unix), released on 2019-12-09.

=head1 DESCRIPTION

Support coercion from UID.

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
