package Perl::Examples::POD::HTML;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-24'; # DATE
our $DIST = 'Perl-Examples'; # DIST
our $VERSION = '0.096'; # VERSION

1;
# ABSTRACT: Embedding HTML in POD

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Examples::POD::HTML - Embedding HTML in POD

=head1 VERSION

This document describes version 0.096 of Perl::Examples::POD::HTML (from Perl distribution Perl-Examples), released on 2023-02-24.

=head1 DESCRIPTION

HTML can be embedded in POD, using:

 =for HTML <b>some html</b>

or:

 =begin HTML

 <b>some html</b>
 <i>some more html</i>
 ...

 =end HTML

This is explained in L<perlpod>.

=for HTML <b>HTML snippet 1</b>

=begin text

text snippet 1.

 foo bar

 +-----------------+----------------+---------------------+-----------------------------------------+-----------------------------------------+
 | scenario        | module_startup | time                | cpu                                     | filename                                |
 +-----------------+----------------+---------------------+-----------------------------------------+-----------------------------------------+
 | LogAny::Startup | 1              | 2016-01-07T15:05:13 | Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz | LogAny-Startup.2016-01-07T15-05-13.json |
 | LogAny::Startup | 1              | 2016-01-07T15:10:51 | Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz | LogAny-Startup.2016-01-07T15-10-51.json |
 | LogAny::Startup | 1              | 2016-01-10T22:27:48 | Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz | LogAny-Startup.2016-01-10T22-27-48.json |
 +-----------------+----------------+---------------------+-----------------------------------------+-----------------------------------------+

=end text

=begin man

man snippet 1

 foo bar

 +-----------------+----------------+---------------------+-----------------------------------------+-----------------------------------------+
 | scenario        | module_startup | time                | cpu                                     | filename                                |
 +-----------------+----------------+---------------------+-----------------------------------------+-----------------------------------------+
 | LogAny::Startup | 1              | 2016-01-07T15:05:13 | Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz | LogAny-Startup.2016-01-07T15-05-13.json |
 | LogAny::Startup | 1              | 2016-01-07T15:10:51 | Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz | LogAny-Startup.2016-01-07T15-10-51.json |
 | LogAny::Startup | 1              | 2016-01-10T22:27:48 | Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz | LogAny-Startup.2016-01-10T22-27-48.json |
 +-----------------+----------------+---------------------+-----------------------------------------+-----------------------------------------+

=end man

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perl-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perl-Examples>.

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

This software is copyright (c) 2023, 2020, 2018, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
