package Progress::Any::Output::Null;

use 5.010;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-18'; # DATE
our $DIST = 'Progress-Any'; # DIST
our $VERSION = '0.220'; # VERSION

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub update {
    1;
}

1;
# ABSTRACT: Null output

__END__

=pod

=encoding UTF-8

=head1 NAME

Progress::Any::Output::Null - Null output

=head1 VERSION

This document describes version 0.220 of Progress::Any::Output::Null (from Perl distribution Progress-Any), released on 2022-10-18.

=for Pod::Coverage ^(new|update)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Progress-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Progress-Any>.

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

This software is copyright (c) 2022, 2020, 2018, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Progress-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
