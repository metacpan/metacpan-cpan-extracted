package Protocol::XMLRPC;

use strict;
use warnings;

our $VERSION = '0.10';

1;
__END__

=head1 NAME

Protocol::XMLRPC - XML-RPC implementation

=head1 SYNOPSIS

    my $method_call = Protocol::XMLRPC::MethodCall->new(name => 'foo.bar');
    $method_call->add_param(1);
    $method_call = Protocol::XMLRPC::MethodCall->parse(...);

    my $method_response = Protocol::XMLRPC::MethodResponse->new;
    $method_response->param(1);
    $method_response = Protocol::XMLRPC::MethodResponse->parse(...);

=head1 DESCRIPTION

L<Protocol::XMLRPC> is an XML-RPC protocol implementation. Method parameters
types are guessed just like in L<JSON>, but you can pass explicit type if
guessing is wrong for you. Read more about parameter creation at
L<Protocol::XMLRPC::ValueFactory>.

It differs from other modules because it doesn't provide any mechanism for
making actual HTTP requests. This way it can be used either in async or sync
modes with your favorite http client or a web framework.

=head1 DOCUMENTATION

=over 4

=item L<Protocol::XMLRPC::MethodCall>

Create and parse XML-RPC request.

=item L<Protocol::XMLRPC::MethodResponse>

Create and parse XML-RPC response.

=item L<Protocol::XMLRPC::Client>

A simple client for XML-RPC calls.

=item L<Protocol::XMLRPC::Dispatcher>

A simple server for XML-RPC calls.

=back

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/protocol-xmlrpc/

=head1 CREDITS

Jan Harders

Knut Arne Bjørndal

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009-2012, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
