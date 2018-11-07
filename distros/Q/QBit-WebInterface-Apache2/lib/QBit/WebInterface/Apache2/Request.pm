package QBit::WebInterface::Apache2::Request;
$QBit::WebInterface::Apache2::Request::VERSION = '0.006';
use qbit;

use base qw(QBit::WebInterface::Request);

__PACKAGE__->mk_accessors(qw(r));

sub http_header {
    my ($self, $name) = @_;

    my $value = $self->r->headers_in->get($name);

    return defined($value) ? $value : '';
}

sub method {shift->r->method()}

sub uri {shift->r->unparsed_uri()}

sub scheme {
    return $_[0]->r->subprocess_env('SSL_SERVER_S_DN_CN')
      ? 'https'
      : 'http';
}

sub server_name {shift->r->get_server_name()}

sub server_port {shift->r->get_server_port()}

sub remote_addr {shift->r->connection->remote_ip()}

sub query_string {shift->r->args || ''}

sub _read_from_stdin {
    my ($self, $buffer_ref, $size) = @_;

    return $self->r->read($$buffer_ref, $size);
}

TRUE;
