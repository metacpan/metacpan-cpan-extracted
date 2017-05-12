package RPC::Any;
use 5.008001;

our $VERSION = '1.00';

1;

__END__

=head1 NAME

RPC::Any - A simple, unified interface to XML-RPC and JSON-RPC.

=head1 DESCRIPTION

RPC::Any is a simple, unified interface to multiple RPC protocols.
Right now it supports L<XML-RPC|http://www.xmlrpc.com/> and all
three versions of L<JSON-RPC|http://groups.google.com/group/json-rpc/web>
(1.0, 1.1, and 2.0).

The goal of RPC::Any is to be simple to use, and to be highly extendable.
RPC::Any is designed to work properly in taint mode, and fully supports
Unicode. It was written for real-world use in a major production
application.

If you're planning to use RPC::Any, you probably want to see
L<RPC::Any::Server>. In the future, there will also be an
C<RPC::Any::Client>.

=head1 SEE ALSO

L<RPC::Any::Server>

=head1 TODO

=over

=item *

C<RPC::Any::Client>

=back

=head1 SUPPORT

Right now, the best way to get support for C<RPC::Any> is to email
the author using the email address in the L</AUTHOR> section below.

=head1 BUGS

RPC::Any is relatively new, but it has very extensive tests and is being
heavily used in a L<major production application|http://www.bugzilla.org/>.
However, there could still be bugs lurking in its code.

You can report a bug by emailing C<bug-RPC-Any@rt.cpan.org> or
by using the RT web interface at
L<https://rt.cpan.org/Ticket/Display.html?Queue=RPC-Any>.

=head1 AUTHOR

Max Kanat-Alexander <mkanat@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 Everything Solved, Inc.

This library (the entirety of RPC-Any) is free software; you
can redistribute it and/or modify it under the terms of the
Artistic License 2.0. For details, see the full text of the
license at L<http://opensource.org/licenses/artistic-license-2.0.php>.

This program is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties. For details, see the full text of the
license at L<http://opensource.org/licenses/artistic-license-2.0.php>.
