package QBit::WebInterface::FastCGI::Request;
$QBit::WebInterface::FastCGI::Request::VERSION = '0.006';
use qbit;

use base qw(QBit::WebInterface::Request);

sub http_header {
    my ($self, $name) = @_;

    $name =~ s/-/_/g;
    my $value = $ENV{'HTTP_' . uc($name)};

    return defined($value) ? $value : '';
}

sub method {$ENV{'REQUEST_METHOD'}}

sub uri {$ENV{'REQUEST_URI'}}

sub scheme {$ENV{'SCHEME'}}

sub server_name {$ENV{'SERVER_NAME'}}

sub server_port {$ENV{'SERVER_PORT'}}

sub remote_addr {$ENV{'REMOTE_ADDR'}}

sub query_string {$ENV{'QUERY_STRING'}}

sub _read_from_stdin {
    my ($self, $buffer_ref, $size) = @_;

    my ($in) = $self->{'request'}->GetHandles();

    return read($in, $$buffer_ref, $size);
}

TRUE;
