package Perinci::Sub::Util::ResObj;

use strict;
use Carp;

use overload
    q("") => sub {
        my $res = shift; "ERROR $res->[0]: $res->[1]\n" . Carp::longmess();
    };

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-02'; # DATE
our $DIST = 'Perinci-Sub-Util'; # DIST
our $VERSION = '0.471'; # VERSION

1;
# ABSTRACT: An object that represents enveloped response suitable for die()-ing

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Util::ResObj - An object that represents enveloped response suitable for die()-ing

=head1 VERSION

This document describes version 0.471 of Perinci::Sub::Util::ResObj (from Perl distribution Perinci-Sub-Util), released on 2023-07-02.

=head1 SYNOPSIS

Currently unused. See L<Perinci::Sub::Util>'s C<warn_err> and C<die_err>
instead.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Util>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2020, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
