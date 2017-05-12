package Perinci;

our $VERSION = '0.32'; # VERSION

1;
# ABSTRACT: Collection of Perl modules for Rinci and Riap

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci - Collection of Perl modules for Rinci and Riap

=head1 VERSION

This document describes version 0.32 of Perinci (from Perl distribution Perinci), released on 2015-09-03.

=head1 DESCRIPTION

Perinci is a collection of modules for implementing/providing tools pertaining
to L<Rinci> and L<Riap>, spread over several distributions for faster
incremental releases. These tools include:

=over 4

=item * Wrapper

L<Perinci::Sub::Wrapper> is the subroutine wrapper which implements/enforces
many of the metadata properties, like argument validation (using information in
C<args>) as well as offers features like assign default values, convert argument
passing style, automatically envelope function result, etc.

It is extensible so you can implement wrapper for your properties too.

=item * Riap clients and servers (Perinci::Access::*)

L<Perinci::Access::Perl> is a client/server (well, neither really, since
everything is in-process) to access Perl modules/functions using the Riap
protocol. It is basically a way to call your modules/functions using URI syntax;
it also dictates a bit on how you should write your functions and where to put
the metadata, though it provides a lot of flexibility.

L<Perinci::Access::HTTP::Client> and L<Perinci::Access::HTTP::Server> is a pair
of client/server library to access Perl modules/functions using Riap over HTTP,
implementing the L<Riap::HTTP> specification.

L<Perinci::Access::Simple::Client>, L<Perinci::Access::Simple::Server::Socket>,
L<Perinci::Access::Simple::Server::Pipe> are client/server libraries that
implement L<Riap::Simple>, either via TCP/Unix socket or piping.

L<Perinci::Access> is a simple wrapper for all Riap clients, you give it a
URL/module name/whatever and it will try to select the appropriate Riap client
for you.

=item * Command-line libraries

L<Perinci::CmdLine> is an extensible and featureful command-line library to
create command-line programs and API clients. Features include: transparent
remote access (thanks to Riap), command-line options parsing, --help message,
shell tab completion, etc.

=item * Documentation tools

See CPAN for L<Perinci::To::POD>, L<Perinci::To::Text>, L<Perinci::To::HTML>.
These document generators support translations based on L<Locale::Maketext>.

=item * Function/metadata generators

These are convenient tools to generate common/generic function and/or metadata.
For example, L<Perinci::Sub::Gen::AccessTable> can generate accessor function +
metadata for table data.

See CPAN for more C<Perinci::Sub::Gen::*> modules.

=item * Others

Samples: L<Perinci::Use>, L<Perinci::Exporter>, L<Test::Rinci>.

See CPAN for more Perinci::* modules.

=back

To get started, read L<Perinci::Manual::Tutorial>.

=head1 FAQ

=head2 What does Perinci mean?

Perinci is taken from Indonesian word, meaning: to specify, to explain in more
detail. It can also be an abbreviation for "B<Pe>rl implementation of B<Rinci>".

=head1 SEE ALSO

L<Rinci>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci>

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
