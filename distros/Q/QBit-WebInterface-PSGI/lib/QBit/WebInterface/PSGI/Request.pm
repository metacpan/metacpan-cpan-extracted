package QBit::WebInterface::PSGI::Request;
$QBit::WebInterface::PSGI::Request::VERSION = '0.005';
use qbit;

use base qw(QBit::WebInterface::Request);

sub http_header {
    my ($self, $name) = @_;

    $name =~ s/-/_/g;
    $name = uc($name);
    my $value = $self->{'ENV'}{'HTTP_' . $name} // $self->{'ENV'}{$name};

    return defined($value) ? $value : '';
}

sub method {shift->{'ENV'}{'REQUEST_METHOD'}}

sub uri {shift->{'ENV'}{'REQUEST_URI'}}

sub scheme {shift->{'ENV'}{'psgi.url_scheme'}}

sub server_name {shift->{'ENV'}{'SERVER_NAME'}}

sub server_port {shift->{'ENV'}{'SERVER_PORT'}}

sub remote_addr {shift->{'ENV'}{'REMOTE_ADDR'}}

sub query_string {shift->{'ENV'}{'QUERY_STRING'}}

sub _read_from_stdin {
    my ($self, $buffer_ref, $size) = @_;

    return read($self->{'ENV'}{'psgi.input'}, $$buffer_ref, $size);
}

TRUE;
