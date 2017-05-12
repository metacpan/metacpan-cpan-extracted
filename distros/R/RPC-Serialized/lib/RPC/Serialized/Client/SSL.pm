package RPC::Serialized::Client::SSL;
{
  $RPC::Serialized::Client::SSL::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized::Client';

use IO::Socket::SSL;
use RPC::Serialized::Config;
use RPC::Serialized::Exceptions;

sub new {
    my $class = shift;
    my $params = RPC::Serialized::Config->parse(@_);

    my $socket = IO::Socket::SSL->new($params->io_socket_inet)
        or throw_system "Failed to create socket: ".IO::Socket::SSL::errstr();

    return $class->SUPER::new(
        $params, {rpc_serialized => {ifh => $socket, ofh => $socket}},
    );
}

1;

# ABSTRACT: SSL based RPC client


__END__
=pod

=head1 NAME

RPC::Serialized::Client::SSL - SSL based RPC client

=head1 VERSION

version 1.123630

=head1 SYNOPSIS

 use RPC::Serialized::Client::SSL;
  
 my $c = RPC::Serialized::Client::SSL->new({
     io_socket_ssl => {PeerPort => 20203},
 });
  
 my $result = $c->remote_sub_name(qw/ some data /);
     # remote_sub_name gets mapped to an invocation on the RPC server
     # it's best to wrap this in an eval{} block

=head1 DESCRIPTION

This module allows you to communicate with an L<RPC::Serialized> server over
IPv4 Internet Domain sockets, using SSL encapsulation.

What you need to know is that the options to this module are those you would
normally pass to an instance of L<IO::Socket::SSL>, so check out the manual
page for that to see what features are available. As in the L</SYNOPSIS>
example above, pass the options in a hash reference mapped to the key
C<io_socket_ssl>.

For further information on how to pass these settings into C<RPC::Serialized>,
and make RPC calls against the server, please see the L<RPC::Serialized>
manual page.

=head1 THANKS

Kindly submitted by Oleg A. Mamontov.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

