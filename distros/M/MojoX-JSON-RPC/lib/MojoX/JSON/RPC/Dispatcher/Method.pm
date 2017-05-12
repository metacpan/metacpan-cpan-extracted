package MojoX::JSON::RPC::Dispatcher::Method;

use Mojo::Base -base;

has id              => undef;
has method          => undef;
has params          => undef;
has result          => undef;
has is_notification => 0;

has error_code    => undef;
has error_message => undef;
has error_data    => undef;

sub clear_error {
    my ($self) = @_;
    return $self->error( undef, undef, undef );
}

sub error {
    my ( $self, $code, $message, $data ) = @_;
    $self->error_code($code);
    $self->error_message($message);
    $self->error_data($data);
    return $self;
}

sub has_error {
    my ($self) = @_;
    return !!$self->error_code;
}

sub internal_error {
    my ( $self, $msg ) = @_;
    return $self->error( -32603, 'Internal error.', $msg );
}

sub invalid_params {
    my ( $self, $msg ) = @_;
    return $self->error( -32602, 'Invalid params.', $msg );
}

sub invalid_request {
    my ( $self, $msg ) = @_;
    return $self->error( -32600, 'Invalid Request.', $msg );
}

sub method_not_found {
    my ( $self, $msg ) = @_;
    return $self->error( -32601, 'Method not found.', $msg );
}

sub parse_error {
    my ( $self, $msg ) = @_;
    return $self->error( -32700, 'Parse error.', $msg );
}

sub response {
    my ($self) = @_;
    return {
        jsonrpc => '2.0',
        $self->is_notification ? () : ( id => $self->id ),
        $self->has_error
        ? ( error => {
                code    => $self->error_code,
                message => $self->error_message,
                data    => $self->error_data,
            }
            )
        : ( result => $self->result )
    };
}

1;

__END__

=head1 NAME

MojoX::JSON::RPC::Dispatcher::Method - The data holder between RPC requests and responses.

=head1 SYNOPSIS

    use MojoX::JSON::RPC::Dispatcher::Method;

    my $meth = MojoX::JSON::RPC::Dispatcher::Method->new(
       method => 'sum',
       id     => 1
    );

    $meth->error_code(300);

=head1 DESCRIPTION

This module is heavily inspired by L<JSON::RPC::Dispatcher::Procedure>.

=head1 ATTRIBUTES

L<MojoX::JSON::RPC::Dispatcher::Method> implements the following attributes.

=head2 C<id>

Request id.

=head2 C<method>

Request method name.

=head2 C<params>

Request parameters.

=head2 C<result>

Request result.

=head2 C<is_notification>

Indicates whether request is a notification.

=head2 C<error_code>

Error code.

=head2 C<error_message>

Error message.

=head2 C<error_data>

Error data.

=head1 METHODS

L<MojoX::JSON::RPC::Dispatcher::Method> inherits all methods from L<Mojo::Base> and
implements the following new ones.

=head2 C<clear_error>

Clear error code, message and data.

=head2 C<error>

Set error code and message. Optionally set some error data.

    $proc->error(-32602, 'Invalid params');

    $proc->error(-32603, 'Internal error.', '...');


=head2 C<has_error>

Returns a boolean indicating whether an error code has been set.

=head2 C<internal_error>

Sets an Internal Error as defined by the JSON-RPC 2.0 spec.

    $proc->internal_error;

    $proc->internal_error('...');


=head2 C<invalid_params>

Sets an Invalid Params error as defined by the JSON-RPC 2.0 spec.

    $proc->invalid_params;

    $proc->invalid_params('...');

=head2 C<invalid_request>

Sets an Invalid Request error as defined by the JSON-RPC 2.0 spec.

    $proc->invalid_request;

    $proc->invalid_request('...');


=head2 C<method_not_found>

Sets a Method Not Found error as defined by the JSON-RPC 2.0 spec.

    $proc->method_not_found;

    $proc->method_not_found('...');

=head2 C<parse_error>

Sets a Parse error as defined by the JSON-RPC 2.0 spec.

    $proc->parse_error;

    $proc->parse_error('...');

=head2 C<response>

Formats the data stored in this object into the data structure expected
by L<MojoX::JSON::RPC::Dispatcher>, which will ultimately be returned
to the client.

    my $res = $meth->response;

=head1 SEE ALSO

L<MojoX::JSON::RPC::Dispatcher>, L<JSON::RPC::Dispatcher::Procedure>

=cut
