package POEx::Role::PSGIServer::ProxyWriter;
$POEx::Role::PSGIServer::ProxyWriter::VERSION = '1.150280';
#ABSTRACT: (DEPRECATED) Provides a push writer for PSGI applications to use
use MooseX::Declare;

class POEx::Role::PSGIServer::ProxyWriter {
    use MooseX::Types::Moose(':all');
    use POEx::Types::PSGIServer(':all');


    has server_context => (
        is => 'ro',
        isa => PSGIServerContext,
        required => 1
    );


    has proxied => (
        is => 'ro',
        isa => Object,
        weak_ref => 1,
        required => 1,
    );


    method write($data) {
        $self->proxied->write($self->server_context, $data);
    }


    method close() {
        $self->proxied->close($self->server_context);
    }


    method poll_cb(CodeRef $coderef) {
        my $on_flush = sub { $self->$coderef() };
        my $id = $self->server_context->{wheel}->ID;
        $self->proxied->set_wheel_flusher($id => $on_flush);
        $on_flush->();
    }
}
1;

__END__

=pod

=head1 NAME

POEx::Role::PSGIServer::ProxyWriter - (DEPRECATED) Provides a push writer for PSGI applications to use

=head1 VERSION

version 1.150280

=head1 PUBLIC_ATTRIBUTES

=head2 server_context

    is: ro, isa: PSGIServerContext, required: 1

This is the server context from POEx::Role::PSGIServer. It is needed to determine the semantics of the current request

=head2 proxied

    is: ro, isa: Object, weak_ref: 1, required: 1

This is the actual object that consumes POEx::Role::PSGIServer. It is weakened to make sure it is properly collected when the connection closes

=head1 PUBLIC_METHODS

=head2 write

    ($data)

write proxies to the weakened PSGIServer consumer object passing along the L</server_context>

=head2 close

close is proxied to the weakened PSGIServer consumer passing along L</server_context>

=head2 poll_cb

    (CodeRef $coderef)

poll_cb is provided to complete the interface. The first argument to $coderef will be $self

=head1 AUTHOR

Nicholas Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
