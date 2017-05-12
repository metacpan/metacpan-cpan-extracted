package Perinci::Web;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.01'; # VERSION

1;
# ABSTRACT: Rinci/Riap-based web application framework

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Web - Rinci/Riap-based web application framework

=head1 VERSION

This document describes version 0.01 of Perinci::Web (from Perl distribution Perinci-Web), released on 2015-09-04.

=head1 SYNOPSIS

=head1 DESCRIPTION

Perinci::Web is a web application framework. It will let you define routes to
your functions (accessed via L<Riap> protocol), templating, assets, etc. The
spirit is much like L<Perinci::CmdLine>: to let you write as much core
functionality in normal Perl functions equipped with metadata rich enough to
make converting/using them in a web application to be as easy as possible.

It is not implemented yet.

=head1 ATTRIBUTES

=head1 METHODS

=head2 $pweb = Perinci::Web->new(%opts)

Create an instance.

=head2 $pweb->app() -> CODE

Generate a PSGI application. You can then deploy your web application using any
PSGI web server.

=head1 FAQ

=head2 How does Perinci::Web compare with other web application frameworks?

The main difference is that Perinci::Web accesses your code through L<Riap>
protocol, not directly. This means that aside from local Perl code,
Perinci::Web can also provide web application interface for code in remote
hosts/languages.

Aside from this difference, there are several others: XXX

=head2 How do I provide HTTP API for my web application?

This is one of the reasons why the L<Riap> (specifically, L<Riap::HTTP>)
protocol was created. You can easily provide API access to your functions using
L<Perinci::Access::HTTP::Server>.

=head1 SEE ALSO

L<Perinci>, L<Rinci>, L<Riap>.

L<Perinci::CmdLine>. This is a command-line application framework and not a web
application framework, but Perinci::Web is created in the same spirit as this
module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Web>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Web>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Web>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
