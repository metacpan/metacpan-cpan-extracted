use strict; use warnings;

package Net::OAuth2Server;
our $VERSION = '0.006';

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::OAuth2Server - A light, simple, flexible OAuth2 server framework

=head1 DISCLAIMER

B<I cannot promise that the API is fully stable yet.>
For that reason, no documentation is provided.

=head1 DESCRIPTION

A server-side OAuth2 framework with the following aims:

=over 2

=item Well designed for direct use as-is within a web application:

Application programmers should have a reasonable abstraction to build on
so they can fill in the specifics of their application
without having to reimplement significant parts of the protocol anyway.

=item Extensible enough as a framework to implement any OAuth2 extension:

It should be possible to implement any OAuth2 extension
such that it can easily be shipped as a CPAN module.

=item Independent from specific web frameworks:

It should not be necessary to reimplement OAuth2 as a plugin or extension
for every single framework.

=item Frugal in dependencies and means of implementation:

OAuth2 is not deep or clever technology, it is glue.
There is no need for anything deep or clever in an implementation of it.

=back

=head1 SEE ALSO

This is a very distant descendant of the server portion of L<OAuth::Lite2>.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
