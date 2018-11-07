package Exception::WebInterface::OwnServer::BadRequest;
$Exception::WebInterface::OwnServer::BadRequest::VERSION = '0.008';
use base qw(Exception);

package QBit::WebInterface::OwnServer::Request;
$QBit::WebInterface::OwnServer::Request::VERSION = '0.008';
use qbit;

use base qw(QBit::WebInterface::Request);

__PACKAGE__->mk_ro_accessors(qw(socket));

my $CHOMP_QR = qr/[\r\n]+$/;

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    my $request_str = readline($self->socket);
    $request_str = '' unless defined($request_str);
    $request_str =~ s/$CHOMP_QR//;

    if ($request_str =~ /^(GET|POST|HEAD)\s+(.+?)\s+HTTP\/1\.[01]$/) {
        $self->{'method'} = $1;
        $self->{'uri'}    = $2;
    } else {
        throw Exception::WebInterface::OwnServer::BadRequest gettext('Bad request');
    }

    $self->{'query_string'} = $self->{'uri'} =~ /\?(.+)$/ ? $1 : '';

    while ((my $str = readline($self->socket)) !~ /^[\r\n]{1,2}$/) {
        $str =~ s/$CHOMP_QR//;
        my ($name, $value) = split(/:\s*/, $str, 2);

        $name = uc($name);
        $name =~ tr/-/_/;

        $self->{'headers'}{$name} = $value;
    }
}

sub http_header {
    my ($self, $name) = @_;

    $name = uc($name);
    $name =~ tr/-/_/;

    my $value = $self->{'headers'}{$name};

    return defined($value) ? $value : '';
}

sub method {shift->{'method'}}

sub uri {shift->{'uri'}}

sub scheme {'http'}

sub server_name {'localhost'}

sub server_port {shift->{'port'}}

sub remote_addr {'127.0.0.1'}

sub query_string {shift->{'query_string'}}

sub _read_from_stdin {
    my ($self, $buffer_ref, $size) = @_;

    $self->{'__CAN_READ_BYTES__'} = $self->http_header('CONTENT_LENGTH') unless exists($self->{'__CAN_READ_BYTES__'});
    $size = $self->{'__CAN_READ_BYTES__'} if $size > $self->{'__CAN_READ_BYTES__'};

    my $readed = read($self->socket, $$buffer_ref, $size);
    $self->{'__CAN_READ_BYTES__'} -= $readed;

    return $readed;
}

TRUE;
