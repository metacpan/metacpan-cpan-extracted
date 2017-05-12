package QBit::WebInterface::Apache2;
$QBit::WebInterface::Apache2::VERSION = '0.004';
use qbit;

use base qw(QBit::WebInterface);

use Apache2::Connection;
use Apache2::RequestIO;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use URI::Escape qw(uri_escape_utf8);

use QBit::WebInterface::Apache2::Request;

sub handler : method {
    my ($self, $r) = @_;

    $self = $self->new() unless blessed($self);

    $self->request(QBit::WebInterface::Apache2::Request->new(r => $r));

    $self->build_response();

    $r->err_headers_out->add('Set-Cookie' => $_->as_string()) foreach values(%{$self->response->cookies});

    while (my ($key, $value) = each(%{$self->response->headers})) {
        $r->headers_out->add($key => $value);
    }

    $r->content_type($self->response->content_type);
    $r->headers_out->add(
        'Content-Disposition' => 'attachment; filename="' . $self->_escape_filename($self->response->filename) . '"')
      if $self->response->filename;

    $r->headers_out->add(Location => $self->response->location)
      if $self->response->location;

    eval {
        $r->print(
            ref($self->response->data)
            ? ${$self->response->data}
            : $self->response->data
        ) if defined($self->response->data);
    };

    my $status = $self->response->status;
    $r->status($status) if defined($status);

    $self->request(undef);
    $self->response(undef);

    return Apache2::Const::OK;
}

sub get_cmd {
    my ($self) = @_;

    my ($path, $cmd);
    if ($self->request->uri() =~ /^\/([^?\/]+)(?:\/([^\/?#]+))?/) {
        ($path, $cmd) = ($1, $2);
    } else {
        ($path, $cmd) = $self->default_cmd();
    }

    $path = '' unless defined($path);
    $cmd  = '' unless defined($cmd);

    return ($path, $cmd);
}

sub make_cmd {
    my ($self, $new_cmd, $new_path, @params) = @_;

    my %vars = defined($params[0])
      && ref($params[0]) eq 'HASH' ? %{$params[0]} : @params;

    my ($path, $cmd) = $self->get_cmd();

    $path = uri_escape_utf8($self->_get_new_path($new_path, $path));
    $cmd = uri_escape_utf8($self->_get_new_cmd($new_cmd, $cmd));

    return "/$path/$cmd"
      . (
        %vars
        ? '?'
          . join(
            $self->get_option('link_param_separator', '&amp;'),
            map {uri_escape_utf8($_) . '=' . uri_escape_utf8($vars{$_})} keys(%vars)
          )
        : ''
      );
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::WebInterface::Apache2 - Package for connect WebInterface to Apache 2.

=head1 GitHub

https://github.com/QBitFramework/QBit-WebInterface-Apache2

=head1 Install

=over

=item *

cpanm QBit::WebInterface::Apache2

=item *

apt-get install libqbit-webinterface-apache2-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut
