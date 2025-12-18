package PAGI;

use strict;
use warnings;

our $VERSION = '0.001001';

1;

__END__

=head1 NAME

PAGI - Perl Asynchronous Gateway Interface

=head1 SYNOPSIS

    # PAGI is in active development on GitHub
    # See https://github.com/jjn1056/pagi

=head1 DESCRIPTION

PAGI (Perl Asynchronous Gateway Interface) is a Perl implementation inspired by
Python's ASGI specification. It provides a standard interface between async-capable
Perl web servers and applications, enabling high-concurrency web applications with
modern features like WebSockets and HTTP/2.

B<This CPAN distribution is a namespace placeholder.> Active development is
happening on GitHub.

=head1 STATUS

B<EXPERIMENTAL> - PAGI is under active development and not yet ready for
production use. The API is subject to change without notice.

=head1 REPOSITORY

Development is hosted on GitHub:

L<https://github.com/jjn1056/pagi>

To contribute or follow development:

    git clone https://github.com/jjn1056/pagi.git

Issues and pull requests are welcome.

=head1 SEE ALSO

=over 4

=item * L<IO::Async> - The async framework PAGI is built on

=item * L<Plack> - PSGI reference implementation (synchronous counterpart)

=item * L<PSGI> - Perl Web Server Gateway Interface specification

=item * L<https://asgi.readthedocs.io/> - Python ASGI specification

=back

=head1 AUTHOR

John Napiorkowski E<lt>jjnapiork@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by John Napiorkowski.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
